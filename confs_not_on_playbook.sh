#!/bin/bash

setsebool -P httpd_can_network_connect 1

dnf install -y libvirt virt-manager
