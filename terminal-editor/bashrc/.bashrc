# ssh_collection
alias compose_now='ssh -o IdentitiesOnly=yes -i ~/.ssh/keys/compose/id_ed25519 user@address.com -p '
alias compose_now2='ssh -o IdentitiesOnly=yes -i ~/.ssh/keys/compose/id_ed25519 user@address.com -p '
alias compose_now3='ssh -o IdentitiesOnly=yes -i ~/.ssh/keys/compose/id_ed25519 user@address.com -p '
alias sshaddk='ssh-add ~/.ssh/keys/compose/id_ed25519'

# packages_collection
alias update_dist='sudo apt-get update && sudo apt-get dist-upgrade -y'
alias update_full='sudo apt-get update && sudo apt-get upgrade -y' 
alias clean='sudo apt autoremove && sudo apt autoclean -y'
alias search_pkg='apt-cache search'
alias update='sudo apt update -y'

# go_to_collection
alias gotow='cd /home/echo/.local/share/warp-terminal/themes'
alias goton='sudo nano ~/.config/neofetch/config.conf'
alias gotos='sudo nano ~/.config/starship.toml'
alias gotoh='cd /repo/homelab/home-lab/'
alias gotohtl='cd /var/www/html'
alias gotologs='cd /var/log'

# git_collection
alias gitge='git config --global user.email alporjects1@proton.me'
alias gshortlog='git log --oneline --decorate --graph --all'
alias gitgu='git config --global user.name LR03'
alias gplm='git pull --rebase origin main'
alias gpld='git pull --rebase origin dev'
alias gundo='git reset --soft HEAD~1'
alias gphm='git push origin main'
alias gphd='git push origin dev'
alias gpl='git pull --rebase'
alias gfo='git fetch origin'
alias glog='git log -p -1'
alias gcm='git commit -m'
alias gco='git checkout'
alias gst='git status'
alias gcl='git clone'
alias gaa='git add .'

# directory_collection
alias ....='cd ../../../../../../../../../../../../../..'
alias ...='cd ../..'
alias home='cd ~'
alias ..='cd ..'

# find_it_collection
alias findext='find . -type f -name "*."'
alias findit='find . -name 2>/dev/null'
alias finddir='find . -type d -name'
alias find='find . -name'

# misc
alias bkupbashrc='cp ~/.bashrc ~/.bashrc.$(date +%Y%m%d%H%M%S).bak'
alias dms='sudo ./scripts/clean_memory.sh'
alias cms='free -m -l -t'
alias df='df -h'
#
alias ping='ping -c 5'
alias netstat='netstat -tuln'
alias nettop='sudo nethogs'
#
alias rm='rm -i'
alias rmd='sudo rm -rf'
alias cls='clear        '

# list_collection
alias ll='ls -liha'
alias lmd='ls -lt'
alias la='ls -A'
alias l='ls -CF'

# function_it_collection
huntit() {
    sudo find / -name "$1*" 2>/dev/null
}

killit() {
    echo "You sure you want to kill processes matching '$1'? (y/n)"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        pkill -f "$1"
    else
        echo "Aborted."
    fi
}

backit() {
    src="$1"
    dest="$2"
    filename=$(basename "$src")

    if [ -z "$src" ] || [ -z "$dest" ]; then
        echo "Usage: backit /path/to/source /path/to/backup/destination"
        return 1
    fi

    if [ ! -e "$src" ]; then
        echo "Source path does not exist."
        return 1
    fi

    if [ ! -d "$dest" ]; then
        echo "Destination must be a directory."
        return 1
    fi

    tar -czvf "$dest/$filename-$(date +%Y%m%d%H%M%S).tar.gz" "$src"
}

sendit() {
    src="$1"
    dest="$2"

    if [ -z "$src" ] || [ -z "$dest" ]; then
        echo "Usage: sendit /path/to/source user@remote:/path/to/destination"
        return 1
    fi

    if [ ! -e "$src" ]; then
        echo "Source path does not exist."
        return 1
    fi

    if ! command -v rsync >/dev/null; then
        echo "rsync is not installed. Please install it first."
        return 1
    fi

    rsync -avh --progress "$src" "$dest"
}
