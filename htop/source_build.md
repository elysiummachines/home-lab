***htop/lm-sensors + Compile + Path + pkgs/dependencies***

```sh
1) apt-get install git libncursesw5-dev autotools-dev autoconf libtool pkg-config build-essential lm-sensors libsensors-dev -y 'Debian based distros'
2) dnf install git lm_sensors-devel autoconf automake libtool ncurses-devel gcc make -y 'RHEL based distros'
3) dnf groupinstall "Development Tools" -y **for RHEL, SUSE distros, comprehensive set of development tools and libraries**
4) git clone https://github.com/htop-dev/htop.git 'Repo'
5) cd htop 'ls -lah always, get use to structures'
6) ./autogen.sh 'runs autotools commands, generates configuration scripts, checks dependencies'
7) ./configure 'system Inspection, generate makefiles, set configuration options'
8) make -j$(nproc) 'dynamically fetches cores'
9) make install
10) ls -l /usr/local/bin/ 'should see htop'
11) echo $PATH 'noticed /usr/local/bin/ missing'
12) echo 'export PATH=/usr/local/bin:$PATH' >> ~/.profile 'add path'
13) source ~/.profile 
14) htop --version 'htop 3.4.0-dev-3.3.0-141-g58efa4e'
15) htop
16) cp ~/.config/htop/htoprc ~/.config/htop/htoprc.bak 'backup config'
```