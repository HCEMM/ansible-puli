#!/bin/sh

ansible-playbook -i inventory/test_hosts site.yml --syntax-check
