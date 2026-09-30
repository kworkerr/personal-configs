colorscheme cpp-theme

let s:CXX = "clang++"

function! CompileAndRunCpp()
    update
    let flags = ""

    if search('#include\s*<pthread\.h>', 'nw')
        let flags .= " -pthread"
    endif

    if search('#include\s*<dlfcn\.h>', 'nw')
        let flags .= " -ldl"
    endif

    if search('#include\s*<aio\.h>', 'nw')
        let flags .= " -lrt"
    endif

    let l:src = shellescape(expand('%:p'), 1)
    let l:out = shellescape(expand('%:p:r'), 1)
    execute '!' . s:CXX . ' ' . l:src . ' -o ' . l:out . flags . '&&' . ' clear ' . ' && ' . l:out
endfunction

nnoremap <buffer> <C-F> :call CompileAndRunCpp()<CR>
