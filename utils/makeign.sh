#!/bin/bash

infile="$(dirname $0)/../config.bu.yml"
outfile="$(dirname $0)/../http/config.ign"

echo Updating ignition file at $outfile
if command -v podman >/dev/null 2>&1; then
    podman run -i --rm quay.io/coreos/butane:release --pretty --strict < $infile > $outfile
elif command -v docker >/dev/null 2>&1; then
    docker run -i --rm quay.io/coreos/butane:release --pretty --strict < $infile > $outfile
elif command -v butane >/dev/null 2>&1; then
    butane --pretty --strict < $infile > $outfile
else
    echo "You need to have one of: Butane, Podman or Docker for this script to generate ignition files."
    echo "Download Butane: https://github.com/coreos/butane/releases"
    exit 1
fi
