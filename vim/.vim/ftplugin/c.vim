colorscheme c-theme

let s:CC = "clang"

function! CompileAndRun()
    update
    let flags = ""

    if search('#include\s*<math\.h>', 'nw')
        let flags .= " -lm"
    endif

    if search('#include\s*<pthread\.h>', 'nw')
        let flags .= " -pthread"
    endif

    if search('#include\s*<dlfcn\.h>', 'nw')
        let flags .= " -ldl"
    endif

    if search('#include\s*<aio\.h>', 'nw')
        let flags .= " -lrt"
    endif

    if search('#include\s*<ncurses\.h>', 'nw')
        let flags .= " -lncurses"
    endif

    let l:src = shellescape(expand('%:p'), 1)
    let l:out = shellescape(expand('%:p:r'), 1)
    execute '!' . ' clear && ' . s:CC . ' ' . l:src . ' -o ' . l:out . flags . ' && ' . ' clear ' . ' && ' . l:out
endfunction

nnoremap <buffer> <C-F> :call CompileAndRun()<CR>
