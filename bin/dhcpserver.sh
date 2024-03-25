#!/bin/bash


INTERFACES=$(ip link | grep -P '^\d' | awk '{print $2}' | cut -d: -f 1 | grep -P '[^(lo)]')


echo "
these are your interfaces:

$INTERFACES

current config:
$1 is the interface for the DHCP server
$2 is the interface with internet access

"


if [ $# != 2 ] ; then
	echo "proper usage is: `basename $0` DHCP WAN"
  exit 1
fi


PREV_PID=$(ps aux | grep -P 'dhcpd.+\b(en|wl).+\b$' | awk '{print $2}')
PREV_INTERFACE=$(ps aux | grep -P 'dhcpd.+\b(en|wl).+\b$' | awk '{print $NF}')


CONF=/tmp/dhcpserver.${1}.conf
GATEWAY=139.96.30.100
SUBNET=$(echo $GATEWAY | cut -d . -f 1-3).0
RANGE_MIN=$(echo $GATEWAY | cut -d . -f 1-3).150
RANGE_MAX=$(echo $GATEWAY | cut -d . -f 1-3).250


if ! [ -f $CONF ]; then
  echo "
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  option subnet-mask 255.255.255.0;
  option routers $GATEWAY;
  subnet $SUBNET netmask 255.255.255.0 {
    range $RANGE_MIN $RANGE_MAX;
  }
  " > $CONF
fi


if ! [ -z $PREV_INTERFACE ]; then
  ip addr del $GATEWAY/24 dev $PREV_INTERFACE
fi


if ! [ -z $PREV_PID ]; then
  kill $PREV_PID
fi


ip link set up dev $1
ip addr add $GATEWAY/24 dev $1


dhcpd -cf $CONF $1


iptables --table nat -A POSTROUTING -o $2 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward

