# Only enable graphical askpass when a display exists
if [ -n "$DISPLAY" ]; then
    export SSH_ASKPASS=/usr/libexec/openssh/gnome-ssh-askpass
else
    unset SSH_ASKPASS
    #export GIT_TERMINAL_PROMPT=1       # TODO: if git gives some graphical prompts, try uncommenting this. Otherwise, SSH_ASKPASS might be enough
fi