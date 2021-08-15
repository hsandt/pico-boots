#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re


# This script patches web assembly in an exported HTML cartridge for PICO-8 v0.2.1-0.2.2,
# doing operations equivalent to the patches used in patch_pico8_runtime.sh
# - 4x token: extend cartridge token limit to 32768
# - fast reload: skip loading animation (rotating floppy disk) during reload()
# - fast load (Windows only, TODO): skip loading animation (rotating floppy disk) during load() (once)


wasm_funcs_pattern = re.compile(r"// EMSCRIPTEN_START_FUNCS\n(?:.*\n)*// EMSCRIPTEN_END_FUNCS")

# The reload pattern sets some counter to 0x1e = 30, and has actually two occurrences in WASM
# The second one must match either some BBS download-reload or the load-reload code,
# but certainly replacing both can only help make loading faster
# (note that the case of calling reload without passing a filename is not consistently patched
# to be faster by our change, at least in the editor binary, so there may be even more calls
# to change to improve the patch)
# Regex pattern was updated to support both pico8 0.2.1 and 0.2.2, and hopefully further versions
# too, assuming the variable names don't change but the numbers do.
# If 0.2.3+ change variable names, please adapt the regex pattern.
# We will entirely remove the matched statement.
# Ex of first occurrence (pico8 0.2.2c):
#    {Lm(2968664,b)|0;g=30-(c[742431]|0)|0;h=(g|0)<30?g:30;c[742430]=(h|0)>2?h:2;c[742431]=150}
# => {Lm(2968664,b)|0}
# Ex of second occurrence (pico8 0.2.2c):
# {...;a[2968664]=0;g=30-(c[742431]|0)|0;h=(g|0)<30?g:30;c[742430]=(h|0)>2?h:2;c[742431]=150;return}
# {...;a[2968664]=0;return}
reload_set_counter_pattern = re.compile(r";g=30-\(c\[([0-9]+)\]\|0\).*c\[\1\]=[0-9]+")


def get_wasm_funcs_string_patched_with_4x_token(wasm_funcs_string):
    """
    Return a WASM string patched for 4x token

    """
    # Ex from pico8 0.2.2c:
    #     o=gh(n)|0;if((o|0)>8192){ug(49924,6);c[i>>2]=o;
    # =>  o=gh(n)|0;if((o|0)>32768){ug(49924,6);c[i>>2]=o;
    # So far, the pattern worked on all recent versions of PICO-8
    replaced_string = wasm_funcs_string.replace('if((o|0)>8192)', 'if((o|0)>32768)')
    if replaced_string == wasm_funcs_string:
        raise Exception(f"4x_token patch replacement found no matching string in WASM, patch could not be applied!")
    return replaced_string


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
    replaced_string = reload_set_counter_pattern.sub('', wasm_funcs_string, count=2)
    if replaced_string == wasm_funcs_string:
        raise Exception(f"4x_token patch replacement found no matching string in WASM, patch could not be applied!")
    return replaced_string


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

    parser = argparse.ArgumentParser(description='Patch PICO-8 v0.2.1-0.2.2 JS file.')
    parser.add_argument('input_filepath', type=str, help='path to JS file with WASM to patch')
    parser.add_argument('output_filepath', type=str, help='output path to patched JS file to create (pass same value as input_filepath to patch in-place)')
    args = parser.parse_args()

    logging.info(f"Patching {args.input_filepath} into {args.output_filepath}...")
    patch_js_file(args.input_filepath, args.output_filepath)
    logging.info(f"Patched {args.input_filepath} into {args.output_filepath}")


if __name__ == '__main__':
    main()
