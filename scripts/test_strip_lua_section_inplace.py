# -*- coding: utf-8 -*-
import unittest
from . import strip_lua_section_inplace

import logging
from os import path
import shutil, tempfile


class TestStripLuaSectionInplace(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_add_label_info(self):
        test_lines = [
            'pico-8 cartridge // http://www.pico-8.com',
            'version 32',
            '__lua__',
            'CONTENT',
            'CONTENT',
            'CONTENT',
            '__gfx__',
            '0000000',
            '0000000',
            '0000000'
        ]
        expected_new_lines = [
            'pico-8 cartridge // http://www.pico-8.com',
            'version 32',
            '__gfx__',
            '0000000',
            '0000000',
            '0000000'
        ]
        test_filepath = path.join(self.test_dir, 'test.p8')
        with open(test_filepath, 'w') as f:
            f.write('\n'.join(test_lines))

        strip_lua_section_inplace.strip_lua_section_inplace(test_filepath)

        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), '\n'.join(expected_new_lines))


if __name__ == '__main__':
    logging.basicConfig(level=logging.ERROR)
    unittest.main()
