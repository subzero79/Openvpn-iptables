#!/bin/bash
export INTERFACE="tun0"
export VPNUSER="deluge-daemon"
export LANIP="10.10.10.0/24"
export NETIF="eth0"

#Flush tables
iptables -F -t nat
iptables -F -t mangle
iptables -F -t filter
#Mark traffic per owner
iptables -t mangle -A OUTPUT ! --dest $LANIP  -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT --dest $LANIP -p udp --dport 53 -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT --dest $LANIP -p tcp --dport 53 -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT ! --src $LANIP -j MARK --set-mark 0x1

#Allow responses. Actual torrent traffic
iptables -A INPUT -i $INTERFACE -m conntrack --ctstate ESTABLISHED -j ACCEPT

#Block incoming
iptables -A INPUT -i $INTERFACE -j REJECT

#Authorize DNS queries to google
iptables -t nat -A OUTPUT --dest $LANIP -p tcp --dport 53  -m owner --uid-owner $VPNUSER  -j DNAT --to-destination 8.8.8.8

#Let vpn user access to lo and tun0

iptables -A OUTPUT -o lo -m owner --uid-owner $VPNUSER -j ACCEPT
iptables -A OUTPUT -o $INTERFACE -m owner --uid-owner $VPNUSER -j ACCEPT

#Outgoing masquerade thrugh tun0
iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

#Reject connection from vpn ip going through main gateway
iptables -A OUTPUT ! --src $LANIP -o $NETIF -j REJECT

export GATEWAYIP=`ifconfig tun0 | grep 'inet addr:' | cut -d: -f3 | awk '{print $1}'` 

if [[ `ip rule list | grep -c 0x1` == 0 ]]; then
 ip rule add from all fwmark 0x1 lookup $VPNUSER
fi

ip route flush table $VPNUSER
ip route replace default via $GATEWAYIP table $VPNUSER
ip route append default via 127.0.0.1 dev lo table $VPNUSER
ip route flush cache
