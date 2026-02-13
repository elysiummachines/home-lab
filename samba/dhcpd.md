### ISC DHCP Server + DHCP Reservation

```sh
dnf install dhcp-server
nano /etc/dhcp/dhcpd.conf

default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

subnet 0.0.0.0 netmask 255.255.255.0 {
  range 0.0.0.0 0.0.0.0;
  option routers 0.0.0.0;
  option subnet-mask 0.0.0.0;
  option domain-name-servers 0.0.0.0;
  option domain-name "elysium";
  option domain-search "elysium";
}

host device1 {
  hardware ethernet #MAC#;
  fixed-address #ip#;
}

systemctl enable dhcpd
systemctl start dhcpd
systemctl status dhcpd 'see clients leases'
```