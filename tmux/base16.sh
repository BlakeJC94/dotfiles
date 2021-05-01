# Base16 Styling Guidelines:

#base00=default   # - Default
#base01='#151515' # - Lighter Background (Used for status bars)
#base02='#202020' # - Selection Background
#base03='#909090' # - Comments, Invisibles, Line Highlighting
#base04='#505050' # - Dark Foreground (Used for status bars)
#base05='#D0D0D0' # - Default Foreground, Caret, Delimiters, Operators
#base06='#E0E0E0' # - Light Foreground (Not often used)
#base07='#F5F5F5' # - Light Background (Not often used)
#base08='#AC4142' # - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
#base09='#D28445' # - Integers, Boolean, Constants, XML Attributes, Markup Link Url
#base0A='#F4BF75' # - Classes, Markup Bold, Search Text Background
#base0B='#90A959' # - Strings, Inherited Class, Markup Code, Diff Inserted
#base0C='#75B5AA' # - Support, Regular Expressions, Escape Characters, Markup Quotes
#base0D='#6A9FB5' # - Functions, Methods, Attribute IDs, Headings
#base0E='#AA759F' # - Keywords, Storage, Selector, Markup Italic, Diff Changed
#base0F='#8F5536' # - Deprecated, Opening/Closing Embedded Language Tags, e.g. <? php ?>

# Daycula theme
# base00='#1a1d45'  # - Default
# base01='#ff4ea5' # - Lighter Background (Used for status bars1
# base02='#7eb564' # - Selection Background
# base03='#eaad64' # - Comments, Invisibles, Line Highlighting
# base04='#7a89ec' # - Dark Foreground (Used for status bars)
# base05='#b66cdc' # - Default Foreground, Caret, Delimiters, Operators
# base06='#6cac99' # - Light Foreground (Not often used)
# base07='#d7b7bb' # - Light Background (Not often used)
# base08='#323884' # - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
# base09='#ff4ea5' # - Integers, Boolean, Constants, XML Attributes, Markup Link Url
# base0A='#7eb564' # - Classes, Markup Bold, Search Text Background
# base0B='#eaad64' # - Strings, Inherited Class, Markup Code, Diff Inserted
# base0C='#7a89ec' # - Support, Regular Expressions, Escape Characters, Markup Quotes
# base0D='#b66cdc' # - Functions, Methods, Attribute IDs, Headings
# base0E='#6cac99' # - Keywords, Storage, Selector, Markup Italic, Diff Changed
# base0F='#d7b7bb' # - Deprecated, Opening/Closing Embedded Language Tags, e.g. <? php ?>


# Dracula Color Pallette
white='#f8f8f2'
gray='#44475a'
dark_gray='#282a36'
light_purple='#bd93f9'
dark_purple='#6272a4'
cyan='#8be9fd'
green='#50fa7b'
orange='#ffb86c'
red='#ff5555'
pink='#ff79c6'
yellow='#f1fa8c'


set -g status-left-length 32
set -g status-right-length 150
set -g status-interval 5

# default statusbar colors
set-option -g status-style fg=$cyan,bg=default

set-window-option -g window-status-style fg=$light_purple
# set-window-option -g window-status-style fg=$base0C,bg=$base00
set-window-option -g window-status-format " #I #W"

# active window title colors
set-window-option -g window-status-current-style fg=$orange
set-window-option -g window-status-current-format " #I #[bold]#W"

# pane border colors
set-window-option -g pane-active-border-style fg=$light_purple
set-window-option -g pane-border-style fg=$light_purple

# message text
set-option -g message-style bg=$dark_gray,fg=$yellow

# pane number display
set-option -g display-panes-active-colour $dark_purple
set-option -g display-panes-colour $pink

# clock
set-window-option -g clock-mode-colour $dark_purple

tm_session_name="#[default,fg=$cyan] #S "
set -g status-left "$tm_session_name"

# tm_tunes="#[bg=$base00,fg=$base0D] ♫ #(osascript -l JavaScript ~/.dotfiles/applescripts/tunes.js)"
# "tm_battery="#[fg=$base0F,bg=$base00] ♥ #(battery)"

tm_date="#[default,fg=$green] %R"
tm_host="#[fg=$pink,bg=default] #h "
set -g status-right "$tm_date $tm_host"
