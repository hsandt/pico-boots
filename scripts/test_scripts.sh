#!/bin/bash

# Configuration
picoboots_src_path="$(readlink -f "$(dirname $0)/../src")"
picoboots_scripts_path="$(dirname $0)"

help() {
  echo "Test lua modules with busted

Lua scripts must be written in pure Lua, i.e. they must not use PICO-8-specific syntax.

Dependencies:
- busted (must be in PATH)
- luacov (must be in PATH)
"
usage
}

usage() {
  echo "Usage: test_scripts.sh [ROOT-1 [ROOT-2 [...]]]

ARGUMENTS
  ROOT                      Path to folder containing test scripts.
                            Path is relative to the current working directory,
                            The full relative path to a specific test file can also
                            be passed, but it is recommended to use the -f option instead
                            to benefit from the automated test detection/targeted coverage.
                            If no folder is defined, the current working directory is tested.
                            (this differs from busted which requires '.' to be passed)
                            Ex: 'src/engine/application'
                            (optional, default: single root '.')

OPTIONS
  -f, --file FILE_BASE_NAME Basename of either the Lua source file (module) to test or
                            of the test itself.
                            If FILE_BASE_NAME ends with '_utest', it is stripped
                            to define the module name.
                            Else, it is directly used as module name.
                            A test file named '${MODULE}_utest.lua' should exist
                            somewhere under the ROOTs.
                            If empty, all test files found in the ROOTs are tested.
                            It is recommended to give a different name to every module
                            present under the ROOTS to avoid incorrect test detection/
                            targeted coverage.
                            Ex: 'flow', 'flow_utest'
                            (default: '')

  -m, --filter-mode MODE    Filter mode.
                            '' to filter out #mute (useful to skip WIP tests)
                            'solo' to filter #solo (useful to focus on a specific test)
                            'all' for no filters (include #mute compared to '')
                            (default: '')

  -l, --lua-root EXTRA_LUA_ROOT
                            Lua root used besides engine source directory for lua_path.
                            Add one if you are testing scripts outside the engine source
                            directory, that require other scripts from a given root.
                            Typically, this is your game source directory.

  -h, --help                Show this help message
"
}

# Default parameters
file_base_name=""
filter_mode=""
extra_lua_root=""

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
roots=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -f | --file )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      file_base_name="$2"
      shift # past argument
      shift # past value
      ;;
    -m | --filter-mode )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      filter_mode="$2"
      shift # past argument
      shift # past value
      ;;
    -l | --lua-root )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      extra_lua_root="$2"
      shift # past argument
      shift # past value
      ;;
    -h | --help )
      help
      exit 0
      ;;
    -* )    # unknown option
      echo "Unknown option: '$1'"
      usage
      exit 1
      ;;
    * )     # positional argument: root
      roots+=("$1")
      shift # past argument
      ;;
  esac
done

if [[ ${#roots[@]} -eq 0 ]]; then
  # test the current working directory
  roots=(".")
fi

if [[ ! -z $file_base_name ]] ; then
  # if file basename designates a utest already,
  # extract the name of the tested module
  # (mind the space before '-', and note that a very short name will return empty string, which is OK)
  if [[ ${file_base_name: -6} = "_utest" ]] ; then
    module=${file_base_name::-6}
  else
    module=$file_base_name
  fi
  shift
fi

if [[ -z $module ]] ; then
  # no specific file to test, test them all (inside target project directories)
  test_file_pattern="_utest%.lua$"

  # cover exactly the roots you are testing
  # note: for pico8wtk, the test file is inside engine/ but the source is not, so it won't be covered when testing engine/,
  # which is ideal since we know we are not covering it at 100% anyway
  # .luacov_all will exclude utest themselves from coverage
  coverage_options="${roots[@]} -c \"$picoboots_scripts_path/.luacov_all\""

  # for logging
  module_str="all modules"
else
  # test specific module with exact full name to avoid issues with similar file names (busted uses Lua string.match where escaping is done with '%'')
  test_file_pattern="^${module}_utest%.lua$"

  # luacov filter will ignore any trailing '.lua', so we need to add end symbol '$' just after module name to avoid confusion with similar file names
  # The final '$' will prevent detecting folder with the same name (e.g. ui.lua vs ui/) since all folders continue with '/'.
  # Modules with the exact same name will still be covered together, so make sure to name your modules differently
  # (even between engine and game), as recommended in the Usage.
  # .luacov_current is important to exclude lib files as we don't have control on their names and may be confused with ours (e.g. pl/class.lua vs core/class.lua)
  coverage_options="\"/${module}$\" -c \"$picoboots_scripts_path/.luacov_current\""

  # for logging
  module_str="module $module"
fi

if [[ $filter_mode = "all" ]] ; then
  filter=""
  filter_out=""
  use_coverage=true
elif [[ $filter_mode = "solo" ]]; then
  filter="--filter \"#solo\""  # focus on #solo tests (when working on a particular test, flag it #solo for faster iterations)
  filter_out=""
  use_coverage=false  # coverage on a file is not relevant when testing one or two functions
else
  filter=""
  filter_out="--filter-out \"#mute\""  # by default, skip #mute (flag your WIP tests #mute to avoid error/failure spam)
  use_coverage=true
fi

if [[ $use_coverage = true ]]; then
  # Before test, clean previous coverage
  pre_test_cmd="rm -f luacov.stats.out luacov.report.out"

  # After test, generate luacov report and display all uncovered lines (starting with *0) and coverage percentages
  coverage_options="$coverage_options"
  post_test_cmd="luacov $coverage_options && echo $'\n\n= COVERAGE REPORT =\n' && grep -C 3 -P \"(?:(?:^|[ *])\*0|\d+%)\" luacov.report.out"
else
  # no-ops
  pre_test_cmd=":"
  post_test_cmd=":"
fi

echo "Testing $module_str in: ${roots[@]}..."

# Always give access to engine modules
lua_path="$picoboots_src_path/?.lua"

# Add access to custom (game) modules if testing external source
if [[ ! -z $extra_lua_root ]] ; then
  lua_path+=";$(pwd)/$extra_lua_root/?.lua"
fi

# Actual test command
core_test_cmd="busted ${roots[@]} --lpath=\"$lua_path\" -p \"$test_file_pattern\" $filter $filter_out -c -v"

full_test_cmd="$pre_test_cmd && $core_test_cmd && $post_test_cmd"
echo "> $full_test_cmd"
bash -c "$full_test_cmd"
