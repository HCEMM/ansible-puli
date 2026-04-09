## Some useful debug commands for FreeIPA

### Authenticate to FreeIPA
kinit admin

### Show FreeIPA configuration
ipa config-show

### List users
ipa user-find

### Show user details
ipa user-show username --all

### List groups
ipa group-find

### Show group members
ipa group-show groupname

## OTP / 2FA management

### List OTP tokens
ipa otptoken-find

### List tokens for a user
ipa otptoken-find --owner=username

### Remove OTP token
ipa otptoken-del TOKEN_ID

## LDAP queries

### Query FreeIPA LDAP
ldapsearch -x -H ldap://localhost \
  -b "dc=cluster,dc=hcemm,dc=eu"

### Query specific user
ldapsearch -x -H ldap://localhost \
  -b "dc=cluster,dc=hcemm,dc=eu" \
  "(uid=username)"

### Query groups
ldapsearch -x -H ldap://localhost \
  -b "dc=cluster,dc=hcemm,dc=eu" \
  "(objectClass=posixGroup)"

### With credentials (instead of anonymous)
ldapsearch -x \
  -D "uid=admin,cn=users,cn=accounts,dc=cluster,dc=hcemm,dc=eu" \
  -W \
  -b "cn=users,cn=accounts,dc=cluster,dc=hcemm,dc=eu" \
  "(uid=jsequeira)"

## Debug SSSD

### Check SSSD status
systemctl status sssd

### View logs
journalctl -u sssd

### Detailed logs
less /var/log/sssd/sssd_*.log

## Test identity lookup

id username

getent passwd username

getent group groupname

ssh -vvv username@login1

# 2FA Enforcement

A centralized TOTP-based 2FA enforcement mechanism is implemented using FreeIPA as the authority and login nodes as enforcement points.

Users generate their TOTP token using: ga-setup

The system periodically(each hour) checks whether each user has an OTP token.

- If a user has an OTP token → authentication is restricted to OTP only
- If a user does not have an OTP token → password login remains allowed
Runtime enforcement (Login Nodes)
- After login, users are given a grace period to configure 2FA
- If they fail to do so:
They are notified
Their session is terminated
Key Idea