#!/bin/sh
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"
VIMRUNTIME="${SCRIPT_DIR}/../share/nvim/runtime" "${SCRIPT_DIR}"/nvim-binary
