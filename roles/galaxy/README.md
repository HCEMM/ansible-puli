## This role is not working

### Troubleshoot

If getting pesky errors in `galaxyproject.galaxy : Update Galaxy to specified ref` - especially git stuff - remove `/srv/galaxy/server`, and rerun the tasks.

### Create PostGreSQL user and database

```
sudo -u postgres psql
CREATE ROLE galaxy WITH LOGIN PASSWORD 'galaxy';
ALTER ROLE galaxy CREATEDB;
```

### Galaxy user cannot exist in LDAP

Otherwise, we get the error
```
TASK [galaxyproject.galaxy : Create Galaxy user] ***************************************************************************************************************************************
fatal: [galaxy1]: FAILED! => changed=false 
  msg: |-
    usermod: user 'galaxy' does not exist in /etc/passwd
  name: galaxy
  rc: 6
```
