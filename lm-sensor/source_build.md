***Lm-sensors Compile + Path + pkgs/dependencies***

```sh 
1) apt install git build-essential libtool autotools-dev autoconf automake lm-sensors bison flex libc-bin -y 'Debian distros'
2) dnf install git gcc make libtool autoconf automake lm_sensors -y 'RHEL distros'
3) dnf groupinstall "Development Tools" -y 'comprehensive but more for development'
4) git clone https://github.com/lm-sensors/lm-sensors.git 'repo'
5) cd lm-sensors
6) export PATH=/usr/local/bin:$PATH  
7) make -j6  './autogen.sh or ./configure is not needed, project has a simplified build process compared to other projects'
8) make install
9) ldconfig 'library cache update'
10) sensors-detect 'select properly'
11) sensors -v 
12) nano /scripts/format_sensors.sh 'please see .sh script'
13) chmod +x /scripts/format_sensors.sh 
14) watch -n2 /scripts/format_sensors.sh 'should see landscape format'
```
