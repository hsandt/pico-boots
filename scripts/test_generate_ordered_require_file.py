# Dependencies:
# - tempdir (available via pip)

# tempdir offers a nice Context Manager around tempfile.mkdtemp
# If you don't want to install it, you can replace with Tempdir() with a setUp and tearDown
# doing tempfile.mkdtemp and shutil.rmtree respectively.

import unittest
from os import mkdir, path
import tempdir
import logging
import collections

from . import generate_ordered_require_file

class TestGenerateDependencyGraph(unittest.TestCase):

    def test_generate_ordered_require_file(self):
        with tempdir.TempDir() as temp_dir:
            mkdir(path.join(temp_dir, "render"))
            dummy_script_filepath1 = path.join(temp_dir, "render", "sprite.lua")
            with open(dummy_script_filepath1, "w") as dummy_script1:
                dummy_script1.write("""require("render/color")
""")

            dummy_script_filepath2 = path.join(temp_dir, "render", "animated_sprite.lua")
            with open(dummy_script_filepath2, "w") as dummy_script2:
                dummy_script2.write("""require("render/color")
local sprite = require("render/sprite")
""")

            dummy_script_filepath3 = path.join(temp_dir, "main.lua")
            with open(dummy_script_filepath3, "w") as dummy_script3:
                dummy_script3.write("""
local sprite = require("render/sprite")
local animated_sprite = require("render/animated_sprite")
""")

            dummy_script_filepath4 = path.join(temp_dir, "render", "color.lua")
            with open(dummy_script_filepath4, "w") as dummy_script4:
                dummy_script4.write("""
""")

            dummy_output_filepath = path.join(temp_dir, "output.lua")
            generate_ordered_require_file.write_ordered_require_lines_to(dummy_output_filepath, 'main', [temp_dir])

            self.assertTrue(path.isfile(dummy_output_filepath))

            # read output
            with open(dummy_output_filepath, "r") as output_file:
                self.maxDiff = None

                # verify output content
                # note: the generation function must ensure that files are traversed in alphabetical order
                # note 2: since we find all usages of any managers in a given file rather than all usages of a given manager in any files
                # (and append lines one by one without sorting),
                # the output text is not sorted by edge source, but by edge target (e.g. 1 -> 2, 3 -> 2, 4 -> 2 rather than 1 -> 2, 1 -> 3, 1 -> 4)
                # note 3: our parser cannot decide if a manager dependency is strong (cannot get rid of it without disabling all manager functionality)
                # or weak (could check if nullptr to avoid crash while preserving most of the manager functionality), so we don't generate [style=dotted] edges automatically
                self.assertEqual(output_file.read(), """require("render/color")
require("render/sprite")
require("render/animated_sprite")
""")

    def test_build_ordered_require_lines_from_dependencies(self):
        dependencies = collections.OrderedDict({
            "main": ["render/animated_sprite", "render/sprite"],
            "render/animated_sprite": ["render/color", "render/sprite"],
            "render/sprite": ["render/color"],
            "render/color": [],
        })

        # test passing file path with extension this time
        dependency_graph_lines = generate_ordered_require_file.build_ordered_require_lines_from_dependencies(dependencies, 'main.lua')

        self.assertEqual(dependency_graph_lines, [
            'require("render/color")\n',
            'require("render/sprite")\n',
            'require("render/animated_sprite")\n',
        ])

    def test_build_ordered_require_lines_from_dependencies_circular_dependency_error(self):
        dependencies = collections.OrderedDict({
            "main": ["render/animated_sprite", "render/sprite"],
            "render/animated_sprite": ["render/color", "render/sprite"],
            "render/sprite": ["render/color", "render/animated_sprite"],  # oops, circualr dependency
        })
        with self.assertRaises(Exception):
            generate_ordered_require_file.build_ordered_require_lines_from_dependencies(dependencies, 'main')


if __name__ == '__main__':
    # we don't want to see errors triggered on purpose during tests,
    # but set this to ERROR if you have an unexpected error to debug
    # (we try to raise as much as possible instead of logging errors, though)
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
