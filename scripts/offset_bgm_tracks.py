#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import re

# This script applies an hexadecimal offset to all bgm tracks found in a pico8 file in the __music__
# section. It does not modify default empty track 0x40.
# Note that it won't copy any extra information after __music__, as it expects it to be the last section.
# To be safe, it generates a copy of the file with offset tracks, named {original_basename}_offset.p8
# It errors if offsetting the value will go beyond the valid range (0x00-0x3F).
# It does not move the sfx tracks accordingly.

MAX_TRACK_ID = 0x3f
UNDEFINED_TRACK_ID = 0x40

# Ex: 01 000a2b40
MUSIC_LINE_PATTERN = re.compile(r"([0-9a-f]{2}) ([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})")

def offset_bgm_tracks_in_p8(cartridge_filepath, offset):
    """
    Offset all track IDs in the __music__ section of a p8 cartridge, if still in valid range,
    and generate a file suffixed _offset with the same content, but with track offset.

    """
    basepath, ext = os.path.splitext(cartridge_filepath)

    # verify extension
    if ext != ".p8":
        raise Exception(f"Cartridge filepath '{cartridge_filepath}' does not end with '.p8'")

    offset_cartridge_filepath = f"{basepath}_offset{ext}"

    with open(cartridge_filepath, 'r') as cartridge_filepath, \
         open(offset_cartridge_filepath, 'w') as offset_cartridge_filepath:
        logging.debug(f"Offsetting bgm tracks in cartridge {cartridge_filepath} by {offset} to generate {offset_cartridge_filepath}...")
        offset_bgm_tracks_from_lines_to_file(cartridge_filepath, offset_cartridge_filepath, offset)


def offset_bgm_tracks_from_lines_to_file(source_lines_iterable, target_file, offset):
    """
    Offset all track IDs in the __music__ section of a p8 cartridge, if still in valid range,
    and write the result in target_file (same content, but with track offset).

    """
    inside_music_section = False

    for line in source_lines_iterable:
        if not inside_music_section:
            target_file.write(line)
            if line == "__music__\n":
                # enter music section
                inside_music_section = True
        else:
            # Offset music tracks
            music_line_match = MUSIC_LINE_PATTERN.match(line)
            if music_line_match:
                mode, track1, track2, track3, track4 = music_line_match.groups()
                logging.debug(f"mode: {mode}")
                logging.debug(f"track1: {track1}")
                offset_tracks = [offset_hexadecimal_string(track, offset) for track in (track1, track2, track3, track4)]
                offset_line = f"{mode} {''.join(offset_tracks)}"
                target_file.write(offset_line)
                target_file.write("\n")  # newline (required)
            else:
                # we're done, there should be nothing after the __music__ section
                # if there's anything else, we'll miss it, so be careful
                target_file.write("\n")  # newline at the end (optional)
                return


def offset_hexadecimal_string(hex_string, offset):
    int_value = int(f"0x{hex_string}", 16)

    # don't touch "undefined track id" (40)
    if int_value == UNDEFINED_TRACK_ID:
        return hex_string

    offset_int_value = int_value + offset
    offset_hex_string = hex(offset_int_value)

    if offset_int_value >= 0 and offset_int_value <= MAX_TRACK_ID:
        # cut "0x" prefix from hexadecimal string
        # then pad with 0 if needed to get two figures
        # Ex: "0x6" => "06"
        return offset_hex_string[2:].zfill(2)
    else:
        raise ValueError(f"Cannot offset {hex_string} by {offset}, it would give {offset_hex_string} which is not in valid range 0x00-{hex(MAX_TRACK_ID)}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="""Generate _offset.p8 file from .p8 file with music tracks
offset by offset argument (anything after __music__ section is ignored).""")
    parser.add_argument('path', type=str, help='path containing cartridge file to offset music tracks from')
    parser.add_argument('offset', type=int, default=1, help="""Music track IDs offset (default: 1)""")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    logging.info(f"Offsetting track IDs in __music__ section in {args.path} with offset: {args.offset}...")

    offset_bgm_tracks_in_p8(args.path, args.offset)

    logging.info(f"Done.")
