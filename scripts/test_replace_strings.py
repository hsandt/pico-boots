# -*- coding: utf-8 -*-

import unittest
from . import replace_strings

import logging
from os import path
import shutil, tempfile


class TestParsingGameModuleConstantDefinitions(unittest.TestCase):

    def test_parse_game_module_constant_definitions_lines_single_table(self):
        module_lines = [
            'local camera_data = {\n',
            '  -- window center offset on y\n',
            '  window_center_offset_y = - 4.5/16,\n',
            '\n',
            '-- half width of the camera window (px)\n',
            'window_half_width = 0x0.04  -- inlined comment\n',
            '}\n',
            '\n',
            'return camera_data\n',
        ]
        self.assertEqual(replace_strings.parse_game_module_constant_definitions_lines(module_lines), {'camera_data': {'window_center_offset_y': '- 4.5/16', 'window_half_width': '0x0.04'}})

    def test_parse_game_module_constant_definitions_lines_multiple_table(self):
        module_lines = [
            'local audio = {}\n',
            '\n',
            'audio.sfx_ids = {\n',
            '  -- sfx 1\n',
            '  menu_select = 1,\n',
            '\n',
            '  -- sfx 2\n',
            '  menu_confirm = 2,\n',
            '}\n',
            '\n',
            'audio.music_ids = {\n',
            '  -- music 1\n',
            '  bgm1 = 1,\n',
            '}\n',
            '\n',
            'return audio\n',
        ]
        self.assertEqual(replace_strings.parse_game_module_constant_definitions_lines(module_lines),
            {
                'audio.sfx_ids': {'menu_select': '1', 'menu_confirm': '2'},
                'audio.music_ids': {'bgm1': '1'}
            }
        )

    def test_parse_game_module_constant_definitions_lines_unwanted_line_outside_table_definition(self):
        module_lines = [
            'unwanted_assignment_before_data_table_start = 1\n',
            'local camera_data = {\n',
            '}\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)

    def test_parse_game_module_constant_definitions_lines_ended_file_but_didnt_find_table(self):
        module_lines = [
            '-- only valid comment but no table\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)

    def test_parse_game_module_constant_definitions_lines_didnt_close_table(self):
        module_lines = [
            'local camera_data = {\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)

    def test_parse_game_module_constant_definitions_lines_invalid_assignment(self):
        module_lines = [
            'local camera_data = {\n',
            '  unsupported_complex_assignment = 1 / 20\n',
            '}\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)

    def test_parse_game_module_constant_definitions_lines_invalid_assignment(self):
        module_lines = [
        'local camera_data = {\n',
        '  -- window center offset on y\n',
        '  window_center_offset_y = - 4.5/16,\n',
        '}\n',
        '\n',
        'local invalid_assignment_outside_table = 9\n',
        '\n',
        'return camera_data\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)

    def test_parse_game_module_constant_invalid_redundant_key(self):
        module_lines = [
            'local audio = {}\n',
            '\n',
            'audio.sfx_ids = {\n',
            '  -- sfx 1\n',
            '  menu_select = 1,\n',
            '\n',
            '  -- sfx 2\n',
            '  menu_select = 2,\n',
            '}\n',
            '\n',
            'return audio\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)

    def test_parse_game_module_constant_invalid_redundant_namespace(self):
        module_lines = [
            'local audio = {}\n',
            '\n',
            'audio.sfx_ids = {\n',
            '  menu_select = 1,\n',
            '}\n',
            '\n',
            'audio.sfx_ids = {\n',
            '  menu_select2 = 2,\n',
            '}\n',
            '\n',
            'return audio\n',
        ]
        self.assertRaises(ValueError, replace_strings.parse_game_module_constant_definitions_lines, module_lines)


class TestParsing(unittest.TestCase):

    def test_parse_variable_substitutes(self):
        test_arg_substitutes = ['itest=character', 'optimization=3']
        self.assertEqual(replace_strings.parse_variable_substitutes(test_arg_substitutes), {'$itest': 'character', '$optimization': '3'})

    def test_parse_variable_substitutes_parsing_error(self):
        test_arg_substitutes = ['itest character']
        self.assertRaises(ValueError, replace_strings.parse_variable_substitutes, test_arg_substitutes)


class TestReplaceAllSymbolsInStrings(unittest.TestCase):

    def test_replace_all_glyphs_in_string(self):
        test_string = '##d and ##x ##d'
        self.assertEqual(replace_strings.replace_all_glyphs_in_string(test_string), '⬇️ and ❎ ⬇️')

    def test_replace_all_symbols_in_string_function(self):
        test_string = 'api.print("hello")'
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string, {}), 'print("hello")')

    def test_replace_all_symbols_in_string_function_ignore_non_whole_word(self):
        test_string = 'pico8api.print("hello")'
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string, {}), 'pico8api.print("hello")')

    def test_replace_all_symbols_in_string_enum(self):
        test_string = 'local c = colors.dark_purple'
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string, {}), 'local c = 2')

    def test_replace_all_symbols_in_string_missing_member(self):
        test_string = 'local c = colors.unknown'
        # this will trigger an error, hidden when testing thx to CRITICAL log level set in __main__
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string, {}), 'local c = assert(false, "UNSUBSTITUTED colors.unknown")')

    def test_replace_all_symbols_in_string_game_symbol_substitute(self):
        test_string = 'self.state = game_character_states.idle'
        self.assertEqual(replace_strings.replace_all_symbols_in_string(test_string, {'game_character_states': {'idle': 1}}), 'self.state = 1')

    def test_replace_all_symbols_in_string_common_keys_error(self):
        test_string = 'some code'
        self.assertRaises(ValueError, replace_strings.replace_all_symbols_in_string, test_string, {'colors': {'my_color': 0}})


class TestReplaceAllValuesInStrings(unittest.TestCase):

    def test_replace_all_values_in_string_variable_and_whole_word_constant(self):
        test_string = 'require("itest_$itest") and super_tile_size - 1'
        self.assertEqual(replace_strings.replace_all_values_in_string(test_string, {'$itest': 'character', 'super_tile_size': 16}), 'require("itest_character") and 16 - 1')

    def test_replace_all_values_in_string_variable_and_non_whole_word_constant_ignored(self):
        test_string = 'super_tile_size_minus_1'
        self.assertEqual(replace_strings.replace_all_values_in_string(test_string, {'super_tile_size': 16}), 'super_tile_size_minus_1')

    def testreplace_all_values_common_keys_error(self):
        test_string = 'some code'
        self.assertRaises(ValueError, replace_strings.replace_all_values_in_string, test_string, {'screen_height': 256})


class TestReplaceStringsInFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_replace_strings(self):
        """^ Test replacing strings in a whole file, with substitutes being shorter or longer than original symbol to test if file is truncated"""
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w', encoding='utf-8') as f:
            f.write('require("itest_$itest")\nrequire("$symbol_is_much_longer")\n##d or ##u\nand ##x\napi.print("press ##x")\nself.state = game_character_states.idle')
        replace_strings.replace_all_strings_in_file(test_filepath, {'game_character_states': {'idle': 1}}, {'$itest': 'character', '$symbol_is_much_longer': 'short'})
        with open(test_filepath, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'require("itest_character")\nrequire("short")\n⬇️ or ⬆️\nand ❎\nprint("press ❎")\nself.state = 1')


class TestReplaceStringsInDir(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_replace_all_strings_in_dir(self):
        test_filepath1 = path.join(self.test_dir, 'test1.lua')
        with open(test_filepath1, 'w', encoding='utf-8') as f:
            f.write('require("itest_$itest")\n##d or ##u\nand ##x\napi.print("press ##x")\nself.state = game_character_states.idle')
        test_filepath2 = path.join(self.test_dir, 'test2.lua')
        with open(test_filepath2, 'w', encoding='utf-8') as f:
            f.write('require("itest_$itest")\n##l or ##r\nand ##o\napi.print("press ##o")\nself.state = game_character_states.jumping')
        replace_strings.replace_all_strings_in_dir(self.test_dir, {'game_character_states': {'idle': 1, 'jumping': 2}}, {'$itest': 'character'})
        with open(test_filepath1, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'require("itest_character")\n⬇️ or ⬆️\nand ❎\nprint("press ❎")\nself.state = 1')
        with open(test_filepath2, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'require("itest_character")\n⬅️ or ➡️\nand 🅾️\nprint("press 🅾️")\nself.state = 2')


if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
