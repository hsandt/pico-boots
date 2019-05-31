#!/bin/bash

# Configuration
src_engine_path="src/engine"

help() {
  echo "Test engine modules with busted

Dependencies: busted (must be in PATH)
"
usage
}

usage() {
  echo "Usage: test.sh [FOLDER-1 [FOLDER-2 [...]]]

ARGUMENTS
  FOLDER                    Folder to test, path relative to 'src/engine'.
                            Sub-folder paths containing '/' are supported.
                            The full relative path to a specific test file can also
                            be passed, but it is recommended to use the -f option to
                            target a specific module.
                            If no folder is defined, the whole 'src/engine' folder is
                            tested.
                            Ex: 'application', 'application/flow.lua' (not recommended)
                            (optional)

OPTIONS
  -f, --file FILE_BASE_NAME Basename of either the module to test or the test itself.
                            If FILE_BASE_NAME ends with '_utest', it is stripped
                            to define the module name.
                            Else, it is directly used as module name.
                            A test file named '${MODULE}_utest.lua' should exist
                            somewhere under 'src/engine'.
                            If empty, all test files found in the FOLDERs are tested.
                            It is recommended to give a different name to each module
                            so there is no need to pass a FOLDER at all when passing
                            a FILE_BASE_NAME
                            Ex: 'flow', 'flow_utest'
                            (default: '')

  -m, --filter-mode MODE    Filter mode.
                            '' to filter out #mute (useful to skip WIP tests)
                            'solo' to filter #solo (useful to focus on a specific test)
                            'all' for no filters (include #mute compared to '')
                            (default: '')

  -h, --help                Show this help message
"
}

# Default parameters
folders=()
file_base_name=""
filter_mode=""

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
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
    -h | --help )
      help
      exit 0
      ;;
    -* )    # unknown option
      echo "Unknown option: '$1'"
      usage
      exit 1
      ;;
    * )     # positional argument: folder
      folders+=("$1")
      shift # past argument
      ;;
  esac
done

if [[ ${#folders[@]} -gt 0 ]]; then
  # test indicated folders under src_engine_path
  for folder in "${folders[@]}"; do
    roots+="\"$src_engine_path/$folder\" "
  done
  # for logging
  folders_str="${folders[@]}"
else
  # test the whole src_engine_path folder
  roots="\"$src_engine_path\""
  # for logging
  folders_str="all folders"
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

  # cover exactly the folders you are testing
  # note: for pico8wtk, the source is outside the engine folder, but we know we are not covering it at 100% so we ignore it anyway
  coverage_targets="$roots"

  # for logging
  module_str="all modules"
else
  # test specific module with exact full name to avoid issues with similar file names (busted uses Lua string.match where escaping is done with '%'')
  test_file_pattern="^${module}_utest%.lua$"

  # luacov filter will ignore any trailing '.lua', so we need to add end symbol '$' just after module name to avoid confusion with similar file names
  # The '$' will prevent detecting folder with the same name (e.g. ui.lua vs ui/) since all folders continue with '/some_file_name'.
  # However, if the tested module requires (directly or indirectly) another module with the exact same name in a different directory, it will also
  # be covered. So never give two modules the same name, as recommended in the Usage.
  coverage_targets="\"/${module}$\""

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
  coverage_options="-c .luacov $coverage_targets"
  post_test_cmd="luacov $coverage_options && echo $'\n\n= COVERAGE REPORT =\n' && grep -C 3 -P \"(?:(?:^|[ *])\*0|\d+%)\" luacov.report.out"
else
  # no-ops
  pre_test_cmd=":"
  post_test_cmd=":"
fi

echo "Testing $module_str in: $folders_str..."

# Run all unit tests
lua_path="src/?.lua;$ENGINE_SRC/?.lua"
core_test_cmd="busted $roots --lpath=\"$lua_path\" -p \"$test_file_pattern\" $filter $filter_out -c -v"

# Note that roots and lua_path are relative to the project root, so change the working directory to there first
# in case this script is called from somewhere else
pushd "$(dirname $0)"

full_test_cmd="$pre_test_cmd && $core_test_cmd && $post_test_cmd"
echo "> $full_test_cmd"
bash -c "$full_test_cmd"

popd
