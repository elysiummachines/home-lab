***Ubount recursive DNS***

```sh
1) apt install unbound
2) nano /etc/unbound/unbound.conf.d/pi-hole.conf **unbound_config.md**
3) service unbound restart
4) dig pi-hole.net @127.0.0.1 -p 5335
5) dig dnssec.works @127.0.0.1 -p 5335 **authority flag should be 1**
6) enter ip into broswer >> gui >> settings >> dns >> in the "Upstream DNS Servers" check "Custom 1 (IPv4)"
7) entered 127.0.0.1#5335 into empty box1
8) below that section you will see "Potentially dangerous options" >> bind it to your nic >> in my case "Respond only on interface eth0"
```
