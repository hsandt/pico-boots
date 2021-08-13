#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os


# This script creates a copy of a .p8 cartridge into a sub-folder 'p8_for_png' (located in the same
#  folder as the cartridge), and replaces usages of ".p8" with ".p8.png" so reload() statements
#  can work properly in the PNG export.
# We used to replace the assignment of cartridge_ext = ".p8" in constants.lua only,
#  but with the new constant substitution system we now end up with hardcoded ".p8" in various places,
#  sometimes integrated in the strings themselves. We are now supporting this too.

def get_p8_code_with_p8_png_ext(p8_code):
    """
    Return a p8 code with references to ".p8", whether in assignment
    or last function argument (whether concatenated or integrated in string argument)
    are replaced with ".p8.png" (using single quotes if originally single quotes)

    """
    # Single quote
    # Ex 1: cartridge_ext='.p8' => cartridge_ext='.p8.png'
    # Ex 2: filepath=filebase..'.p8' => filepath=filebase..'.p8.png'
    # Ex 3: reload(0, 0, 'data.p8') => reload(0, 0, 'data.p8.png')
    # Ex 4: reload(0, 0, data_name..'.p8') => reload(0, 0, data_name..'.p8.png')
    p8_text_adapted = p8_code.replace('.p8"', '.p8.png"')

    # Double quote
    # Ex 1: cartridge_ext=".p8" => cartridge_ext=".p8.png"
    # Ex 2: filepath=filebase..".p8" => filepath=filebase..".p8.png"
    # Ex 3: reload(0, 0, "data.p8") => reload(0, 0, "data.p8.png")
    # Ex 4: reload(0, 0, data_name..".p8") => reload(0, 0, data_name..".p8.png")
    p8_text_adapted = p8_text_adapted.replace(".p8'", ".p8.png'")

    return p8_text_adapted


def adapt_p8_for_png(input_filepaths):
    """
    Apply modifications to p8 code contained in each input filepath to make it work as png cartridge,
    and write result in p8_for_png sub-folder in each input file's respective folder.

    """
    for input_filepath in input_filepaths:
        with open(input_filepath, 'r') as f:
            logging.debug(f"Opening p8 file '{input_filepath}' to adapt for PNG...")

            p8_text = f.read()
            p8_text_adapted = get_p8_code_with_p8_png_ext(p8_text)

        # write adapted file in sub-folder 'p8_for_png'
        parent_dirpath = os.path.dirname(input_filepath)
        input_file_basename = os.path.basename(input_filepath)
        output_dir = os.path.join(parent_dirpath, 'p8_for_png')

        if not os.path.exists(output_dir):
            os.mkdir(output_dir)
        output_filepath = os.path.join(output_dir, input_file_basename)

        with open(output_filepath, 'w') as f:
            logging.debug(f"Writing p8 adapted for PNG to file '{output_filepath}'...")

            # replace file content (truncate as the file may already exist with longer content)
            f.truncate()
            f.write(p8_text_adapted)


def main():
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description='Adapt .p8 for PNG export.')
    parser.add_argument('input_filepaths', type=str, nargs='+', help='path to .p8 file')
    args = parser.parse_args()

    logging.info(f"Adapting {args.input_filepaths} for PNG into sub-folder adapt_for_png...")
    adapt_p8_for_png(args.input_filepaths)
    logging.info(f"Adapted {args.input_filepaths} for PNG into sub-folder adapt_for_png")


if __name__ == '__main__':
    main()
