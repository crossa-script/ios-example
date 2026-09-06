#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/Crossa.xcframework" >&2
    exit 64
fi

source_framework=$1
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
example_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
destination="$example_directory/CrossaBinary/Crossa.xcframework"

if [ ! -d "$source_framework" ]; then
    echo "Crossa XCFramework was not found: $source_framework" >&2
    exit 66
fi

if [ ! -f "$source_framework/Info.plist" ]; then
    echo "The source is not a valid XCFramework: $source_framework" >&2
    exit 65
fi

rm -rf "$destination"
mkdir -p "$(dirname -- "$destination")"
cp -R "$source_framework" "$destination"
echo "Installed Crossa XCFramework at CrossaBinary/Crossa.xcframework"
echo "Use a Release XCFramework for the default example and benchmarking."
