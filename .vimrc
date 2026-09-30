" Plugins and indentation per filetype
filetype plugin indent on

" Syntax
syntax on

" Theme

colorscheme default-theme

" File execution keybind (<C-F>) is configured per file type:
" ~/.vim/ftplugin/c.vim            (s:CC)
" ~/.vim/after/ftplugin/cpp.vim    (s:CXX)
" If you use GCC instead of Clang, change those variables.

" General configuration
set number
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set scrolloff=999
