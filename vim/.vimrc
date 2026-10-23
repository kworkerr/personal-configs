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
hi Normal ctermbg=NONE guibg=NONE " Remove if you want to vim have it own color
set backspace=indent,eol,start " For some bullshit reason this is necessary or i cant delete characters on files
set number
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set scrolloff=999

augroup discord_presence
    autocmd!
    autocmd BufEnter * call writefile(
        \ [expand('%:t')],
        \ expand('~/.cache/vim-presence')
        \ )
augroup END
