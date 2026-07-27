### For ansible, creating reverse DNS etc etc - DON'T INPUT A ZONE NAME

### on ldap1
ipa dnszone-add   --name-from-ip=10.0.150.0/24   --name-server=freeipa.cluster.hcemm.eu.   --admin-email=joao.sequeira.hcemm.eu.   --dynamic-update=TRUE   --allow-sync-ptr=TRUE

### forward records
ipa dnsrecord-add cluster.hcemm.eu login --a-rec=10.0.150.204
ipa dnsrecord-add cluster.hcemm.eu login --a-rec=10.0.150.205

### host records
ipa host-add login1.cluster.hcemm.eu --ip-address=10.0.150.204
ipa host-add login2.cluster.hcemm.eu --ip-address=10.0.150.205
ipa host-add tlmaster1.cluster.hcemm.eu --ip-address=10.0.150.206
ipa host-add tlmaster2.cluster.hcemm.eu --ip-address=10.0.150.207
ipa host-add freeipa.cluster.hcemm.eu --ip-address=10.0.150.203

### on all VMs that need DNS from freeipa
nmcli con mod enp1s0 ipv4.dns "10.0.150.203"
nmcli con mod enp1s0 ipv4.ignore-auto-dns yes
nmcli con up enp1s0

nmcli con mod ens1f0np0 ipv4.dns "10.0.150.203"
nmcli con mod ens1f0np0 ipv4.ignore-auto-dns yes
nmcli con up ens1f0np0