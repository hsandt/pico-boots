#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import logging
import os
import re
import collections

"""
Pure library script

Provides a function to generate a dependency map for all scripts found under a list of root folders.

"""

# Ex: local my_module = require("category/my_module")
# Ex 2: require("category/my_enums")
REQUIRE_CALL_PATTERN = re.compile(r"(?:local \w+(?:\s+)?=(?:\s+)?)?require\(\"([\w/]+)\"\)")


def generate_dependency_map(scripts_roots):
    """
    Return a dependency map: OrderedDict: {module_name: [dependency_name1, dependency_name2, ...]}
    for all scripts recursively searched in all scripts_roots.

    If print_arrow_from_required is False (default), graph arrows mean "is used by".
    Otherwise, arrows are reversed and mean "is using".

    """
    # use an ordered dict for more predictible iteration order
    dependency_map = collections.OrderedDict()

    for scripts_root in scripts_roots:
        for dirpath, dirnames, filenames in os.walk(scripts_root):
            # Sort dirs and files to make the line order in the output file content more stable
            dirnames.sort()
            filenames.sort()

            # Iterate over all Lua files and extract base filename as module name
            for filename in filenames:
                # Only consider true sources, ignore utests
                if filename.endswith(".lua") and not filename.endswith("_utest.lua"):
                    filepath = os.path.join(dirpath, filename)
                    logging.debug(f"Inspecting {filepath}...")

                    # we always store relative paths from script root (pico-boots/src or game/src)
                    # in dependency map to avoid unwanted src/ (or /tmp/ in unit tests) and
                    # match path passed to require()
                    rel_filepath = os.path.relpath(filepath, scripts_root)

                    # just cut the .lua so it really matches the path passed to require
                    # (we match ?.lua so require paths never contain them)
                    rel_filebasepath = rel_filepath[:-4]

                    # initialize dependencies list
                    dependency_map[rel_filebasepath] = []

                    with open(filepath, "r") as module_file:
                        # identify dependencies by finding all "require(...)" or
                        # "local m = require(...)" at the beginning of the file
                        for line in module_file:
                            require_call_match = REQUIRE_CALL_PATTERN.match(line)
                            if require_call_match:
                                required_path = require_call_match[1]

                                # store dependency with relative paths
                                dependency_map[rel_filebasepath].append(required_path)
                                logging.debug(f"'{rel_filebasepath}' requires '{required_path}'")

    return dependency_map
