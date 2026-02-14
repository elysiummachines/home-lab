***Removal + cleanup + Tool removal***

```sh
1) rm -f /usr/local/bin/tmux 'remove tmux binary'
2) apt-get remove --purge git autoconf automake libtool pkg-config libevent-dev ncurses-dev build-essential bison -y 'remove tools on debian'
2) dnf remove git autoconf automake libtool pkgconf libevent-devel ncurses-devel gcc make -y 'remove tools on rhel'
3) apt autoremove -y 
3) dnf autoremove -y
4) rm -rf ~/tmux 'clean up source /'
5) rm -rf ~/.tmux/plugins/tpm
6) rm -rf ~/.tmux/plugins/tmux-resurrect
7) sed -i '/export PATH=\/usr\/local\/bin:\$PATH/d' ~/.profile 'revert PATH changes in ~/.profile'
8) source ~/.profile
9) history -c
```
