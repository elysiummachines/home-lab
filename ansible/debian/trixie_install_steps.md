***Package Isolation + Python Virtual Environment + Source List***

```sh
1) sudo apt install python3 python3-pip -y 'can compile your own or package'
2) sudo apt install python3-venv 'Virtual Environment'
3) sudo mkdir /ansible 'or in /opt if you prefer'
4) chmod 740 /ansible 'lock to user or group'
5) sudo chown -R echo:echo /ansible
6) python3 -m venv /ansible/venv 'Create the env'
7) sudo chown -R echo:echo /ansible/venv 'to install packages'
8) export PATH=$PATH:/ansible/bin
9) source /ansible/venv/bin/activate 'Activate the env'
10) pip install ansible
11) pip install --upgrade pip setuptools 'if not updated'
12) ansible --version '[core 2.17.3]'
13) python --version 'Python 3.12.6'
```

***Updating***

```sh
1) source /ansible/venv/bin/activate 'needed each time'
2) pip install --upgrade ansible
3) deactivate
```
