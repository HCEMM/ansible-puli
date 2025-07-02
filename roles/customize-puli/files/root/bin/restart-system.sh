#!/bin/bash

for name in klamsa sjuhasz csensen tpankotai jsequeira lpongor ; do
  mount 10.0.50.187:/mnt/MirrorHDD/scratch/${name} /scratch/${name}
done

for ((i=0; i<$num_computes; i++)) ; do
  ipmitool -I lanplus -H ${c_bmc[$i]} -U ${bmc_username} -P ${bmc_password} chassis bootdev pxe options=persistent
done

for ((i=0; i<$num_computes; i++)) ; do
  ipmitool -E -I lanplus -H ${c_bmc[$i]} -U ${bmc_username} -P ${bmc_password} chassis power reset
done

wwctl node set --ipmipass ${bmc_password} --ipmiuser ${bmc_username} --all

systemctl restart slurmdbd
systemctl restart munge
systemctl restart slurmctld

copy_files_to_nodes.sh /etc/slurm/prolog.sh
copy_files_to_nodes.sh /etc/slurm/epilog.sh
copy_files_to_nodes.sh /etc/slurm/gres.conf scc-gpu01-10G,scc-gpu02-10G

pdsh -w $(IFS=','; echo "${c_name[*]}") systemctl start munge
pdsh -w $(IFS=','; echo "${c_name[*]}") systemctl start slurmd
pdsh -w $(IFS=','; echo "${c_name[*]}") "/usr/sbin/nhc-genconf -H '*' -c -" | dshbak -c
pdsh -w $(IFS=','; echo "${gpu_nodes[*]}") nvidia-smi


pdsh -w $(IFS=','; echo "${c_name[*]}") 'mkdir -p /var/run/slurm /var/log/slurm /var/spool/slurm && \
chown root:slurm /var/run/slurm /var/log/slurm /var/spool/slurm && \
chmod 770 /var/run/slurm /var/log/slurm /var/spool/slurm'

pdsh -w $(IFS=','; echo "${c_name[*]}") 'chronyc makestep'
pdsh -w $(IFS=','; echo "${gpu_nodes[*]}") systemctl start slurmd

scontrol update nodename=ALL state=resume
# Check nodes are on and uptime
pdsh -w $(IFS=','; echo "${c_name[*]}") uptime





