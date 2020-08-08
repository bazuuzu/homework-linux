#!/bin/bash
# Create raid10

mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg
mkdir /etc/mdadm
touch /etc/mdadm/mdadm.conf
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
echo $(cat /proc/mdstat)
