#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

echo 'export TEXMFHOME=/home/rex/07_PRes/02_Latex/tex/latex/pkg' >> ~/.zshrc