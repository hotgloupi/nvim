#!/bin/sh
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"

unset PYTHONPATH
unset PYTHONUSERBASE
unset PYTHONHOME
unset LD_LIBRARY_PATH

export VIMRUNTIME="${SCRIPT_DIR}/../share/nvim/runtime"
export NVIM_CLANG_FORMAT_SCRIPT_PATH="${SCRIPT_DIR}/clang-format.py"
export NVIM_CLANG_FORMAT_BINARY_PATH="${SCRIPT_DIR}/clang-format"
export NVIM_PYTHON_HOST_PROGRAM="${SCRIPT_DIR}/python2"
export NVIM_PYTHON3_HOST_PROGRAM="${SCRIPT_DIR}/python3"
export NVIM_CQUERY_BINARY="${SCRIPT_DIR}/cquery"
export NVIM_PYLS_BINARY="${SCRIPT_DIR}/pyls"
"${SCRIPT_DIR}"/nvim-binary "$@"
