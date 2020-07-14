import unittest
from . import analyze

import logging
from os import path
import shutil, tempfile


class TestAnalyzeScript(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_analyze_script(self):
        source_text = """local a = 5
"""
        expected_stats_text = """source.lua (source.p8)
by analyze_script
- version: 16
- lines: 3
- chars: 47
- tokens: 3
- compressed chars: 48

"""

        source_relative_filepath = 'source.lua'
        source_filepath = path.join(self.test_dir, source_relative_filepath)
        stats_filepath = path.join(self.test_dir, 'stats.txt')

        with open(source_filepath, 'w') as s:
            s.write(source_text)

        with open(stats_filepath, 'w') as s:
            analyze.analyze_script(self.test_dir, source_relative_filepath, s)

        with open(stats_filepath, 'r') as s:
            self.assertEqual(s.read(), expected_stats_text)


class TestCartridgify(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_cartridgify(self):
        source_text = """local a = 5
"""
        expected_target_text = """pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- source.lua
-- by analyze_script
local a = 5
"""

        source_relative_filepath = 'source.lua'
        source_filepath = path.join(self.test_dir, source_relative_filepath)
        target_filepath = path.join(self.test_dir, 'target.p8')

        with open(source_filepath, 'w') as s:
            s.write(source_text)

        analyze.cartridgify(self.test_dir, source_relative_filepath, target_filepath)

        with open(target_filepath, 'r') as t:
            self.assertEqual(t.read(), expected_target_text)


class TestPrintStats(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_print_stats(self):
        cartridge_text = """pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
local a = 5
"""
        expected_stats_text = """cartridge.p8
- version: 16
- lines: 1
- chars: 12
- tokens: 3
- compressed chars: 12

"""

        cartridge_filepath = path.join(self.test_dir, 'cartridge.p8')
        stats_filepath = path.join(self.test_dir, 'stats.txt')

        with open(cartridge_filepath, 'w') as c:
            c.write(cartridge_text)

        with open(stats_filepath, 'w') as s:
            analyze.print_stats(cartridge_filepath, s)

        with open(stats_filepath, 'r') as s:
            self.assertEqual(s.read(), expected_stats_text)




if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
