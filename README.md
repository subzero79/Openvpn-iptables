# Openvpn-iptables

In your .conf client file you need to add

route-nopull
script-security 2
up /path_to_script

Redirect traffic per uid through openvpn tunnel

When the vpn connection goes down the first entry at vpn table will disappear, leaving just a route to loopback, this will avoid the application to leak data through the main interface (eth0, the default gateway for the main table), since all packets outgoing from the app have a tracing mark


Notes
- There is a more generic way to take this approach. This involves changing the init scripts of each daemon, they usually have a variable ($USER) for chuid of start-stop-daemon, that chuid can accept input the form of user:group, so if we create a group called vpn an put it in the openvpn script all daemons running under that group will have their traffic pushed trough the tun0 interface

- Once reboot the iptables will be gone, you can install iptables-persistant to save them so they will be there to prevent leakage. In case the vpn fails to start.

- once the vpn is connected you can ensure the application is going out through VPN observing the traffic increase in tun0, also iftop -i tun0 -P should indicate out/in connections in that interface. This webpage also will say if the application has a different outgoing WAN IP http://checkmytorrentip.net/


Reference: https://www.niftiestsoftware.com/2011/08/28/making-all-network-traffic-for-a-linux-user-use-a-specific-network-interface/ 
