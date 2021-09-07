#!/bin/bash

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

CONF="$HOME/.config"


export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

#Add cargo to path for Rust stuff
export PATH="$HOME/.cargo/bin:$PATH"

# load api keys
if [ -f "$HOME/.api_keys" ] ; then
    . "$HOME/.api_keys"
fi

#source local anacron (https://askubuntu.com/questions/235089/how-can-i-run-anacron-in-user-mode)
if [ -f "$HOME/.anacron/etc/anacrontab" ] ; then
    /usr/sbin/anacron -s -t $HOME/.anacron/etc/anacrontab -S $HOME/.anacron/spool
fi

# detect when running in wsl  = = = = = = = = = = = = = = = = = = = = 
kernel=`uname -r`
variant=${kernel:9}

if [ $variant == 'microsoft-standard' ]; then
    export win_home="/mnt/c/Users/dclayton/"
    export onedrive="/mnt/c/Users/dclayton/'OneDrive - Bluegrass Cellular'/"
    export desktop="/mnt/c/Users/dclayton/'OneDrive - Bluegrass Cellular'/Desktop/"
fi
# == = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 

/usr/bin/setxkbmap -option "ctrl:nocaps"


export VISUAL=vim
export EDITOR="$VISUAL"
export CONF

# virtualenvwrapper stuff
# export WORKON_HOME=$HOME/.virtualenvs
# export PROJECT_HOME=$HOME/code
# source $HOME/.local/bin/virtualenvwrapper.sh

# man page syntax highlighting via bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export PATH="$HOME/.poetry/bin:$PATH"

# export PATH="$HOME/go/bin/"

export STARSHIP_CONFIG="$HOME/.config/starship/config.toml"

eval "$(pyenv init --path)"
