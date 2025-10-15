#!/bin/bash

setsebool -P httpd_can_network_connect 1

# resize partitions

# ldap connection
dnf install -y openldap-clients
dnf install -y sssd realmd oddjob oddjob-mkhomedir adcli samba-common-tools
nano /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
systemctl enable sssd
systemctl start sssd
nano /etc/nsswitch.conf         # lineinfile ->  shadow:     files sss
authselect enable-feature with-mkhomedir
authselect apply-changes
nano /etc/pam.d/common-session      # lineinfile -> session required pam_mkhomedir.so skel=/etc/skel/ umask=0077


# according to https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_authentication_and_authorization_in_rhel/configuring-sssd-to-use-ldap-and-require-tls-authentication_configuring-authentication-and-authorization-in-rhel
dnf -y install openldap-clients sssd sssd-ldap oddjob-mkhomedir
authselect select sssd with-mkhomedir
cp core-dirsrv.ca.pem /etc/openldap/certs
nano /etc/openldap/ldap.conf
nano /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd oddjobd
systemctl enable sssd oddjobd


update-crypto-policies --set LEGACY


# install Xfce
dnf groupinstall "Xfce" "base-x"
systemctl set-default graphical.target

# Install Robert's project
git clone https://github.com/RobertHenschel/slurm-desktop
pip install PyQt5
dnf install xcb-util-wm xcb-util-keysyms
python3 simple_slurm_viewer.py
python3 slurm_partition_viewer.py

# ThinLinc
# - web access (:300 default)
# - X11 forwarding
# - those nice apps


# CheckMK - everything about it

# General VMs - setting up the repos not present/enabled in alma minimal
dnf install -y epel-release
dnf config-manager --set-enabled crb

# Open firewall for ssh, http, https, AMQP
- name: Open firewall for ssh, http, https, AMQP
  ansible.builtin.firewalld:
    port: "{{ item }}"
    permanent: true
    state: enabled
    immediate: yes
    zone: public
  loop:
    - 22/tcp
    - 80/tcp
    - 443/tcp
    - 5671/tcp

# Make idempotent on "setup_slurm"


# Nginx server
setsebool -P httpd_use_nfs 1
mount 10.0.150.209:/srv/galaxy /srv/galaxy



# Galaxy server
# /srv/galaxy 10.0.150.211(rw,sync,no_subtree_check,no_root_squash) in /etc/exports
groupadd galaxy
adduser galaxy -g galaxy -s /bin/bash
su galaxy
cd
git clone https://github.com/galaxyproject/galaxy
cd galaxy
run.sh

# Slurm DRMAA is deprecated
#wget https://github.com/natefoo/slurm-drmaa/releases/download/1.1.5/slurm-drmaa-1.1.5-22.05.el9.x86_64.rpm
#dnf install -y slurm-drmaa-1.1.5-22.05.el9.x86_64.rpm
#./configure -g -O0 && make



pip install watchdog


tusd -host localhost -port 1080 -upload-dir=/scratch/galaxy/database/tmp -hooks-http=galaxy.hcemm.eu/api/upload/hooks -hooks-http-forward-headers=X-Api-Key,Cookie


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

