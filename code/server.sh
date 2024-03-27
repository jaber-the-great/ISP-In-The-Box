#!/bin/bash

# Change the IPs of the server(ISP in the box) and the client device
# The tunnel IP should be in th same subnet as the client device
# NS1="namespace1"
# NS2="namespace2"
# ClientIP='169.222.11.xx'
# ServerIP='128.111.aa.aa'
# TunnelIP='192.168.11.1/30'
# OutInterface='eno2'
# NumOfQueues=8

NS1="ns1"
NS2="ns2"
ClientIP='169.231.8.224'
ServerIP='128.111.5.228'
TunnelIP='192.168.1.1/30'
OutInterface='eno2'
NumOfQueues=8

#########################################################################
# Install the required packages and modules for gre tunnel
sudo modprobe ip_gre
lsmod | grep gre
sudo apt install iptables iproute2
sudo echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sudo sysctl -p
# Create the GRE tunnel and the namespace and configure the GRE tunnel
sudo iptunnel add gre1 mode gre remote $ClientIP local $ServerIP ttl 255
ip netns add $NS1
ip link set gre1 netns $NS1
ip netns exec $NS1 ip addr add $TunnelIP dev gre1
ip netns exec $NS1 ip link set gre1 up

# Create veth pairs and assign IPs to the interfaces
#sudo ip link add veth1 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 123 type veth peer name veth2 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 124 
ip link add veth1 type veth peer name veth2
ip addr add 172.16.1.2/30 dev veth2
ip link set veth2 up

# Assign the veth1 interface to the namespace and configure the namespace
ip link set veth1 netns $NS1
ip netns exec $NS1 ip addr add 172.16.1.1/30 dev veth1
ip netns exec $NS1 ip link set veth1 up
ip netns exec $NS1 ip route add default via 172.16.1.2

# Configure the NAT(NATing to northbound interface of ISP in the box)
iptables -t nat -A POSTROUTING -o $OutInterface -j MASQUERADE
# Setting the DNS server for the namespace just in case of testing  
ip netns exec $NS1 sed -i '1s/^/nameserver 8.8.8.8\n /' /etc/resolv.conf

###########################################################################
# Create the second namespace and configure the veth pairs and the namespace
ip netns add $NS2
# This veth pair is used to connect the second namespace to the first namespace
#sudo ip link add veth3 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 125 type veth peer name veth4 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 126
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


ip netns exec $NS2 ip route add default via 172.16.3.2
iptables -t nat -A POSTROUTING -o $OutInterface -j MASQUERADE

# Configuring NAT and DNS inside the namespace2 to connect to the internet. 
ip netns exec $NS2 iptables -t nat -A POSTROUTING -o veth5 -j MASQUERADE
ip netns exec $NS2 sed -i '1s/^/nameserver 8.8.8.8\n /' /etc/resolv.conf

# Routing configurations to route the data between two namespaces
ip netns exec $NS1 ip route del default dev veth1 via 172.16.1.2
ip netns exec $NS1 ip route add default dev veth1
ip netns exec $NS1 ip route change default dev veth1 via 172.16.3.1
ip netns exec $NS2 ip route add 172.16.1.0/30 dev veth3
ip netns exec $NS2 ip route change default via 172.16.3.2 dev veth5

# Increasing the number of queues for the veth interfaces, 
# NO need to run it if you are specifying the number of queues in the veth creation
# ethtool -L veth2 tx $NumOfQueues rx $NumOfQueues
# ethtool -L veth4 tx $NumOfQueues rx $NumOfQueues
# ip netns exec $NS1 ethtool -L veth1 tx $NumOfQueues rx $NumOfQueues
# ip netns exec $NS2 ethtool -L veth3 tx $NumOfQueues rx $NumOfQueues
# If not using xdp bridge, then use the following lines to create a linux bridge
# In case of using xdp bridge, the bridge should be deleted
# BR='LibreBridge'
# ip link add $BR type bridge
# ip link set dev veth2 master $BR
# ip link set dev veth4 master $BR
# ip link set dev $BR up

# Adding the routes back to the GRE tunnel
ip route add 192.168.1.0/24 dev veth6 via 172.16.3.1 
ip netns exec $NS2 ip route add 192.168.1.0/24 dev veth3 via 172.16.1.1

# Adding more clients to the server
NS1="namespace1"
NS2="namespace2"
ServerIP='128.111.5.228'
interface='gre2'

newClientIP='169.231.16.247'
# Increament with 4 for the next client
# Do the same for the client device
newTunnelIP='192.168.1.5/30'
sudo iptunnel add $interface mode gre remote $newClientIP local $ServerIP ttl 255
ip link set $interface netns $NS1
ip netns exec $NS1 ip addr add $newTunnelIP dev $interface
ip netns exec $NS1 ip link set $interface up

# Setting up new brdges 
ip link set LibreBridge down
ip link del LibreBridge


sudo ip link add down1 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 226 type veth peer name down2 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 227
sudo ip link add up1 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 326 type veth peer name up2 numrxqueues $NumOfQueues numtxqueues $NumOfQueues index 327
ip link set up1 up 
ip link set up2 up
ip link set down1 up
ip link set down2 up
ip link add downbr type bridge
ip link add upbr type bridge
ip link add librebr type bridge

ip link set dev up1 master librebr
ip link set dev down2 master librebr

ip link set dev down1 master downbr
ip link set dev veth2 master downbr

ip link set dev up2 master upbr
ip link set dev veth4 master upbr

ip link set dev downbr up
ip link set dev upbr up
ip link set dev librebr up

# deleting the queues on veth2 and veth4
tc qdisc delete dev veth2 root
tc qdisc delete dev veth4 root
ethtool -L veth2 tx 1 rx 1
ethtool -L veth4 tx 1 rx 1
