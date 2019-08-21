# -*- coding: utf-8 -*-
import unittest
from unittest import mock
from . import add_require

import os
from os import path
import shutil, tempfile


class TestAddRequireFromDir(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

        # Mock find_module_names (use __name__, which should be '__main__', for relative import)
        find_module_names_patch = mock.patch(f"{__name__}.add_require.find_relative_module_paths",
            new=mock.Mock(return_value=["helper/print_helper", "helper/sub/other_helper"]))
        find_module_names_patch.start()
        self.addCleanup(find_module_names_patch.stop)

        # Stub add_require_from_module_paths and store reference to mock to check calls later
        add_require_from_module_paths_patch = mock.patch(f"{__name__}.add_require.add_require_from_module_paths")
        self.add_require_from_module_paths_mock = add_require_from_module_paths_patch.start()
        self.addCleanup(add_require_from_module_paths_patch.stop)

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_add_require_from_dir(self):
        add_require.add_require_from_dir('test_filepath', 'dummy root', 'dummy dirname')

        self.add_require_from_module_paths_mock.assert_called_once()
        self.add_require_from_module_paths_mock.assert_called_with('test_filepath', ["helper/print_helper", "helper/sub/other_helper"])


class TestAddRequireHelpers(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_add_require_from_module_paths(self):
        test_lines = [
            '-- a test file',
            '--[[add_require]]',
            '',
            'function use_print_helper()',
            '    print_helper("hello")',
            'end'
        ]
        expected_new_lines = [
            '-- a test file',
            '--[[add_require]]',
            'require("helper/print_helper")',
            'require("helper/sub/other_helper")',
            '',
            'function use_print_helper()',
            '    print_helper("hello")',
            'end'
        ]

        test_filepath = path.join(self.test_dir, 'test.p8')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))
        add_require.add_require_from_module_paths(test_filepath, ["helper/print_helper", "helper/sub/other_helper"])
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '\n'.join(expected_new_lines))

    def test_find_relative_module_paths(self):
        helper_dirpath = path.join(self.test_dir, 'helper')
        os.mkdir(helper_dirpath)
        dummy_module1 = path.join(helper_dirpath, 'dummy_module1.lua')
        with open(dummy_module1, 'a') as f:
            pass

        helper_subdirpath = path.join(helper_dirpath, 'subdir')
        os.mkdir(helper_subdirpath)
        dummy_module2 = path.join(helper_subdirpath, 'dummy_module2.lua')
        with open(dummy_module2, 'a') as f:
            pass

        self.assertEqual(add_require.find_relative_module_paths(self.test_dir, 'helper'), ['helper/dummy_module1', 'helper/subdir/dummy_module2'])


if __name__ == '__main__':
    unittest.main()
