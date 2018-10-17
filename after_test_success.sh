#!/usr/bin/env sh

set -e

echo 'updating symlink...'

SYMLINK_LOCATION=../../../../tinyci-example_production

ln -sf $PWD $SYMLINK_LOCATION
