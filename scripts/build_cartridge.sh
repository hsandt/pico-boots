#!/bin/bash

# Configuration
picoboots_src_path="$(dirname "$0")/../src"
picoboots_scripts_path="$(dirname "$0")"

help() {
  echo "Build .p8 file from a main source file.

It may be used to build an actual game or an integration test runner.

The game file may require any scripts by its relative path from the game source root directory,
and any engine scripts by its relative path from pico-boots source directory.

If --minify-level MINIFY_LEVEL is passed with MINIFY_LEVEL >= 1,
the lua code of the output cartridge is minified using the local luamin installed via npm.

If --unify is passed with suffix (e.g. '_ingame'), a \"unity build\" is done:
- a file 'ordered_require[suffix].lua' is generated, containing all require for the game
  in dependency order, dependent modules at the bottom
- all sources are already concatenated in a giant file by picotool, so we just strip all
  require statements and package definitions added by picotool.
  Module tables are defined directly in outer scope and can be used in any code below their
  declarations. When requiring a package and storing it in a local variable, make sure to
  name that local variable exactly as in the package definition itself. All package definitions
  must be done with a 'local my_module = ...' at the beginning and 'return my_module' at the end.
- the #unity symbol is passed to preprocessing, so the developer can add a
  require('ordered_require[suffix]') surrounded by #if unity either at main top or in some 'common'
  file required at main top.

System dependencies:
- picotool (p8tool must be in PATH)

Local dependencies:
- luamin#feature/newline-separator (installed via npm install/update inside npm folder)
"
usage
}

usage() {
  echo "Usage: build_game.sh GAME_SRC_PATH RELATIVE_MAIN_FILEPATH [REQUIRED_RELATIVE_DIRPATH]

ARGUMENTS
  GAME_SRC_PATH                 Path to the game source root.
                                Path is relative to the current working directory.
                                All 'require's should be relative to that directory.
                                Ex: 'src'

  RELATIVE_MAIN_FILEPATH        Path to main lua file.
                                Path is relative to GAME_SRC_PATH,
                                and contains the extension '.lua'.
                                Ex: 'main.lua'

  REQUIRED_RELATIVE_DIRPATH     Optional path to directory containing files to require.
                                Path is relative to the game source directory.
                                If it is set, pre-build will add require statements for any module
                                found recursively under this directory, in the main source file.
                                This is used with itest_main.lua to inject itests via auto-registration
                                on require.
                                Do not put files containing non-PICO-8 compatible code in this folder!
                                (in particular advanced Lua and busted-specific functions meant for
                                headless unit tests)
                                Ex: 'itests'

OPTIONS
  -p, --output-path OUTPUT_PATH Path to build output directory.
                                Path is relative to the current working directory.
                                (default: '.')

  -o, --output-basename OUTPUT_BASENAME
                                Basename of the p8 file to build.
                                (default: 'game')

  -c, --config CONFIG           Build config. Since preprocessor symbols are passed separately,
                                this is only used to determine the intermediate and output paths.
                                If no config is passed, we assume the project has a single config
                                and we don't use intermediate sub-folder not output file suffix.
                                (default: '')

  -A, --no-append-config        Append config name to the OUTPUT_BASENAME
                                If CONFIG is set and --no-append-config is not passed, '_{CONFIG}' is appended
                                to OUTPUT_BASENAME before '.p8'.
                                This is useful when working with multiple cartridges in the same folder
                                so PICO-8 load() can be used with a path that doesn't depend on config.
                                (default: append config to output basename)

  -s, --symbols SYMBOLS_STRING  String containing symbols to define for the preprocess step
                                (parsing #if [symbol]), separated by ','.
                                Ex: -s symbol1,symbol2 ...
                                (default: no symbols defined)

  --game-constant-module-paths-prebuild GAME_CONSTANT_MODULE_PATHS_STRING_PREBUILD
                                String containing paths to game data modules defining constants as table members
                                to replace at prebuild time.
                                Paths are separated by ' ' and contain '.lua' extension
                                Paths are relative to the current working directory.
                                Format: --game-constant-module-paths 'path_to_file1.lua path_to_file2.lua'
                                (default: '')

  --game-constant-module-paths-postbuild GAME_CONSTANT_MODULE_PATHS_STRING_POSTBUILD
                                String containing paths to game data modules defining constants as table members
                                to replace at prebuild time.
                                Paths are separated by ' ' and contain '.lua' extension
                                Paths are relative to the current working directory.
                                Format: --game-constant-module-paths 'path_to_file1.lua path_to_file2.lua'
                                (default: '')

  -r, --replace-strings-game-substitute-dir-prebuild GAME_SUBSTITUTE_DIR_PREBUILD
                                Path to directory containing game_substitute_table.py to be imported at prebuild time.
                                Path is relative to the current working directory.
                                (default: '')

  -v, --variable-substitutes-prebuild VARIABLE_SUBSTITUTES_PREBUILD
                                List of variable definitions to substitute in .lua files  at prebuild time
                                when variable names are recognized, prefixed with '$'.
                                Definitions must be separated by ' '.
                                Format: --variable-substitutes 'var1=value1 var2=value2'
                                => String '\$var1' will be replaced with 'value1', etc.
                                (default: '')

  -d, --data DATA_FILEPATH      Path to data p8 file containing gfx, gff, map, sfx and music sections.
                                Path is relative to the current working directory,
                                and contains the extension '.p8'.
                                (default: '')

  -M, --metadata METADATA_FILEPATH
                                Path the file containing cartridge metadata. Title and author are added
                                manually with the options below, so in practice, it should only contain
                                the label picture for export.
                                Path is relative to the current working directory,
                                and contains the extension '.p8'.
                                (default: '')

  -t, --title TITLE             Game title to insert in the cartridge metadata header
                                (default: '')

  -a, --author AUTHOR           Author name to insert in the cartridge metadata header
                                (default: '')

  -m, --minify-level MINIFY_LEVEL
                                Minify the output cartridge __lua__ section, using newlines as separator
                                for minimum readability.
                                MINIFY_LEVEL values:
                                  0: no minification
                                  1: minify local variables
                                  2: minify member names and table key strings
                                  3: minify member names, table key strings, assigned global variables and declared global functions
                                  CAUTION: When using level 2 or higher, make sure to use the [\"key\"] syntax
                                             for any key you need to preserve during minification (see README.md).
                                           When using level 3, make sure to assign global variables / declare global function before
                                             any usage. picotool concatenates modules in an order that may push your global
                                             definitions to the end. To reduce risks, try to add your global definitions
                                             such as enum and helper functions in some custom common.lua file required
                                             in your main file after engine/pico8/api and engine/common.
                                             In addition, make local *all* variables that can be local, or you may end up
                                             with a homonymous non-local variable (e.g. member) in another place that will
                                             refuse to get minified until the first assignment of that variable is found,
                                             which doesn't make sense
                                (default: 0)

  -u, --unify ORDERED_REQUIRE_FILE_SUFFIX
                                Unity build: no require, all modules defined in order in outer scope, define #unity symbol
                                ORDERED_REQUIRE_FILE_SUFFIX will be appended to 'ordered_require' file basename.
                                Pass '' if you don't need a suffix.

  -h, --help                    Show this help message
"
}

# Default parameters
output_path='.'
output_basename='game'
config=''
no_append_config=false
symbols_string=''
game_constant_module_paths_string_prebuild=''
game_constant_module_paths_string_postbuild=''
game_substitute_dir_prebuild=''
variable_substitutes_prebuild=''
data_filepath=''
metadata_filepath=''
title=''
author=''
minify_level=0
unify=false
ordered_require_file_suffix=''

# Read arguments
positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -p | --output-path )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      output_path="$2"
      shift # past argument
      shift # past value
      ;;
    -o | --output-basename )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      output_basename="$2"
      shift # past argument
      shift # past value
      ;;
    -c | --config )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      config="$2"
      shift # past argument
      shift # past value
      ;;
    -A | --no-append-config )
      no_append_config=true
      shift
      ;;
    -s | --symbols )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      symbols_string="$2"
      shift # past argument
      shift # past value
      ;;
    --game-constant-module-paths-prebuild )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      game_constant_module_paths_string_prebuild="$2"
      shift # past argument
      shift # past value
      ;;
    --game-constant-module-paths-postbuild )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      game_constant_module_paths_string_postbuild="$2"
      shift # past argument
      shift # past value
      ;;
    -r | --replace-strings-game-substitute-dir-prebuild )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      game_substitute_dir_prebuild="$2"
      shift # past argument
      shift # past value
      ;;
    -v | --variable-substitutes-prebuild )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      variable_substitutes_prebuild="$2"
      shift # past argument
      shift # past value
      ;;
    -d | --data )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      data_filepath="$2"
      shift # past argument
      shift # past value
      ;;
    -M | --metadata )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      metadata_filepath="$2"
      shift # past argument
      shift # past value
      ;;
    -t | --title )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      title="$2"
      shift # past argument
      shift # past value
      ;;
    -a | --author )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      author="$2"
      shift # past argument
      shift # past value
      ;;
    -m | --minify-level )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      minify_level="$2"
      shift # past argument
      shift # past value
      ;;
    -u | --unify )
      unify=true
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      ordered_require_file_suffix="$2"
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
    * )     # store positional argument for later
      positional_args+=("$1")
      shift # past argument
      ;;
  esac
done

if ! [[ ${#positional_args[@]} -ge 2 && ${#positional_args[@]} -le 3 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 2 or 3."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

game_src_path="${positional_args[0]}"
relative_main_filepath="${positional_args[1]}"
required_relative_dirpath="${positional_args[2]}"  # optional

output_filename="$output_basename"

# if config is passed, append to output basename
if [[ -n "$config" && "$no_append_config" == false ]] ; then
  output_filename+="_$config"
fi
output_filename+=".p8"

output_filepath="$output_path/$output_filename"


# Split symbols string into a array by splitting on ','
# https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
IFS=',' read -ra symbols <<< "$symbols_string"

# Define special symbol #minify_levelX where X is the minification level,
# so we can safely add minification tricks in code without affecting builds not using that level.
if [[ "$minify_level" -gt 0  ]]; then
  symbols+=("minify_level$minify_level")
fi

# Define special symbol #unity when doing unity build (use this to early define
# types needed for outer scope, e.g. by adding local requires to the common files)
if [[ "$unify" == true ]]; then
  symbols+=("unity")
fi

echo "Building '$game_src_path/$relative_main_filepath' -> '$output_filepath'"

# clean up any existing output file
rm -f "$output_filepath"

echo ""
echo "Pre-build..."

# Copy metadata.p8 to future output file path. When generating the .p8, p8tool will preserve the __label__ present
# at the output file path, so this is effectively a way to setup the label.
# However, title and author are lost during the process and must be manually added to the header with add_metadata.py

# Create directory for output file if it doesn't exist yet
mkdir -p $(dirname "$output_filepath")

if [[ -n "$metadata_filepath" ]] ; then
  if [[ -f "$metadata_filepath" ]]; then
    cp_label_cmd="cp \"$metadata_filepath\" \"$output_filepath\""
    echo "> $cp_label_cmd"
    bash -c "$cp_label_cmd"

    if [[ $? -ne 0 ]]; then
      echo ""
      echo "Copy label step failed, STOP."
      exit 1
    fi
  else
    echo ""
    echo "Could not find metadata file at '$metadata_filepath', STOP."
    exit 1
  fi
fi

# if config is passed, use intermediate sub-folder
intermediate_path='intermediate'
if [[ -n "$config" ]] ; then
  intermediate_path+="/$config"
fi

# create intermediate and intermediate/pico-boots directory to prepare source copy
# (rsync can create the engine and game 'src' sub-folders itself)
mkdir -p "$intermediate_path/pico-boots"

# Copy framework and game source to intermediate directory
# to apply pre-build steps without modifying the original files
rsync -rl --del "$picoboots_src_path/" "$intermediate_path/pico-boots/src"
rsync -rl --del "$game_src_path/" "$intermediate_path/src"
if [[ $? -ne 0 ]]; then
  echo ""
  echo "Copy source to intermediate step failed, STOP."
  exit 1
fi

# Apply preprocessing directives for given symbols (separated by space, so don't surround array var with quotes)
preprocess_cmd="\"$picoboots_scripts_path/preprocess.py\" \"$intermediate_path\" --symbols ${symbols[@]}"
echo "> $preprocess_cmd"
bash -c "$preprocess_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Preprocess step failed, STOP."
  exit 1
fi

# Prebuild replace strings: we may have src_min folders in intermediate path for analyzing only (for normal builds,
# we only minify in post-build, not on individual files), and we should not try to substitute them
# (it's too late on minified files anyway), so make sure to only replace strings in (non-minified backup) engine and game source folders

# Here, we replace as much symbols as we can, basically everything except what would be replaced with unicode characters and glyphs,
# because p8tool build/listrawlua doesn't support them all and would either fail (e.g. KeyError on '\x7f') or replace them with underscores
# (e.g. PICO-8 circle input would become '_'). Instead, we will replace such characters during post-build.

# Replace strings in engine scripts, with engine symbols only (predefined in replace_strings.py)
# ! Note that preprocess doesn't strip comments anymore since we decided to rely entirely on minification for this
# ! But minification is done in post-build, so replace strings will work on comments too, which is a waste!
# ! Consider having preprocess at least strip the most obvious comments (block comments and harder to parse)
# ! or applying a simple minification step that preserves all variables names (at least global ones) just to remove comments
# ! before replacing strings.
replace_strings_in_engine_cmd="\"$picoboots_scripts_path/replace_strings.py\" \"$intermediate_path/pico-boots/src\""
echo "> $replace_strings_in_engine_cmd"
bash -c "$replace_strings_in_engine_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Replace strings in engine step failed, STOP."
  exit 1
fi

# Replace strings in game scripts, with engine symbols AND game symbols (defined in $game_substitute_dir_prebuild/game_substitute_table.py)
# using prebuild options
replace_strings_in_game_prebuild_cmd="\"$picoboots_scripts_path/replace_strings.py\" \"$intermediate_path/src\""
if [[ -n "$game_substitute_dir_prebuild" ]] ; then
  replace_strings_in_game_prebuild_cmd+=" --game-substitute-table-dir \"$game_substitute_dir_prebuild\""
fi
if [[ -n "$game_constant_module_paths_string_prebuild" ]] ; then
  replace_strings_in_game_prebuild_cmd+=" --game-constant-module-path $game_constant_module_paths_string_prebuild"
fi
if [[ -n "$variable_substitutes_prebuild" ]] ; then
  replace_strings_in_game_prebuild_cmd+=" --variable-substitutes $variable_substitutes_prebuild"
fi

echo "> $replace_strings_in_game_prebuild_cmd"
bash -c "$replace_strings_in_game_prebuild_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Replace strings in game during prebuild step failed, STOP."
  exit 1
fi

# If building an itest main, add itest require statements
if [[ -n "$required_relative_dirpath" ]] ; then
  add_require_itest_cmd="\"$picoboots_scripts_path/add_require.py\" \"$intermediate_path/src/$relative_main_filepath\" "$intermediate_path/src" \"$required_relative_dirpath\""
  echo "> $add_require_itest_cmd"
  bash -c "$add_require_itest_cmd"

  if [[ $? -ne 0 ]]; then
    echo ""
    echo "Add require step failed, STOP."
    exit 1
  fi
fi

# For unity build, generate the ordered require file (which just requires all files needed by main,
# modules depended on always above modules depending on them) in the intermediate folder (it should not be
# versioned, and generated on the fly). The main Lua file should require it if #unity, so this step is mandatory
# for unity builds. Do it after pre-processing (on intermediate folders) so any require statement that should be stripped
# for this build configuration has already been removed, and we only require the modules we really need.
if [[ "$unify" == true ]]; then
  generate_ordered_require_cmd="python3 -m pico-boots.scripts.generate_ordered_require_file \"$intermediate_path/src/ordered_require${ordered_require_file_suffix}.lua\" \"$relative_main_filepath\" "$intermediate_path/src" \"$intermediate_path/pico-boots/src\""
  echo "> $generate_ordered_require_cmd"
  bash -c "$generate_ordered_require_cmd"

  if [[ $? -ne 0 ]]; then
    echo ""
    echo "Generate ordered require step failed, STOP."
    exit 1
  fi
fi

echo ""
echo "Build..."

# picotool uses require paths relative to the requiring scripts, so for project source we need to indicate the full path
# support both requiring game modules and pico-boots modules
lua_path="$(pwd)/$intermediate_path/src/?.lua;$(pwd)/$intermediate_path/pico-boots/src/?.lua"

# if passing data, add each data section to the cartridge
if [[ -n "$data_filepath" ]] ; then
  data_options="--gfx \"$data_filepath\" --gff \"$data_filepath\" --map \"$data_filepath\" --sfx \"$data_filepath\" --music \"$data_filepath\""
fi

# Build the game from the main script
build_cmd="p8tool build --lua \"$intermediate_path/src/$relative_main_filepath\" --lua-path=\"$lua_path\" $data_options \"$output_filepath\""
echo "> $build_cmd"

if [[ "$config" == "release" ]]; then
  # We are building for release, so capture warnings mentioning
  # token count over limit.
  # (faster than running `p8tool stats` on the output file later)
  # Indeed, users should be able to play our cartridge with vanilla PICO-8.
  error=$(bash -c "$build_cmd 2>&1")
  # Store exit code for fail check later
  build_exit_code="$?"
  # Now still print the error for user, this includes real errors that will fail and exit below
  # and warnings on token/character count
  >&2 echo "$error"

  # Emphasize error on token count now, with extra comments
  # regex must be stored in string, then expanded
  # it doesn't support \d
  token_regex="token count ([0-9]+)"
  if [[ "$error" =~ $token_regex ]]; then
    # Token count above 8192 was detected by p8tool
    # However, p8tool count is wrong as it ignores the latest counting rules
    # which are more flexible. So just in case, we still not fail the build and
    # only print a warning.
    token_count=${BASH_REMATCH[1]}
    echo "token count of $token_count detected, but p8tool counts more tokens than PICO-8, so this is only an issue beyond ~8700 tokens."
  fi
else
  # Debug build is often over limit anyway, so don't check warnings
  # (they will still be output normally)
  bash -c "$build_cmd"
  # Store exit code for fail check below (just to be uniform with 'release' case)
  build_exit_code="$?"
fi

if [[ "$build_exit_code" -ne 0 ]]; then
  echo ""
  echo "Build step failed, STOP."
  exit 1
fi

echo ""
echo "Post-build..."

# We now unify before minify to avoid spending minified names on package/module-related variables
# that will eventually get stripped
if [[ "$unify" == true ]]; then
  unify_cmd="$picoboots_scripts_path/unify.py \"$output_filepath\""
  echo "> $unify_cmd"
  bash -c "$unify_cmd"

  if [[ $? -ne 0 ]]; then
    echo "Unification failed, STOP."
    exit 1
  fi
fi

if [[ "$minify_level" -gt 0  ]]; then
  minify_cmd="$picoboots_scripts_path/minify.py \"$output_filepath\" --minify-level $minify_level"
  echo "> $minify_cmd"
  bash -c "$minify_cmd"

  if [[ $? -ne 0 ]]; then
    echo "Minification failed, STOP."
    exit 1
  fi
fi

if [[ -n "$game_constant_module_paths_string_postbuild" ]] ; then
  # Postbuild replace strings: this is only meant for last-minute replacement for unicode characters and glyphs,
  # because p8tool listrawlua (used during minify above) doesn't support them all (see Prebuild replace strings note) so we should replace them after
  # p8tool step.
  # However, make sure to protect all symbols replaced this way with an underscore or ["key"] definition/access to avoid losing them during minify
  # before they could be replaced.
  # Alternatively, replace listrawlua with a custom parser that extract all lines in the __lua__ section (would also fix other problems related to what p8tool
  # recognizes as valid code).
  # (this can be done before or after add metadata step)

  # Replace strings in built script that need substitution at postbuild time only
  # - custom game constant module paths (e.g. audio PCM unicode string stored as table member)
  # - glyphs (following glyph code convention)

  # Note that this will try to replace engine strings again, although they have been replaced earlier, but this is okay, it should do nothing
  # (as long as you didn't try to replace some strings with engine strings, which is not recommended to avoid two-step uncertainty!)
  replace_strings_in_game_postbuild_cmd="\"$picoboots_scripts_path/replace_strings.py\" \"$output_filepath\" \
    --game-constant-module-path $game_constant_module_paths_string_postbuild --replace-glyphs"

  echo "> $replace_strings_in_game_postbuild_cmd"
  bash -c "$replace_strings_in_game_postbuild_cmd"

  if [[ $? -ne 0 ]]; then
    echo ""
    echo "Replace strings in game during postbuild step failed, STOP."
    exit 1
  fi
fi

if [[ -n "$title" || -n "$author" ]] ; then
  # Add metadata to cartridge
  # Since label has been setup during Prebuild, we don't need to add it with add_metadata.py anymore
  # Thefore, for the `label_filepath` argument just pass the none value "-"
  add_header_cmd="$picoboots_scripts_path/add_metadata.py \"$output_filepath\" \"-\" \"$title\" \"$author\""
  echo "> $add_header_cmd"
  bash -c "$add_header_cmd"

  if [[ $? -ne 0 ]]; then
    echo ""
    echo "Add metadata failed, STOP."
    exit 1
  fi
fi

echo ""
echo "Build succeeded: '$output_filepath'"
