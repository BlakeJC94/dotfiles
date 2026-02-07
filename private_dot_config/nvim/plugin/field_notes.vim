let g:field_notes_dir = '~/Workspace/field-notes'
let g:field_notes_vert = v:true
let g:blog_content_dir = '~/Workspace/repos/blog/content'

function! s:Slugify(string)
  let output = a:string
  let output = tolower(output)
  let output = substitute(output, '\W\+', '-', 'g')
  let output = substitute(output, '^-\+', '', 'g')
  let output = substitute(output, '-\+$', '', 'g')
  return output
endfunction

function! s:GetGitDir()
  if len(system("command -v git")) == 0
    return ""
  endif
  let l:git_dir = split(system(join(["git", "-C", expand("%:p:h"),  "rev-parse",  "--git-dir"], " ")), '\n')[0]
  if l:git_dir[0:5] == "fatal:"
    return ""
  endif
  return l:git_dir
endfunction

function! s:GetNoteTitle(...)
  let l:title = join(a:000, " ")

  if len(l:title) == 0
    let l:git_dir = s:GetGitDir()
    if len(l:git_dir) > 0
      " Branch
      let l:project_path = finddir('.git/..', expand('%:p:h') . ';')
      let l:project_name = split(l:project_path, '/')[-1]
      let l:branch_name = split(system(join(["git", "-C", expand("%:p:h"), "branch", "--show-current", "--quiet"], " ")), '\n')[0]
    else
      " Dir
      let l:project_parent_dirs = split(getcwd(), '/')
      let l:project_name = l:project_parent_dirs[-2]
      let l:branch_name = l:project_parent_dirs[-1]
    endif
    let l:project_name = substitute(l:project_name, '^\.\+', '', 'g')
    let l:branch_name = substitute(l:branch_name, '^\.\+', '', 'g')
    let l:title = join([l:project_name, l:branch_name], ": ")
  endif

  return l:title
endfunction

function! s:StartNote(...) abort
  let l:title = call('s:GetNoteTitle', a:000)
  let l:filename = s:Slugify(l:title) . ".md"
  let l:filepath = join([g:field_notes_dir, l:filename], '/')

  return l:filepath
endfunction

function! s:LinkNote(...)
  let l:title = call('s:GetNoteTitle', a:000)
  let l:filename = s:Slugify(l:title) . ".md"
  let l:filepath = join(['.', l:filename], '/')

  let l:markdown_text = '![' . a:title . '](' . l:filepath . ')'

  if expand("%:e") == "md"
    call append(line('.'), l:markdown_text)
  endif
endfunction

function! s:GetNoteHeading(...)
  let l:title = call('s:GetNoteTitle', a:000)
  let l:heading = substitute(l:title, '^', '# ', '')
  let l:heading = substitute(l:heading, '$', '\n\n', '')
  return l:heading
endfunction

function! s:InitializeNoteIfNeeded(...)
  if !filereadable(expand('%'))
    call setline(1, split(call('s:GetNoteHeading', a:000), '\n', 1))
    set buftype=
    set nomodified
  endif
endfunction

" TODO Allow a second arg to customize where the `img` directory goes?
" AIDEV-NOTE: Moves image to structured img directory and inserts markdown reference
function! s:MoveImage(...)
  if a:0 == 0
    echo "Error: Target image path required"
    return
  endif

  let l:target_image_path = expand(a:1)

  " Check if target image exists
  if !filereadable(l:target_image_path)
    echo "Error: Target image file does not exist: " . l:target_image_path
    return
  endif

  " Split target image path into components
  let l:target_parent = fnamemodify(l:target_image_path, ':h')
  let l:target_stem = fnamemodify(l:target_image_path, ':t:r')
  let l:target_ext = fnamemodify(l:target_image_path, ':e')

  " Split current filepath into components
  let l:dest_parent = expand('%:p:h')
  let l:dest_stem = expand('%:t:r')
  let l:dest_ext = expand('%:e')

  " Create destination directory structure
  let l:img_subdir = s:Slugify(l:dest_stem)
  let l:dest_dir = join([l:dest_parent, 'img', l:img_subdir], '/')

  " Create directory if it doesn't exist
  if !isdirectory(l:dest_dir)
    call mkdir(l:dest_dir, 'p')
  endif

  " Create destination file path
  let l:slugified_target_stem = s:Slugify(l:target_stem)
  let l:dest_filename = l:slugified_target_stem . '.' . l:target_ext
  let l:dest_path = join([l:dest_dir, l:dest_filename], '/')

  " Copy the image file
  let l:copy_cmd = 'cp "' . l:target_image_path . '" "' . l:dest_path . '"'
  let l:result = system(l:copy_cmd)
  if v:shell_error != 0
    echo "Error copying file: " . l:result
    return
  endif

  " Create relative path for markdown
  let l:relative_path = join(['./img', l:img_subdir, l:dest_filename], '/')

  " Insert markdown image reference below current line
  let l:markdown_text = '![' . l:target_stem . '](' . l:relative_path . ')'
  call append(line('.'), l:markdown_text)

  echo "Image moved to: " . l:dest_path
endfunction

" Installing Write on Linux:
" ```
" wget https://www.styluslabs.com/download/write-tgz
" mkdir -p ~/.local/opt
" mv write-latest.tar.gz ~/.local/opt
" cd ~/.local/opt
" tar xzfv write-latest.tar.gz
" cd Write
" sudo ./setup.sh
" xdg-mime default Write.desktop image/svg+xml
" ```

" Installing Write on MacOS
" ```
" brew install write
" brew install duti
" duti -s $(osascript -e 'id of app "Write"') .svg all
" duti -s $(osascript -e 'id of app "Write"') .svgz all
" ```

function! s:NewDiagram(...)
  let l:title = join(a:000, " ")

  if len(l:title) == 0
    let l:title = strftime("%Y_%m_%d_%H%M")
  endif

  " Split current filepath into components
  let l:dest_parent = expand('%:p:h')
  let l:dest_stem = expand('%:t:r')
  let l:dest_ext = expand('%:e')

  " Create destination directory structure
  let l:img_subdir = s:Slugify(l:dest_stem)
  let l:dest_dir = join([l:dest_parent, 'img', l:img_subdir], '/')
  let l:dest_filename = s:Slugify(l:title). ".svg"
  let l:dest_path = join([l:dest_dir, l:dest_filename], '/')

  " Create directory if it doesn't exist
  if !isdirectory(l:dest_dir)
    call mkdir(l:dest_dir, 'p')
  endif

  " Make target image name: img_name=`expand('%:t:r') . '_' . slugify(diagram_name) .  '.ext'`
  let l:filename = s:Slugify(l:title) . ".svg"

  " Get the template path
  let l:template_path = join([l:dest_parent, 'templates', "template.svg"], '/')

  " Copy the image file
  let l:copy_cmd = 'cp "' . l:template_path . '" "' . l:dest_path . '"'
  let l:result = system(l:copy_cmd)
  if v:shell_error != 0
    echo "Error copying file: " . l:result
    return
  endif

  " Create relative path for markdown
  let l:relative_path = join(['./img', l:img_subdir, l:dest_filename], '/')

  " Insert markdown image reference below current line
  let l:markdown_text = '![' . l:title . '](' . l:relative_path . ')'
  call append(line('.'), l:markdown_text)

  echo "Created new canvas at: " . l:dest_path
endfunction

" AIDEV-NOTE: Adds Hugo front matter to blog post based on first heading
function! s:BlogHeader() abort
  " Find the first line that starts with '# '
  let l:title = ""
  let l:heading_line_num = 0
  let l:line_count = line('$')

  for l:line_num in range(1, l:line_count)
    let l:line_content = getline(l:line_num)
    if l:line_content =~# '^# '
      " Extract the text after '# '
      let l:title = substitute(l:line_content, '^# ', '', '')
      let l:heading_line_num = l:line_num
      break
    endif
  endfor

  if len(l:title) == 0
    echo "Error: No heading found (line starting with '# ')"
    return
  endif

  " Format the date string (ISO 8601 with timezone)
  let l:date_str = strftime('%Y-%m-%dT%T%z')
  " Insert colon in timezone offset: +0000 -> +00:00
  let l:date_str = substitute(l:date_str, '\([+-]\d\d\)\(\d\d\)$', '\1:\2', '')

  " Create the front matter lines
  let l:front_matter = [
    \ "+++",
    \ "date = '" . l:date_str . "'",
    \ "draft = true",
    \ "title = '" . l:title . "'",
    \ "+++"
  \ ]

  " Insert at the top of the file
  call append(0, l:front_matter)

  " Remove the original heading line (adjust line number for inserted front matter)
  let l:adjusted_line_num = l:heading_line_num + len(l:front_matter)
  execute l:adjusted_line_num . 'delete'

  echo "Added blog header with title: " . l:title
endfunction

command! -nargs=* -bang Note call s:OpenNote(<bang>0, <q-args>)
command! -nargs=* -bang Notes call s:OpenNotesDir(<bang>0)

function! s:OpenNote(bang, args)
    let l:split_cmd = a:bang ? 'edit' : 'split'
    let l:vert_prefix = g:field_notes_vert ? 'vert' : ''

    if a:bang
        call s:LinkNote(a:args)
    endif

    let l:note_path = s:StartNote(a:args)
    let l:cmd = 'silent ' . l:vert_prefix . ' ' . l:split_cmd . ' ' . fnameescape(l:note_path)
    execute l:cmd

    call s:InitializeNoteIfNeeded(a:args)
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
command! -nargs=* Diagram call s:NewDiagram(<q-args>)

command! -nargs=* -complete=file_in_path Image call s:MoveImage(<q-args>)

command! -nargs=* Slugify echo s:Slugify(<q-args>)
command! -nargs=1 Link exec "let pos = getpos('.') | norm! :s/" . escape(expand('<cWORD>'), '/\') . "/[" . escape(expand('<cWORD>'), '/\') . "](" . escape(<q-args>, '/\') . ")/<CR> | call setpos('.', pos)"

" Notes
nnoremap <Leader>n :Note<CR>
nnoremap <Leader>N :split \| edit ~/Workspace/repos/field-notes/notes \| lcd %:p:h<CR>


command! BlogHeader call s:BlogHeader()
command! -nargs=1 BlogWrite call s:BlogWrite(<q-args>)

function! s:BlogWrite(subdir)
    let l:subdir = a:subdir
    let l:target = expand(g:blog_content_dir) . '/' .  l:subdir . '/' . expand('%:t')

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
    call s:BlogHeader()
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

    " Transform the string with s:Slugify(string)
    let l:slug = s:Slugify(l:header_text)

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
