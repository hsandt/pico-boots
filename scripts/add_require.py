#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import os
import shutil, tempfile

# This script adds "require" statements to a passed lua file,
# for each lua file found recursively in a passed directory path.
# It will only add the statements after the first `--[[add_require]]` tag found in the passed file.
# Note that it doesn't store a reference to the returned module with something like `local module = require("module")`,
# so the required modules should be self-sufficient (e.g. define global variables or have a side effect on some singleton)

# Use it from your PICO-8 game project as a pre-build step to require files you need to find dynamically
# (e.g. itests)

# Usage:
# add_require.py requiring_filepath required_dirpath
# requiring_filepath:           path of the source lua file where to add require statements (.lua is not mandatory). Relative to current working directory.
# require_root:                 path of the root from which we should require modules listed in required_relative_dirpath
# required_relative_dirpath:    path of the directory recursively containing lua modules to require, relative to the require root

def add_require_from_dir(requiring_filepath, require_root, required_relative_dirpath):
    """
    Add `require("{relative_module_path}")` in `requiring_filepath`, under the first `--[[add_require]]` tag,
    for each module found under `require_root`/`required_relative_dirpath`, using module paths relative to
    `require_root`.

    test.lua:
        -- a test file
        --[[add_require]]

        function use_print_helper()
            print_helper("hello")
        end

    helper/print_helper.lua:
        function print_helper(msg)
            print(msg)
        end

    helper/sub/other_helper.lua:
        function dummy()
        end

    >>> add_require_from_dir('src/test.lua', 'src', 'helper')

    test.lua:
        -- a test file
        --[[add_require]]
        require("helper/print_helper")
        require("helper/sub/other_helper")

        function use_helper()
            print_helper("hello")
        end

    """
    relative_module_paths = find_relative_module_paths(require_root, required_relative_dirpath)
    add_require_from_module_paths(requiring_filepath, relative_module_paths)

def add_require_from_module_paths(requiring_filepath, relative_module_paths):
    """
    Add `require("{module}")` in `requiring_filepath`, under the first `--[[add_require]]` tag,
    for each relative module path in `relative_module_paths`.

    """
    with open(requiring_filepath, 'r') as f:
        # create a temporary file with the modified content before it replaces the original file
        temp_dir = tempfile.mkdtemp()
        try:
            temp_filepath = os.path.join(temp_dir, 'temp.lua')
            with open(temp_filepath, 'w') as temp_f:
                for line in f:
                    temp_f.write(line)
                    if line.strip() == '--[[add_require]]':
                        for relative_module_path in relative_module_paths:
                            temp_f.write(f'require("{relative_module_path}")\n')
            shutil.copy(temp_filepath, requiring_filepath)
        finally:
            shutil.rmtree(temp_dir)


def find_relative_module_paths(require_root, relative_dirpath):
    """
    Return list of module paths found recursively under `root`/`relative_dirpath`,
    relative to `root`.

    Result is similar to what find_all_scripts in all_itests_headless_utest.lua would return, but it is meant for
    PICO-8 instead of busted and paths are prefixed with `root` already.

    """
    module_names = []
    dirpath = os.path.join(require_root, relative_dirpath)
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            if file.endswith(".lua"):
                # remove ".lua" from the end
                module_name = file[:-4]

                # unfortunately, os.walk will provide us either the filename or the full root path,
                # so we need to retrieve the relative path of the file from the dirpath ourselves
                full_module_path = os.path.join(root, module_name)
                relative_module_path = os.path.relpath(full_module_path, require_root)
                module_names.append(relative_module_path)
                print(f"root: {root}")
                print(f"full_module_path: {full_module_path}")
                print(f"relative_module_path: {relative_module_path}")
                print(f"require_root: {require_root}")

    return module_names


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Add require statements to a lua source file.')
    parser.add_argument('requiring_filepath', type=str, help='path of the source lua file where to add require statements (.lua is not mandatory)')
    parser.add_argument('require_root', type=str, help='path of the root from which we should require modules listed in required_relative_dirpath')
    parser.add_argument('required_relative_dirpath', type=str, help='path of the directory recursively containing lua modules to require, relative to the require root')
    args = parser.parse_args()
    add_require_from_dir(args.requiring_filepath, args.require_root, args.required_relative_dirpath)
    print(f"Added require statements found in \"{args.require_root}\" / \"{args.required_relative_dirpath}\" to \"{args.requiring_filepath}\".")
