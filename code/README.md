# How to use:
## Server scirpt:
### Traffic aggregation
* One GRE tunnel is created per user (subscriber)
* The user utilizes the server IP address (eth0 in the picture) as the other end of tunnel
* When the traffic reaches to ISP through GRE tunnel, the GRE header would be dissected in namesapce 1
* The network configurations in namespace 1 routes this traffic to veth3 in namespace 2 so that the traffic goes through veth2 and veth4 for LibreQoS shaping
* When the upstream traffic reaches back to namespace 1, it routes the traffic to the corresponding client through the same GRE tunnel
### LibreQoS traffic shaping
* LibreQoS preforms traffic shaping on veth2 and veth4. 
* Either use the linux bridge between veth2 and veth4 or the XDP bridge; NOT both together.

### NATing and routing traffic to/from internet
* On the other side of LibreQoS shaper, is the namespace two which performs NATing and DeNATing
* The namespace 2 gets the traffic from namespace 1, NAT it to the upstream interface of the ISP in the box. 
* When the traffic comes back from upstream interface, the opposite of NAT operation would happen, and it has IP addresses in specific range
* Namespace 2 sends this traffic to namespace one through LibreQoS shaper.


## Client script
* First installs the requried modules and packages for GRE tunnel 
* Then, configure the GRE tunnel. The correct configuration shoulb be able to ping the other side of tunnel
* There are several ways to route the traffic through GRE tunnel to our ISP in the box:
    1. Define GRE interface as default route (Not recommended for PINOT experiment)
    2. Use IP table to make the system route the traffic through ISP in the box for specific networks 
    3. Make the net application use this interface by command parameters eg ping -I gre1 8.8.8.8
    4. Create a docker network and make the docker containers connecting to that network use GRE tunnel as default route
    5. Create linux namespace and by configuring the iptable, make it use as default route