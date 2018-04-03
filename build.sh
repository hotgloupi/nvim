#!/bin/bash
set -eaux
SCRIPT="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT})"
INSTALL_DIR="${SCRIPT_DIR}/${BUILD_NAME:-build-linux}"
CMAKE=${CMAKE:-cmake}
CORES=${CORES:-4}

unset PYTHONPATH
unset PYTHONUSERBASE
unset PYTHONHOME

${CMAKE} --version

############################# build neovim
if [ ! -f "${INSTALL_DIR}"/bin/nvim ]; then
	echo "Building Neovim"

	cd "${SCRIPT_DIR}"/neovim
	mkdir -p .deps
	cd .deps
	${CMAKE} ../third-party -DCMAKE_BUILD_TYPE=Release > "${SCRIPT_DIR}"/neovim.log
	make >> "${SCRIPT_DIR}"/neovim.log

	cd "${SCRIPT_DIR}"/neovim
	mkdir -p build
	cd build
	${CMAKE} .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" >> "${SCRIPT_DIR}"/neovim.log
	make -j${CORES} >> "${SCRIPT_DIR}"/neovim.log
	make install >> "${SCRIPT_DIR}"/neovim.log
	mv "${INSTALL_DIR}/bin/nvim" "${INSTALL_DIR}/bin/nvim-binary"
	cp "${SCRIPT_DIR}/launcher.sh" "${INSTALL_DIR}/bin/nvim"
fi

############################# build xsel
if [ ! -f "${INSTALL_DIR}"/bin/xsel ]; then
	echo "Building xsel"
	cd "${SCRIPT_DIR}"/xsel*
	mkdir -p build
	cd build
	../configure --prefix="${INSTALL_DIR}"
	make
	make install
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
	"${INSTALL_DIR}"/bin/pip3 install python-language-server >> "${SCRIPT_DIR}"/python-3.log
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
	"${INSTALL_DIR}"/bin/pip2.7 install python-language-server >> "${SCRIPT_DIR}"/python-2.log
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


############################# build cquery
if [ ! -f "${INSTALL_DIR}"/bin/cquery ]; then
    ./waf configure \
        --llvm-config="${INSTALL_DIR}/bin/llvm-config" \
        --variant=release \
        --prefix="${INSTALL_DIR}" \
        --use-system-clang
fi

############################# Vim-plug
if [ ! -f "${INSTALL_DIR}"/share/nvim/runtime/autoload/plug.vim ]; then
    cd "${SCRIPT_DIR}/vim-plug"
    cp plug.vim "${INSTALL_DIR}"/share/nvim/runtime/autoload/plug.vim
fi

############################# Fix neovim python host programs
cat > "${INSTALL_DIR}"/share/nvim/sysinit.vim << EOF
let g:python_host_prog = \$NVIM_PYTHON_HOST_PROGRAM
let g:python3_host_prog = \$NVIM_PYTHON3_HOST_PROGRAM
let g:clang_format_path = \$NVIM_CLANG_FORMAT_BINARY_PATH
EOF


############################## Remove hidden directories
find "${INSTALL_DIR}" -ignore_readdir_race -name '.*' -prune -exec rm -rf {} \;
