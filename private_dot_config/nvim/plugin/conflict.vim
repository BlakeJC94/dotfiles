 command! -nargs=0 ConflictMarkerThemselves     call conflict_marker#themselves()
command! -nargs=0 ConflictMarkerOurselves      call conflict_marker#ourselves()
command! -nargs=0 -bang ConflictMarkerBoth     call conflict_marker#compromise(<bang>0)
command! -nargs=0 ConflictMarkerNone           call conflict_marker#down_together()
command! -nargs=0 -bang ConflictMarkerNextHunk call conflict_marker#next_conflict(<bang>0)
command! -nargs=0 -bang ConflictMarkerPrevHunk call conflict_marker#previous_conflict(<bang>0)

nnoremap <silent><Plug>(conflict-marker-themselves) :<C-u>ConflictMarkerThemselves<CR>
nnoremap <silent><Plug>(conflict-marker-ourselves)  :<C-u>ConflictMarkerOurselves<CR>
nnoremap <silent><Plug>(conflict-marker-both)       :<C-u>ConflictMarkerBoth<CR>
nnoremap <silent><Plug>(conflict-marker-both-rev)   :<C-u>ConflictMarkerBoth!<CR>
nnoremap <silent><Plug>(conflict-marker-none)       :<C-u>ConflictMarkerNone<CR>
nnoremap <silent><Plug>(conflict-marker-next-hunk)  :<C-u>ConflictMarkerNextHunk<CR>
nnoremap <silent><Plug>(conflict-marker-prev-hunk)  :<C-u>ConflictMarkerPrevHunk<CR>

nmap <buffer>]x <Plug>(conflict-marker-next-hunk)
nmap <buffer>[x <Plug>(conflict-marker-prev-hunk)
nmap <buffer>ct <Plug>(conflict-marker-themselves)
nmap <buffer>co <Plug>(conflict-marker-ourselves)
nmap <buffer>cn <Plug>(conflict-marker-none)
nmap <buffer>cb <Plug>(conflict-marker-both)
nmap <buffer>cB <Plug>(conflict-marker-both-rev)
