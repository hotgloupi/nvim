#!/bin/sh
set -eaux
SCRIPT=`readlink -f "$0"`
SCRIPT_DIR=`dirname "${SCRIPT}"`
OS="${1:-linux}"

BUILD_DIR="${SCRIPT_DIR}/build-$OS"
RELEASE_DIR="${SCRIPT_DIR}/release-$OS"
RELEASE_TARBALL="${SCRIPT_DIR}/nvim-$OS.tgz"

if [ ! -d "${BUILD_DIR}" ]; then
	echo "Cannot find '${BUILD_DIR}'"
	exit 1
fi


try()
{
    ( "$@" ) || echo "    ---> failed, ignore error"
}

if [ -z "${USE_EXISTING_RELEASE:-}" ]; then
    if [ -d "${RELEASE_DIR}" ]; then
        echo "ERROR: Found existing release directory in '${RELEASE_DIR}'"
        exit 1
    fi
    cp -r "${BUILD_DIR}" "${RELEASE_DIR}"
    chmod -R u+rwX "${RELEASE_DIR}"
fi

############################# Cleanup
cd "${RELEASE_DIR}"
rm -f bin/openssl
rm -f bin/c_rehash
rm -f bin/2to3*
rm -f bin/pip3.6
rm -f bin/python3.6m
rm -f bin/easy_install*
rm -f bin/idle*
rm -f bin/llvm*
rm -f bin/clang-5.0
rm -f bin/clang
rm -f bin/clang-cpp
rm -f bin/clang-import-test
rm -f bin/clang++
rm -f bin/clang-cl
rm -f bin/clang-check
rm -f bin/bugpoint
rm -f bin/lli
rm -f bin/llc
rm -f bin/obj2yaml
rm -f bin/yaml2obj
rm -f bin/scan-build
rm -f bin/scan-view
rm -f bin/sancov
rm -f bin/sanstats
rm -f bin/opt
rm -f bin/c-index-test
rm -f bin/verify-uselistorder
rm -rf bin/python*-config

rm -f lib/BugpointPasses.so
rm -f lib/libLTO.so*
rm -f lib/LLVMHello.so
rm -rf lib/python3.6/test
rm -rf lib/python2.7/test
rm -rf lib/engines-1.1
rm -rf lib/clang
rm -rf lib/pkgconfig
rm -rf lib/cmake

rm -rf include

rm -rf libexec

rm -rf share/doc
rm -rf share/man
rm -rf share/clang
rm -rf share/pkgconfig
rm -rf share/scan-*

#rm -rf share/nvim/runtime/python/ycm/tests
#rm -rf share/nvim/runtime/third_party/ycmd/ycmd/tests
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/JediHTTP/vendor/jedi/test
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/JediHTTP/jedihttp/tests
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/JediHTTP/vendor/waitress/waitress/tests
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/waitress/waitress/tests
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/bottle/test
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/gocode/_testing
#
## XXX Saving 30Mb
#rm -rf share/nvim/runtime/third_party/ycmd/third_party/OmniSharpServer

find . -ignore_readdir_race -name __pycache__ -prune -exec rm -rf {} \;
find "${RELEASE_DIR}" -ignore_readdir_race -name '.*' -prune -exec rm -rf {} \;
find . -name '*.exe' -delete
find . -name '*.a' -delete
find . -name '*.pyc' -delete
find . -name '*.pyo' -delete

############################ Fix script path




############################ Fix RPATH
cd "${RELEASE_DIR}"

# python bin/lib
for b in bin/python3 bin/python2 ; do chmod u+w "$b" ; chrpath -r '$ORIGIN/../lib' "$b" ; done

# python extensions
find lib/python3.6/lib-dynload -name '*.so' -exec chrpath -r '$ORIGIN/../..' {} \;
find lib/python2.7/lib-dynload -name '*.so' -exec chrpath -r '$ORIGIN/../..' {} \;
#chrpath -r '$ORIGIN/../..' lib/python3.6/site-packages/greenlet.cpython-36m-x86_64-linux-gnu.so
try chrpath -r '$ORIGIN/../../..' lib/python3.6/site-packages/msgpack/_packer.cpython-36m-x86_64-linux-gnu.so
try chrpath -r '$ORIGIN/../../..' lib/python3.6/site-packages/msgpack/_unpacker.cpython-36m-x86_64-linux-gnu.so
try chrpath -r '$ORIGIN/../../..' lib/python2.7/site-packages/msgpack/_packer.so
try chrpath -r '$ORIGIN/../../..' lib/python2.7/site-packages/msgpack/_unpacker.so

# cquery
chrpath -r '$ORIGIN/../lib' bin/cquery

# ycm core
#find "${BUILD_DIR}" -name ycm_core.so
#find "${RELEASE_DIR}" -name ycm_core.so
#chrpath -r '$ORIGIN/../../../../../lib' share/nvim/runtime/third_party/ycmd/ycm_core.so


########################### strip binaries
cd "${RELEASE_DIR}"
strip -x bin/nvim-binary
strip -x bin/python2
strip -x bin/python3
find . \( -name '*.so' -o -name '*.so.*' \) -print -exec strip -x {} \;

########################### create the tarball
cd "${RELEASE_DIR}"
rm -rf .tmp
mkdir -p .tmp/bin .tmp/share/nvim
mv * .tmp/share/nvim
( cd .tmp/bin && ln -s ../share/nvim/bin/nvim nvim )
mv .tmp/* .
rmdir .tmp
rm -f "${RELEASE_TARBALL}"
tar cjf "${RELEASE_TARBALL}" *

echo "Created '$RELEASE_TARBALL'"
