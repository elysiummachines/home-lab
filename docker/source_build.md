***Install + Permissions + Lxc***

#### OS: Debian 13 (Trixie)
#### environment: su
#### GPG Keys for different distro: https://download.docker.com/linux/ 

```sh
0) apt-get update && apt-get upgrade -y 'good habit not a step'
1) apt-get install apt-transport-https ca-certificates curl git gnupg lsb-release -y 'All tools needed'
2) install -m 0755 -d /etc/apt/keyrings 'keyrings directory'
3) curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 'offical key'
4) echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null **in my case since docker doesnt support 13 yet I had to add Bookworm repo "echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
5) chmod a+r /etc/apt/keyrings/docker.gpg 'permisions'
6) apt-get update -y
7) apt-get install docker-ce docker-ce-cli containerd.io docker-ce-rootless-extras -y
8) systemctl status docker 'green'
9) docker --version 'Docker version 27.1.1, build 6312585'
10) docker run --privileged hello-world 'on promox this will work with out adding "lxc.apparmor.profile: unconfined" "lxc.cgroup.devices.allow: a" and "lxc.cap.drop:" to the .conf file of lxc'
11) docker network ls  
12) docker ps
```

***Uninstall Docker***
```sh
1) sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-ce-rootless-extras
```
