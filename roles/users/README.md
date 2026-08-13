# Management of users, both for the LDAP and Slurm services

## Slurm account management

### See accounting information

| Action | Command |
| --- | --- |
| List all accounts and organizations | `sacctmgr show account format=Account,Organization,Description` |
| Show children of account | `sacctmgr show account withassoc format=Account,ParentName,User where account=grp_jsequeira` |
| Show user | `sacctmgr show user jsequeira` |
| Same but for all users | `sacctmgr show user format=User,DefaultAccount,AdminLevel` |
| Show all associations | `sacctmgr show associations` |
| Same but prettier | `sacctmgr show associations format=Cluster,Account,User,Partition,QOS` |
| Show associations for an account | `sacctmgr show associations where account=grp_jsequeira` |
| Show QOS | `sacctmgr show qos` |
| Show TRES | `sacctmgr show tres` |
| Show clusters | `sacctmgr show cluster` |
| See all FairShare values | `sshare -a -l` |

---

### Add entities

| Action | Command |
| --- | --- |
| Add an account | `sacctmgr add account grp_jsequeira Description="[PI] João Sequeira" Organization=HCEMM` |
| Add an account with parent account | `sacctmgr add account grp_jsequeira Parent=HCEMM Organization=HCEMM` |
| Add a user | `sacctmgr add user jsequeira Account=grp_jsequeira Cluster=sccluster` |
| Add wildcard association (allows all partitions) | `sacctmgr add user user=jsequeira account=grp_jsequeira cluster=sccluster` |
| Add partition association | `sacctmgr add user user=jsequeira account=grp_jsequeira partition=gpu cluster=sccluster` |

---

### Edit entities

| Action | Command |
| --- | --- |
| Change Organization of account | `sacctmgr modify account grp_jsequeira set Organization=HCEMM` |
| Change Description of account | `sacctmgr modify account grp_jsequeira set Description="[PI] João Sequeira"` |
| Set FairShare | `sacctmgr modify account grp_jsequeira set Fairshare=100` |
| Modify association | `sacctmgr modify association where user=jsequeira account=grp_jsequeira partition=gpu set MaxJobs=2` |
| Set default account | `sacctmgr modify user jsequeira set DefaultAccount=grp_jsequeira` |

---

### Remove entities

| Action | Command |
| --- | --- |
| Delete a specific association | `sacctmgr delete user where user=jsequeira account=grp_jsequeira partition=gpu` |
| Delete all associations for a user | `sacctmgr delete user where user=jsequeira` |
| Delete all associations for an account | `sacctmgr delete user where account=grp_jsequeira` |
| Remove a user | `sacctmgr delete user jsequeira` |
| Remove an account | `sacctmgr delete account grp_jsequeira` |

---
