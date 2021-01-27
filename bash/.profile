# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

CONF="$HOME/.config"


# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc from .config if it exists
    if [ -f "$CONF/bash/.bashrc" ]; then
    	. "$CONF/bash/.bashrc"
    # include .bashrc if it exists
    elif [ -f "$HOME/.bashrc" ]; then
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
    sudo /etc/init.d/xrdp start > /dev/null
fi
# == = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 


export VISUAL=vim
export EDITOR="$VISUAL"
export CONF

# virtualenvwrapper stuff
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/code
source $HOME/.local/bin/virtualenvwrapper.sh

export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library/"
