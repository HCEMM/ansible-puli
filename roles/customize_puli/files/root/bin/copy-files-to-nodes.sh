#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 [-n <node1,node2,...>] <file1,file2,...>"
    exit 1
}

# Default nodes
NODES=("scc-mem01-10G" "scc-mem02-10G" "scc-gpu01-10G" "scc-gpu02-10G" "scc-cpu02-10G" "scc-cpu03-10G" "scc-cpu04-10G" "scc-cpu05-10G" "scc-cpu06-10G" "scc-cpu07-10G" "scc-cpu08-10G" "scc-cpu09-10G" "scc-cpu10-10G" "scc-cpu11-10G")

# Parse the optional -n argument
while getopts "n:" opt; do
  case $opt in
    n) 
      IFS=',' read -r -a NODES <<< "$OPTARG"
      ;;
    \?) 
      usage
      ;;
  esac
done

# Shift positional arguments if -n was provided
shift $((OPTIND - 1))

if [ -z "$1" ]; then
    echo "Error: Specify file(s) to SCP into nodes."
    usage
fi

# Process comma-separated file list
IFS=',' read -r -a FILES <<< "$1"

# Loop through files and perform SCP and permission changes on each file
for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' does not exist."
    exit 1
  fi

  PERMISSIONS=`stat -c "%a %n" "$FILE" | awk '{print $1}'`
  OWNER=`stat -c "%U" "$FILE"`
  FILENAME=`basename "$FILE"`

  for NODE in "${NODES[@]}"; do
    echo "Copying $FILE to $NODE"
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$FILE" "$NODE:/tmp/$FILENAME"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$NODE" "cp /tmp/$FILENAME $FILE; chmod $PERMISSIONS $FILE; chown $OWNER $FILE"
  done
done
