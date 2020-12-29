#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
import sys
import collections
from pathlib import Path
from queue import Queue

from .generate_dependency_map import generate_dependency_map

"""
Generates a file in [output_filepath] containing require calls in order, files mentioned below requiring files mentioned above.
Use this to generate a file that you'll require from main or some common.lua, to force picotool to concatenate
files in the same order and make it possible to build with --unity for a more compact cartridge with
module definitions in outer scope, as they need to be in dependency order.

Hardcoded strings note:
  require("ordered_require[_optional_cartridge_suffix]") and require("engine/common") also automatically skipped to avoid infinite recursion,
  since this script is made to generate an ordered_require[_optional_cartridge_suffix].lua to be required inside engine/common.lua
  (if you use it differently, you may need to adapt hardcoded strings).

Sources are scanned in [scripts_rootX] and the main entry file must be passed as [entry_script_path].

Usage:
python generate_ordered_require_file.py output_filepath entry_script_path scripts_root1 [scripts_root2 ...]

Parameter           Description

output_filepath     Path to .dot graph file to generate
                    Base filename without extension supported

entry_script_path   Path to main entry Lua file, relative to game src folder
                    With or without .lua extension

scripts_rootX       Scripts root #X (engine and game src folders)

"""

def write_ordered_require_lines_to(output_filepath, entry_script_path, scripts_roots):
    """
    Write require call lines into a Lua file at output_filepath, so requiring this file
    early in the project (in main or some common.lua required at main top) will force picotool
    to concatenate some modules in a given order: modules below depending on modules above.

    This will allow to build cartridge with --unity and strip all package and require definitions
    for a more compact cartridge.

    """
    # suffix output filepath with ".lua" if not already
    if not output_filepath.endswith(".lua"):
        output_filepath += ".lua"

    # make sure output dir exists
    output_dir = os.path.dirname(output_filepath)
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
        logging.info(f"Created output directory: {output_dir}")
    elif not os.path.isdir(output_dir):
        logging.error(f"output_dir '{output_dir}' exists but is not a directory")
        return

    dependency_map = generate_dependency_map(scripts_roots)
    lines = build_ordered_require_lines_from_dependencies(dependency_map, entry_script_path)

    # write to output file
    with open(output_filepath, "w+") as dot_file:
        dot_file.writelines(lines)


def build_ordered_require_lines_from_dependencies(dependency_map, entry_script_path):
    """
    Return a list of lines containing require calls in dependency order,
    from depended on to dependent modules.
    Raises error if a circular dependency is found.

    The scan starts at entry_script_path (actually relative path from game src), checks the
    next required path, then its own required paths in depth-first search, until a script without
    requirements is found (this one is appended first to the list of lines).
    It then goes up and continue scanning the following requires, skipping any module already
    required and appended. If any parent module (whose require is in progress, but not appended yet)
    is found, it means there is a circular dependency, and the scan fails.

    """
    # cut .lua extension if needed
    if entry_script_path.endswith(".lua"):
        entry_script_path = entry_script_path[:-4]

    lines = []
    visit_stack = []  # only for circular dependency detection
    already_required_module_paths = []

    visit_path(dependency_map, entry_script_path, visit_stack, already_required_module_paths, lines)

    return lines


def visit_path(dependency_map, path, visit_stack, already_required_module_paths, lines):
    visit_stack.append(path)

    if path not in dependency_map:
        raise Exception(f"No entry found in dependency map for '{path}'. dependency_map: {dependency_map}\n")

    required_paths = dependency_map[path]
    for required_path in required_paths:
        # check for circular dependency
        if required_path in visit_stack:
            raise Exception(f"Circular dependency detected: current visit stack is {visit_stack}, requiring {required_path}\n")

        # if already required, it's fine, skip it
        # else, visit it recursively
        # also hardcode ignoring ordered_require itself, which doesn't exist yet but will be the output file
        if required_path not in already_required_module_paths and not required_path.startswith('ordered_require'):
            visit_path(dependency_map, required_path, visit_stack, already_required_module_paths, lines)

            # we finished visiting this path and adding any deeper require,
            # so we can now require that required script itself (doing it here
            # instead of after the loop also ensures only actually required scripts
            # are added, so never main)

            # hardcoded: we do visit engine/common which includes scripts of interest, but never
            # add a line to require it since the ordered_require[_optional_cartridge_suffix].lua is meant to be required in
            # engine/common.lua and that would cause infinite recursion (out of memory in PICO-8)
            if required_path != 'engine/common':
                # ex: 'require("engine/application/coroutine_curry")'
                lines.append(f'require("{required_path}")\n')
                already_required_module_paths.append(required_path)

    # we are done with this node, pop from the stack
    visit_stack.pop()


def main():
    logging.basicConfig(level=logging.INFO)

    # get the full path of this script using realpath, because:
    # - Path.cwd() will give a different path if executing the script form a different folder
    # - sys.argv[0] will only give the relative path from the current working directory,
    #   making it impossible to retrieve parent directories via Path parent
    current_script_path = os.path.realpath(__file__)
    current_script_dir = os.path.dirname(current_script_path)

    logging.debug(f"current_script_path: '{current_script_path}'")
    logging.debug(f"current_script_dir: '{current_script_dir}'")

    parser = argparse.ArgumentParser(description='Unify lua code in cartridge.')
    parser.add_argument('output_filepath', type=str, help='path to output ordered require file to')
    parser.add_argument('entry_script_path', type=str, help='path to main entry source file to start scanning from')
    parser.add_argument('scripts_roots', type=str, nargs='+', help='locations of Lua source file roots (engine and game src folders)')
    args = parser.parse_args()

    logging.info(f"Generating ordered require file for Lua sources in {args.scripts_roots} to {args.output_filepath} (entry script: {args.entry_script_path})...")
    write_ordered_require_lines_to(args.output_filepath, args.entry_script_path, args.scripts_roots)
    logging.info(f"Generated ordered require file in {args.output_filepath}")

if __name__ == "__main__":
    main()
