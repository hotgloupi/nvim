#!/bin/sh
set -eau
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"
INSTALL_DIR="${SCRIPT_DIR}/install"

########################### build neovim
cd "${SCRIPT_DIR}"/neovim
make CMAKE_BUILD_TYPE=Release BUILD_TYPE="Unix Makefiles" CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
make install
strip -x "${INSTALL_DIR}/bin/nvim" 
mv "${INSTALL_DIR}/bin/nvim" "${INSTALL_DIR}/bin/nvim-binary"
cp "${SCRIPT_DIR}/launcher.sh" "${INSTALL_DIR}/bin/nvim"

########################### build zlib
cd "${SCRIPT_DIR}"/zlib*
mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
make install

########################### build openssl
cd "${SCRIPT_DIR}"/openssl
./Configure linux-x86_64 no-shared \
	-fPIC \
	-I"${INSTALL_DIR}"/include \
	-L"${INSTALL_DIR}"/lib \
	--prefix="${INSTALL_DIR}" \
	--openssldir="${INSTALL_DIR}/ssl"
make
make install

########################### build python
cd "${SCRIPT_DIR}"/Python-3.6.0
mkdir -p build
cd build
../configure --prefix="${INSTALL_DIR}" --enable-shared LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib"
make -j4
make install

############################ build python
cd "${SCRIPT_DIR}"/ycm
"${INSTALL_DIR}/bin/python" install.py --clang-completer
cp plugin/youcompleteme.vim "${INSTALL_DIR}"/share/nvim/runtime/plugin/
cp autoload/youcompleteme.vim "${INSTALL_DIR}"/share/nvim/runtime/autoload/
mkdir -p "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd
cp third_party/ycmd/libclang.so* "${INSTALL_DIR}"/lib
cp third_party/ycmd/ycm_core.so "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/
chrpath -r '$ORIGIN/../../../../../lib' "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/
