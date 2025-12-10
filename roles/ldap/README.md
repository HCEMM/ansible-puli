## Some useful commands

Check remote AD
```
ldapsearch -x -H ldap://10.0.40.11:389 \
  -D "CN=[AD_user],CN=Users,DC=hcemm,DC=eu" -w [AD_password] \
  -b "DC=hcemm,DC=eu" \
  "(sAMAccountName=*)"
```

Check the local LDAP schemas
```
ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn
```
Query the LDAP for user info
```
ldapsearch -H ldap://127.0.0.1 -D "cn=admin,dc=cluster,dc=local" -w [ze_passvort] -b "cn=schema,dc=cluster,dc=local"
```
Debug sssd
```
less /var/log/sssd/sssd.log
```

### Generate certificates for LDAP
```
openssl genrsa -out ca.key 4096                                     # create ca.key
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt \
  -subj "/C=HU/ST=Hungary/L=Szeged/O=PuliSupercomputer/OU=IT/CN=PuliLDAP-CA"        # create ca.crt
openssl genrsa -out ldap.key 4096                                   # create ldap.key
openssl req -new -key ldap.key -out ldap.csr -config ldap_san.cnf       # create ldap.csr
openssl x509 -req -in ldap.csr -CA ca.crt -CAkey ca.key -CAcreateserial   -out ldap.crt -days 3650 -sha256 -extfile ldap_san.cnf -extensions req_ext      # create ldap.crt
```