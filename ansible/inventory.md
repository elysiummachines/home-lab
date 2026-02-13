# host List 

```sh

[proxmox_nodes]
HS01 ansible_host=HS01.domain ansible_python_interpreter=/usr/bin/python3 ansible_ssh_user=USER_NAME ansible_port=PORT_NUMBER
HS02 ansible_host=HS02.domain ansible_python_interpreter=/usr/bin/python3 ansible_ssh_user=USER_NAME ansible_port=PORT_NUMBER

[domain_controller_nodes]
DC01 ansible_host=DC01.domain ansible_python_interpreter=/usr/bin/python3 ansible_ssh_user=USER_NAME ansible_port=PORT_NUMBER
DC02 ansible_host=DC02.domain ansible_python_interpreter=/usr/bin/python3 ansible_ssh_user=USER_NAME ansible_port=PORT_NUMBER

[all:vars]
ansible_ssh_common_args='-o IdentitiesOnly=yes'
```
