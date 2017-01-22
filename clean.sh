#!/bin/sh
git clean -fdx -e '/build*'
git submodule foreach --recursive git clean -fdx
