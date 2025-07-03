#! /bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 <filename> "
    exit 1
}

FILE=$1
PERMISSIONS=`stat -c "%a %n" $1 | awk '{print $1}'`
OWNER=`stat -c "%U" $1`
FILENAME=`basename $FILE`

rm -f $FILE
nano $FILE
chmod $PERMISSIONS $FILE
chown $OWNER $FILE
echo "File [$FILE] has been reset."
