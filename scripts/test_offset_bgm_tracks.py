import unittest
from . import offset_bgm_tracks

import logging
from os import path
import shutil
import tempfile


class TestOffsetBgmTracksInP8(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_offset_bgm_tracks_in_p8(self):
        # We actually test p8tool listrawlua
        cartridge_content = """pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
__sfx__
__music__
00 23242840
02 25262d40

"""

        expected_offset_content = """pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
__sfx__
__music__
00 2b2c3040
02 2d2e3540

"""
        cartridge_filepath = path.join(self.test_dir, 'cartridge.p8')
        cartridge_offset_filepath = path.join(self.test_dir, 'cartridge_offset.p8')

        with open(cartridge_filepath, 'w') as source_file:
            source_file.write(cartridge_content)

        offset_bgm_tracks.offset_bgm_tracks_in_p8(cartridge_filepath, 8)

        with open(cartridge_offset_filepath, 'r') as target_file:
            self.assertEqual(target_file.read(), expected_offset_content)


class TestOffsetBgmTracksFromLinesToFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_offset_bgm_tracks_from_lines_to_file(self):
        # We actually test p8tool listrawlua
        cartridge_content_lines = [
            'pico-8 cartridge // http://www.pico-8.com\n',
            'version 29\n',
            '__lua__\n',
            '__sfx__\n',
            '__music__\n',
            '00 23242840\n',
            '02 25262d40\n',
        ]

        expected_offset_cartridge_content_lines = [
            'pico-8 cartridge // http://www.pico-8.com\n',
            'version 29\n',
            '__lua__\n',
            '__sfx__\n',
            '__music__\n',
            '00 2b2c3040\n',
            '02 2d2e3540\n',
        ]

        cartridge_offset_filepath = path.join(self.test_dir, 'cartridge_offset.p8')

        with open(cartridge_offset_filepath, 'w') as target_file:
            offset_bgm_tracks.offset_bgm_tracks_from_lines_to_file(cartridge_content_lines, target_file, 8)

        with open(cartridge_offset_filepath, 'r') as target_file:
            self.assertEqual(target_file.readlines(), expected_offset_cartridge_content_lines)


class TestOffsetHexadecimalString(unittest.TestCase):

    def test_offset_hexadecimal_string_preserve_undefined(self):
        self.assertEqual(offset_bgm_tracks.offset_hexadecimal_string("40", 3), "40")

    def test_offset_hexadecimal_string_add_single_figures(self):
        self.assertEqual(offset_bgm_tracks.offset_hexadecimal_string("00", 3), "03")

    def test_offset_hexadecimal_string_add_two_figures(self):
        self.assertEqual(offset_bgm_tracks.offset_hexadecimal_string("2e", 3), "31")

    def test_offset_hexadecimal_string_subtract(self):
        self.assertEqual(offset_bgm_tracks.offset_hexadecimal_string("2e", -3), "2b")

    def test_offset_hexadecimal_string_invalid_add(self):
        self.assertRaises(ValueError, offset_bgm_tracks.offset_hexadecimal_string, "3d", 3)

    def test_offset_hexadecimal_string_invalid_subtract(self):
        self.assertRaises(ValueError, offset_bgm_tracks.offset_hexadecimal_string, "2", -3)


if __name__ == '__main__':
    # we don't want to see errors triggered on purpose during tests,
    # but set this to ERROR if you have an unexpected error to debug
    # (we try to raise as much as possible instead of logging errors, though)
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
