# CrowdSec role

This role installs and configures CrowdSec on the SMS/cpu1 node.

It manages:

- CrowdSec repository and package installation
- CrowdSec service
- CrowdSec firewall bouncer service
- HCEMM whitelist parser
- HAProxy SSH parser
- HAProxy SSH connection-abuse scenario
- Fail2Ban-to-CrowdSec reconcile script
- Weekly cron job for importing repeated Fail2Ban bans from login nodes

## Important

The bouncer API key must not be committed to Git.

If the bouncer was already configured manually, keep:

```yaml
crowdsec_manage_bouncer_config: false
```

If Ansible should manage the bouncer config, store the key in Ansible Vault and set:

```yaml
crowdsec_manage_bouncer_config: true
crowdsec_bouncer_api_key: "<vaulted-key>"
```

## Manual checks

```bash
systemctl status crowdsec --no-pager -l
systemctl status crowdsec-firewall-bouncer --no-pager -l
cscli machines list
cscli bouncers list
cscli metrics show bouncers
iptables -L CROWDSEC_CHAIN -n -v
ipset list | grep crowdsec
/usr/local/sbin/crowdsec-f2b-reconcile --dry-run
```

## Fail2Ban import logic

The reconcile script collects Fail2Ban `Ban` records from login nodes, filters internal and HCEMM trusted IPs, and adds remaining repeated offenders to CrowdSec as manual decisions.

CrowdSec manual decisions require a duration, so this role uses a long duration and refreshes weekly through cron.

## Useful Commands

```bash
cscli metrics
cscli alerts list
cscli decisions list
cscli decisions delete/add --ip 1.2.3.4 
cscli Alerts delete/add --ip 1.2.3.4 
```

## Delete Decisions that added manually

```bash
cscli alerts list --all -o json \
| jq -r '.[] | select(.scenario == "hcemm/fail2ban-import") | .decisions[]?.value' \
| sort -u

cscli alerts list --all -o json \
| jq -r '.[] | select(.scenario == "hcemm/fail2ban-import") | .decisions[]?.value' \
| sort -u \
| while read -r ip; do
    [ -z "$ip" ] && continue
    echo "[DELETE] $ip"
    cscli decisions delete --ip "$ip"
  done
```  
  
 ## Delete Alerts that added manually
 
 ```bash
 cscli alerts list --all -o json \
| jq -r '.[] | select(.scenario == "hcemm/fail2ban-import") | .id' \
| while read -r id; do
    [ -z "$id" ] && continue
    echo "[DELETE ALERT] $id"
    cscli alerts delete --id "$id"
  done
 ``` 
 
 ### Debugging

-- Agent:
 ```bash
journalctl -u crowdsec -f
 ```

 -- Bouncer:
 ```bash
journalctl -u crowdsec-firewall-bouncer -f
 ```