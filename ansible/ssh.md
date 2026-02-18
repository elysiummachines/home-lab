***ED-SSH-PUB***
```bash
1) ssh-keygen -t ed25519 -C "your_email@example.com"
2) chmod 700 ~/.ssh 
3) chmod 600 ~/.ssh/id_ed25519
4) chmod 644 ~/.ssh/id_ed25519.pub
5) ssh-copy-id -i ~/.ssh/id_ed25519.pub root@HS01.alprojects.tech
6) ssh-copy-id -i ~/.ssh/id_ed25519.pub root@HS02.alprojects.tech
```

***Passphrase add***
```bash
1) eval $(ssh-agent)
2) ssh-add ~/.ssh/id_ed25519 **will be prompted to enter the passphrase**
3) ssh-add -l
```
