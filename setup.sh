#!/bin/bash

# install npm packages for minification
# (execute once after cloning repo, or when a node package needs update)
npm_path="$(dirname "$0")/scripts/npm"
pushd "$npm_path"
npm update
popd
