***Home-brew + Permission fix + bashrc***

```sh
1) cp ~/.bashrc ~/.bashrc.backup  'always backup'
2) apt install build-essential curl file git 
3) /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
4) chown -h ms01:ms01 /home/ms01/.bashrc
5) chown -R ms01:ms01 /home/linuxbrew/.linuxbrew  
6) chmod 644 /home/ms01/.bashrc 
7) su ms01
8) echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc 'SYMLINK error, follow next 3 steps'
9) sudo rm /home/ms01/.bashrc  
10) sudo touch /home/ms01/.bashrc 
11) sudo chown ms01:ms01 /home/ms01/.bashrc 'must be sudoer'
12) source ~/.bashrc 
13) brew --version '4.3.10 for me''
```
