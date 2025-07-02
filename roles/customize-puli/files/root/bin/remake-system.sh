# Before resetting master node
backup_home_folders.sh
# Backup user information (passwd and shadow file entries)
awk -F: '$3 >= 1000 && $3 < 5000' /etc/passwd > /backup/user_passwd_entries.bak
awk -F: '$3 >= 1000 && $3 < 5000' /etc/shadow > /backup/user_shadow_entries.bak
# Backup user groups
awk -F: '$3 >= 1000 && $3 < 5000' /etc/group > /backup/user_group_entries.bak
# backup slurm configuration files

# After resetting master node
restore_home_folders.sh
# Append the saved user entries back to the new system
cat /backup/user_passwd_entries.bak >> /etc/passwd
cat /backup/user_shadow_entries.bak >> /etc/shadow
cat /backup/user_group_entries.bak >> /etc/group
# Set correct permissions for shadow file
chown root:shadow /etc/shadow
chmod 640 /etc/shadow

systemctl disable --now firewalld
timedatectl set-timezone Europe/Budapest
# 3. Install OpenHPC Components
dnf install -y http://repos.openhpc.community/OpenHPC/3/EL_9/x86_64/ohpc-release-3-1.el9.x86_64.rpm
dnf -y install dnf-plugins-core
dnf config-manager --set-enabled crb
dnf -y install ohpc-base warewulf-ohpc hwloc-ohpc warewulf-common-ohpc-localdb
systemctl enable chronyd.service
echo "local stratum 10" >> /etc/chrony.conf
echo "server ${ntp_server}" >> /etc/chrony.conf
echo "allow all" >> /etc/chrony.conf
systemctl restart chronyd
dnf -y install ohpc-slurm-server slurm-slurmdbd-ohpc
cp /etc/slurm/slurm.conf.ohpc /etc/slurm/slurm.conf
cp /etc/slurm/cgroup.conf.example /etc/slurm/cgroup.conf
perl -pi -e "s/SlurmctldHost=\S+/SlurmctldHost=${sms_name}/" /etc/slurm/slurm.conf

dnf -y groupinstall "InfiniBand Support"
udevadm trigger --type=devices --action=add
systemctl restart rdma-load-modules@infiniband.service
<<EOF		# Configure IPoIB - will not do this for now, as don't know what advantage would Lustre bring to our system
cp /opt/ohpc/pub/examples/network/centos/ifcfg-ib0 /etc/sysconfig/network-scripts
perl -pi -e "s/master_ipoib/${sms_ipoib}/" /etc/sysconfig/network-scripts/ifcfg-ib0
perl -pi -e "s/ipoib_netmask/${ipoib_netmask}/" /etc/sysconfig/network-scripts/ifcfg-ib0
echo "[main]" > /etc/NetworkManager/conf.d/90-dns-none.conf
echo "dns=none" >> /etc/NetworkManager/conf.d/90-dns-none.conf
systemctl start NetworkManagerEOF
EOF

#ifconfig ens10f0 10.0.8.1 netmask 255.255.255.0 up
ip link set dev ${sms_eth_internal} up
#ip address add ${sms_ip}/${internal_netmask} broadcast + dev ${sms_eth_internal}    # outputs "Error: ipv4: Address already assigned."
perl -pi -e "s/ipaddr:.*/ipaddr: ${sms_ip}/" /etc/warewulf/warewulf.conf
perl -pi -e "s/netmask:.*/netmask: ${internal_netmask}/" /etc/warewulf/warewulf.conf
perl -pi -e "s/network:.*/network: ${internal_network}/" /etc/warewulf/warewulf.conf
perl -pi -e 's/template:.*/template: static/' /etc/warewulf/warewulf.conf
perl -pi -e "s/range start:.*/range start: ${c_ip[0]}/" /etc/warewulf/warewulf.conf
perl -pi -e "s/range end:.*/range end: ${c_ip[$((num_computes-1))]}/" /etc/warewulf/warewulf.conf
perl -pi -e "s/mount: false/mount: true/" /etc/warewulf/warewulf.conf
systemctl start warewulfd				# apparently neccessary to start warewulfd before running the next command
wwctl profile set -y default --netmask=${internal_netmask}
wwctl profile set -y default --gateway=${ipv4_gateway}
wwctl profile set -y default --netdev=default --nettagadd=DNS=${dns_servers}
perl -pi -e "s/warewulf/${sms_name}/" /srv/warewulf/overlays/host/rootfs/etc/hosts.ww
perl -pi -e "s/warewulf/${sms_name}/" /srv/warewulf/overlays/generic/rootfs/etc/hosts.ww
echo "next-server ${sms_ip};" >> /srv/warewulf/overlays/host/rootfs/etc/dhcpd.conf.ww
systemctl enable --now warewulfd
wwctl configure --all
bash /etc/profile.d/ssh_setup.sh

## 3.8. Define compute image for provisioning
wwctl container import docker://ghcr.io/warewulf/warewulf-rockylinux:9 rocky-9.4 --syncuser
wwctl container exec rocky-9.4 /bin/bash <<- EOF
  dnf -y install http://repos.openhpc.community/OpenHPC/3/EL_9/x86_64/ohpc-release-3-1.el9.x86_64.rpm
  dnf -y update
EOF

# last three lines are mine, for creating the var folders where I want them
wwctl container exec rocky-9.4 /bin/bash <<- EOF
  dnf -y install ohpc-base-compute ohpc-slurm-client
  systemctl enable munge
  systemctl enable slurmd
  dnf -y install chrony lmod-ohpc
  mkdir -p /var/run/slurm /var/log/slurm /var/spool/slurm && \
  chown root:slurm /var/run/slurm /var/log/slurm /var/spool/slurm && \
  chmod 774 /var/run/slurm /var/log/slurm /var/spool/slurm
  dnf -y update
  dnf -y clean all
EOF

wwctl container exec rocky-9.4 /bin/bash <<- EOF
  dnf -y install ohpc-base-compute ohpc-slurm-client
  systemctl enable munge
  systemctl enable slurmd
EOF

### 3.8.4. Additional Customization
export CHROOT=/srv/warewulf/chroots/rocky-9.4/rootfs
# Enable InfiniBand drivers - done 
dnf -y --installroot=$CHROOT groupinstall "InfiniBand Support"
# Increase locked memory limits - done
perl -pi -e 's/# End of file/\* soft memlock unlimited\n$&/s' /etc/security/limits.conf
perl -pi -e 's/# End of file/\* hard memlock unlimited\n$&/s' /etc/security/limits.conf
perl -pi -e 's/# End of file/\* soft memlock unlimited\n$&/s' $CHROOT/etc/security/limits.conf
perl -pi -e 's/# End of file/\* hard memlock unlimited\n$&/s' $CHROOT/etc/security/limits.conf
# Enable ssh control via resource manager - done
echo "account required pam_slurm.so" >> $CHROOT/etc/pam.d/sshd
#  Enable forwarding of system logs - done
echo 'module(load="imudp")' >> /etc/rsyslog.d/ohpc.conf
echo 'input(type="imudp" port="514")' >> /etc/rsyslog.d/ohpc.conf
systemctl restart rsyslog
echo "*.* action(type=\"omfwd\" Target=\"${sms_ip}\" Port=\"514\" " \
"Protocol=\"udp\")">> $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^\*\.info/\\#\*\.info/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^authpriv/\\#authpriv/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^mail/\\#mail/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^cron/\\#cron/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^uucp/\\#uucp/" $CHROOT/etc/rsyslog.conf
# Add ClusterShell - Not for now, pdsh is fine
dnf -y install clustershell
cd /etc/clustershell/groups.d
mv local.cfg local.cfg.orig
echo "adm: ${sms_name}" > local.cfg
echo "compute: ${compute_prefix}[1-${num_computes}]" >> local.cfg
echo "all: @adm,@compute" >> local.cfg
# Add NHC - done
dnf -y install nhc-ohpc
dnf -y --installroot=$CHROOT install nhc-ohpc
echo "HealthCheckProgram=/usr/sbin/nhc" >> /etc/slurm/slurm.conf
# Add GEOPM - don't even know what this is for
export kargs="${kargs} intel_pstate=disable"
dnf -y --installroot=$CHROOT install kmod-msr-safe-ohpc
dnf -y --installroot=$CHROOT install msr-safe-ohpc
dnf -y --installroot=$CHROOT install msr-safe-slurm-ohpc
# Add ignition and gdisk for disk partitioning - don't even know where I got this from
dnf -y --installroot=$CHROOT install ignition gdisk


wwctl overlay import generic /etc/subuid
wwctl overlay import generic /etc/subgid
echo "server ${sms_ip} iburst" | wwctl overlay import generic <(cat) /etc/chrony.conf
wwctl overlay mkdir generic /etc/sysconfig/
wwctl overlay import generic <(echo SLURMD_OPTIONS="--conf-server ${sms_ip}") /etc/sysconfig/slurmd
wwctl overlay mkdir generic --mode 0700 /etc/munge
wwctl overlay import generic /etc/munge/munge.key
wwctl overlay chown generic /etc/munge/munge.key $(id -u munge) $(id -g munge)
wwctl overlay chown generic /etc/munge $(id -u munge) $(id -g munge)


## 3.9. Finalizing provisioning configuration
wwctl container build rocky-9.4
wwctl overlay build
for ((i=0; i<$num_computes; i++)) ; do
  wwctl node add --container=rocky-9.4 \
  --ipaddr=${c_ip[$i]} --hwaddr=${c_mac[$i]} ${c_name[i]}
done
wwctl overlay build

# Install Nvidia drivers on compute nodes
wwctl container copy rocky-9.4 rocky-9.4-gpu
wwctl container exec rocky-9.4-gpu /bin/bash <<- EOF    # TODO - See if I can do all installs in one go
  dnf install -y elrepo-release
  dnf install -y nvidia-detect 
  dnf install -y kmod-nvidia
EOF
wwctl node set -y --container=rocky-9.4-gpu scc-gpu01-1G scc-gpu02-1G
wwctl overlay build

wwctl configure --all
systemctl enable --now munge
systemctl enable --now slurmctld


# Slurm first time permissions configuration - on master node
mkdir /var/spool/slurm
sudo chown -R root:slurm /var/spool/slurm
sudo chmod -R 774 /var/spool/slurm
chown slurm:root /etc/slurm/slurmdbd.conf   # slurm has to be owner!!
chmod 600 /etc/slurm/slurmdbd.conf          # has to be this value!!
mkdir /var/log/slurm
chmod 755 /var/log/slurm
# copy previous files
chown slurm:slurm -R /var/log/slurm
chmod 744 -R /var/log/slurm
mkdir -p /var/spool/slurm/slurmctld
chown slurm:root -R /var/spool/slurm
chmod 755 -R /var/spool/slurm
# On master node
systemctl enable slurmdbd
systemctl start slurmdbd
systemctl enable munge
systemctl enable slurmctld
systemctl restart munge
systemctl restart slurmctld

for name in klamsa sjuhasz csensen tpankotai jsequeira lpongor ; do
  mount 10.0.50.187:/mnt/MirrorHDD/scratch/${name} /scratch/${name}
done

for ((i=0; i<$num_computes; i++)) ; do
  ipmitool -I lanplus -H ${c_bmc[$i]} -U ${bmc_username} -P ${bmc_password} chassis bootdev pxe options=persistent
done

for ((i=0; i<$num_computes; i++)) ; do
  ipmitool -E -I lanplus -H ${c_bmc[$i]} -U ${bmc_username} -P ${bmc_password} chassis power reset
done

wwctl node set -y --ipmipass ${bmc_password} --ipmiuser ${bmc_username} --all

for ((i=0; i<$num_computes; i++)) ; do
  wwctl node set -y --ipmiaddr ${c_bmc[$i]} --ipmipass ${bmc_password} --ipmiuser ${bmc_username} --ipmiinterface lanplus ${c_name[$i]}
done

# MySQL stuff - TODO - put commands here _tomorrow_ some day

systemctl restart slurmdbd
systemctl restart munge
systemctl restart slurmctld
pdsh -w $(IFS=','; echo "${c_name[*]}") systemctl start munge
pdsh -w $(IFS=','; echo "${c_name[*]}") systemctl start slurmd
pdsh -w $(IFS=','; echo "${c_name[*]}") "/usr/sbin/nhc-genconf -H '*' -c -" | dshbak -c
pdsh -w $(IFS=','; echo "${gpu_nodes[*]}") nvidia-smi


pdsh -w $(IFS=','; echo "${c_name[*]}") 'mkdir -p /var/run/slurm /var/log/slurm /var/spool/slurm && \
chown root:slurm /var/run/slurm /var/log/slurm /var/spool/slurm && \
chmod 770 /var/run/slurm /var/log/slurm /var/spool/slurm'

copy_files_to_nodes.sh /etc/slurm/prolog.sh
copy_files_to_nodes.sh /etc/slurm/epilog.sh
copy_files_to_nodes.sh /etc/slurm/gres.conf scc-gpu01-1G,scc-gpu02-1G

pdsh -w $(IFS=','; echo "${c_name[*]}") 'chronyc makestep'
pdsh -w $(IFS=','; echo "${gpu_nodes[*]}") systemctl start slurmd

# Check nodes are on and uptime
pdsh -w $(IFS=','; echo "${c_name[*]}") uptime
pdsh -w $(IFS=','; echo "${c_name[*]}") systemctl start munge
pdsh -w $(IFS=','; echo "${c_name[*]}") systemctl start slurmd
pdsh -w $(IFS=','; echo "${c_name[*]}") "/usr/sbin/nhc-genconf -H '*' -c -" | dshbak -c
pdsh -w $(IFS=','; echo "${gpu_nodes[*]}") nvidia-smi
scontrol update nodename=ALL state=resume


# Install Nvidia drivers - following these instructions: https://www.admin-magazine.com/HPC/Articles/Warewulf-4-GPUs
# Maybe these are no longer needed, if installed on compute nodes through the Rocky-gpu image, but will leave these here for now
dnf install -y tar bzip2 make automake gcc gcc-c++ pciutils elfutils-libelf-devel libglvnd-devel
distribution=rhel9
ARCH=$( /bin/arch )   # x86_64
dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/$distribution/${ARCH}/cuda-$distribution.repo
dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)
dnf install -y kernel kernel-core kernel-modules
dnf module install nvidia-driver			# takes a while - besides, had to do the following two commands after, so maybe not even do this one
dnf module remove nvidia-driver				
dnf module reset nvidia-driver
dnf clean all
dnf -y module install nvidia-driver:latest-dkms
pdsh -w scc-gpu01-1G 'sysctl -w net.ipv4.ip_forward=1;dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo;dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r);dnf install -y kernel kernel-core kernel-modules;dnf -y module install nvidia-driver:latest-dkms;dnf clean all'


# 4. Install OpenHPC Development Components
## 4.1. Development Tools
dnf -y install ohpc-autotools
dnf -y install EasyBuild-ohpc
dnf -y install hwloc-ohpc
dnf -y install spack-ohpc
dnf -y install valgrind-ohpc

## 4.2. Compilers
dnf -y install gnu14-compilers-ohpc

## 4.3. MPI Stacks
dnf -y install openmpi5-pmix-gnu14-ohpc mpich-ofi-gnu14-ohpc

## 4.4. Performance Tools
dnf -y install ohpc-gnu14-perf-tools

## 4.5. Setup default development environment
dnf -y install lmod-defaults-gnu14-openmpi5-ohpc

## 4.6. 3rd Party Libraries and Tools - install all available package offerings within OpenHPC - won't run this for now, seems like a lot
dnf -y install ohpc-gnu14-serial-libs
dnf -y install ohpc-gnu14-io-libs
dnf -y install ohpc-gnu14-python-libs
dnf -y install ohpc-gnu14-runtimes
dnf -y install ohpc-gnu14-mpich-parallel-libs
dnf -y install ohpc-gnu14-openmpi5-parallel-libs


# accounting database construction
groupadd -g 1003 jsequeira
useradd -m -p q_38jF_L -g jsequeira -u 1003 fnedenyi
groupadd -g 1004 klamsa
useradd -m -p by_9u_Zs -g klamsa -u 1004 atiszla
groupadd -g 1005 sjuhasz
useradd -m -p AGe_Zf2a -g sjuhasz -u 1005 jszilvi
groupadd -g 1006 csensen
useradd -m -p b37DqHf -g csensen -u 1006 avo
groupadd -g 1007 tpankotai
useradd -m -p q4p_Ja#v -g tpankotai -u 1007 pahizol
groupadd -g 1008 lpongor
useradd -m -p pongorls -g lpongor -u 1008 pongorls

sacctmgr list cluster # check if cluster is there
#sacctmgr add cluster sccluster # if it isn't there
sacctmgr -i add account jsequeira
sacctmgr -i add user fnedenyi account=jsequeira
sacctmgr -i add account klamsa
sacctmgr -i add user atiszla account=klamsa
sacctmgr -i add account sjuhasz
sacctmgr -i add user jszilvi account=sjuhasz
sacctmgr -i add account csensen
sacctmgr -i add user avo account=csensen
sacctmgr -i add account tpankotai
sacctmgr -i add user pahizol account=tpankotai
sacctmgr -i add account lpongor
sacctmgr -i add user pongorls account=lpongor


dnf install nfs-utils
mkdir /scratch/klamsa
mount 10.0.50.187:/mnt/MirrorHDD/scratch/klamsa /scratch/klamsa
mkdir /scratch/sjuhasz
mount 10.0.50.187:/mnt/MirrorHDD/scratch/sjuhasz /scratch/sjuhasz
mkdir /scratch/csensen
mount 10.0.50.187:/mnt/MirrorHDD/scratch/csensen /scratch/csensen
mkdir /scratch/tpankotai
mount 10.0.50.187:/mnt/MirrorHDD/scratch/tpankotai /scratch/tpankotai
mkdir /scratch/jsequeira
mount 10.0.50.187:/mnt/MirrorHDD/scratch/jsequeira /scratch/jsequeira
mkdir /scratch/lpongor
mount 10.0.50.187:/mnt/MirrorHDD/scratch/lpongor /scratch/lpongor



# Add pam_slurm_adopt plugin
cd ./contribs/pam_slurm_adopt
make && make install

# set right permissions for files
chown slurm:slurm /var/log/slurmctld.log


# Spack installs
spack install miniconda3    # these take a long time. Just be happy they work
spack install apptainer

# Required by users
spack install python@3.8 jdk


# enable internet on compute nodes
sysctl -w net.ipv4.ip_forward=1



wwctl overlay build scc-cpu04-1G
wwctl configure --all
ipmitool -E -I lanplus -H 10.0.50.162 -U jsequeira -P Aroma3-Unclip chassis power reset









wwsh -y file import /etc/passwd
wwsh -y file import /etc/group
wwsh -y file import /etc/shadow
wwsh -y file import /etc/subuid
wwsh -y file import /etc/subgid
wwsh file sync passwd
wwsh file sync group
wwsh file sync shadow
wwsh file sync subuid
wwsh file sync subgid


# remove repo
dnf repolist
dnf repository-packages nvhpc remove
rm /etc/yum.repos.d/nvhpc.repo


# ThinLinc
/opt/thinlinc/sbin/tl-setup         # setup ThinLinc
tl-config /vsmagent/agent_hostname=scc-mem02-1G   # set agent hostname
systemctl restart vsmagent          # restart agent


# Setup LDAP in VPN
dnf install nss-pam-ldapd openldap-clients nss-pam-ldapd
nano /etc/authselect/user-nsswitch.conf 
authselect apply-changes
https://github.com/manbaritone/OpenHPC-Installation/blob/master/08_LDAP%20server.md


# Check if InfiniBand is working
lsof | grep infiniband
ibv_devinfo
ibv_devices

# Setup Galaxy server on the HPC cluster
# https://training.galaxyproject.org/training-material/topics/admin/tutorials/ansible-galaxy/tutorial.html
ansible-playbook galaxy.yml
# To fix the GPGD keys, edit roles/galaxyproject.postgresql/tasks/redhat.yml as here - https://www.postgresql.org/message-id/4f803fbc884177e5ead5e54dee52db5048d21110.camel%40gunduz.org


# change boot order for no PXE boot
efibootmgr -o 0013,000F,0011,0012,0014,001C,001D,001E,0016,0015,0020,0022,0021,000E,0008,0009,000A,000B,000C,000D

# change it back
efibootmgr -o 0023,001F,001B,0017,0022,001E,001A,0016,0020,001C,0018,0014,0021,001D,0019,0015


# Mail tests (SMTP)
echo "This is a test message" | sendmail joao.sequeira@hcemm.eu
systemctl status postfix


# 2FA setup
dnf install -y google-authenticator
#Follow these instructions - https://forums.rockylinux.org/t/rocky-linux-9-google-auth-install-guide/9592/3
#Additional part - selinux will block the pam_google_authenticator.so module, so you need to allow it
ausearch -m avc -ts recent | audit2allow -M pam_google_auth
semodule -i pam_google_auth.pp


# Check if firewall gives problems
# Add services allowed by firewall
firewall-cmd --add-service tftp --permanent && firewall-cmd --reload


# Setup Fail2Ban - https://reintech.io/blog/implementing-fail2ban-security-rocky-linux-9
dnf install fail2ban
systemctl enable fail2ban
systemctl start fail2ban
# Check if it's running
fail2ban-client status
# Check if it's banning
fail2ban-client status sshd

add_user.sh -u fnedenyi -p q_38jF_L -g jsequeira -i 1003 -d 1003
add_user.sh -u atiszla -p by_9u_Zs -g klamsa -i 1004 -d 1004
add_user.sh -u jszilvi -p AGe_Zf2a -g sjuhasz -i 1005 -d 1005
add_user.sh -u avo -p alessandra -g csensen -i 1006 -d 1006
add_user.sh -u pahizol -p pahizol -g tpankotai -i 1007 -d 1007
add_user.sh -u pongorls -p pongorls -g lpongor -i 1008 -d 1008
add_user.sh -u knemes -p jTSGeU62DW -g lpongor -i 1009
add_user.sh -u abeno -p xandi -g lpongor -i 1012


copy_files_to_nodes.sh /etc/profile.d/spack.sh
