# scheme: "Gruvbox dark, hard"
# author: "Dawid Kurek (dawikur@gmail.com), morhetz (https://github.com/morhetz/gruvbox)"
# https://github.com/dawikur/base16-gruvbox-scheme/blob/master/gruvbox-dark-hard.yaml
set -g @base00 "#1D2021" # dark0_hard
set -g @base01 "#3C3836" # dark1 ---
set -g @base02 "#504945" # dark2 --
set -g @base03 "#665C54" # dark3 -
set -g @base04 "#BDAE93" # light3 +
set -g @base05 "#D5C4A1" # light2 ++
set -g @base06 "#EBDBB2" # light1 +++
set -g @base07 "#FBF1C7" # light0_hard ++++
set -g @base08 "#FB4934" # bright_red
set -g @base09 "#FE8019" # bright_orange
set -g @base0A "#FABD2F" # bright_yellow
set -g @base0B "#B8BB26" # bright_green
set -g @base0C "#8EC07C" # bright_aqua/cyan
set -g @base0D "#83A598" # bright_blue
set -g @base0E "#D3869B" # bright_purple
set -g @base0F "#D65D0E" # neutral_orange

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
