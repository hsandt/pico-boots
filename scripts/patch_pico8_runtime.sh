#!/bin/bash

# Configuration
patches_path="$(dirname "$0")/patches"

help() {
  echo "Create a patched copy of pico8 runtime binary

Apply the following patches to a copy of pico8 runtime binary for Linux 64-bit:
- 4x token: increase token limit to 32768
- fast reload: skip pause with rotating floppy disk animation during reload
and create a patched copy with suffix '_4x_token_fast_reload'

Dependencies:
- xdelta (must be in PATH)
"
usage
}

usage() {
  echo "Usage: patch_pico8_runtime.sh PICO8_RUNTIME_BINARY_PATH

ARGUMENTS
  PICO8_RUNTIME_BINARY_PATH  Path to the pico8 runtime binary for Linux 64-bit

  -h, --help                Show this help message
"
}

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
    * )     # store positional argument for later
      positional_args+=("$1")
      shift # past argument
      ;;
  esac
done

if ! [[ ${#positional_args[@]} -ge 1 && ${#positional_args[@]} -le 1 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 1."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

pico8_runtime_binary_path="${positional_args[0]}"

# https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
if hash xdelta 2>/dev/null; then
	# xdelta exists, apply each patch one by one
  # patch_files="pico8_0.2.1b_linux_runtime_4x_token_xdelta.patch pico8_0.2.1b_linux_runtime_fast_reload_xdelta.patch"
  patch_files="pico8_0.2.1b_linux_runtime_4x_token_xdelta.patch"

  # prepare a staging file we'll be working from
  ls
  cp "$pico8_runtime_binary_path" "${pico8_runtime_binary_path}_staging"

  for patch_file in $patch_files; do
    # xdelta cannot patch in-place, so always with other 2 files (as we preserve the original file in this script)
    patch_cmd="xdelta patch \"$patches_path/$patch_file\" \"${pico8_runtime_binary_path}_staging\" \"${pico8_runtime_binary_path}_patched\""
    echo "> $patch_cmd"
    bash -c "$patch_cmd"

    if [[ $? -ne 0 ]]; then
      echo ""
      echo "Patching with \"$patch_file\" failed, STOP."
      exit 1
    fi

    # then replace staging with patch so we advance to next patch (this is not needed on last iteration)
    cp_cmd="cp \"${pico8_runtime_binary_path}_patched\" \"${pico8_runtime_binary_path}_staging\""
    echo "> $cp_cmd"
    bash -c "$cp_cmd"

    if [[ $? -ne 0 ]]; then
      echo ""
      echo "Copying step failed, STOP."
      exit 1
    fi
  done

  # we can now delete _staging, which should have the same content as _patched
  rm "${pico8_runtime_binary_path}_staging"

  # chmod the patched executable to make it playable
  chmod a+x "${pico8_runtime_binary_path}_patched"
else
  # we only support xdelta (but could also support bsdiff if easier to install on some platforms)
  echo "ERROR: xdelta not found, cannot patch runtime binary"
  exit 1
fi
