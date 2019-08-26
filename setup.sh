#!/bin/bash

# install npm packages for minification
npm_path="$(dirname "$0")/scripts/npm"
pushd "$npm_path"
npm update
popd
