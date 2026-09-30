setlocal tabstop=2
setlocal shiftwidth=2
setlocal softtabstop=2

function! RunShellScript()
    update

    let l:first = getline(1)
    if l:first =~# '^#!'
        let l:interp = substitute(l:first, '^#!\s*', '', '')
    else
        let l:interp = 'sh'
    endif

    let l:src = shellescape(expand('%:p'), 1)
    execute '!' . l:interp . ' ' . l:src
endfunction

nnoremap <buffer> <C-F> :call RunShellScript()<CR>
