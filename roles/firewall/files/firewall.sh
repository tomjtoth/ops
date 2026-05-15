#!/bin/sh

# This script is to be run on boot + when rules change

# exit with failure on any "unhandled" non-zero return value
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


$BIN -A $NEW -p tcp --dport 80 -j ACCEPT
$BIN -A $NEW -p tcp --dport 443 -j ACCEPT


# return control
$BIN -A $NEW -j RETURN

### insert NEW chain at 1st place
$BIN -I INPUT 1 -j $NEW

# detach, flush & delete OLD
$BIN -D INPUT -j $OLD 2>/dev/null || true
$BIN -F $OLD 2>/dev/null || true
$BIN -X $OLD 2>/dev/null || true

# enforce default policies
POLICY=${1:-ACCEPT}
$BIN -S INPUT | grep -q "^-P INPUT $POLICY" || $BIN -P INPUT $POLICY
$BIN -S FORWARD | grep -q "^-P FORWARD $POLICY" || $BIN -P FORWARD $POLICY
