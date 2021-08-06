#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
from collections import namedtuple
from enum import Enum


# This script applies preprocessing and code enabling to the intermediate source code meant to be built for PICO-8:
# 1. skip empty/blank lines
# 2. remove full line comments (keep block comment start/middle/end)
# 3. strip all code between full lines "--#if [symbol]" and "--#else/endif" if `symbol` is not defined (passed from external config).
# 4. strip all code between full lines "--#ifn [symbol]" and "--#else/endif" if `symbol` is defined.
# 5. strip all code between full lines "--#else" and "--#endif" using the opposite rule of the preceding block
# 6. enable all code between full lines "--[[#pico8" and "--#pico8]]" (unless stripped by 1.).
# 7. strip one-line debug function calls like log() and assert() if the corresponding symbols are not defined


# Extra notes on 7:

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


# Regex patterns

# Tag to enter a pico8-only block (it's a comment block so that busted never runs it but preprocess reactivates it)
# Unlike normal comment blocks, we expect to match from the line start
pico8_start_pattern = re.compile(r"\s*--\[=*\[#pico8")
# Closing tag for pico8-only block. Unlike normal comment blocks, we expect to match from the line start and we ignore anything after the block end!
# So you should have the same number of '='. They are supported in case you need to wrap multi-line strings.
pico8_end_pattern = re.compile(r"\s*--#pico8]=*]")

# if pattern supports up to 1 OR (||) clause. If you need more, consider manual parsing
# of everything after #if rather than a regex expression handling everything.
if_pattern = re.compile(r"\s*--#if (\w+)\s*(?:\|\|\s*(\w+))?\s*$")
ifn_pattern = re.compile(r"\s*--#ifn (\w+)\s*$")
else_pattern = re.compile(r"\s*--#else\s*$")
endif_pattern = re.compile(r"\s*--#endif\s*$")

# To be safe, we only detect full line comments and ignore any block comment
# even if they may be ending on the same line (as it's harder to verify exact block ending),
# so we added a negative look-ahead for [=[ and ]=]
# Note that we're checking from line start with ^, so we must strip line before applying regex
comment_pattern = re.compile(r'^--(?!\[=*\[)(?!\]=*\])')

# Candidate functions to strip, as they are typically bound to a defined symbol
strippable_functions = ['assert', 'log', 'warn', 'err']
preserved_functions_list_by_symbol = {
    'assert': ['assert'],
    'log':    ['log', 'warn', 'err']
}
cached_stripped_function_call_patterns_by_defined_symbols_list = {}


class RegionInfo():
    """
    Information on current pre-procesing region
    Regions can be embedded (e.g. 'if' inside 'if') so they must be stored in a stack

    Attributes:
        region_type: RegionType
        if_block_mode: int

    """
    def __init__(self, region_type, if_block_mode):
        self.region_type = region_type
        self.if_block_mode = if_block_mode

    def __str__(self):
        return f"<RegionInfo: ({self.region_type}, {self.if_block_mode})>"


# Type of preprocessing region the parser is located in
class RegionType(Enum):
    IF = 1      # between if and the next else or endif
    IFN = 2     # between ifn and the next else or endif
    ELSE = 3    # between else and endif (after either if or ifn)
    PICO8 = 4   # between pico8 start and end directives
    IGNORED = 5 # we were inside a false condition so we don't care, we are just waiting for #else or #endif


# Parsing mode of each individual #if block
class IfBlockMode(Enum):
    ACCEPTED = 1  # the condition was true
    REFUSED  = 2  # the condition was false
    IGNORED  = 3  # we were inside a false condition so we don't care, we are just waiting for #else or #endif


# Parsing state machine modes
class ParsingMode(Enum):
    ACTIVE   = 1  # we are copying each line
    IGNORING = 2  # we are ignoring all content in the current if block


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

    # explore the tree of regions by storing the current stack of RegionInfo encountered from top to bottom
    # note that the stack can only have one RegionType with IfBlockMode.REFUSED, and if it has one, all entries
    # above in the stack must have IfBlockMode.IGNORED
    region_info_stack = []
    current_mode = ParsingMode.ACTIVE  # it is ParsingMode.ACTIVE iff region_info_stack is empty or region_info_stack[-1].if_block_mode == IfBlockMode.ACCEPTED

    for line in lines:
        # preprocess directives
        opt_match = None      # if or ifn match depending on which one succeeds, None if both fail
        negative_if = False   # True if we have #ifn, False else

        if_boundary_match = if_pattern.match(line)
        if not if_boundary_match:
            if_boundary_match = ifn_pattern.match(line)
            if if_boundary_match:
                negative_if = True

        else_boundary_match = None
        if not if_boundary_match:
            else_boundary_match = else_pattern.match(line)

        if if_boundary_match:
            region_type = RegionType.IFN if negative_if else RegionType.IF

            if current_mode is ParsingMode.ACTIVE:
                symbol = if_boundary_match.group(1)

                # positive if supports one || symbol
                if not negative_if:
                    symbol2 = if_boundary_match.group(2)
                else:
                    symbol2 = None

                # for #if, you need to have symbol defined, for #ifn, you need to have it undefined
                if (symbol in defined_symbols or symbol2 in defined_symbols) ^ negative_if:
                    # symbol is defined, so remain active and add that to the stack
                    region_info_stack.append(RegionInfo(region_type, IfBlockMode.ACCEPTED))
                    # still strip the preprocessor directives themselves (don't add it to accepted lines)
                else:
                    # symbol is not defined, enter ignoring mode and add that to the stack
                    region_info_stack.append(RegionInfo(region_type, IfBlockMode.REFUSED))
                    current_mode = ParsingMode.IGNORING
            else:
                # we are already in an unprocessed block so we don't care whether that subblock verifies the condition or not
                # continue ignoring lines but push to the stack so we can wait for #else or #endif
                region_info_stack.append(RegionInfo(region_type, IfBlockMode.IGNORED))

        elif else_boundary_match:
            if region_info_stack and region_info_stack[-1].region_type in (RegionType.IF, RegionType.IFN):
                # reverse the if block mode state of the if(n) region (if ignored, keep ignoring)
                last_region_info = region_info_stack.pop()
                if last_region_info.if_block_mode is IfBlockMode.ACCEPTED:
                    region_info_stack.append(RegionInfo(RegionType.ELSE, IfBlockMode.REFUSED))
                    current_mode = ParsingMode.IGNORING
                elif last_region_info.if_block_mode is IfBlockMode.REFUSED:
                    region_info_stack.append(RegionInfo(RegionType.ELSE, IfBlockMode.ACCEPTED))
                    current_mode = ParsingMode.ACTIVE
                else:
                    # if we were ignoring the whole #if block, keep ignoring it and no need to change current mode
                    region_info_stack.append(RegionInfo(RegionType.ELSE, IfBlockMode.IGNORED))
            else:
                raise Exception('an --#else was encountered outside an --#if(n) block. Make sure the block starts with an --#if(n) directive')

        elif endif_pattern.match(line):
            if region_info_stack and region_info_stack[-1].region_type in (RegionType.IF, RegionType.IFN, RegionType.ELSE):
                # go one level up
                last_region_info = region_info_stack.pop()
            else:
                raise Exception('an --#endif was encountered outside an --#if(n)/else block. Make sure the block starts with an --#if(n) directive')

            if current_mode is ParsingMode.IGNORING:
                # if we left the refusing block, then the new last mode is ACCEPTED and we should be active again
                # otherwise, we have simply left an IGNORED mode and we remain IGNORING
                if last_region_info.if_block_mode is IfBlockMode.REFUSED:
                    current_mode = ParsingMode.ACTIVE
        elif pico8_start_pattern.match(line):
            if region_info_stack and any(region_info.region_type is RegionType.PICO8 for region_info in region_info_stack):
                raise Exception('a pico8 block start was encountered inside a pico8 block')

            # we detected a pico8 block and should continue appending the lines normally (since we are building for pico8)
            # the if block mode is not relevant for pico8 region, which are always accepted, but to keep semantic
            # we just pass ACCEPTED
            region_info_stack.append(RegionInfo(RegionType.PICO8, IfBlockMode.ACCEPTED))

        elif pico8_end_pattern.match(line):
            if region_info_stack and region_info_stack[-1].region_type is RegionType.PICO8:
                # go one level up
                region_info_stack.pop()
            else:
                raise Exception('a pico8 block end was encountered outside a pico8 block')

        elif current_mode is ParsingMode.ACTIVE:
            if not line.isspace() and not is_full_comment_line(line) and not match_stripped_function_call(line, defined_symbols):
                    preprocessed_lines.append(line)

    if region_info_stack:
        raise Exception(f'file ended inside a block of region type: {region_info_stack[-1].region_type}. Make sure the last region is closed.')

    return preprocessed_lines


def is_full_comment_line(line):
    """Return true if line is a full comment"""
    # strip so we don't have to check whitespaces in common_pattern regex
    return comment_pattern.match(line.strip())


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
