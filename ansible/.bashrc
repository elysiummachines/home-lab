# ansible_collection
alias venv='source /ansible/venv/bin/activate'
alias versiona='ansible --version'
alias pinga='ansible all -m ping'
alias playa='ansible-playbook'
alias listhostsa='ansible all --list-hosts'
alias testsyntaxa='ansible-playbook --syntax-check'
alias checkinva='ansible-inventory --list -y'
alias cmdalla='ansible all -a'
alias playbookv='ansible-playbook -v'
alias clearssh='rm -rf home/echo/.ssh/known_hosts'
alias sshlist='ssh-add -l'
alias restarta='sudo systemctl restart ansible'


# ansible_function_collection
function ansible_update() {
    ansible-playbook -i /ansible/venv/inventory /ansible/venv/playbooks/update-hosts.yaml
}

function ansible_kali() {
    ansible-playbook -i /ansible/venv/inventory /ansible/venv/playbooks/ansible-kali.yaml
}

function ansible_sshd() {
    asnible-playbook  -i /ansible/venv/inventory /ansible/venv/playbooks/ansible-sshd.yaml
}
