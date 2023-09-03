#!/bin/bash

# check if user is root
if [[ $EUID -ne 0 ]]
then
        echo "This script must be run as root"
        exit 1
fi

# Take user input
echo -i "Enter interface (e.g. ens160)[ens160]: "
read -ei "ens160" interface


echo -i "Enter IP address with mask (e.g. 192.168.1.1/24): "
read ip_address

echo -i "Enter Gateway IP (e.g. 192.168.1.254): "
read gateway

echo -i "Enter DNS server 1 (e.g. 1.1.1.1): "
read dns


touch /etc/netplan/50-cloud-init.yaml
# Create a backup of the netplan file
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.backup


echo -e "
network:
 version: 2
 renderer: networkd
 ethernets:
  $interface:
   addresses: [$ip_address]
   routes:
    - to: default
      via: $gateway
   nameservers:
    addresses: [$dns]
" > /etc/netplan/50-static-$interface.yaml

# Check if the new configuration works
check=$(sudo netplan try)

if [ $? -eq 0 ]; then
  echo "Netplan configuration is successful. Applying now..."
  # Apply the new configuration
  sudo netplan apply
else
  echo "Netplan configuration failed. Reverting to the previous configuration.."
  # revert to the backup
  sudo cp /etc/netplan/50-cloud-init.yaml.backup /etc/netplan/50-cloud-init.yaml
fi

echo -n "Please enter a hostname: "

read hostname



sudo hostnamectl set-hostname $hostname

echo -e 'Hostname set'

