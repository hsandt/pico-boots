#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
from enum import Enum


# This script applies preprocessing and code enabling to the intermediate source code meant to be built for PICO-8:
# 1. strip all code between full lines "--#if [symbol]" and "--#endif" if `symbol` is not defined (passed from external config).
# 2. strip all code between full lines "--#ifn [symbol]" and "--#endif" if `symbol` is defined.
# 3. enable all code between full lines "--[[#pico8" and "--#pico8]]" (unless stripped by 1.).
# 4. strip one-line debug function calls like log() and assert() if the corresponding symbols are not defined


# Extra notes on 4:

# a. One-line function stripping avoids having to surround e.g. "log()" with "--#if log" and "--#endif" every time.
# Our Regex doesn't support multi-line calls or deep bracket detection, therefore, when using multi-line logs/asserts:
# - make sure that you never end the first line with a closing bracket, such as:
#     log(sum(1, 2)
#     .."!")
#   as it will detect a full statement and strip the first line but keeping the others trailing in the void.
# - surround all the lines with --#if [symbol] and --#endif with the matching symbol.

# b. In addition, make sure you never insert gameplay code inside a log or assert (such as assert(coresume(coroutine)))
# and always split gameplay/debug code in 2 lines

# c. log, warn and err behave the same way, they all use the "log" symbol.

# d. If stripping fails somewhat, your release build with error with "attempt to call bil value 'log'" or something similar.


# Note that when run with busted for unit tests, the source code remains untouched.
# Therefore, any code inside "--#if" is processed normally, and code inside "--[[#pico8" blocks is ignored.
# So the common strategy to insert PICO-8 and busted-specific code is:
# - Place PICO-8-specific code inside "--[[#pico8" comment blocks
# - Place busted-specific code inside "--#if busted". Since the symbol 'busted' is never defined, it will never be run by PICO-8.


# Candidate functions to strip, as they are typically bound to a defined symbol
strippable_functions = ['assert', 'log', 'warn', 'err']
preserved_functions_list_by_symbol = {
    'assert': ['assert'],
    'log':    ['log', 'warn', 'err']
}
cached_stripped_function_call_patterns_by_defined_symbols_list = {}


def get_stripped_functions(defined_symbols):
    """
    Return the list of function names for which one-line calls should be stripped,
    given a list of defined symbols

    """
    stripped_functions = list(strippable_functions)
    for symbol, preserved_functions in preserved_functions_list_by_symbol.items():
        if symbol in defined_symbols:
            for preserved_function in preserved_functions:
                stripped_functions.remove(preserved_function)
    return stripped_functions


def generate_stripped_function_call_pattern(stripped_functions):
    """
    Return a Regex pattern that detects any one-line call of any function whose name is in stripped_functions
    If there are no functions to strip, return None.

    """
    # if there is nothing to strip, return None now to avoid creating a regex with just "(?:)\(\)" that would match a line starting with brackets
    if not stripped_functions:
        return None

    # Many good regex exist to match open and closing brackets, unfortunately they use PCRE features like ?> unsupported in Python re,
    #   so we use a very simple regex only capable of detecting the final closing bracket, without being certain that this is the last one.
    # Because of this, you should never end the first line of a multi-line call with a bracket as it would be interpreted as a one-line call.
    # Comments after call are supported.

    # For better regex with PCRE to detect surrounding brackets and quotes, see:
    # https://stackoverflow.com/questions/2148587/finding-quoted-strings-with-escaped-quotes-in-c-sharp-using-a-regular-expression
    # https://stackoverflow.com/questions/4568410/match-comments-with-regex-but-not-inside-a-quote adapted to lua comments
    # https://stackoverflow.com/questions/546433/regular-expression-to-match-outer-brackets#546457
    # https://stackoverflow.com/questions/18906514/regex-for-matching-functions-and-capturing-their-arguments#18908330

    # ex: '(?:log|warn|err)'
    function_names_alternative_pattern = f"(?:{'|'.join(stripped_functions)})"
    # ex: '^\s*(?:log|warn|err)\(.*\)\s*(?:--.*)?$'
    stripped_function_call_pattern = re.compile(rf'^\s*{function_names_alternative_pattern}\(.*\)\s*(?:--.*)?$')
    return stripped_function_call_pattern


def get_or_generate_stripped_function_call_pattern_from_defined_symbols(defined_symbols_tuple):
    """
    get_stripped_functions + generate_stripped_function_call_pattern with memoization
    defined_symbols_tuple is a tuple as it must be hashable to be a key

    """
    if defined_symbols_tuple in cached_stripped_function_call_patterns_by_defined_symbols_list:
        return cached_stripped_function_call_patterns_by_defined_symbols_list[defined_symbols_tuple]

    stripped_functions = get_stripped_functions(defined_symbols_tuple)
    stripped_function_call_pattern = generate_stripped_function_call_pattern(stripped_functions)
    cached_stripped_function_call_patterns_by_defined_symbols_list[defined_symbols_tuple] = stripped_function_call_pattern
    return stripped_function_call_pattern


# Parsing mode of each individual #if block
class IfBlockMode(Enum):
    ACCEPTED = 1  # the condition was true
    REFUSED  = 2  # the condition was false
    IGNORED  = 3  # we were inside a false condition so we don't care, we are just waiting for #endif


# Parsing state machine modes
class ParsingMode(Enum):
    ACTIVE   = 1  # we are copying each line
    IGNORING = 2  # we are ignoring all content in the current if block


# Regex patterns

# Tag to enter a pico8-only block (it's a comment block so that busted never runs it but preprocess reactivates it)
# Unlike normal comment blocks, we expect to match from the line start
pico8_start_pattern = re.compile(r"\s*--\[=*\[#pico8")
# Closing tag for pico8-only block. Unlike normal comment blocks, we expect to match from the line start and we ignore anything after the block end!
# So you should have the same number of '='. They are supported in case you need to wrap multi-line strings.
pico8_end_pattern = re.compile(r"\s*--#pico8]=*]")

if_pattern = re.compile(r"\s*--#if (\w+)")    # ! ignore anything after 1st symbol
ifn_pattern = re.compile(r"\s*--#ifn (\w+)")  # ! ignore anything after 1st symbol
endif_pattern = re.compile(r"\s*--#endif")


def preprocess_dir(dirpath, defined_symbols):
    """Apply preprocessor directives to all the source files inside the given directory, for the given defined_symbols"""
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                preprocess_file(os.path.join(root, file), defined_symbols)


def preprocess_file(filepath, defined_symbols):
    """
    Apply preprocessor directives to a single file, for the given defined_symbols

    test.lua:
        print("always")
        --#if debug
        print("debug")
        --#endif
        if true:
            print("hello")

    >>> preprocess_file('test.lua', ['debug'])

    test.lua:
        print("always")
        print("debug")
        if true:
            print("hello")

    or

    >>> preprocess_file('test.lua', [])

    test.lua:
        print("always")
        if true:
            print("hello")

    """
    with open(filepath, 'r+') as f:
        logging.debug(f"Preprocessing file {filepath}...")
        preprocessed_lines = preprocess_lines(f, defined_symbols)
        # replace file content (truncate as the new content may be shorter)
        f.seek(0)
        f.truncate()
        f.writelines(preprocessed_lines)

def preprocess_lines(lines, defined_symbols):
    """
    Apply stripping and preprocessor directives to iterable lines of source code, for the given defined_symbols
    It is possible to pass a file as lines iterator

    """
    preprocessed_lines = []

    inside_pico8_block = False

    # explore the tree of #if by storing the current stack of ifs encountered from top to bottom
    if_block_modes_stack = []  # can only be filled with [IfBlockMode.ACCEPTED*, IfBlockMode.REFUSED?, IfBlockMode.IGNORED* (only if 1 REFUSED)]
    current_mode = ParsingMode.ACTIVE  # it is ParsingMode.ACTIVE iff if_block_modes_stack is empty or if_block_modes_stack[-1] == IfBlockMode.ACCEPTED

    for line in lines:
        # 3. preprocess directives
        opt_match = None      # if or ifn match depending on which one succeeds, None if both fail
        negative_if = False   # True if we have #ifn, False else

        if_boundary_match = if_pattern.match(line)
        if not if_boundary_match:
            if_boundary_match = ifn_pattern.match(line)
            if if_boundary_match:
                negative_if = True

        if if_boundary_match:
            if current_mode is ParsingMode.ACTIVE:
                symbol = if_boundary_match.group(1)
                # for #if, you need to have symbol defined, for #ifn, you need to have it undefined
                if (symbol in defined_symbols) ^ negative_if:
                    # symbol is defined, so remain active and add that to the stack
                    if_block_modes_stack.append(IfBlockMode.ACCEPTED)
                    # still strip the preprocessor directives themselves (don't add it to accepted lines)
                else:
                    # symbol is not defined, enter ignoring mode and add that to the stack
                    if_block_modes_stack.append(IfBlockMode.REFUSED)
                    current_mode = ParsingMode.IGNORING
            else:
                # we are already in an unprocessed block so we don't care whether that subblock verifies the condition or not
                # continue ignoring lines but push to the stack so we can wait for #endif
                if_block_modes_stack.append(IfBlockMode.IGNORED)
        elif endif_pattern.match(line):
            if current_mode is ParsingMode.ACTIVE:
                # check that we had some #if in the stack
                if if_block_modes_stack:
                    # go one level up, remain active
                    if_block_modes_stack.pop()
                else:
                    logging.warning('an --#endif was encountered outside an --#if block. Make sure the block starts with an --#if directive')
            else:
                last_mode = if_block_modes_stack.pop()
                # if we left the refusing block, then the new last mode is ACCEPTED and we should be active again
                # otherwise, we have simply left an IGNORED mode and we remain IGNORING
                if last_mode is IfBlockMode.REFUSED:
                    current_mode = ParsingMode.ACTIVE
        elif current_mode is ParsingMode.ACTIVE:
            if pico8_start_pattern.match(line):
                # we detected a pico8 block and should continue appending the lines normally (since we are building for pico8)
                # the bool flag is only here to check that 1 end pattern will match 1 start pattern
                # since we don't really need embedded pico8 blocks, we assume only 1 level and don't use a stack here
                if not inside_pico8_block:
                    inside_pico8_block = True
                else:
                    logging.warning('a pico8 block start was encountered inside a pico8 block. It will be ignored')
            elif pico8_end_pattern.match(line):
                if inside_pico8_block:
                    inside_pico8_block = False
                else:
                    logging.warning('a pico8 block end was encountered outside a pico8 block. It will be ignored')
            elif not match_stripped_function_call(line, defined_symbols):
                preprocessed_lines.append(line)

    if if_block_modes_stack:
        logging.warning('file ended inside an --#if block. Make sure the block is closed by an --#endif directive')
    if inside_pico8_block:
        logging.warning('file ended inside a --[[#pico8 block. Make sure the block is closed by a --#pico8]] directive')

    return preprocessed_lines


def match_stripped_function_call(line, defined_symbols):
    """Return true iff the line contains a function call (and optionally a comment) that should be stripped in the passed config"""
    stripped_function_call_pattern = get_or_generate_stripped_function_call_pattern_from_defined_symbols(tuple(defined_symbols))
    if stripped_function_call_pattern is None:
        return False

    return bool(stripped_function_call_pattern.match(line))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Apply preprocessor directives.')
    parser.add_argument('path', type=str, help='path containing source files to preprocess')
    parser.add_argument('--symbols', nargs='*', type=str, help="symbols to define, e.g. 'debug'")
    args = parser.parse_args()
    if args.symbols is None:
        args.symbols = []

    logging.basicConfig(level=logging.INFO)
    preprocess_dir(args.path, args.symbols)
    print(f"Preprocessed all files in {args.path} with symbols {args.symbols}.")
