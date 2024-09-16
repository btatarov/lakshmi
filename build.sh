#!/bin/sh
DEFAULT_BUILD="debug"
ALLOWED_BUILDS=("release" "debug")
DEFAULT_SCRIPT="test/main.lua"

build=${1:-$DEFAULT_BUILD}
script=${2:-$DEFAULT_SCRIPT}

if [[ ! " ${ALLOWED_BUILDS[@]} " =~ " ${build} " ]]; then
    echo "Invalid build type: $build"
    echo "Valid values are: ${ALLOWED_BUILDS[@]}"
    exit 1
fi

extra_args="-show-timings"
if [ $build == "debug" ]; then
    extra_args="$extra_args -debug -vet"
fi

odin run src/ -out=build/lakshmi $extra_args -- $script
