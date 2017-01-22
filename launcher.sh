#!/bin/sh
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"

export VIMRUNTIME="${SCRIPT_DIR}/../share/nvim/runtime" 
export NVIM_PYTHON_HOST_PROGRAM="${SCRIPT_DIR}/python2"
export NVIM_PYTHON3_HOST_PROGRAM="${SCRIPT_DIR}/python3"
"${SCRIPT_DIR}"/nvim-binary "$@"
