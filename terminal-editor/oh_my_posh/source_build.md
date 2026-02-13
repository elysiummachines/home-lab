# Home brew for Debain

```sh
brew install jandedobbeleer/oh-my-posh/oh-my-posh 
oh-my-posh --version 
oh-my-posh font install 
brew update && brew upgrade oh-my-posh 'should be updated but just in case'
mkdir -p ~/.config 
cp /home/linuxbrew/.linuxbrew/opt/oh-my-posh/themes/paradox.omp.json ~/.config/oh-my-posh.json 
echo 'eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh.json)"' >> ~/.bashrc 
source ~/.bashrc 'should see default theme'
nano ~/.poshthemes/theme-name.json 'needed to create it'
cd ~/.poshthemes 
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip 
unzip themes.zip 
chmod u+rw ~/.poshthemes/*.json 
ls ~/.poshthemes 'should see 100+ themes'
nano ~/.bashrc 'you should see **eval entry**' 
```
