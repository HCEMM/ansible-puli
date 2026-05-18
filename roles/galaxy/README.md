## This role is not working

### Troubleshoot

If getting pesky errors in `galaxyproject.galaxy : Update Galaxy to specified ref` - especially git stuff - remove `/srv/galaxy/server`, and rerun the tasks.

### Create PostGreSQL user and database

```
sudo -u postgres psql
CREATE ROLE galaxy WITH LOGIN PASSWORD 'galaxy';
ALTER ROLE galaxy CREATEDB;
```