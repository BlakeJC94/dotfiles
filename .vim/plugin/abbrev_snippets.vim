iabbrev <expr> @@D strftime('%Y-%m-%d %a')
iabbrev <expr> @@T strftime('%Y-%m-%dT%T%z')[:21] . ':00'

inoreabbrev <expr> xxtoday "strftime(\"%Y-%m-%d %a\", localtime() + (0 * 86400))"
inoreabbrev <expr> xxyesterday strftime("%Y-%m-%d %a", localtime() + (-1 * 86400))
inoreabbrev <expr> xxtomorrow strftime("%Y-%m-%d %a", localtime() + (1 * 86400))

inoreabbrev <expr> ,u system('uuidgen')->trim()->tolower()

inoreabbrev rbm # TODO: remove before merging
inoreabbrev cbm # TODO: change before merging
inoreabbrev ubm # TODO: uncomment before merging

" Expand `%%` as current filename in command mode
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" C-q : Code fence in insert mode <>
" inoremap <C-q> <cmd>exec 'norm! i```<C-o>O```<Space>' \| startinsert<CR>
" " C-v : Code block in insert mode <>
" inoremap <C-v> <cmd>exec 'norm! i%%<C-o><Plug>CommentaryLine<C-o>A ' \| startinsert<CR>
