#!/bin/bash
# Cahange the IPs of the server(ISP in the box) and the client device and tu
# The tunnel IP is the accociated IP of the client device in the GRE tunnel
# In this case, GRE tunnle has 2 IPs, one for the server and one for the client. 
# The client side has 192.168.11.2 and the server side has 192.168.11.1
PinotIP='169.222.11.xx'
ServerIP='128.111.aa.aa'
TunnelIP='192.168.11.2/30'
Table='dockerToGre'
Container="docker1"
Subnet='172.30.0.0/16'

# Install the required packages and modules for gre tunnel
sudo modprobe ip_gre
lsmod | grep gre
sudo apt install iptables iproute2
sudo echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sudo sysctl -p

# Create the GRE tunnel and configure the GRE tunnel
sudo iptunnel add gre1 mode gre remote $ServerIP local $PinotIP ttl 255
sudo ip addr add $TunnelIP dev gre1
sudo ip link set gre1 up

# At this point, the client dvice should be able to ping the server side of tunnle
# ping 192.168.11.1 should work
# To check client has access to internet through GRE:
# ping -I gre1 8.8.8.8 should work

# Create a new routing table and add the container subnet to it  
echo -e "100\t$Table" >> /etc/iproute2/rt_tables
sudo ip route change default dev gre1 table $Table
sudo ip rule add from $Subnet table $Table

# Create a new docker network and run a container in it
# This part makes sure all the traffic from the container goes through the GRE tunnel
docker network create --subnet $Subnet greBr
docker run  -itd  --network greBr --name $CONTAINER   ubuntu:22.04  sleep infinity
docker exec -it $CONTAINER bash
apt update
apt install -y iproute2 net-tools iputils-ping speedtest-cli iperf3 nano curl tshark 
exit
