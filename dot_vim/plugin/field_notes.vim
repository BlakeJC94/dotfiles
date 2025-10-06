let g:field_notes_dir = '~/Dropbox/field-notes'
let g:field_notes_vert = v:true
let g:blog_content_dir = '~/Workspace/repos/blog/content/All posts'

command! -nargs=* -bang Note call s:OpenNote(<bang>0, <q-args>)
command! -nargs=* -bang Notes call s:OpenNotesDir(<bang>0)

function! s:OpenNote(bang, args)
    let l:split_cmd = a:bang ? 'edit' : 'split'
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

function! s:OpenNotesDir(bang)
    let l:split_cmd = a:bang ? 'edit' : 'split'
    let l:vert_prefix = g:field_notes_vert ? 'vert' : ''

    let l:cmd = 'silent ' . l:vert_prefix . ' ' . l:split_cmd . ' ' . fnameescape(g:field_notes_dir)
    execute l:cmd
    execute 'silent lcd' expand("%:p:h")
endfunction

command! -nargs=1 -bang Journal exec '<mods> Note<bang> ' . strftime("%Y-%m-%d %a", localtime() + (<args> * 86400))
command! -nargs=1 -bang Log exec '<mods> Note<bang> ' . strftime("%Y-%W: %b %d", localtime() + ((<args> * 7 + (strftime('%w') - 1 + 7) % 7) * 86400))

command! -bang Today exec '<mods> Journal<bang> 0'
command! -bang Tomorrow exec '<mods> Journal<bang> 1'
command! -bang Yesterday exec '<mods> Journal<bang> -1'
command! -bang NextMonday exec '<mods> Journal<bang> ' . ((8 - strftime('%w') + 0) % 7)
command! -bang LastMonday exec '<mods> Journal<bang> ' . (- ((strftime('%w') - 1 + 7) % 7))
command! -bang NextFriday exec '<mods> Journal<bang> ' . ((5 - strftime('%w') + 7) % 7)
command! -bang LastFriday exec '<mods> Journal<bang> ' . (- ((strftime('%w') - 5 + 7) % 7))

command! -bang ThisWeek exec '<mods> Log<bang> 0'
command! -bang NextWeek exec '<mods> Log<bang> 1'
command! -bang LastWeek exec '<mods> Log<bang> -1'

command! -nargs=* Asciiflow !open https://asciiflow.com/
command! -nargs=* Diagram call field_notes#NewDiagram(<q-args>)

command! -nargs=* -complete=file_in_path Image call field_notes#MoveImage(<q-args>)

command! -nargs=* Slugify echo field_notes#Slugify(<q-args>)
command! -nargs=1 Link exec "let pos = getpos('.') | norm! :s/" . escape(expand('<cWORD>'), '/\') . "/[" . escape(expand('<cWORD>'), '/\') . "](" . escape(<q-args>, '/\') . ")/<CR> | call setpos('.', pos)"

" Notes
nnoremap <Leader>n :Note<CR>
nnoremap <Leader>N :split \| edit ~/Workspace/repos/field-notes/notes \| lcd %:p:h<CR>

command! -nargs=* -bang CatBetweenDates call field_notes#CatFilesBetweenDates(<bang>0, <f-args>)


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
