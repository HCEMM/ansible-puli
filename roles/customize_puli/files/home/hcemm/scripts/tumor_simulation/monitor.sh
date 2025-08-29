#!/bin/bash
watch -n 2 '
clear
echo "🌡️  Tumor Simulation Dashboard - Node View"
for i in {0..3}; do
    echo -e "\n-----------------------------"
    echo "Patient $i"
    tail -n 5 patient_$i/log.txt
done
'
