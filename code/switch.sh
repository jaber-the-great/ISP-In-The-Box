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



# Trunk on linux server 10
sudo modprobe 8021q
lsmod | grep 8021q
sudo ip link add link enp216s0f0 name enp216s0f0.100 type vlan id 22
sudo ip addr add 192.168.0.200/24 dev enp216s0f0.100
sudo ip link set up enp216s0f0.100


# Configuration on server 9:
192.168.0.0/24 via 192.168.0.200 dev ens2f

# configuration on server 2:
192.168.0.0/24 dev eno2 proto kernel scope link src 192.168.0.203
10.0.0.0/8 via 10.0.0.2 dev eno2 


ip route add default dev eno2 table mytable1
ip route change default dev eno2 via 10.0.0.2 table mytable1
ip rule add from all to 192.168.99.0/24 table mytable1










