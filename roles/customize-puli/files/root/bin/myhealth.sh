#!/bin/bash

read -sp "Enter IPMI password: " password
echo ""
ipmitool -I lanplus -H 10.0.50.141 -U jsequeira -P "$password" sdr elist all
