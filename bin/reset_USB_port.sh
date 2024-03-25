#!/bin/bash


if $(echo $1 | grep -Pq '\d+'); then
  bus=$1
else 
  TARGET=$1
fi

if [ -z $1 ]; then 
  clear
  lsusb
  echo "
  no target device provided, please select one e.g. 'Lenovo'
  or a bus number e.g. 2
  "
  exit 1
fi



if [ -z $bus ]; then
  bus=$(lsusb | grep $TARGET | awk '{print $2}')
fi

pci=$(sudo lsusb -v -s $bus:1 2>/dev/null | grep -Po '.*iSerial.*\b\K\d+:\d+:\d+\.\d+')
module=$(sudo lsusb -v -s  $bus:1 2>/dev/null | grep -Po '\Dhci')

echo -n "$pci" | sudo tee /sys/bus/pci/drivers/${module}*/unbind
sleep 1
echo -n "$pci" | sudo tee /sys/bus/pci/drivers/${module}*/bind
