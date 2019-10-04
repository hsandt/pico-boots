#!/bin/bash

# Try to find a running PICO-8 session and reload it.
# Requires xdotool (mostly Linux).

# This is often used in combination with a build script to "hot reload" a modified cartridge.
# However, it only makes sense if the built cartridge is the same as the one currently run.

if hash timeout 2>/dev/null && hash xdotool 2>/dev/null; then
	# --sync makes sure the window is active before sending the key, but it gets stuck
	# if no matching window is found, so timeout tries to prevent this,
	# although it doesn't guarantee that ctrl+r is correctly received after focus
	timeout 0.15 xdotool search --sync --class pico8 windowactivate key ctrl+r &&
		echo "Reloaded pico8"
else
	echo "timeout or xdotool commands could not be found, cannot reload."
	exit 1
fi
