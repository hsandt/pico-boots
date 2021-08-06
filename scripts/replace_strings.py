#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-

import argparse
import logging
import os
import re

# This script replace glyph identifiers, some functions and symbols in general, and values (constants + $variables)
# with the corresponding unicode characters and substitute symbol names.
# Set the glyphs and symbols to replace in GLYPH_TABLE and ENGINE_SYMBOL_SUBSTITUTE_TABLE.
# It is possible to add game-specific symbols by defining a GAME_SYMBOL_SUBSTITUTE_TABLE in another file,
# and game-specific constants by defining a GAME_CONSTANT_SUBSTITUTE_TABLE in that same file 'game_substitute_table.py'
# (see command-line option --game-substitute-table-dir)

# input glyphs
# (when using input functions (btn, btnp), prefer enum input.button_ids)
GLYPH_UP = '⬆️'
GLYPH_DOWN = '⬇️'
GLYPH_LEFT = '⬅️'
GLYPH_RIGHT = '➡️'
GLYPH_X = '❎'
GLYPH_O = '🅾️'

# prefix of all glyph identifiers
GLYPH_PREFIX = '##'

# dict mapping an ascii glyph identifier suffix with a unicode glyph
GLYPH_TABLE = {
    'u': GLYPH_UP,
    'd': GLYPH_DOWN,
    'l': GLYPH_LEFT,
    'r': GLYPH_RIGHT,
    'x': GLYPH_X,
    'o': GLYPH_O,
}

# Functions and enum constants to substitute
# There are all present in engine, and not specific to any game.
# Enums are only substituted for token/char limit reasons
# Format: { namespace1: {name1: substitute1, name 2: substitute2, ...}, ... }
ENGINE_SYMBOL_SUBSTITUTE_TABLE = {
    # Functions

    # api.print is useful for tests using native print, but in runtime, just use print
    'api': {
        'print': 'print'
    },

    # Enums

    # for every enum added here, surround enum definition with --#ifn pico8
    #   to strip it from the build, unless you need to map the enum string
    #   to its value dynamically with enum_values[dynamic_string]
    # remember to update the values of any preprocessed enum modified

    # !! Make sure to update them manually whenever you change an enum,
    # !! as we don't have a Lua parser to directly get values from enums

    # color
    'colors': {
        'black':        0,
        'dark_blue':    1,
        'dark_purple':  2,
        'dark_green':   3,
        'brown':        4,
        'dark_gray':    5,
        'light_gray':   6,
        'white':        7,
        'red':          8,
        'orange':       9,
        'yellow':       10,
        'green':        11,
        'blue':         12,
        'indigo':       13,
        'pink':         14,
        'peach':        15,
    },

    # math
    'directions': {
        'left':  0,
        'up':    1,
        'right': 2,
        'down':  3,
    },

    'horizontal_dirs': {
        'left':     1,
        'right':    2,
    },

    'vertical_dirs': {
        'up':     1,
        'down':    2,
    },

    # input
    'button_ids': {
        'left':     0,
        'right':    1,
        'up':       2,
        'down':     3,
        'o':        4,
        'x':        5,
    },

    'btn_states': {
        'released':         0,
        'just_pressed':     1,
        'pressed':          2,
        'just_released':    3,
    },

    'input_modes': {
        'native':       0,
        'simulated':    1,
    },

    # ui
    'alignments': {
      'left': 1,
      'horizontal_center': 2,
      'center': 3,
      'right': 4,
    },

    # render
    'anim_loop_modes': {
      'freeze_first':  1,
      'freeze_last':   2,
      'clear':         3,
      'loop':          4,
    },
}

# Engine constant substitutes
ENGINE_CONSTANT_SUBSTITUTES = {
    # So far, replacing all these constants has only led to more compressed chars,
    # maybe because global variable minification is already very powerful
    # If you substitute them again, make sure to surround their definitions
    # with --#if busted or --#if constants to avoid weird results in PICO-8 like `128 = 128`
    # 'screen_width': 128,
    # 'screen_height': 128,
    # 'tile_size': 8,
    # 'map_region_tile_width': 128,
    # 'map_region_tile_height': 32,
    # 'map_region_width': 1024,
    # 'map_region_height': 256
}

# prefix of all variable identifiers
VARIABLE_PREFIX = '$'

def replace_all_strings_in_dir(dirpath, game_symbol_substitute_table, game_value_substitutes_table):
    """
    Replace all the glyph identifiers, symbols (engine + optional game substitutes) and
    value (constant + variable) substitutes in all source files in a given directory

    """
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                replace_all_strings_in_file(os.path.join(root, file), game_symbol_substitute_table, game_value_substitutes_table)


def replace_all_strings_in_file(filepath, game_symbol_substitute_table, game_value_substitutes_table):
    """
    Replace all the glyph identifiers, symbols (engine + optional game substitutes) and
    value (constant + variable) substitutes in a given file

    test.txt:
        require('itest_$itest')
        ##d or ##u
        and ##x
        api.print("press ##x")

    >>> replace_all_glyphs_in_file('test.txt', {'itest': 'character'})

    test.txt:
        require('itest_character')
        ⬇️ or ⬆️
        and ❎
        print("press ❎")

    """
    # make sure to open files as utf-8 so we can handle glyphs on any platform
    # (when locale.getpreferredencoding() and sys.getfilesystemencoding() are not "UTF-8" and "utf-8")
    # you can also set PYTHONIOENCODING="UTF-8" to visualize glyphs when debugging if needed
    logging.debug(f'replacing all strings in file {filepath}...')
    with open(filepath, 'r+', encoding='utf-8') as f:
        data = f.read()
        data = replace_all_glyphs_in_string(data)
        data = replace_all_symbols_in_string(data, game_symbol_substitute_table)
        data = replace_all_values_in_string(data, game_value_substitutes_table)
        # replace file content (truncate as the new content may be shorter)
        f.seek(0)
        f.truncate()
        f.write(data)

def replace_all_glyphs_in_string(text):
    """
    Replace the glyph identifiers of a certain type with the corresponding glyph

    >>> replace_all_glyphs_in_string("##d and ##x ##d")
    '⬇️ and ❎ ⬇️'

    """
    for identifier_char, glyph in GLYPH_TABLE.items():
        text = text.replace(GLYPH_PREFIX + identifier_char, glyph)
    return text

def generate_get_substitute_from_dict(substitutes):
    def get_substitute(match):
        member = match.group(1)  # "{member}"
        if member in substitutes:
            return str(substitutes[member])  # enums are substituted with integers, so convert
        else:
            original_symbol = match.group(0)  # "{namespace}.{member}"
            # in general, we should substitute all members of a namespace, especially enums
            logging.error(f'no substitute defined for {original_symbol}, but the namespace (first part) is present in ENGINE_SYMBOL_SUBSTITUTE_TABLE')
            # return something easy to debug in PICO-8, in case the user missed the error message
            # note that we should normally escape quotes in original_symbol, but we rely on the fact that
            # symbols should not contain quotes
            return f'assert(false, "UNSUBSTITUTED {original_symbol}")'
    return get_substitute

def replace_all_symbols_in_string(text, game_symbol_substitute_table):
    """
    Replace symbols "namespace.member" defined in ENGINE_SYMBOL_SUBSTITUTE_TABLE
    and game_symbol_substitute_table with the corresponding substitutes
    Convert integer to string for replacement to support enum constants

    >>> replace_all_symbols_in_string("api.print(\"hello\")")
    'print("hello")'

    """
    full_symbol_substitutes_table = {**ENGINE_SYMBOL_SUBSTITUTE_TABLE, **game_symbol_substitute_table}
    for namespace, substitutes in full_symbol_substitutes_table.items():
        # strings like "pico8api.lua" contain namespaces like "api." so make sure to replace with wholeword
        # to avoid replacing unwanted strings (that said, this actually occurred in a comment, only because
        # the preprocess step is not stripping comments anymore)
        SYMBOL_PATTERN = re.compile(rf"\b{namespace}\.(\w+)\b")
        text = SYMBOL_PATTERN.sub(generate_get_substitute_from_dict(substitutes), text)
        if 'assert(false, "UNS' in text:
            print(text)
    return text


def replace_all_values_in_string(text, game_value_substitutes_table):
    """
    Replace args with the corresponding substitutes, using ENGINE_ARG_SUBSTITUTES, and game_value_substitutes_table if defined.

    >>> replace_all_values_in_string("require('itest_$itest')", {"itest": "character"})
    'require("itest_character")'

    """
    # Python 3.9 note: use ENGINE_ARG_SUBSTITUTES | game_value_substitutes_table
    full_value_substitutes_table = {**ENGINE_CONSTANT_SUBSTITUTES, **game_value_substitutes_table}
    for value_name, substitute in full_value_substitutes_table.items():
        # when defining GAME_CONSTANT_SUBSTITUTE_TABLE we often put numbers directly for simplicity
        # so unlike variable substitutes defined with = directly in command-line, we must convert them to string
        # note that the VARIABLE_PREFIX ($) was baked into table keys, so no need to re-add them
        # and constant names should just be preserved
        if value_name.startswith(VARIABLE_PREFIX):
            text = text.replace(value_name, str(substitute))
        else:
            # For constants, there is no prefix so it's easy to end up with some concatenated name like
            # map_region_width and map_region_width_tile, in which case we don't want to replace the former string
            # in the latter string! So make sure to detect whole word by checking regex boundaries
            a = False
            if text.startswith('common pico-8 constants'):
                print(f'replace: {value_name} with {substitute}')
                print(f'text before: {text}')
                a = True
            text = re.sub(rf'\b{value_name}\b', str(substitute), text)
            if a:
                print(f'text after: {text}')
    return text


def parse_variable_substitutes(variable_substitutes):
    """Parse a list of variable substitutes in the format 'variable1=substitute1 variable2=substitute2 ...' into a dictionary of {variable: substitute}"""
    variable_substitutes_table = {}
    for variable_definition in variable_substitutes:
        # variable_definition should have format 'variable1=substitute1'
        members = variable_definition.split("=")
        if len(members) == 2:
            variable, substitute = variable_definition.split("=")
            # we do not support surrounding quotes which would be integrated in the names, so don't use names with spaces
            # note that we now inject the prefix directly before the variable name
            # ex: 'itest' => '$itest'
            # this allows us to distinguish '$variables' from 'constants' (without prefix)
            variable_substitutes_table[VARIABLE_PREFIX + variable] = substitute
        else:
            raise ValueError(f"variable_substitutes contain definition with not exactly 2 '=' signs: {variable_definition.split}")
    return variable_substitutes_table


if __name__ == '__main__':
    import sys

    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description='Replace predetermined strings in all source files in a directory.')
    parser.add_argument('dirpath', type=str, help='path containing source files where strings should be replaced')
    parser.add_argument('--game-substitute-table-dir', type=str,
        help='path to directory containing game_substitute_table.py to be imported \
Should define a variable GAME_SYMBOL_SUBSTITUTE_TABLE with format: \
{ namespace1: {name1: substitute1, name2: substitute2, ...}, ... } \
and GAME_CONSTANT_SUBSTITUTE_TABLE associating constant names to values with format: \
{name1: value1, name2: value2, ...}')
    parser.add_argument('--variable-substitutes', type=str, nargs='*', default=[],
        help='extra substitutes table in the format "variable1=substitute1 variable2=substitute2 ...". \
Does not support spaces in names because surrounding quotes would be part of the names')
    args = parser.parse_args()

    # default
    game_symbol_substitute_table = {}
    game_value_substitutes_table = {}

    # retrieve any game-specific symbols and values (constants and variables)
    if args.game_substitute_table_dir:
        # add game_symbol_substitute_table to system path to allow import of game_substitute_table.py
        # supposed to be in this directory
        sys.path.append(args.game_substitute_table_dir)

        # now import and retrieve game symbol substitute table
        import game_substitute_table
        game_symbol_substitute_table = game_substitute_table.GAME_SYMBOL_SUBSTITUTE_TABLE
        game_value_substitutes_table = game_substitute_table.GAME_CONSTANT_SUBSTITUTE_TABLE

    # get variable substitutes (those must be prefixed with $ in .lua)
    variable_substitutes_table = parse_variable_substitutes(args.variable_substitutes)

    # merge both constant and variable substitute tables into the complete value substitute table
    # this works because we baked the ARG_PREFIX ($) into the variable substitute table, so both
    # are now at the same level
    game_value_substitutes_table.update(variable_substitutes_table)

    replace_all_strings_in_dir(args.dirpath, game_symbol_substitute_table, game_value_substitutes_table)
    logging.debug(f"Replaced all strings in all files in {args.dirpath} with game symbol substitutes: {game_symbol_substitute_table} \
and game value substitutes: {game_value_substitutes_table}.")
