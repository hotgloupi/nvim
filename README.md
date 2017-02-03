# nvim

## Description

 Prebuilt neovim that includes:

 - Neovim 0.1.7
 - YouCompleteMe
 - Python 2.7.13
 - Python 3.6.0
 - LLVM+clang 3.9.1

 For now, only linux binaries are provided, do not hesitate to open an issue if
 you need it for another platform.

 YouCompleteMe is compiled with clang completion enabled for C/C++ languages,
 but also includes python completion by default.

## Installation

 Just grab the last version and extract it in a prefix of your choice:

    $ mkdir ~/local
    $ wget -O - https://github.com/hotgloupi/nvim/releases/download/0.6/nvim-linux.x86_64.tgz | tar xjf - -C ~/local
    $ export PATH=~/local/bin:$PATH
    $ nvim --version

 Note: You should remove any installed version of YouCompleteMe from your own
 config

## Usage

### Using clang-format

 If you want to use the shipped clang-format, you can bind it using
 `NVIM_CLANG_FORMAT_SCRIPT_PATH` environment variable:

    autocmd FileType c,cpp,objc map <C-K> :pyf $NVIM_CLANG_FORMAT_SCRIPT_PATH<CR>
    autocmd FileType c,cpp,objc imap <C-K> <c-o>:pyf $NVIM_CLANG_FORMAT_SCRIPT_PATH<CR>
