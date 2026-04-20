## Testing connection to controller

```
nc -zv slurmctld1 6817                  # see if it can communicate on the port to get the conf (nc from netcat package)
sha256sum /etc/munge/munge.key          # get checksums of keys, if they match they match
munge -n | ssh slurmctld1 unmunge       # test keys between VMs - if you don't want to be counting characters
```

## List users

```
sacctmgr list user format=User,DefaultAccount,Account
```

## Configurations of Slurm

Remote controller authority: `/etc/sysconfig/slurmd`

### Node management

```
scontrol update nodename=scc-cpu02-10g state=drain reason='a reason'            # put a node unavailable
```