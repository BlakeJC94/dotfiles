let g:field_notes_dir = '~/Dropbox/field-notes'
let g:field_notes_vert = v:true
let g:blog_content_dir = '~/Workspace/repos/blog/content/All posts'


command! -nargs=* -bang Note call s:OpenNote(<bang>0, 0, <q-args>)
command! -nargs=* -bang NoteSplit call s:OpenNote(<bang>0, 1, <q-args>)

function! s:OpenNote(bang, split, args)
    let l:split_cmd = a:split ? 'edit' : 'split'
    let l:vert_prefix = g:field_notes_vert ? 'vert' : ''

    if a:bang
        call field_notes#LinkNote(a:args)
    endif

    let l:note_path = field_notes#StartNote(a:args)
    let l:cmd = 'silent ' . l:vert_prefix . ' ' . l:split_cmd . ' ' . fnameescape(l:note_path)
    execute l:cmd

    call field_notes#InitializeNoteIfNeeded(a:args)
    execute 'lcd ' expand("%:p:h")
    echo expand("%:p")
endfunction


command! Notes call s:OpenNotesDir()

function! s:OpenNotesDir()
    let l:split_cmd = 'split'
    let l:vert_prefix = g:field_notes_vert ? 'vert' : ''

    let l:cmd = 'silent ' . l:vert_prefix . ' ' . l:split_cmd . ' ' . fnameescape(g:field_notes_dir)
    execute l:cmd
    execute 'silent lcd' expand("%:p:h")
endfunction


" command! -bang NextMonday exec '<mods> Journal<bang> ' . ((8 - strftime('%w') + 0) % 7)
" command! -bang LastMonday exec '<mods> Journal<bang> ' . (- ((strftime('%w') - 1 + 7) % 7))
"
command! -nargs=1 -bang Log exec '<mods> Note<bang> ' . strftime("%Y-%W: %b %d", localtime() + ((<args> * 7 + (strftime('%w') - 1 + 7) % 7) * 86400))

command! -bang ThisWeek exec '<mods> Log<bang> 0'
command! -bang NextWeek exec '<mods> Log<bang> 1'
command! -bang LastWeek exec '<mods> Log<bang> -1'

command! -nargs=* Asciiflow !open https://asciiflow.com/
command! -nargs=* Diagram call field_notes#NewDiagram(<q-args>)

command! -nargs=* -complete=file_in_path Image call field_notes#MoveImage(<q-args>)

command! -nargs=* Slugify echo field_notes#Slugify(<q-args>)
command! -nargs=1 Link exec "let pos = getpos('.') | norm! :s/" . escape(expand('<cWORD>'), '/\') . "/[" . escape(expand('<cWORD>'), '/\') . "](" . escape(<q-args>, '/\') . ")/<CR> | call setpos('.', pos)"


command! BlogHeader call field_notes#BlogHeader()
command! BlogWrite call s:BlogWrite()

function! s:BlogWrite()
    let l:target = expand(g:blog_content_dir) . '/' . expand('%:t')

    if filereadable(l:target)
        let l:choice = confirm("File already exists:\n" . l:target . "\nOverwrite?", "&Yes\n&No", 2)
        if l:choice != 1
            echo "Aborted: file not written."
            return
        endif
    endif

    execute 'write' fnameescape(l:target)
    execute 'edit' fnameescape(l:target)
    echo "File written to: " . l:target
    call field_notes#BlogHeader()
endfunction
