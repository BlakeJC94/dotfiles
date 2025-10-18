
" =====
let g:llm_vert = v:false
let g:llm_state = {
      \ 'progress_timer': v:null,
      \ 'awaiting_response': v:false,
      \ }

command! -range -nargs=* LLM call LLM(<line1>, <line2>, <q-mods>, <q-args>)

function! LLM(start_line, end_line, mods, args)
    let current_bufnr = bufnr('%')
    let bufnr = OpenLLMBuffer()
    normal! ggdG

    let job_opts = GetJobOpts(a:start_line, a:end_line, current_bufnr, bufnr)
    call RunLLM(a:args, job_opts)
endfunction

" =====
"
"
func! OpenLLMBuffer()
    let scratch_buffer_name = '[LLM]'

    " Check if a buffer with the scratch name already exists
    let l:bufnr = bufnr(scratch_buffer_name)

    " If the buffer exists and is in a window
    if l:bufnr != -1 && bufwinnr(l:bufnr) != -1
        " Go to the existing window if it's already open
        exec bufwinnr(l:bufnr) . 'wincmd w'
        " Ensure the buffer is focused within that window (useful if multiple buffers are in the same split)
        exec 'buffer ' . l:bufnr
        return l:bufnr
    endif

    " If the buffer exists but is not in a window, or if it doesn't exist
    if l:bufnr == -1
        " Create a new buffer if it doesn't exist
        exec 'new ' . scratch_buffer_name
        let l:bufnr = bufnr('%') " Get the buffer number of the newly created buffer
    else
        " Open the existing buffer in a new split
        exec 'new'
        exec 'buffer ' . l:bufnr
        let l:bufnr = l:bufnr
    endif

    " Set options for the scratch buffer
    setlocal buftype=nofile       " Not associated with a file
    setlocal bufhidden=wipe       " Wipe on close
    setlocal filetype=markdown    " Set filetype (optional, useful for syntax highlighting plugins)
    setlocal noswapfile          " No swap file
    setlocal nobuflisted         " Don't list in buflist
    setlocal noundofile          " Don't save to undofile
    setlocal foldcolumn=0         " No fold column
    setlocal signcolumn=no       " No sign column

    return l:bufnr
endfunc


function! GetJobOpts(start_line, end_line, current_bufnr, bufnr)
    let job_opts = {
        \ 'pty': v:true,
        \ 'out_io':'buffer',
        \ 'out_buf': a:bufnr,
        \ 'err_io':'buffer',
        \ 'err_buf': a:bufnr,
        \ }
    " Is current mode visual? (V, v, Ctrl-v) or are the strta/end lines given
    if mode() =~? '^[vV\x16]$' || a:start_line != a:end_line
      let job_opts['in_io'] = 'buffer'
      let job_opts['in_buf'] = a:current_bufnr
      let job_opts['in_top'] = a:start_line
      let job_opts['in_bot'] = a:end_line
    end
    return job_opts
endfunction


function! RunLLM(prompt, job_opts)
    let cmd = 'llm ' . a:prompt
    call job_start(cmd, a:job_opts)
endfunction

" =====
