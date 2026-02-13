Linux FW + SSH Configuration: 

```sh
1) semanage port -a -t ssh_port_t -p tcp 4193 
2) semanage port -l | grep ssh or semanage port -l | grep ssh_port_t 
3) systemctl restart sshd 
4) systemctl status sshd 
5) systemctl stop firewalld 
6) systemctl mask firewalld **logout/login + new port**
7) dnf install iptables-services -y 
8) systemctl start iptables
9) systemctl enable iptables 
10) nano /etc/sysconfig/iptables 
    # 
    # Allow Samba, DNS, DHCP Access 
    -A INPUT -p tcp  -s 0.0.0.0/24 -m state --state NEW -m multiport --dports 53,88,135,139,389,445,464,636,3268,49152:65535 -j ACCEPT 
    -A INPUT -p udp -s 0.0.0.0/24 -m state --state NEW -m multiport --dports 53,123,137,138,389,636 -j ACCEPT 
    # 
    # Allow/Drop for SSH IP Addresses 
    -A INPUT -p tcp -s 0.0.0.0/32 --dport 4193 -m state --state NEW -j ACCEPT 
    # 
    #DROP is more security focused REJECT gives away to much info 
    -A INPUT -p tcp --dport 22 -j DROP  
    #
11) systemctl restart iptables 
12) systemctl restart sshd 'logout/login'
```