## To check on munge keys

Check the value of the key.
```
ls -l /etc/munge/munge.key
md5sum /etc/munge/munge.key
```

Challenge keys against each other.
```
munge -n | unmunge
munge -n | ssh slurmctld1 unmunge
munge -n | ssh scc-mem02-10g unmunge
munge -n | ssh slurmdbd1 unmunge
```
