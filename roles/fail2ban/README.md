## Find specific jail configuration

`fail2ban-client -d | grep -A30 -B5 "'nginx-bad-request'"`

## See status of all jails

```bash
JAILS=`fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g'`
for JAIL in $JAILS
do
  fail2ban-client status $JAIL
done
```

### Get bans for a specific jail

```bash
grep "\[nginx-bad-request\] Ban" /var/log/fail2ban.log     # substitute jail name for [nginx-bad-request], ofc
```