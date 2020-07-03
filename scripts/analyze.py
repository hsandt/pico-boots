#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os, sys
import shutil, tempfile
import re
from subprocess import Popen

# This script uses p8tool on .lua files to provide interesting stats:
# A. Count tokens in a single .lua file, ignoring require statements
# B. Count tokens in each .lua file recursively found in a directory, using the same process as A.
#
# Stats are directly printed to stdout
#
# Apply this script to the intermediate directory *after* building for release config,
# as this will give the most meaningful results (pre-processing already applied).

CARTRIDGE_AND_LUA_HEADER = """pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
"""
META_INFO_FORMAT = """-- {}
-- by analyze_script
"""
EXCLUDE_FILE_PATTERN = re.compile(r".+_utest\.lua$")
# TODO: pico8api, bustedhelper...

def analyze_scripts_in_dir(dirpath):
    """Print lua script stats for all the source files inside the given directory"""
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua") and not EXCLUDE_FILE_PATTERN.match(file):
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

    analyze_scripts_in_dir(args.path)
