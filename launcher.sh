#!/bin/sh
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"

export VIMRUNTIME="${SCRIPT_DIR}/../share/nvim/runtime" 
export PATH="${SCRIPT_DIR}":$PATH
"${SCRIPT_DIR}"/nvim-binary
