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