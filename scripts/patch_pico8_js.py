#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re


# This script patches web assembly in an exported HTML cartridge for PICO-8 v0.2.1b,
# doing operations equivalent to the patches used in patch_pico8_runtime.sh
# - 4x token: extend cartridge token limit to 32768
# - fast reload: skip loading animation (rotating floppy disk) during reload()
# - fast load (Windows only): skip loading animation (rotating floppy disk) during load() (once)


wasm_funcs_pattern = re.compile(r"// EMSCRIPTEN_START_FUNCS\n(?:.*\n)*// EMSCRIPTEN_END_FUNCS")

# The reload pattern sets some counter to 0x1e, and has actually two occurrences in WASM
# The second one must match either some BBS download-reload or the load-reload code,
# but certainly replacing both can only help make loading faster
reload_set_counter_pattern = re.compile(r";g=30-\(c\[732417\]\|0\).*c\[732417\]=28")


def get_wasm_funcs_string_patched_with_4x_token(wasm_funcs_string):
    """
    Return a WASM string patched for 4x token

    """
    return wasm_funcs_string.replace('if((o|0)>8192)', 'if((o|0)>32768)')


def get_wasm_funcs_string_patched_with_fast_load(wasm_funcs_string):
    """
    Return a WASM string patched for fast load

    """
    # TODO based on existing patch
    return wasm_funcs_string


def get_wasm_funcs_string_patched_with_fast_reload(wasm_funcs_string):
    """
    Return a WASM string patched for fast reload

    """
    # remove counter set code completely (1st one is important for reload,
    # 2nd one may help for other loading procedures)
    return reload_set_counter_pattern.sub('', wasm_funcs_string, count=2)


def parse_wasm_funcs_string(js_text):
    """
    Return (wasm_funcs_string, (start, end))
    wasm_funcs_string: content between // EMSCRIPTEN_START_FUNCS and // EMSCRIPTEN_END_FUNCS (included)
    (start, end): span of the whole content (start and end position in js_text)

    """
    wasm_funcs_match = wasm_funcs_pattern.search(js_text)
    if not wasm_funcs_match:
        raise Exception("Could not find WASM FUNCS pattern in JS text")

    return wasm_funcs_match[0], wasm_funcs_match.span()


def patch_js_file(input_filepath, output_filepath):
    """
    Apply patches to JS file containing WASM
    If patching in-place, just pass output_filepath equal to input_filepath

    """
    with open(input_filepath, 'r') as f:
        logging.debug(f"Opening JS file '{input_filepath}' for patching...")

        # get WASM string and span (start, end) to replace just that part later
        js_text = f.read()
        wasm_funcs_string, (start, end) = parse_wasm_funcs_string(js_text)

        wasm_funcs_string_patched = get_wasm_funcs_string_patched_with_4x_token(wasm_funcs_string)
        wasm_funcs_string_patched = get_wasm_funcs_string_patched_with_fast_load(wasm_funcs_string_patched)
        wasm_funcs_string_patched = get_wasm_funcs_string_patched_with_fast_reload(wasm_funcs_string_patched)

        js_text_patched = js_text[:start] + wasm_funcs_string_patched + js_text[end:]

    with open(output_filepath, 'w') as f:
        logging.debug(f"Writing patched JS to file '{output_filepath}'...")

        # replace file content (truncate as the file may already exist with longer content)
        f.truncate()
        f.write(js_text_patched)


def main():
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description='Patch PICO-8 v0.2.1b JS file.')
    parser.add_argument('input_filepath', type=str, help='path to JS file with WASM to patch')
    parser.add_argument('output_filepath', type=str, help='output path to patched JS file to create (pass same value as input_filepath to patch in-place)')
    args = parser.parse_args()

    logging.info(f"Patching {args.input_filepath} into {args.output_filepath}...")
    patch_js_file(args.input_filepath, args.output_filepath)
    logging.info(f"Patched {args.input_filepath} into {args.output_filepath}")


if __name__ == '__main__':
    main()
