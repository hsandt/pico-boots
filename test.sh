#!/bin/bash

help() {
  echo "Test pico-boots modules with busted

This is essentially a proxy script for scripts/test_scripts.sh that avoids
passing src/engine/FOLDER every time we want to test a group of scripts.

Dependencies:
- busted (must be in PATH)
- luacov (must be in PATH)
"
usage
}

usage() {
  echo "Usage: test.sh [FOLDER-1 [FOLDER-2 [...]]]

ARGUMENTS
  FOLDER                    Path to engine folder to test.
                            Path is relative to src/engine. Sub-folders are supported.
                            (optional, default: '')

  -h, --help                Show this help message
"
}

# Default parameters
folders=()
other_options=()

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
roots=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help )
      help
      exit 0
      ;;
    -* )    # we started adding options
            # since we don't support "--" for final positional arguments, just pass all the rest to test_scripts.sh
      break
      ;;
    * )     # positional argument: folder
      folders+=("$1")
      shift # past argument
      ;;
  esac
done

# Paths are relative to src/engine, so prepend it before passing to actual test script
for folder in "${folders[@]}"; do
  roots+=("\"src/engine/$folder\"")
done

"$(dirname $0)/scripts/test_scripts.sh" ${roots[@]} $@
