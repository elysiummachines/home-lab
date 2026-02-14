***Repo + smb.conf + krb5.conf + Updates***

```sh
1) mv /etc/samba/smb.conf /etc/samba/smb.conf.old 
2) mv /etc/krb5.conf /etc/krb5.conf.old 
3) mkdir -p /samba-4.20.0 
4) cd ../../samba-4.20.0  'was in a home user folder'
5) wget https://download.samba.org/pub/samba/stable/samba-4.20.0.tar.gz 
6) tar -zxf samba-4.20.0.tar.gz 
7) cd samba-4.20.0 
8) dnf install epel-release -y  'installing Enterprise Repo'
9) dnf update -y 
10) dnf config-manager --set-enabled powertools 'on Build 8.6'
11) dnf config-manager --set-enabled crb 'on Build 9.3'
12) dnf repolist 
```
***Packages + Variables + Compile Parameters***

```sh
1) dnf -y install docbook-style-xsl bison flex gcc gdb gnutls-devel jansson-devel keyutils-libs-devel krb5-workstation libacl-devel libaio-devel libattr-devel libblkid-devel libtasn1 libtasn1-tools libxml2-devel
          libxslt openldap-devel pam-devel perl perl-ExtUtils-MakeMaker perl-Parse-Yapp popt-devel python3-cryptography python3-dns python3-gpg python36-devel readline-devel systemd-devel tar zlib-devel json perl-JSON
          lmdb-devel gpgme-devel libarchive-devel dbus-devel python3-markdown python3-pyasn1 rpcgen libtirpc-devel screen python3-devel krb5-devel --skip-broken 
2) find /usr -name "lmdb.h" **should show up**
3)find /usr/include -name "rpc.h" **should show up**
4) export CFLAGS="-I/path/to/lmdb -I/usr/include/tirpc $CFLAGS" **tested with/without**
5) export CPPFLAGS="-I/path/to/lmdb -I/usr/include/tirpc $CPPFLAGS" **good practice to include them**
6) dnf update -y 
7) ./configure --enable-selftest \ --with-piddir=/usr/local/samba/var/run \ --with-privatedir=/usr/local/samba/private \ --with-sockets-dir=/usr/local/samba/var/run \ --with-lockdir=/usr/local/samba/var/locks \ --with-statedir=/usr/local/samba/var \ --with-cachedir=/usr/local/samba/var/cache 
8) make -j6 **6=core count** 
9) make install
10) ls /usr/local/samba/bin **lots of green entries** 
11) ls /usr/local/samba/sbin **line of green entry** 
12) samba -b | grep "CONFIGFILE" ** this will point to where conf is located**
```
***Provisioning + Bash Configuration + Resolv.conf***

```sh
1) export PATH=/usr/local/samba/bin:/usr/local/samba/sbin:$PATH
2) nano /etc/hosts **Made adjustments**
3) nano /etc/resolv.conf **Made adjustments**
4) chattr +i /etc/resolv.conf **Immutable status**
5) samba-tool domain provision --use-rfc2307 --interactive --option="interfaces= lo ens18" --option="bind interfaces only=yes" 
6) samba **start it off**
7) ps -ax | grep samba **long list**
8) chown root:root /usr/local/samba/etc/smb.conf 'if not already'
9) chmod 640 /usr/local/samba/etc/smb.conf  'compiled location'
```
***Testing Configuration Aftermath***

```sh
1) cp /usr/local/samba/private/krb5.conf /etc/krb5.conf 'dont forget to do this'
2) host -t SRV _kerberos._udp.alprojects.tech 'passed'
3) host -t SRV _ldap._tcp.alprojects.tech 'passed'
4) samba-tool dbcheck --cross-ncs 'healthy'
5) host -t A dc01.alprojects.tech 'passed'
6) ping -c3 www.google.ca 'passed'
7) kinit administrator 'logged in'
8) testparm 'passed'
9) klist 'generated ticket'
```
***Chrony + Syslog + Local-7*** 

```sh
1) dnf install chrony -y 'if not installed'
2) systemctl enable chronyd --now 
3) systemctl restart chronyd 
4) systemctl status chronyd 
5) chronyc sources 
6) chronyc tracking
7) nano /etc/chrony.conf 'for accuracy add more than one'
   pool 0.pool.ntp.org iburst 
   pool 1.pool.ntp.org iburst 
   pool 3.pool.ntp.org iburst
8) chronyc ntpdata 'since the last or current time sync' 
9) nano /etc/rsyslog.conf 
   local7.*    /var/log/samba-audit.log 
10) nano /var/log/samba-audit.log 'save and exit'
11) chmod 644 /var/log/samba-audit.log 'if its not already' 
12) systemctl restart rsyslog 
13) tail -f /var/log/samba-audit.log 
14) tail -f /var/log/samba/0.0.0.0.log 'this is present because logging is working correctly' 
15) tail -f /var/log/samba/%m.log 
16) tail -f /var/log/samba/smbd.log 
17) tail -f /var/log/samba/winbindd.log (all tail commands showing normal operation)
```