#!/bin/bash

# Configuration
# PICO-8 version could be an argument, but it doesn't change often so setting manually is fine for now
pico8_version="0.2.1b"
patches_path="$(dirname "$0")/patches"

help() {
  echo "Patch pico8 runtime binaries for Linux, OSX and Windows

User must provide path to [game].bin directory exported from PICO-8, and [game] itself.

This script applies the following patches:
- 4x token: increase cartridge token limit to 32768
- fast reload: skip loading animation (rotating floppy disk) during reload()

In-place mode replaces the runtime binaries directly, while default mode creates
a patched copy of the binaries with the suffix '_patched'.

Dependencies:
- xdelta3 (must be in PATH)
"
usage
}

usage() {
  echo "Usage: patch_pico8_runtime.sh BIN_EXPORT_DIR_PATH GAME_NAME

ARGUMENTS
  BIN_EXPORT_DIR_PATH       Path [game].bin folder created by PICO-8 export .bin
                            It should contain a linux, [game].app and windows folder

  GAME_NAME                 Name of the exported game
                            It is the part before '.bin' in BIN_EXPORT_DIR_PATH,
                            and also the base name of the runtime binaries.

  -i, --inplace             Patch the runtime binaries in-place
                            Caution: this will replace the existing file (but should
                            be harmless on a binary generated by PICO-8 export .bin)

  -h, --help                Show this help message
"
}


# Default parameters
inplace=false

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
roots=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help )
      help
      exit 0
      ;;
    -i | --inplace )
      inplace=true
      shift
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

if ! [[ ${#positional_args[@]} -ge 2 && ${#positional_args[@]} -le 2 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 2."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

bin_export_dir_path="${positional_args[0]}"
game_name="${positional_args[1]}"

# https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
if hash xdelta3 2>/dev/null; then

  # Arg $1: os name ('linux', 'osx', 'windows')
  # Arg $2: path of runtime binary to patch
  function patch_pico8_runtime_for_os_at {
    os_name="$1"
    pico8_runtime_binary_path="$2"

    # prepare the output file we'll be patching in-place,
    # even when using --inplace, we prefer operating outside the original file and moving the patched binary back to the original
    #  only at the end, in case operations go wrong and are interrupted in the middle
    cp "$pico8_runtime_binary_path" "${pico8_runtime_binary_path}_patched"

  	# xdelta3 exists, apply each patch one by one
    patch_names="4x_token fast_reload fast_load"

    # apply each patch one by one
    for patch_name in $patch_names; do
      patch_file="${patches_path}/pico8_${pico8_version}_${os_name}_runtime_${patch_name}_xdelta3.vcdiff"
      echo $patch_file

      # Only apply patch if found, don't fail if not found (for now, only Windows has fast_load patch)
      if [[ -f "${patch_file}" ]]; then
        # xdelta3 can patch in-place when using the overwrite -f option
        # all patches should be "clean" i.e. without checksum, so we shouldn't need to -n option
        # if you happen to have a patch with input file checksum (not very useful when chaining patches), just add -n or better,
        #  add -n when decoding patch but re-encode it with -n too to create a clean patch without checksum
        patch_cmd="xdelta3 -f -d -s \"${pico8_runtime_binary_path}_patched\" \"$patch_file\" \"${pico8_runtime_binary_path}_patched\""

        echo "> $patch_cmd"
        bash -c "$patch_cmd"

        if [[ $? -ne 0 ]]; then
          echo ""
          echo "Patching with \"$patch_file\" failed, STOP."
          exit 1
        fi
      fi
    done

    # chmod the patched executable to make it playable
    chmod a+x "${pico8_runtime_binary_path}_patched"

    # $inplace variable is accessible in this scope
    if [[ "$inplace" == true ]] ; then
      # replace original binary with patched version (just so user sees clean name)
      mv "${pico8_runtime_binary_path}_patched" "${pico8_runtime_binary_path}"
      echo "Replaced original binary with patched binary, as using --inplace"
    fi
  }

  # Linux
  patch_pico8_runtime_for_os_at linux "$bin_export_dir_path/linux/${game_name}"

  # OSX
  patch_pico8_runtime_for_os_at osx "$bin_export_dir_path/${game_name}.app/Contents/MacOS/${game_name}"

  # Windows
  # TODO: fast_reload patch
  patch_pico8_runtime_for_os_at windows "$bin_export_dir_path/windows/${game_name}.exe"

else
  # we only support xdelta3 (but could also support bsdiff if easier to install on some platforms)
  echo "ERROR: xdelta3 not found, cannot patch runtime binary"
  exit 1
fi
