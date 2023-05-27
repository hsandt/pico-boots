#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
import shutil, tempfile
from enum import Enum

# This script removes the __lua__ section of a .p8 cart so it can be used as pure data cart
# This is useful when saving a data cart from an offline p8 script run headlessly, as this will save
# the script itself in __lua__ section but you generally don't need it again at runtime.
# CAUTION: this modifies the .p8 file in-place!

# Usage:
# strip_lua_section_inplace.py filepath
#
# ARGUMENTS
# filepath          path to .p8 data file to remove __lua__ section from

class ParsingPhase(Enum):
    BEFORE_LUA = 1
    INSIDE_LUA = 2
    AFTER_LUA = 3

data_section_header_pattern = re.compile(r'^__(gfx|label|gff|map|sfx|music|change_mask|meta)__$')

def strip_lua_section_inplace(filepath):
    """
    Replace label content inside the file with content from another line

    test.p8:
        pico-8 cartridge // http://www.pico-8.com
        version 32
        __lua__
        CONTENT
        CONTENT
        CONTENT
        __gfx__
        0000000
        0000000
        0000000

    >>> add_label_info('test.p8')

    test.p8:
        pico-8 cartridge // http://www.pico-8.com
        version 32
        __gfx__
        0000000
        0000000
        0000000

    """
    with open(filepath, 'r') as f:
        with tempfile.TemporaryDirectory() as temp_dir:
            # create a temporary file with the modified content before it replaces the original file
            temp_filepath = os.path.join(temp_dir, 'test.p8')
            with open(temp_filepath, 'w') as temp_f:
                parsing_phase = ParsingPhase.BEFORE_LUA

                for line in f:
                    stripped_line = line.rstrip()

                    # First, check for section change
                    if parsing_phase == ParsingPhase.BEFORE_LUA:
                        if stripped_line == '__lua__':
                            # We entered __lua__ section
                            parsing_phase = ParsingPhase.INSIDE_LUA
                    elif parsing_phase == ParsingPhase.INSIDE_LUA:
                        section_header_match = data_section_header_pattern.match(stripped_line)
                        if section_header_match:
                            # We exited __lua__ section to enter another (data) section
                            parsing_phase = ParsingPhase.AFTER_LUA
                    # else, we are in ParsingPhase.AFTER_LUA, so don't check for further section
                    # change as we have already passed the __lua__ section and should keep all the rest

                    # Second, copy line if we are outside __lua__ section
                    if parsing_phase != ParsingPhase.INSIDE_LUA:
                        temp_f.write(line)

            # Copy temp file content to original place for in-place modification
            shutil.copy(temp_filepath, filepath)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Strip __lua__ section from p8 cart file in-place.')
    parser.add_argument('filepath', type=str, help='path of the file to process (.p8)')
    args = parser.parse_args()
    strip_lua_section_inplace(args.filepath)
    print(f"Stripped __lua__ section from '{args.filepath}'.")
