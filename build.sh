#!/bin/bash
set -eaux
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"
INSTALL_DIR="${SCRIPT_DIR}/${BUILD_NAME:-build-linux}"
CMAKE=${CMAKE:-cmake}
CORES=${CORES:-4}

${CMAKE} --version

############################# build neovim
if [ ! -f "${INSTALL_DIR}"/bin/nvim ]; then
	echo "Building Neovim"

	cd "${SCRIPT_DIR}"/neovim
	mkdir -p .deps
	cd .deps
	${CMAKE} ../third-party -DCMAKE_BUILD_TYPE=Release > "${SCRIPT_DIR}"/neovim.log
	make -j${CORES} >> "${SCRIPT_DIR}"/neovim.log

	cd "${SCRIPT_DIR}"/neovim
	mkdir -p build
	cd build
	${CMAKE} .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" >> "${SCRIPT_DIR}"/neovim.log
	make -j${CORES} >> "${SCRIPT_DIR}"/neovim.log
	make install >> "${SCRIPT_DIR}"/neovim.log
	mv "${INSTALL_DIR}/bin/nvim" "${INSTALL_DIR}/bin/nvim-binary"
	cp "${SCRIPT_DIR}/launcher.sh" "${INSTALL_DIR}/bin/nvim"
fi

############################ build zlib
if [ ! -f "${INSTALL_DIR}"/lib/libz.so ]; then
	echo "Building zlib"
	cd "${SCRIPT_DIR}"/zlib*
	mkdir -p build
	cd build
	${CMAKE} .. -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" > "${SCRIPT_DIR}"/zlib.log
	make install >> "${SCRIPT_DIR}"/zlib.log
fi

############################ build openssl
if [ ! -f "${INSTALL_DIR}"/lib/libssl.a ]; then
	echo "Building OpenSSL"
	cd "${SCRIPT_DIR}"/openssl
	./Configure linux-x86_64 no-shared \
		-fPIC \
		-I"${INSTALL_DIR}"/include \
		-L"${INSTALL_DIR}"/lib \
		--prefix="${INSTALL_DIR}" \
		--openssldir="${INSTALL_DIR}/ssl" > "${SCRIPT_DIR}"/openssl.log
	make >> "${SCRIPT_DIR}"/openssl.log
	make install >> "${SCRIPT_DIR}"/openssl.log
fi

############################ build python3
if [ ! -f "${INSTALL_DIR}"/bin/python3 ]; then
	echo "Building Python 3"
	cd "${SCRIPT_DIR}"/Python-3.*
	mkdir -p build
	cd build
	../configure \
		--prefix="${INSTALL_DIR}" \
		--enable-shared \
		LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib" > "${SCRIPT_DIR}"/python-3.log
	make -j${CORES} >> "${SCRIPT_DIR}"/python-3.log
	make install >> "${SCRIPT_DIR}"/python-3.log
	"${INSTALL_DIR}"/bin/pip3 install neovim >> "${SCRIPT_DIR}"/python-3.log
fi

############################# build python2
if [ ! -f "${INSTALL_DIR}"/bin/python2 ]; then
	echo "Building Python 2"
	cd "${SCRIPT_DIR}"/Python-2.*
	mkdir -p build
	cd build
	../configure \
		--prefix="${INSTALL_DIR}" \
		--enable-unicode=ucs4 \
		--enable-shared \
		--with-ensurepip=install \
		LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib" > "${SCRIPT_DIR}"/python-2.log
	make -j${CORES} >> "${SCRIPT_DIR}"/python-2.log
	make install >> "${SCRIPT_DIR}"/python-2.log
	"${INSTALL_DIR}"/bin/pip2.7 install neovim >> "${SCRIPT_DIR}"/python-2.log
fi

export PATH="${INSTALL_DIR}/bin":$PATH

############################# build LLVM and Clang
if [ ! -f "${INSTALL_DIR}"/lib/libclang.so ]; then
	echo "Building LLVM and clang"
	cd "${SCRIPT_DIR}"/llvm*
	mkdir -p build
	cd build
	${CMAKE} .. \
		-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DPYTHON_EXECUTABLE="${INSTALL_DIR}/bin/python2.7" > "${SCRIPT_DIR}"/llvm.log
	make -j${CORES} >> "${SCRIPT_DIR}"/llvm.log
	make install >> "${SCRIPT_DIR}"/llvm.log
	cd "${INSTALL_DIR}"
	cp share/clang/clang-format.py bin
fi

############################# build YouCompleteMe
if [ ! -f "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/ycm_core.so ]; then
	echo "Building YCM"
	cd "${SCRIPT_DIR}"/ycm
	mkdir -p build
	cd build
	${CMAKE} \
		-G "Unix Makefiles" \
		-DEXTERNAL_LIBCLANG_PATH="${INSTALL_DIR}/lib/libclang.so" \
		-DPYTHON_LIBRARY="${INSTALL_DIR}/lib/libpython2.7.so" \
		-DPYTHON_INCLUDE_DIR="${INSTALL_DIR}/include/python2.7" \
		-DPYTHON_EXECUTABLE="${INSTALL_DIR}/bin/python2.7" \
		-DCMAKE_BUILD_TYPE=Release \
		../third_party/ycmd/cpp > "${SCRIPT_DIR}"/ycm.log
	make -j${CORES} >> "${SCRIPT_DIR}"/ycm.log

	cd "${SCRIPT_DIR}"/ycm
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
	cp third_party/ycmd/ycm_core.so "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/
	cp -r  third_party/ycmd/CORE_VERSION "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd
fi

############################# Fix neovim python host programs
cat > "${INSTALL_DIR}"/share/nvim/sysinit.vim << EOF
let g:python_host_prog = \$NVIM_PYTHON_HOST_PROGRAM
let g:python3_host_prog = \$NVIM_PYTHON3_HOST_PROGRAM
let g:clang_format_path = \$NVIM_CLANG_FORMAT_BINARY_PATH
EOF


############################## Remove hidden directories
find "${INSTALL_DIR}" -ignore_readdir_race -name '.*' -prune -exec rm -rf {} \;
