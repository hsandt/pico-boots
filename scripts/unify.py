#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import shutil
import re
from enum import Enum
from subprocess import Popen, PIPE

# This script unifies the __lua__ section of a cartridge {game}.p8:
# 1. It uses p8tool listlua A.p8 to quickly extract the __lua__ code into {game}_unified.lua
# 2. It removes package table definition inserted by p8tool
# 3. It removes package function definition surrounding code inserted by p8tool
# 4. It removes require function definition and all require calls inserted by p8tool
# 5. It reads the header (before __lua__) of {game}.p8 and copies it into {game}_unified.p8
# 6. It appends {game}_unified.lua's content to {game}_unified.p8
# 7. It finishes reading {game}.p8's remaining sections and appends them into {game}_unified.p8
# 8. It replaces {game}.p8 with {game}_unified.p8

# It requires script to have been minified at least with level 1,
# as it doesn't check for comments and extra whitespaces.

script_dir_path = os.path.dirname(os.path.realpath(__file__))

# same as minify.py
LUA_HEADER = b"__lua__\n"

# package table definition inserted by p8tool at top of lua source
# _c is never minified, so you can keep it
# Ex: "package={loaded={},_c={}}"
# Ex minified: "a={b={},_c={}}"
PACKAGE_TABLE_DEFINITION_PATTERN = re.compile(r"\w+={\w+={},_c={}}")

# package function definition inserted by p8tool to surround each .lua file
# note that we match the end of the previous package (if any), including its return
# since we must remove all module returns when flattening the source
# we could retrieve 'package' minified name from PACKAGE_TABLE_DEFINITION_PATTERN
# to retrieve it just before "._c", but the "_c" alone makes sure we won't misidentify
# unrelated code with a package function definition
# in minified code, \s+ below is always a single space
# after "end", we always have \n even on unminified code as picotool generates the
# package function surrounding code this way
# (newline separator ensures we have newlines when minified)
# Ex: "return coroutine_runner\nend\npackage._c["engine/core/coroutine_curry"]=function()"
# Ex minified: "return ej end\na._c["engine/core/coroutine_curry"]=function()"
PACKAGE_FUNCTION_DEFINITION_PATTERN = re.compile(r"(?:(?:return \w+\s+)?end\n)?\w+\._c\[\"[\w/]+\"\]=function\(\)")

# require function definition inserted by p8tool
# 1st match is the name of the require function
# it is important because minification may change this name,
# and we use it to find require calls
# note that we are matching the "(return module) end" of the last package defined (missed by PACKAGE_FUNCTION_DEFINITION_PATTERN),
# so without this removal the syntax won't even be correct

# variant when using no minification nor clean lua (still capture "require" so we can use same code as minified
# to get require function name)
REQUIRE_FUNCTION_DEFINITION_PATTERN_UNMINIFIED = re.compile(r"""(?:(?:return \w+\s+)?end\n)?function (require)\(p\)
local l=package\.loaded
if \(l\[p]==nil\) l\[p]=package._c\[p]\(\)
if \(l\[p]==nil\) l\[p]=true
return l\[p]
end\n""")

# variant when using minification level 1 or more, which also requires clean lua
REQUIRE_FUNCTION_DEFINITION_PATTERN_MINIFIED = re.compile(r"""(?:(?:return \w+\s+)?end\n)?function (\w+)\((\w+)\)local (\w+)=(\w+)\.\w+
if \3\[\2]==nil then \3\[\2]=\4\._c\[\2]\(\)end
if \3\[\2]==nil then \3\[\2]=true end
return \3\[\2]end\n""")

# you need to call .format(require_function_name = '...') on this (after finding the require function name)
# to get the actual pattern
REQUIRE_FUNCTION_CALL_PATTERN_FORMAT = r"(?:local \w+(?:\s+)?=(?:\s+)?)?{require_function_name}\(\"[\w/]+\"\)"


# same as minify.py
class Phase(Enum):
    CARTRIDGE_HEADER = 1  # copying header, from "pico-8 cartridge..." to "__lua__"
    LUA_SECTION      = 2  # found "__lua__", still copy the 2 author/version comment lines then appending unified lua all at once
    LUA_CATCHUP      = 3  # skipping the unused original lua until we reach the other sections
    OTHER_SECTIONS   = 4  # copying the last sections


def unify_lua_in_p8(cartridge_filepath):
    """
    Unifies the __lua__ section of a p8 cartridge.

    """
    logging.debug(f"Unifying lua in cartridge {cartridge_filepath}...")

    root, ext = os.path.splitext(cartridge_filepath)
    if not ext.endswith(".p8"):
        raise Exception(f"Cartridge filepath '{cartridge_filepath}' does not end with '.p8'")

    unified_cartridge_filepath = f"{root}_unified.p8"
    lua_filepath = f"{root}.lua"
    unified_lua_filepath = f"{root}_unified.lua"

    # Many steps are copied from minify.py to make this script standalone
    # but to avoid duplication and redundant operations, consider
    # extracting Lua code once, then minify + unify, then reinject in .p8 once.

    # Step 1: extract lua code into separate file
    with open(lua_filepath, 'w') as lua_file:
        extract_lua(cartridge_filepath, lua_file)

    # Step 2-4: unify lua code in this file to a new _unified file
    with open(lua_filepath, 'r') as lua_file:
        original_char_count = sum(len(line) for line in lua_file)
        print(f"Original lua code has {original_char_count} characters")
        # we wrote to lua_file and are now at the end, so rewind
        lua_file.seek(0)
        with open(unified_lua_filepath, 'w+') as unified_lua_file:
            unify_lua(lua_file, unified_lua_file)

    # Step 5-7: inject unified lua code into target cartridge
    phase = Phase.CARTRIDGE_HEADER
    with open(cartridge_filepath, 'r') as source_file,     \
         open(unified_cartridge_filepath, 'w') as target_file, \
         open(unified_lua_filepath, 'r') as unified_lua_file:
        inject_lua_in_p8(source_file, target_file, unified_lua_file)

    # Step 8: replace original p8 with unified p8, clean up intermediate files
    # os.remove(cartridge_filepath)
    # os.remove(lua_filepath)
    # os.remove(unified_lua_filepath)
    shutil.move(unified_cartridge_filepath, cartridge_filepath)


# same as minify.py
def extract_lua(source_filepath, lua_file):
    """
    Extract lua from .p8 cartridge at source_filepath (string) to lua_file (file descriptor: write)

    """
    (_stdoutdata, stderrdata) = Popen([f"p8tool listrawlua \"{source_filepath}\" | awk 'NR % 2 == 1'"], shell=True, stdout=lua_file, stderr=PIPE).communicate()
    if stderrdata:
        raise Exception(f"p8tool listrawlua failed with:\n\n{stderrdata.decode()}")


def unify_lua(lua_file, unified_lua_file):
    """
    Strip package table definition, package definitions, require definition and require calls
    in lua_file (file descriptor: read) and write result to unified_lua_file (file descriptor: write)

    """

    # for now we apply regex on the whole text
    # this is probably not a good idea for memory, but more simple to handle patterns
    # spread over multiple lines
    lua_text = lua_file.read()

    # 2. It removes package table definition inserted by p8tool
    # Performance: good, this definition is always at the start, and we stop on first
    # occurrence
    unified_lua_text = PACKAGE_TABLE_DEFINITION_PATTERN.sub("", lua_text, count=1)

    # 3. It removes package function definition surrounding code inserted by p8tool
    # Performance: OK, but we have to go through the whole text with the complex regex
    unified_lua_text = PACKAGE_FUNCTION_DEFINITION_PATTERN.sub("", unified_lua_text)

    # 4. It removes require function definition and all require calls inserted by p8tool

    # a. First, search the require function definition, as it will give us the (potentially minified)
    # require function name (if not minified, it is of course "require")
    # Performance: there is only one match at the end, so it's a waste to go through all
    # the code just to find it. It may be worth doing a search for step 3 (and manually
    # removing code as in 4b. below), then starting search from the end of that last search
    # (i.e. the start of the last package). This would effectively simulate a line-by-line
    # iteration over the file to preserve O(N), N line count (we could also rely on
    # minification using newline-separator so we know we don't need multi-line matching
    # everywhere, and can identify package start/end line-by-line)
    require_definition_match = REQUIRE_FUNCTION_DEFINITION_PATTERN_MINIFIED.search(unified_lua_text)

    # if not using minification, we should search for code as output by picotool (with one-line if patterns)
    # (we don't know if we are using minification in this context)
    if not require_definition_match:
        require_definition_match = REQUIRE_FUNCTION_DEFINITION_PATTERN_UNMINIFIED.search(unified_lua_text)

    if not require_definition_match:
        raise Exception("Unify script failed: cannot find require function definition (neither original nor clean lua)")

    # if we entered the non-minified branch above (found match on REQUIRE_FUNCTION_DEFINITION_PATTERN_UNMINIFIED),
    # then we know the name is "require" (but simpler to keep this line in common for the two cases than hardcoding it)
    require_function_name = require_definition_match[1]

    # b. We must remove the require function definition now, but since we already have a match,
    # no need for another expensive REQUIRE_FUNCTION_DEFINITION_PATTERN_(UN)MINIFIED.sub("", unified_lua_text)
    # just take the string position from the match, and remove everything between start and end
    # but concatenating everything before, and after, together<
    # Performance: OK, single concatenation, but remember we manipulate big text,
    # so for huge files a line-by-line buffering may help
    unified_lua_text = unified_lua_text[:require_definition_match.start()] + unified_lua_text[require_definition_match.end():]

    # c. Remove all require function calls (based on found require function name)
    # Performance: unfortunately we must go through all the file again
    # If you decide to do a single line iteration over the whole file instead,
    # then you should retrieve require function name to start with (this means you may
    # want to do a backward search to find the require function definition)
    # To support unminified code (not recommended as unity build works best with minification),
    # we also match spaces around '='
    # Of course, developer *could* also add spaces around brackets, but we only support common writing
    # as most of the time code will be minified anyway.
    require_function_call_pattern = REQUIRE_FUNCTION_CALL_PATTERN_FORMAT.format(require_function_name = require_function_name)
    unified_lua_text = re.compile(require_function_call_pattern).sub("", unified_lua_text)

    # Write to output file
    unified_lua_file.write(unified_lua_text)

# same as minify.py
def inject_lua_in_p8(source_file, target_file, injected_lua_file):
    """
    Inject lua from injected_lua_file (file descriptor: read)
    into a copy of source_file (file descriptor: read)
    producing target_file (file descriptor: write)

    """
    phase = Phase.CARTRIDGE_HEADER
    for line in source_file:
        if phase is Phase.CARTRIDGE_HEADER:
            # Step 4: copy header (also copy the "__lua__" line just after)
            target_file.write(line)
            if line == "__lua__\n":
                # enter lua section
                phase = Phase.LUA_SECTION

        elif phase is Phase.LUA_SECTION:
            # Step 5: copy injected lua
            target_file.writelines(injected_lua_file.readlines())
            target_file.write("\n")  # newline required before other sections
            phase = Phase.LUA_CATCHUP

        elif phase is Phase.LUA_CATCHUP:
            # skip all lines until __gfx__
            if line == "__gfx__\n":
                # copy the __gfx__ line itself
                target_file.write(line)
                phase = Phase.OTHER_SECTIONS

        else:  # phase is Phase.CARTRIDGE_HEADER
            # Step 6: copy remaining sections
            target_file.write(line)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Unify lua code in cartridge.')
    parser.add_argument('path', type=str, help='path containing cartridge file to unify')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    logging.info(f"Unifying lua code in {args.path}...")

    unify_lua_in_p8(args.path)

    logging.info(f"Unified lua code in {args.path}")
