### Samba Users & Groups  + DB+ Shares

```sh
1) samba-tool user create echo Word1234 --given-name='Heffy' --surname='moef' --must-change-at-next-login 
2) pdbedit -L 'Samba user database' 
3) samba-tool user list 'basic view compared to pdbedit' 
4) samba-tool group list 'you should see the same in RSAT'
5) samba-tool group show Users 'specific Samba group' 
6) pdbedit -L -v echo 'specific Samba user' 
7) mkdir -p /usr/local/samba/var/locks/sysvol/alprojects.tech/APPS 
8) mkdir -p /usr/local/samba/var/locks/sysvol/alprojects.tech/SHARES 
9) chown root:3000000 /usr/local/samba/var/locks/sysvol/alprojects.tech/APPS 
10) chown root:3000000 /usr/local/samba/var/locks/sysvol/alprojects.tech/SHARES 
11) chmod 770 /usr/local/samba/var/locks/sysvol/alprojects.tech/APPS 'If not already' 
12) chmod 770 /usr/local/samba/var/locks/sysvol/alprojects.tech/SHARES 'If not already'
```