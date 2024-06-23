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

# Creating trunk
(config)# interface te1/0/1
(config-if)# switchport mode trunk
(config-if)# switchport trunk allowed vlan 10,20,30


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


##################### Switch Configuration ############################

# Configuration vlan for server 9 (downstream)
(config)# vlan 11
(config)# interface te1/0/4
(config-if)# switchport mode access
(config-if)# switchport access vlan 11
(config-if)# exit

# Configuration vlan for server 2 (upstream)
(config)# vlan 22
(config)# interface te1/0/3
(config-if)# switchport mode access
(config-if)# switchport access vlan 22
(config-if)# exit

# Configuration trunk for server 10
(config)# interface te1/0/1
(config-if)# switchport mode trunk
(config-if)# switchport trunk allowed vlan 11,22
(config-if)# exit

##################### Server 10 Configuration (LibreQoS) ############################
# Trunk on linux server 10
sudo apt-get install vlan
sudo modprobe 8021q
lsmod | grep 8021q
sudo ip link add link enp216s0f0 name enp216s0f0.100 type vlan id 22
sudo ip addr add 192.168.0.200/24 dev enp216s0f0.100
sudo ip link set up enp216s0f0.100

sudo ip link add link enp216s0f0 name enp216s0f0.200 type vlan id 11
sudo ip addr add 192.168.1.200/24 dev enp216s0f0.200
sudo ip link set up enp216s0f0.200

sudo su -c 'echo "8021q" >> /etc/modules'


# No need for next line   
# ip route add 192.168.99.0/24 dev enp216s0f0.200 via 192.168.1.203

# LibreQoS required this line
ethtool -K enp216s0f0 rxvlan off


##################### LibreQoS config ############################
###### ispConfig.py  ######

# Interface connected to core router
interfaceA = 'enp216s0f0'

# Interface connected to edge router
interfaceB = 'enp216s0f0'

OnAStick = True
# VLAN facing the core router
StickVlanA = 11
# VLAN facing the edge router
StickVlanB = 22
ignoreSubnets = []
allowedSubnets = ['100.64.0.0/10', '192.168.0.0/16']

###### /etc/lqos.conf  ######
# Comment the section for two interface setup 
[bridge]
use_xdp_bridge = true
interface_mapping = [
        { name = "enp216s0f0", redirect_to = "enp216s0f0", scan_vlans = true }
]
vlan_mapping = [
        { parent = "enp216s0f0", tag = 11, redirect_to = 22 },
        { parent = "enp216s0f0", tag = 22, redirect_to = 11 }
]

##################### Server 9 Configuration (Core Router) ############################
# Configuration on server 9:
ip route add 192.168.0.0/24 dev ens2f
# Add table rules for gre traffic
TABLE="mytable"
echo -e "300\t$TABLE" >> /etc/iproute2/rt_tables
ip route add default dev ens2f1 table $TABLE
ip rule add from 192.168.99.0/24 table $TABLE
ip route change default dev ens2f1 via 192.168.0.203 table $TABLE 
##################### Server 2 Configuration (Edge Router) ############################


ip route del 192.168.0.0/24 dev eno2 proto kernel scope link src 192.168.0.203
ip route add 192.168.0.0/16 dev eno2 via 192.168.1.203










