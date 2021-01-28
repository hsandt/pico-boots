#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os, sys
import shutil
import re
from subprocess import Popen
from . import minify

# This script uses p8tool on .lua files to provide interesting stats:
# A. Count tokens and chars in a single .lua file, ignoring require statements
# B. Count tokens and chars in each .lua file recursively found in a directory, using the same process as A.
# C. Count tokens and chars in each .lua file as in B., but after minification lv3

# Stats are directly printed to stdout
#
# Apply this script to the intermediate directory *after* building for release config,
# as this will give the most meaningful results (pre-processing already applied).
# When used as a main script, method C is used since analysis is mostly useful for big projects,
# which should use minification.

CARTRIDGE_AND_LUA_HEADER = """pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
"""
META_INFO_FORMAT = """-- {}
-- by analyze_script
"""

# regex patterns of files to exclude from analysis (utests, bustedhelper and pico8api
# are never put in a PICO-8 build)
UTEST_FILE_PATTERN = re.compile(r".+_utest\.lua$")
BUSTED_ONLY_FILES = ["bustedhelper.lua", "pico8api.lua", "headless_itest.lua"]


def minify_and_analyze_scripts_in_dir(dirpath):
    """
    Generate a copy of the given directory suffixed with '_min' and containing
    lv3-minified versions of the scripts (normally done after p8tool), then analyze
    those minified scripts.

    Differences compared to a full build:

    - it doesn't remove require statements as in a unify build,
      so would have more tokens and characters than compared to a unify build (pessimistic)
      this can be fixed with a simple regex

    - the sum of compressed char counts is generally bigger than the compressed char counts of
      the concatenated code, as compression tends to get some extra on bigger samples
      of text (pessimistic)

    - it minifies symbols from the start of the alphabet for each file,
      so variable names are a bit shorter (optimistic)

    """
    # no need to get basename, just add '_min' to the whole path string
    # to simplify we just copy the whole tree; note that it will also copy
    # utests and busted-only files, so we still need to skip them during
    # minification below
    min_dirpath = f"{dirpath}_min"

    if os.path.isdir(min_dirpath):
        shutil.rmtree(min_dirpath)

    shutil.copytree(dirpath, min_dirpath)

    for root, dirs, files in os.walk(min_dirpath):
        for file in files:
            if file.endswith(".lua") and                        \
                    not UTEST_FILE_PATTERN.match(file) and      \
                    file not in BUSTED_ONLY_FILES:
                # define input and output filepath
                lua_filepath = os.path.join(root, file)
                basepath, ext = os.path.splitext(lua_filepath)
                min_lua_filepath = f"{basepath}_min{ext}"

                # minify file into output path
                # PERFORMANCE: it would be nice to multiprocessing to
                # minify files in parallel, to make us of full CPU on each core
                minify.minify_lua_file(lua_filepath, min_lua_filepath, minify_level=3)

                # replace original with minified file (remove just in case move semantics
                # prevents overwrite)
                os.remove(lua_filepath)
                shutil.move(min_lua_filepath, lua_filepath)

    analyze_scripts_in_dir(min_dirpath)

def analyze_scripts_in_dir(dirpath):
    """Print lua script stats for all the source files inside the given directory"""
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua") and                        \
                    not UTEST_FILE_PATTERN.match(file) and      \
                    file not in BUSTED_ONLY_FILES:
                # PERFORMANCE: it would be nice to multiprocessing to
                # analyze files in parallel, to make us of full CPU on each core
                analyze_script(root, file, sys.stdout)


def analyze_script(root, lua_relative_filepath, output_stream):
    """
    Print lua script stats for this file. It must be a Lua source.
    It is built into a .p8 cartridge only containing that source as an intermediate step,
    so picotool can analyze it like a cartridge
    (we could also import picotool Python scripts and use functions directly on the Lua code, e.g.
    `Lua.from_lines(data.section_lines[section], ...)`)

    """
    lua_filepath = os.path.join(root, lua_relative_filepath)

    # copy script to intermediate folder 'analysis'
    assert lua_filepath.endswith(".lua"), f"filepath {lua_filepath} doesn't end with '.lua'"
    cartridge_filepath = lua_filepath[:-4] + ".p8"
    # turn .lua in .p8 cartridge
    cartridgify(root, lua_relative_filepath, cartridge_filepath)
    # apply p8tool stats
    print_stats(cartridge_filepath, output_stream)
    # cleanup (do not put this in try-finally so in case of error,
    # we can debug what went wrong in the file)
    try:
        os.remove(cartridge_filepath)
    except OSError as e:
        print("Failed with: ", e.strerror)


def cartridgify(root, lua_relative_filepath, output_filepath):
    """
    Create .p8 from .lua by just adding PICO-8 cartridge and lua section header.

    """
    lua_filepath = os.path.join(root, lua_relative_filepath)

    with open(lua_filepath, 'r') as lua_file, open(output_filepath, 'w') as output_file:
        output_file.write(CARTRIDGE_AND_LUA_HEADER)
        output_file.write(META_INFO_FORMAT.format(lua_relative_filepath))
        for line in lua_file:
            output_file.write(line)


def print_stats(cartridge_filepath, output_stream):
    """
    Print stats for .p8 cartridge

    """
    Popen(["p8tool", "stats", cartridge_filepath], stdout=output_stream).communicate()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Print stats for each lua file found recursively under a directory.')
    parser.add_argument('path', type=str, help='Path of the source directory recursively containing lua sources')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    # print tends to output after analyze results, so `echo` directly to have precedence
    Popen(["echo", f"Analyzing lua scripts in {args.path}...\n"]).communicate()

    minify_and_analyze_scripts_in_dir(args.path)
