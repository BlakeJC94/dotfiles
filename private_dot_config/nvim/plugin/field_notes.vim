let g:field_notes_dir = '~/Workspace/field-notes'
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
    let l:dir = fnameescape(g:field_notes_dir)

    let l:cmd = 'silent ' . l:vert_prefix . ' ' . l:split_cmd . ' ' . l:dir
    execute l:cmd
    execute 'silent lcd ' . l:dir
endfunction

command! -nargs=1 -bang Log
      \ exec '<mods> Note<bang> ' .
      \ strftime(
      \   "%Y-%W: %b %d",
      \   localtime()
      \   + (<args> * 7 * 86400)
      \   - ((strftime("%u", localtime()) - 1) * 86400)
      \ )

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


command! RenameNote call s:RenameNote()
function! s:RenameNote()
    " Get the first line that matches the regex ^#\s\(.*\)
    let l:line_num = search('^#\s\+\(.*\)', 'n')
    if l:line_num == 0
        echo "Error: No header found (no line matching '^# ...')"
        return
    endif

    " Get the text in the first capture group \1
    let l:line = getline(l:line_num)
    let l:header_text = substitute(l:line, '^#\s\+\(.*\)', '\1', '')

    " Transform the string with field_notes#Slugify(string)
    let l:slug = field_notes#Slugify(l:header_text)

    " Update the filename
    let l:current_file = expand('%:p')
    let l:current_dir = expand('%:p:h')
    let l:current_ext = expand('%:e')
    let l:new_filename = l:slug . (empty(l:current_ext) ? '' : '.' . l:current_ext)
    let l:new_path = l:current_dir . '/' . l:new_filename

    " Check if new file already exists
    if filereadable(l:new_path) && l:new_path != l:current_file
        let l:choice = confirm("File already exists:\n" . l:new_path . "\nOverwrite?", "&Yes\n&No", 2)
        if l:choice != 1
            echo "Aborted: file not renamed."
            return
        endif
    endif

    " Save current file and rename
    write
    execute 'saveas' fnameescape(l:new_path)
    call delete(l:current_file)
    echo "File renamed to: " . l:new_filename
endfunction
