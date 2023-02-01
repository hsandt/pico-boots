# -*- coding: utf-8 -*-

import unittest
from . import replace_variable_with_file_content

import logging
from os import path
import shutil, tempfile


class TestReplaceAllVariablesInFileWithFileContent(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_replace_all_variables_in_file_with_file_content(self):
        """Test replacing strings in a whole file, with substitutes being shorter or longer than original symbol to test if file is truncated"""
        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w', encoding='utf-8') as f:
            f.write('special_content = $special_content')

        content_filepath = path.join(self.test_dir, 'special_content_data.txt')
        with open(content_filepath, 'w', encoding='utf-8') as f:
            f.write('"string"')

        replace_variable_with_file_content.replace_all_variables_in_file_with_file_content(test_filepath, 'special_content', content_filepath, True)

        with open(test_filepath, 'r', encoding='utf-8') as f:
            self.assertEqual(f.read(), 'special_content = string')


class TestReplaceAllVariablesInStringWithContent(unittest.TestCase):

    def test_replace_all_variables_in_string_with_content_no_quotes_no_strip(self):
        self.assertEqual(replace_variable_with_file_content.replace_all_variables_in_string_with_content('special_content = $special_content', 'special_content', 'user_data', False), 'special_content = user_data')

    def test_replace_all_variables_in_string_with_content_no_quotes_strip_does_nothing(self):
        # Invalid input as expected user_data to be surrounded with quotes, so this will show a warning, and not strip anything
        self.assertEqual(replace_variable_with_file_content.replace_all_variables_in_string_with_content('special_content = $special_content', 'special_content', 'user_data', True), 'special_content = user_data')

    def test_replace_all_variables_in_string_with_content_quotes_no_strip(self):
        self.assertEqual(replace_variable_with_file_content.replace_all_variables_in_string_with_content('special_content = $special_content', 'special_content', '"string"', False), 'special_content = "string"')

    def test_replace_all_variables_in_string_with_content_single_quotes_strip(self):
        self.assertEqual(replace_variable_with_file_content.replace_all_variables_in_string_with_content('special_content = $special_content', 'special_content', "'string'", True), 'special_content = string')

    def test_replace_all_variables_in_string_with_content_double_quotes_strip(self):
        self.assertEqual(replace_variable_with_file_content.replace_all_variables_in_string_with_content('special_content = $special_content', 'special_content', '"string"', True), 'special_content = string')


if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
