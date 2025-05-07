#!/bin/sh

if [ -f execution.log ]; then
    rm -f execution.log
fi

ansible-playbook -i inventory/test_hosts site.yml -u root -vv

