### Install a tool through the Galaxy API

Install ephemeris which brings a lot of command line utilities.
```
python3 -m venv ~/ephemeris_venv
. ~/ephemeris_venv/bin/activate
pip install ephemeris
```
Install the tool. More information [here](https://training.galaxyproject.org/training-material/topics/admin/tutorials/tool-management/tutorial.html).
```
shed-tools install -g https://galaxy.hcemm.eu -a API_TOKEN --name bwa --owner devteam --section_label "Sequence Alignme
nt"
```

### Troubleshoot

If getting pesky errors in `galaxyproject.galaxy : Update Galaxy to specified ref` - especially git stuff - remove `/srv/galaxy/server`, and rerun the tasks.

#### Create PostGreSQL user and database

```
sudo -u postgres psql
CREATE ROLE galaxy WITH LOGIN PASSWORD 'galaxy';
ALTER ROLE galaxy CREATEDB;
```

#### Galaxy user cannot exist in LDAP

Otherwise, we get the error
```
TASK [galaxyproject.galaxy : Create Galaxy user] ***************************************************************************************************************************************
fatal: [galaxy1]: FAILED! => changed=false 
  msg: |-
    usermod: user 'galaxy' does not exist in /etc/passwd
  name: galaxy
  rc: 6
```

#### If listing tools to install, or their available versions, is taking too long

Check if https://toolshed.g2.bx.psu.edu/ is accessible and responsive.
