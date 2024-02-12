#!/bin/bash

# Change the IPs of the server(ISP in the box) and the client device
# The tunnel IP should be in th same subnet as the client device
NS1="namespace1"
NS2="namespace2"
clientIP='169.222.11.xx'
ServerIP='128.111.aa.aa'
TunnelIP='192.168.11.1/30'

#########################################################################
# Create the GRE tunnel and the namespace and configure the GRE tunnel
sudo iptunnel add gre1 mode gre remote $clientIP local $ServerIP ttl 255
ip netns add $NS1
ip link set gre1 netns $NS1
ip netns exec $NS1 ip addr add $TunnelIP dev gre1
ip netns exec $NS1 ip link set gre1 up

# Create veth pairs and assign IPs to the interfaces
ip link add veth1 type veth peer name veth2
ip addr add 172.16.1.2/30 dev veth2
ip link set veth2 up

# Assign the veth1 interface to the namespace and configure the namespace
ip link set veth1 netns $NS1
ip netns exec $NS1 ip addr add 172.16.1.1/30 dev veth1
ip netns exec $NS1 ip link set veth1 up
ip netns exec $NS1 ip route add default via 172.16.1.2

# Enable IP forwarding and configure the NAT and DNS, this part is not neccessary 
# if you are connecting it to namespace2, it is just for unit testing
iptables -t nat -A POSTROUTING -o eno2 -j MASQUERADE
ip netns exec $NS1 sed -i '1s/^/nameserver 8.8.8.8\n /' /etc/resolv.conf
# Use next line to test the first namespace works correctly, but then remove it
# ip route add 192.168.11.0/24 via 172.16.1.1
# If the client setup is correct, the next line would use GRE tunnel and NS1 to 
# connect to the internet
# ping 8.8.8.8

###########################################################################
# Create the second namespace and configure the veth pairs and the namespace
ip netns add $NS2
# This veth pair is used to connect the second namespace to the first namespace
ip link add veth3 type veth peer name veth4
# This veth pair is used to connect the second namespace to the main space
ip link add veth5 type veth peer name veth6
ip addr add 172.16.2.2/30 dev veth4
ip addr add 172.16.3.2/30 dev veth6
ip link set veth4 up
ip link set veth6 up
ip link set veth3 netns $NS2
ip link set veth5 netns $NS2

ip netns exec $NS2 ip addr add 172.16.2.1/30 dev veth3
ip netns exec $NS2 ip addr add 172.16.3.1/30 dev veth5
ip netns exec $NS2 ip link set veth3 up
ip netns exec $NS2 ip link set veth5 up

# Configuring NAT and DNS inside the namespace2 to connect to the internet. 
# It is better to use NAT here rather than on the main space physical interface
ip netns exec $NS2 ip route add default via 172.16.3.2
iptables -t nat -A POSTROUTING -o eno2 -j MASQUERADE
ip netns exec $NS2 iptables -t nat -A POSTROUTING -o eno2 -j MASQUERADE
ip netns exec $NS2 sed -i '1s/^/nameserver 8.8.8.8\n /' /etc/resolv.conf

# Routing configurations to route the dat between two namespaces
ip netns exec $NS1 ip route del default dev veth1 via 172.16.1.2
ip netns exec $NS1 ip route add default dev veth2
ip netns exec $NS2 ip route add 172.16.1.0/30 dev veth3
ip netns exec $NS2 ip route change default via 172.16.3.2 dev veth5

# Increasing the number of queues for the veth interfaces
ethtool -L veth2 tx 64 rx 64
ethtool -L veth4 tx 64 rx 64

# If not using xdp bridge, then use the following lines to create a linux bridge
# In case of using xdp bridge, the bridge should be deleted
BR='LibreBridge'
ip link add $BR type bridge
ip link set dev veth2 master $BR
ip link set dev veth4 master $BR
ip link set dev $BR up