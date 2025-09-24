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


# Make idempotent on "setup_slurm"



# Galaxy server
run.sh


pip install watchdog


tusd -host localhost -port 1080 -upload-dir=/scratch/galaxy/database/tmp -hooks-http=galaxy.hcemm.eu/api/upload/hooks -hooks-http-forward-headers=X-Api-Key,Cookie
