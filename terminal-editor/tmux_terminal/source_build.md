***tmux + Compile + Path + Sessions + pkgs/dependencies***

```sh
1) apt-get install git autoconf automake libtool pkg-config libevent-dev ncurses-dev build-essential -y 'Debian distros'
2) dnf install git autoconf automake libtool pkgconf libevent-devel ncurses-devel gcc make -y 'RHEL distros'
3) apt-get install bison 'LXC/Docker needs yacc, which is a parser generator and is often required for building software from source'
4) git clone https://github.com/tmux/tmux.git 'Repo'
5) cd tmux 'ls -lah always, get use to structures'
6) ./autogen.sh 'runs autotools commands, generates configuration scripts, checks dependencies'
7) ./configure 'system Inspection, generate Makefiles, configuration options'
8) make -j6
9) make install
10) ls -l /usr/local/bin/ 'htop tmux should be present, skip steps'
11) echo 'export PATH=/usr/local/bin:$PATH' >> ~/.profile
12) source ~/.profile 
13) tmux -V
14) tmux 'green banner session'
15) cd /tmux   
16) git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
17) git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect 
18) Ctrl+a I 'install plugins, terminal pointer should blink'
19) ls ~/.tmux/plugins/ 'should get tpm & tmux-resurrect'
20) while read -r cmd; do history -s "$cmd"; done < ~/.bash_history 'bash history loop'
```