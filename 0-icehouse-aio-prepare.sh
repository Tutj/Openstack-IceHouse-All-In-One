#!/bin/bash -ex

source config.cfg

echo "###### IP STATIC CONFIGURATION OF NICs ######"

#Check ifaces for back up file
ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
cat << EOF > $ifaces

#Setting IP for Controller Node
# NAT LOOPBACK
auto lo
iface lo inet loopback

# EXT NETWORK
# Configure Static IP Address
auto eth0
iface eth0 inet statis
address $MASTER
netmask 255.255.255.0
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

# DATA NETWORK
auto eth1
iface eth1 inet static
address $LOCAL_IP
netmask 255.255.255.0

EOF


# Restart networking service
/etc/init.d/networking restart

echo "###### SYSTEM UPDATING BEFORE INSTALLING ######"

apt-get install -y python-software-properties &&  add-apt-repository cloud-archive:icehouse -y

apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade 


iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost

echo "###### HOSTNAME DECLARATION AND CONFIGURATION OF UBUNTU ######"

hostname controller
echo "controller" > /etc/hostname

#Should use loopback in All-In-One model
cat << EOF >> $iphost
127.0.0.1      localhost
127.0.1.1      controller
$eth0_address  controller
$eth0_address  controller

# The following lines are desirable for IPv6 capable hosts
# ::1 ip6-localhost ip6-loopback
# fe00::0 ip6-localnet
# ff00::0 ip6-mcastprefix
# ff02::1 ip6-allnodes
# ff02::2 ip6-allrouters
EOF

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter" >> /etc/sysctl.conf
sysctl -p

# NTP installing and configuration 
echo "###### INSTALLING AND CONFIGURATION OF NETWORK TIME PROTOCOL ######"
sleep 3
apt-get install -y ntp

# Update /etc/ntp.conf file
# Here we set ntp.ubuntu.com as the direct source of time.
# You will also find that a local time source
# is also provided in case of internet time service interruption.

sed -i 's/server ntp.ubuntu.com/ \
server ntp.ubuntu.com \
server 127.127.1.0 \
fudge 127.127.1.0 stratum 10/g' /etc/ntp.conf

echo "###### NTP RESTART ######"
sleep 3
service ntp restart

echo "###### RABBITMQ INSTALLING ######"
sleep 3
apt-get -y install rabbitmq-server

echo "###### PASSWORD DECLARATION OF RABBITMQ ######"
rabbitmqctl change_password guest $RABBIT_PASS

echo "###### RESTART ######"
sleep 3
service rabbitmq-server restart
sleep 3
init 6
