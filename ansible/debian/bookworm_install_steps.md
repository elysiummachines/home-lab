***Path + Permissions + Bashrc***

```sh
1) mkdir /ansible
2) sudo chown echo:echo /ansible 'amake sure user in sudoers group'
3) export ANSIBLE_HOME=/ansible 'set ANSIBLE_HOME environment variable'
4) chmod 740 /ansible 'lock to user or group'
5) export PATH=$PATH:$ANSIBLE_HOME/bin
```

***Dependecies + Codename + PPA*** 

```sh
1) sudo apt install wget gpg
2) UBUNTU_CODENAME=jammy 'on Trixie 13 this will have to do'
3) wget -O- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6125E2A8C77F2818F7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmor -o /usr/share/keyrings/ansible-archive-keyring.gpg 'PPA Key'
4) echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list 'PPA Resource'
5) sudo apt update && sudo apt install ansible
6) ansible --version '[core 2.17.3]'
```
