#!/bin/bash
set -eaux
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"
INSTALL_DIR="${SCRIPT_DIR}/${BUILD_NAME:-build-linux}"
CMAKE=${CMAKE:-cmake}
CORES=${CORES:-4}

############################# build neovim
if [ ! -f "${INSTALL_DIR}"/bin/nvim ]; then
	cd "${SCRIPT_DIR}"/neovim
	make \
		CMAKE_BUILD_TYPE=Release \
		BUILD_TYPE="Unix Makefiles" \
		CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
	make install
	mv "${INSTALL_DIR}/bin/nvim" "${INSTALL_DIR}/bin/nvim-binary"
	cp "${SCRIPT_DIR}/launcher.sh" "${INSTALL_DIR}/bin/nvim"
fi

############################ build zlib
if [ ! -f "${INSTALL_DIR}"/lib/libz.so ]; then
	cd "${SCRIPT_DIR}"/zlib*
	mkdir -p build
	cd build
	${CMAKE} .. -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
	make install
fi

############################ build openssl
if [ ! -f "${INSTALL_DIR}"/lib/libssl.a ]; then
	cd "${SCRIPT_DIR}"/openssl
	./Configure linux-x86_64 no-shared \
		-fPIC \
		-I"${INSTALL_DIR}"/include \
		-L"${INSTALL_DIR}"/lib \
		--prefix="${INSTALL_DIR}" \
		--openssldir="${INSTALL_DIR}/ssl"
	make
	make install
fi

############################ build python3
if [ ! -f "${INSTALL_DIR}"/bin/python3 ]; then
	cd "${SCRIPT_DIR}"/Python-3.*
	mkdir -p build
	cd build
	../configure \
		--prefix="${INSTALL_DIR}" \
		--enable-shared \
		LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib"
	make -j${CORES}
	make install
	"${INSTALL_DIR}"/bin/pip3 install neovim
fi

############################# build python2
if [ ! -f "${INSTALL_DIR}"/bin/python2 ]; then
	cd "${SCRIPT_DIR}"/Python-2.*
	mkdir -p build
	cd build
	../configure \
		--prefix="${INSTALL_DIR}" \
		--enable-unicode=ucs4 \
		--enable-shared \
		--with-ensurepip=install \
		LDFLAGS="-Wl,-rpath=${INSTALL_DIR}/lib"
	make -j${CORES}
	make install
	"${INSTALL_DIR}"/bin/pip2.7 install neovim
fi

export PATH="${INSTALL_DIR}/bin":$PATH

############################# build LLVM and Clang
if [ ! -f "${INSTALL_DIR}"/lib/libclang.so ]; then
	cd "${SCRIPT_DIR}"/llvm*
	mkdir -p build
	cd build
	${CMAKE} .. -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" -DCMAKE_BUILD_TYPE=Release \
		-DPYTHON_EXECUTABLE="${INSTALL_DIR}/bin/python2.7"
	make -j${CORES}
	make install
fi

############################# build YouCompleteMe
if [ ! -f "${INSTALL_DIR}"/share/nvim/runtime/third_party/ycmd/ycm_core.so ]; then
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
		../third_party/ycmd/cpp
	make -j${CORES}

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
let g:python_host_program = "\$NVIM_PYTHON_HOST_PROGRAM"
let g:python3_host_program = "\$NVIM_PYTHON3_HOST_PROGRAM"
EOF


############################## Remove hidden directories
find . -ignore_readdir_race -name '.*' -prune -exec rm -rf {} \;
#
#
