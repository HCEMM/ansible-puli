## Troubleshoot

### Kernel panic during PXE boot of the compute nodes

Either 
```
wwctl overlay build
wwctl configure --all
```
or
```
wwctl image build almalinux-9
```
should fix it. Follow with the boot again
```
ipmitool -E -I lanplus -H <node_IP> -U <bmc_username> -P <bmc_password> chassis power reset
```
