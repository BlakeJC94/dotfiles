# Source color palette (generated from key=value file)
run-shell -b 'touch ~/.palette && sed "s/^\(.*\)=\(.*\)$/set -g @\1 \2/" ~/.palette > ~/.tmux/colors.tmux'
source-file ~/.tmux/colors.tmux

# Window mode style (e.g. copy mode)
set-option -wg mode-style bg="#{@bright_green}",fg="#{@dark1}"

# Statusbar colors
set-option -g status-style bg="#{@dark0_hard}",fg="#{@light4}"

# Window status styles
set-option -wg window-status-style bg="#{@dark1}",fg="#{@dark4}"
set-option -wg window-status-activity-style bg="#{@dark1}",fg="#{@light4}"
set-option -wg window-status-bell-style bg="#{@dark1}",fg="#{@bright_orange}"
set-option -wg window-status-current-style bg="#{@bright_orange}",fg="#{@dark1}"

# Window background styles
set -g window-active-style bg="#{@dark0_hard}"
set -g window-style bg="#202223"  # dark00: fallback inline color

# Pane borders
set-option -g pane-border-lines heavy
set-option -g pane-active-border-style bg="#{@dark0_hard}",fg="#{@dark0_hard}"
set-option -g pane-border-style bg="#{@dark0_hard}",fg="#{@dark0_hard}"

# Message and command display styles
set-option -g message-style bg="#{@bright_green}",fg="#{@dark1}"
set-option -g message-command-style bg="#{@light4}",fg="#{@dark1}"

# Copy mode highlighting (tmux >= 3.2)
%if #{>=:#{version},3.2}
    set-option -wg copy-mode-match-style "bg=#{@bright_yellow},fg=#{@dark1}"
    set-option -wg copy-mode-current-match-style "bg=#{@light4},fg=#{@dark1}"
%endif

# Statusbar layout
set-option -g status-position bottom


# Left status: session name with prefix indicator
set-option -g status-left "\
#[bg=#{@light4}, fg=#{@dark1}]\
#{?client_prefix,#[bg=#{@bright_blue}],#[bg=#{@light4}]}\
 #{session_name} \
#[bg=#{@dark0_hard},fg=#{@light4},nobold,noitalics,nounderscore]\
#{?client_prefix,#[fg=#{@bright_blue}],#[fg=#{@light4}]}\
#[bg=#{@dark0_hard}, fg=#{@dark0_hard}]\
 \
"

# Current window in status line
set-option -wg window-status-current-format "\
#[bg=#{@dark1},fg=#{@dark0_hard},nobold,noitalics,nounderscore]\
#[bg=#{@bright_blue}, fg=#{@dark1}]\
#{?window_zoomed_flag,#[fg=#{@dark1}],#[fg=#{@dark1}]}\
 #{window_index} #{window_name} \
#[bg=#{@dark0_hard}, fg=#{@dark0_hard}]\
"

# Inactive windows
set-option -wg window-status-format "\
#[bg=#{@dark2}, fg=#{@light4},noitalics]\
#{?window_zoomed_flag,#[fg=#{@light4} bold],#[fg=#{@light4}]}\
 #{window_index} #{window_name} \
#[bg=#{@dark0_hard},fg=#{@dark1},noitalics]\
"

# Right status: date and time
set-option -g status-right "\
#[fg=#{@dark1} nobold, nounderscore, noitalics]\
#[bg=#{@light4}, fg=#{@dark1}]\
 %Y-%m-%d │ %H:%M \
"
