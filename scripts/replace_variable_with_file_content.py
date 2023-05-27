#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-

import argparse
import logging

# This script replaces a $variable in a file with the full content of another file.

# prefix of all variable identifiers
VARIABLE_PREFIX = '$'


def replace_all_variables_in_file_with_file_content(filepath, variable_name, variable_replacing_content_filepath, strip_surrounding_quotes):
    """
    Replace all occurrences of '${variable_name}' with the content of `variable_replacing_content_filepath` in file at `filepath`
    If strip_surrounding_quotes is True, expect surrounding matching quotes around the replacing text, and strip them

    test.lua:
        special_content = $special_content

    special_content_data.txt:
        user_data

    >>> replace_all_glyphs_in_file('test.lua', 'special_content', 'special_content_data.txt')

    test.lua:
        special_content = user_data

    """
    # make sure to open files as utf-8 so we can handle unicode on any platform
    # (when locale.getpreferredencoding() and sys.getfilesystemencoding() are not "UTF-8" and "utf-8")
    # you can also set PYTHONIOENCODING="UTF-8" to visualize unicode when debugging if needed
    with open(filepath, 'r+', encoding='utf-8') as f, open(variable_replacing_content_filepath, 'r', encoding='utf-8') as variable_replacing_content_file:
        original_data = f.read()
        variable_replacing_content = variable_replacing_content_file.read()
        replaced_data = replace_all_variables_in_string_with_content(original_data, variable_name, variable_replacing_content, strip_surrounding_quotes)
        # replace file content (truncate as the new content may be shorter)
        f.seek(0)
        f.truncate()
        f.write(replaced_data)


def replace_all_variables_in_string_with_content(text, variable_name, replacing_content, strip_surrounding_quotes):
    """
    Replace all occurrences of '${variable_name}' with `replacing_content` in `text` and return the resulting text
    If strip_surrounding_quotes is True, expect surrounding matching quotes around the replacing text, and strip them

    >>> replace_all_variables_in_string_with_content('special_content = $special_content', 'special_content' 'user_data')
    'special_content = user_data'

    """
    if strip_surrounding_quotes:
        if replacing_content[0] == '"' and replacing_content[-1] == '"' or replacing_content[0] == "'" and replacing_content[-1] == "'":
            replacing_content = replacing_content[1:-1]
        else:
            logging.warning(f"replace_all_variables_in_string_with_content: strip_surrounding_quotes is true, yet replacing content is not surrounded by double quotes")
    return text.replace(f"{VARIABLE_PREFIX}{variable_name}", replacing_content)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description='Replace all occurrences of "${variable_name}" with the content of `variable_replacing_content_filepath` in file at `filepath`')
    parser.add_argument('filepath', type=str, help='path to file to replace variables in')
    parser.add_argument('variable_name', type=str, help='name of variable to replace, without the "$" prefix')
    parser.add_argument('variable_replacing_content_filepath', type=str, help='path to file containing the text to replace the variable with')
    parser.add_argument('--strip-surrounding-quotes', action="store_true", help='expect file content to have surrounding quotes and strip them for replacement')

    args = parser.parse_args()

    replace_all_variables_in_file_with_file_content(args.filepath, args.variable_name, args.variable_replacing_content_filepath, args.strip_surrounding_quotes)
    logging.debug(f"Replaced all variables '${args.variable_name}' file '{args.filepath}' with content of file '{args.variable_replacing_content_filepath}'.")
