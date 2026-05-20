#!/bin/bash
JAILS=`fail2ban-client status | grep "Jail list" | sed -e 's/^[^:]\+:[ \t]\+//' | sed 's/,//g'`
for JAIL in $JAILS; do fail2ban-client status $JAIL; done;
