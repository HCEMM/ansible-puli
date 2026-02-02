#!/bin/bash
export HOSTS="scc-cpu[02-11]-10G,scc-mem[01-02]-10G,scc-gpu[01-02]-10G"
pdsh -w $HOSTS 'for g in cfdna_clustering csensen jsequeira klamsa lpongor mroland sjuhasz tpankotai zbiacsi; do mkdir -p /scratch/$g; done'
pdsh -w $HOSTS 'for g in cfdna_clustering csensen jsequeira klamsa lpongor mroland sjuhasz tpankotai zbiacsi; do mount -t nfs 10.0.150.146:/mnt/MirrorHDD/scratch/$g /scratch/$g; done'
pdsh -w $HOSTS 'for g in cfdna_clustering csensen jsequeira klamsa lpongor mroland sjuhasz tpankotai zbiacsi; do echo "10.0.150.146:/mnt/MirrorHDD/scratch/$g /scratch/$g nfs defaults,_netdev 0 0" >> /etc/fstab; done'

