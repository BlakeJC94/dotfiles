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
set -g @base0C "#8EC07C" # bright_aqua
set -g @base0D "#83A598" # bright_blue
set -g @base0E "#D3869B" # bright_purple
set -g @base0F "#D65D0E" # neutral_orange

# Window mode style (e.g. copy mode)
set-option -wg mode-style bg="#{@base0B}",fg="#{@base01}"

# Statusbar colors
set-option -g status-style bg="#{@base00}",fg="#{@base04}"

# Window status styles
set-option -wg window-status-style bg="#{@base01}",fg="#{@dark4}"
set-option -wg window-status-activity-style bg="#{@base01}",fg="#{@base04}"
set-option -wg window-status-bell-style bg="#{@base01}",fg="#{@base09}"
set-option -wg window-status-current-style bg="#{@base09}",fg="#{@base01}"

# Window background styles
set -g window-active-style bg="#{@base00}"
set -g window-style bg="#202223"  # dark00: fallback inline color

# Pane borders
set-option -g pane-border-lines heavy
set-option -g pane-active-border-style bg="#{@base00}",fg="#{@base00}"
set-option -g pane-border-style bg="#{@base00}",fg="#{@base00}"

# Message and command display styles
set-option -g message-style bg="#{@base0B}",fg="#{@base01}"
set-option -g message-command-style bg="#{@base04}",fg="#{@base01}"

# Copy mode highlighting (tmux >= 3.2)
%if #{>=:#{version},3.2}
    set-option -wg copy-mode-match-style "bg=#{@base0A},fg=#{@base01}"
    set-option -wg copy-mode-current-match-style "bg=#{@base04},fg=#{@base01}"
%endif

# Statusbar layout
set-option -g status-position bottom


# Left status: session name with prefix indicator
set-option -g status-left "\
#[bg=#{@base04}, fg=#{@base01}]\
#{?client_prefix,#[bg=#{@base0D}],#[bg=#{@base04}]}\
 #{session_name} \
#[bg=#{@base00},fg=#{@base04},nobold,noitalics,nounderscore]\
#{?client_prefix,#[fg=#{@base0D}],#[fg=#{@base04}]}\
#[bg=#{@base00}, fg=#{@base00}]\
 \
"

# Current window in status line
set-option -wg window-status-current-format "\
#[bg=#{@base01},fg=#{@base00},nobold,noitalics,nounderscore]\
#[bg=#{@base0D}, fg=#{@base01}]\
#{?window_zoomed_flag,#[fg=#{@base01}],#[fg=#{@base01}]}\
 #{window_index} #{window_name} \
#[bg=#{@base00}, fg=#{@base00}]\
"

# Inactive windows
set-option -wg window-status-format "\
#[bg=#{@base02}, fg=#{@base04},noitalics]\
#{?window_zoomed_flag,#[fg=#{@base04} bold],#[fg=#{@base04}]}\
 #{window_index} #{window_name} \
#[bg=#{@base00},fg=#{@base01},noitalics]\
"

# Right status: date and time
set-option -g status-right "\
#[fg=#{@base01} nobold, nounderscore, noitalics]\
#[bg=#{@base04}, fg=#{@base01}]\
 %Y-%m-%d │ %H:%M \
"
