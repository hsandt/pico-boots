#!/bin/bash

# Configuration
picoboots_src_path="$(dirname $0)/../src"
picoboots_scripts_path="$(dirname $0)"

help() {
  echo "Build game.p8 file from a main source file with picotool

Dependencies: picotool (p8tool must be in PATH)
"
usage
}

usage() {
  echo "Usage: build.sh MAIN_FILEPATH

  ARGUMENTS
    MAIN_FILEPATH                 Path to main lua file.
                                  Path is relative to the current working directory,
                                  and contains the extension '.lua'.
                                  It should be located at the root of the game source directory,
                                  and all 'require's should be relative to that directory.
                                  Ex: 'src/main.lua'

  OPTIONS
    -o, --output OUTPUT_FILEPATH  Path to output p8 file to build.
                                  Path is relative to the current working directory,
                                  and contains the extension '.p8'.
                                  (default: 'game.p8')

    -d, --data DATA_FILEPATH      Path to data p8 file containing gfx, gff, map, sfx and music sections.
                                  Path is relative to the current working directory,
                                  and contains the extension '.p8'.
                                  (default: '')

    -m, --metadata METADATA_FILEPATH
                                  Path the output p8 file to build.
                                  Path is relative to the current working directory,
                                  and contains the extension '.p8'.
                                  (default: '')

    -t, --title TITLE             Game title to insert in the cartridge metadata header
                                  (default: '')

    -a, --author AUTHOR           Author name to insert in the cartridge metadata header
                                  (default: '')

    -h, --help                    Show this help message
"
}

# Default parameters
output_filepath="game.p8"

# Read arguments
positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -o | --output )
      if [[ $# -lt 2 ]] ; then
        echo "Missing argument for $1"
        usage
        exit 1
      fi
      output_filepath="$2"
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
    -m | --metadata )
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

if [[ ${#positional_args[@]} != 1 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 1"
  usage
  exit 1
fi

main_filepath="${positional_args[0]}"

echo "Building '$main_filepath' -> '$output_filepath'"

# clean up any existing output file
rm -f "$output_filepath"

echo ""
echo "Pre-build..."

# Copy metadata.p8 to future output file path. When generating the .p8, p8tool will preserve the __label__ present
# at the output file path, so this is effectively a way to setup the label.
# However, title and author are lost during the process and must be manually added to the header with add_metadata.py

# Create directory for output file if it doesn't exist yet
mkdir -p $(dirname "$output_filepath")

if [[ ! -z $data_filepath ]] ; then
  if [[ -f "$metadata_filepath" ]]; then
  	cp_label_cmd="cp \"$metadata_filepath\" \"$output_filepath\""
  	echo "> $cp_label_cmd"
  	bash -c "$cp_label_cmd"
  fi
fi

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Pre-build step failed, STOP."
  exit 1
fi

echo ""
echo "Build..."

# picotool uses require paths relative to the requiring scripts, so for project source we need to indicate the full path
# support both requiring game modules and pico-boots modules
game_src_path="$(dirname $main_filepath)"
lua_path="$(pwd)/$game_src_path/?.lua;$(pwd)/$picoboots_src_path/?.lua"

# if passing data, add each data section to the cartridge
if [[ ! -z $data_filepath ]] ; then
  data_options="--gfx \"$data_filepath\" --gff \"$data_filepath\" --map \"$data_filepath\" --sfx \"$data_filepath\" --music \"$data_filepath\""
fi

# Build the game from the main script
build_cmd="p8tool build --lua \"$main_filepath\" --lua-path=\"$lua_path\" $data_options \"$output_filepath\""
echo "> $build_cmd"
bash -c "$build_cmd"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Build step failed, STOP."
  exit 1
fi

if [[ ! -z $title || ! -z $author ]] ; then
  echo ""
  echo "Post-build..."

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
echo "Build succeeded: $output_filepath"
