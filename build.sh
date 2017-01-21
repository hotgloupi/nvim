#!/bin/bash
set -eaux
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"
INSTALL_DIR="${SCRIPT_DIR}/install"

############################ build neovim
cd "${SCRIPT_DIR}"/neovim
make CMAKE_BUILD_TYPE=Release BUILD_TYPE="Unix Makefiles" CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
make install
strip -x "${INSTALL_DIR}/bin/nvim" 
mv "${INSTALL_DIR}/bin/nvim" "${INSTALL_DIR}/bin/nvim-binary"
cp "${SCRIPT_DIR}/launcher.sh" "${INSTALL_DIR}/bin/nvim"

############################ build zlib
cd "${SCRIPT_DIR}"/zlib*
mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
make install

############################ build openssl
cd "${SCRIPT_DIR}"/openssl
./Configure linux-x86_64 no-shared \
	-fPIC \
	-I"${INSTALL_DIR}"/include \
	-L"${INSTALL_DIR}"/lib \
	--prefix="${INSTALL_DIR}" \
	--openssldir="${INSTALL_DIR}/ssl"
make
make install

############################ build python
cd "${SCRIPT_DIR}"/Python-3.6.0
mkdir -p build
cd build
../configure --prefix="${INSTALL_DIR}" --enable-shared LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib"
make -j4
make install
"${INSTALL_DIR}"/bin/pip3 install neovim

############################ build YouCompleteMe
cd "${SCRIPT_DIR}"/ycm
"${INSTALL_DIR}/bin/python3" install.py --clang-completer --build-dir build
cp plugin/youcompleteme.vim "${INSTALL_DIR}"/share/nvim/runtime/plugin/
cp autoload/youcompleteme.vim "${INSTALL_DIR}"/share/nvim/runtime/autoload/
cp doc/youcompleteme.txt "${INSTALL_DIR}"/share/nvim/runtime/doc/
cp -r python  "${INSTALL_DIR}"/share/nvim/runtime
mkdir -p "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd
cp -r  third_party/ycmd/ycmd "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd
cp -r  third_party/ycmd/third_party "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd
cp -r third_party/pythonfutures "${INSTALL_DIR}"/share/nvim/runtime/third_party
cp -r third_party/requests-futures "${INSTALL_DIR}"/share/nvim/runtime/third_party
cp -r third_party/retries "${INSTALL_DIR}"/share/nvim/runtime/third_party
cp third_party/ycmd/libclang.so* "${INSTALL_DIR}"/lib
cp third_party/ycmd/ycm_core.so "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/
cp -r  third_party/ycmd/CORE_VERSION "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd


############################ Cleanup
cd "${INSTALL_DIR}"
rm -f bin/openssl
rm -f bin/c_rehash
rm -f bin/2to3*
rm -f bin/pip3.6
rm -f bin/python3.6m
rm -f bin/easy_install*
rm -f bin/idle*

rm -rf lib/engines-1.1
rm -rf include
rm -rf share/nvim/runtime/python/ycm/tests
rm -rf share/nvim/runtime/third_party/ycmd/ycmd/tests
rm -rf share/nvim/runtime/third_party/ycmd/third_party/JediHTTP/vendor/jedi/test
rm -rf share/nvim/runtime/third_party/ycmd/third_party/JediHTTP/jedihttp/tests
rm -rf share/nvim/runtime/third_party/ycmd/third_party/JediHTTP/vendor/waitress/waitress/tests
rm -rf share/nvim/runtime/third_party/ycmd/third_party/waitress/waitress/tests
rm -rf share/nvim/runtime/third_party/ycmd/third_party/bottle/test
rm -rf share/nvim/runtime/third_party/ycmd/third_party/gocode/_testing
rm -rf lib/python3.6/test

find . -name '*.a' -delete
find share/nvim/runtime/third_party/ycmd/third_party -name '*.so' -delete

find . -ignore_readdir_race -name __pycache__ -prune -exec rm -rf {} \;
find . -ignore_readdir_race -name '.*' -prune -exec rm -rf {} \;
find . -name '*.exe' -delete


############################ Fix RPATH
cd "${INSTALL_DIR}"

# python bin/lib
for b in bin/python3 lib/libpython3.so ; do chmod u+w "$b" ; chrpath -r '$ORIGIN/../lib' "$b" ; done

# python extensions
find lib/python3.6/lib-dynload -name '*.so' -exec chrpath -r '$ORIGIN/../..' {} \;
#chrpath -r '$ORIGIN/../..' lib/python3.6/site-packages/greenlet.cpython-36m-x86_64-linux-gnu.so
chrpath -r '$ORIGIN/../../..' lib/python3.6/site-packages/msgpack/_packer.cpython-36m-x86_64-linux-gnu.so
chrpath -r '$ORIGIN/../../..' lib/python3.6/site-packages/msgpack/_unpacker.cpython-36m-x86_64-linux-gnu.so

# ycm core
chrpath -r '$ORIGIN/../../../../../lib' "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/ycm_core.so

