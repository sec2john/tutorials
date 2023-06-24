Steps (from scratch)

1- Install zsh https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH 

2- Install oh-my-zsh https://github.com/ohmyzsh/ohmyzsh

3- Install Theme powerlevel10K https://github.com/romkatv/powerlevel10k#oh-my-zsh

4- Run Powerlevel10K wizard by enterint in zsh in new console.

5- Tmux (version 3+)

6- Descargarse tmux.conf from sec2john repo:

https://github.com/sec2john/tutorials/tree/main/zsh+tmux

7- ponerlo en la carpeta local, renombrar a archivo oculto

8- Configurar el teminal Mate -> /bin/zsh
   # hacer zsh shell por defecto
   chsh -s $(which zsh)

9- Configurar .zshrc añadiendo la linea al principio del todo: 

if [ "$TMUX" = "" ]; then tmux; fi
De no hacerse provoca problemas de inclusion de sesiones TMUX unas dentro
de otras
