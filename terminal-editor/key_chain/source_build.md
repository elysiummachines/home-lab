***Packages + Dependencies + Permissions***

```sh
1) sudo wget https://github.com/funtoo/keychain/archive/refs/heads/master.zip -O /opt/keychain-master.zip 'prefered location'
2) sudo unzip /opt/keychain-master.zip -d /opt/
3) sudo mv /opt/keychain-master /opt/keychain 'rename for simplicity'
4) sudo chmod +x /opt/keychain/keychain
5) nano ~/.bashrc
6) eval $(/opt/keychain/keychain --eval --agents ssh id_ed25519) 'persistant ssh'
7) source ~/.bashrc
```

***Symbolic Link***

```sh
1) sudo ln -s /opt/keychain/keychain /usr/local/bin/keychain 'must for terminal only'
2) keychain --version
3) which keychain 'should return /usr/local/bin/keychain'
```

