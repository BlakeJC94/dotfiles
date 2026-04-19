" Global variable to track last created PyScrap filename
let g:pyscrap_last_filename = ''

command! -bang -range -nargs=* PyScrap call PyScrapFunction(<bang>0, <line1>, <line2>, <f-args>)

function! PyScrapFunction(bang, line1, line2, ...)
    " Get the selected lines from the current buffer before switching
    let selected_lines = []
    if a:line1 != a:line2 || a:line1 != line('.')
        let selected_lines = getline(a:line1, a:line2)
    endif

    " If no bang and no args, try to open last PyScrap file
    if !a:bang && a:0 == 0 && g:pyscrap_last_filename != ''
        exec 'split ' . g:pyscrap_last_filename
        " If we have selected lines, copy them to the file
        if len(selected_lines) > 0
            call setline(1, selected_lines)
        endif
        return
    endif

    " Create new filename based on arguments or default
    let custom_name = 'scratch'
    if a:0 > 0
        let custom_name = join(a:000, '_')
    endif
    let filename = getcwd() . '/scrap/' . custom_name . '_' . strftime('%Y-%m-%d-%H%M') . '.py'

    " Update last filename when creating new file
    let g:pyscrap_last_filename = filename

    exec 'split ' . filename

    " If we have selected lines, copy them to the new file
    if len(selected_lines) > 0
        call setline(1, selected_lines)
    endif
endfunction

function! PyScrapOperator(type)
    let saved_unnamed_register = @@

    if a:type ==# 'v'
        normal! `<v`>y
    elseif a:type ==# 'char'
        normal! `[v`]y
    elseif a:type ==# 'line'
        normal! '[V']y
    else
        return
    endif

    let selected_text = split(@@, '\n')
    let @@ = saved_unnamed_register

    let filename = getcwd() . '/scrap/scratch_'. strftime("%Y-%m-%d-%H%M"). '.py'
    exec 'split ' . filename

    if len(selected_text) > 0
        call setline(1, selected_text)
    endif
endfunction

nnoremap <silent> <Plug>PyScrapOperator :set opfunc=PyScrapOperator<CR>g@
vnoremap <silent> <Plug>PyScrapOperator :<C-U>call PyScrapOperator(visualmode())<CR>

" Default mappings
nmap gS <Plug>PyScrapOperator
vmap gS <Plug>PyScrapOperator
