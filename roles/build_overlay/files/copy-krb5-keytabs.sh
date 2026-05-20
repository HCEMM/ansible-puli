#!/bin/sh
# Copy back /etc/krb5.keytab files from the the compute nodes and stage them in /srv/krb5/
# to ensure Warewulf has the latest krb5.keytab file when nodes get deployed

PREFIX="/srv/krb5/krb5.keytab-"

function main () {

local node

for node in $(list_nodes)
do
scp "${node}:/etc/krb5.keytab" "${PREFIX}${node}"
done
}

function list_nodes () {
ls -d /srv/krb5/krb5.keytab-* | cut -c "$(expr ${#PREFIX} + 1)"-
}

main "$@"
