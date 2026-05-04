#!/bin/sh


# exit script on any "unhandled" non-zero return value
set -e


BIN=iptables-nft

ACTIVE=$($BIN -S INPUT | awk '/^-A INPUT -j TTJ[01]/ {print $4; exit}')
if [ "$ACTIVE" = "TTJ0" ]; then
    NEW=TTJ1
    OLD=TTJ0
else
    NEW=TTJ0
    OLD=TTJ1
fi


# define NEW chain start from empty ruleset
$BIN -N $NEW 2>/dev/null || true
$BIN -F $NEW

### start building NEW chain
$BIN -A $NEW -i lo -j ACCEPT
$BIN -A $NEW -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

$BIN -A $NEW -m conntrack --ctstate INVALID -j DROP

# SSH with brute-force protection
$BIN -A $NEW -p tcp --dport 55522 -m conntrack --ctstate NEW \
    -m recent --update --seconds 60 --hitcount 10 --name DEFAULT --rsource -j DROP
$BIN -A $NEW -p tcp --dport 55522 -m conntrack --ctstate NEW \
    -m recent --set --name DEFAULT --rsource
$BIN -A $NEW -p tcp --dport 55522 -j ACCEPT

# k3s within the cluster
$BIN -A $NEW -s 10.0.0.0/16 -p tcp --dport 10250 -m conntrack --ctstate NEW -j ACCEPT
$BIN -A $NEW -s 10.0.0.0/16 -p udp --dport 8472 -m conntrack --ctstate NEW -j ACCEPT

# return control
$BIN -A $NEW -j RETURN

### insert NEW chain at 1st place
$BIN -I INPUT 1 -j $NEW

# detach & delete OLD
$BIN -D INPUT -j $OLD 2>/dev/null || true
$BIN -X $OLD 2>/dev/null || true

# enforce default DROP policies
$BIN -S INPUT | grep -q '^-P INPUT DROP' || $BIN -P INPUT DROP
$BIN -S FORWARD | grep -q '^-P FORWARD DROP' || $BIN -P FORWARD DROP
