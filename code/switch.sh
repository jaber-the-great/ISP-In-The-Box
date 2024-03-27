# Basic commands and status check for Cisco Switch
$ conf t
$ show interface status
$ show interface status | include up
$ show mac address-table
$ show ip interface
$ show ip route
$ show run | inc default-gateway
$ show running-config


# Creating VLANs
$ show vlan
(config)# vlan 10
(config)# interface te1/0/1
(config-if)# switchport mode access
(config-if)# switchport access vlan 10
(config-if)# exit

# Assigning IP address to interface
(config)# interfeac te1/0/1
(config-if)# ip address <IP> <mask>
(config-if)# no shutdown
(config-if)# no ip address

# Creating static route
(config)# ip route 192.168.99.0 255.255.255.0 10.0.0.2
(config)# no ip route 192.168.99.0 255.255.255.0

# Creating default gateway
(config)# ip default-gateway <IP>
(config)# no ip default-gateway <IP>









