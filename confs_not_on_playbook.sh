#!/bin/bash

setsebool -P httpd_can_network_connect 1

# resize partitions

# Computes and PAM accession for ansible playbooks
# gave up on this. Doesn't work with keys, doesn't work with these instructions: https://slurm.schedmd.com/faq.html (section "How can I exclude some users from pam_slurm?")
# but it would be nice to be able to run playbook tasks on computes
# for now will use pdsh for everything needed on computes

update-crypto-policies --set LEGACY

# Install Robert's project
git clone https://github.com/RobertHenschel/slurm-desktop
pip install PyQt5
dnf install xcb-util-wm xcb-util-keysyms
python3 simple_slurm_viewer.py
python3 slurm_partition_viewer.py

# To assess later if CrowdSec works well together with fail2ban
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt-get update
sudo apt-get install crowdsec crowdsec-firewall-bouncer

# Might add in the future, watchdog reboots the server when it is hanging
pip install watchdog




# EMMA
virt-install \
  --name myvm \
  --memory 4096 \
  --vcpus 2 \
  --disk size=20,path=/var/lib/libvirt/images/fcbi-reservation1.qcow2 \
  --network bridge=br0,model=virtio \
  --os-variant ubuntu22.04 \
  --graphics none \
  --location /tmp/ubuntu-24.04.3-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
  --extra-args "autoinstall ds=nocloud-net;s=http://10.0.150.101:9876/data/ console=ttyS0,115200n8"

https://www.reddit.com/r/linuxadmin/comments/1c0q5k3/creating_an_automatic_ubuntu_install_is_there_a/

git clone https://github.com/HCEMM/fcbi-instrument-reservation -b sznistvan
apt update
apt install -y python3-pip python3.12-venv
python3 -m venv .env
. .env/bin/activate
pip install -r requirements.txt
python manage.py runserver 0.0.0.0:8000



# Warewulf overlay
wwctl image exec --build=false almalinux-9-ldap /bin/bash -c 'dnf install -y ipa-client sssd oddjob oddjob-mkhomedir authselect certmonger krb5-workstation bind-utils polkit'
systemctl enable oddjobd
systemctl enable certmonger


CONF=/etc/warewulf/nodes.conf

users=(
cfdna_clustering
csensen
jsequeira
klamsa
lpongor
mroland
sjuhasz
tpankotai
zbiacsi
mmanczinger
kvince
)

for u in "${users[@]}"; do
  yq -i '
    .nodeprofiles.default.resources.fstab += [{
      "file": "/scratch/'"$u"'",
      "spec": "10.0.150.147:/mnt/MirrorHDD/scratch/'"$u"'",
      "vfstype": "nfs",
      "mntops": "defaults,_netdev,nofail"
    }]
  ' $CONF
done


mkdir $CHROOT/var/log/slurm
mkdir $CHROOT/var/spool/slurm


# mkdir home dirs in ldap role
# also add new users to sacct
#sacctmgr add account group_name Description="[PI] group" Organization="HCEMM"
#sacctmgr add user USERNAME account=group_name cluster=sccluster


sudo tee /etc/xdg/mimeapps.list <<EOF
[Default Applications]
text/plain=mousepad.desktop
text/x-log=mousepad.desktop
text/x-shellscript=mousepad.desktop
application/x-shellscript=mousepad.desktop
EOF
dnf -y install xdg-utils
xdg-mime query default text/plain
update-mime-database /usr/share/mime


##### CrowdSec Agent installation:

dnf install curl -y

curl -s https://install.crowdsec.net | sh

dnf clean all
dnf makecache

dnf install crowdsec -y


systemctl enable --now crowdsec
systemctl status crowdsec --no-pager
cscli version

##### Firewall Bouncer installation:

dnf install crowdsec-firewall-bouncer-iptables -y
systemctl enable crowdsec-firewall-bouncer
systemctl start crowdsec-firewall-bouncer
systemctl status crowdsec-firewall-bouncer

##### Check connection between Bouncer & Agent:

cscli bouncers list

(looking for something like this: 
Name                         IP       Status
firewall-bouncer             127.0.0.1  ✔ active)

##### Whitelist management:

/etc/crowdsec/parsers/s02-enrich/whitelist.yaml

name: crowdsecurity/whitelists
description: "Whitelist trusted HCEMM admin and infrastructure IPs"
whitelist:
  reason: "trusted HCEMM sources"      
  ip:
    - "79.120.228.107"
  cidr:
    - "127.0.0.0/8"
    - "192.168.0.0/16"
    - "10.0.0.0/8"
    - "172.16.0.0/12"
  # expression:
  #   - "'foo.com' in evt.Meta.source_ip.reverse" 

##### Threat Intelligence activation:

cscli collections list
cscli collections install crowdsecurity/linux
cscli collections install crowdsecurity/sshd

systemctl restart crowdsec
cscli metrics
cscli alerts list
cscli decisions list
iptables -L -n

# limitations on /tmp folder of computes (and maybe login nodes too) so it doesn't fill up
# /etc/tmpfiles.d/tmp.conf
r /tmp/brave_* - - - 6h
r /tmp/_MEI* - - - 6h
export TMPDIR=/scratch/$USER/tmp     # on Slurm prolog script
tmpfs /tmp tmpfs size=20G


# For all new users
ln -s /dev/null /home/*/thinclient_drives


# Just as general debugging, don't remember where this was used
rm -rf /etc/logrotate.d/named; logrotate -d /etc/logrotate.conf; rm -f /var/lib/logrotate/logrotate.status; systemctl restart logrotate.service
