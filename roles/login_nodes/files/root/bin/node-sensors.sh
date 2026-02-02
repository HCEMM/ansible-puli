#!/bin/bash

# Check if the user provided a node name as input
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <node_name_simplified>"
  exit 1
fi

# Run the 'wwctl node sensors' command and filter the output
wwctl node sensors scc-"$1"-1G | grep -Ev '0x00|Not Readable'