#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re
import sys
import collections
from pathlib import Path

from .generate_dependency_map import generate_dependency_map

"""
Generates a DOT graphviz file in [output_filepath] showing the require dependencies between all lua
sources found in [scripts_root].
See more details in generate_dependency_graph docstring

Usage:
python generate_dependency_graph.py output_filepath scripts_root1 [scripts_root2 ...]

Parameter           Description

output_filepath     Path to .dot graph file to generate
                    Base filename without extension supported

scripts_rootX       Scripts root #X (engine and game src folders)

"""


def generate_dependency_graph(output_filepath, scripts_roots, print_arrow_from_required=False):
    """
    Write a DOT file into output_filepath that represents the dependency graph between all modules
    found in scripts recursively searched in all scripts_roots.

    If print_arrow_from_required is False (default), graph arrows mean "is used by".
    Otherwise, arrows are reversed and mean "is using".

    """
    # suffix output filepath with ".dot" if not already
    if not output_filepath.endswith(".dot"):
        output_filepath += ".dot"

    # make sure output dir exists
    output_dir = os.path.dirname(output_filepath)
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
        logging.info(f"Created output directory: {output_dir}")
    elif not os.path.isdir(output_dir):
        logging.error(f"output_dir '{output_dir}' exists but is not a directory")
        return

    dependency_map = generate_dependency_map(scripts_roots)
    lines = build_dependency_graph_lines_from_dependencies(dependency_map, print_arrow_from_required)

    # write to output file
    with open(output_filepath, "w+") as dot_file:
        dot_file.writelines(lines)


def build_dependency_graph_lines_from_dependencies(dependency_map, print_arrow_from_required):
    """
    Return a list of lines that would constitute a DOT graph file representing the passed
    dependencies from the dependency map, with the wanted arrow sense convention.

    """
    # directional graph start
    # rank from top to bottom to visualize strong dependents vs strong dependees easily
    indent = "    "
    lines = [
        "digraph G {\n",
        f"{indent}rankdir=TB\n",
        f"{indent}edge [arrowhead=vee]\n"
    ]

    for filepath, required_paths in dependency_map.items():
        for required_path in required_paths:
            filepath_pair = [filepath, required_path]

            # when using print_arrow_from_required, print required_path -> filepath (means "is used by"),
            # else keep "is using" order
            # note that when reversed, the iteration order still groups same requiring scripts together,
            # so the apparent script order will not make sense in the DOT file
            if print_arrow_from_required:
                filepath_pair.reverse()

            # tune this to change arrow thickness
            thickness = 5

            # ex: '<indent>"engine/application/coroutine_runner" -> "engine/application/coroutine_curry" [penwidth=5]'
            # the double quotes are needed to support path slashes by graphviz
            lines.append(f'{indent}"{filepath_pair[0]}" -> "{filepath_pair[1]}" [penwidth={thickness}]\n')

    # directional graph end
    lines.append("}\n")

    return lines


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
    parser.add_argument('output_filepath', type=str, help='path to output DOT graph file to')
    parser.add_argument('scripts_roots', type=str, nargs='+', help='locations of Lua source file roots (engine and game src folders)')
    parser.add_argument('--arrow-from-required', action="store_true", help='print arrow from user to required script instead of the opposite')
    args = parser.parse_args()

    logging.info(f"Generating dependency graph for Lua sources in {args.scripts_roots} to {args.output_filepath} (arrow from required: {args.arrow_from_required})...")
    generate_dependency_graph(args.output_filepath, args.scripts_roots, args.arrow_from_required)
    logging.info(f"Generated dependency graph in {args.output_filepath}")

if __name__ == "__main__":
    main()
