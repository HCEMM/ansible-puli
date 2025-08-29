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


nmcli connection add type bridge con-name br0 ifname br0
nmcli connection add type ethernet con-name ens1f0np0-slave ifname ens1f0np0 master br0
nmcli con mod br0 ipv4.addresses 10.0.50.185/24 gw4 10.0.50.1
nmcli con mod br0 ipv4.dns 10.0.50.1
nmcli con mod br0 ipv4.method manual
nmcli con up ens1f0np0-slave
nmcli con up br0

# install Xfce
dnf groupinstall "Xfce" "base-x"
systemctl set-default graphical.target

# Get Robert's project working
git clone https://github.com/RobertHenschel/slurm-desktop
pip install PyQt5
dnf install xcb-util-wm xcb-util-keysyms
python3 simple_slurm_viewer.py
python3 slurm_partition_viewer.py

# ThinLinc
# - web access (:300 default)
# - X11 forwarding
# - those nice apps


# CheckMK
