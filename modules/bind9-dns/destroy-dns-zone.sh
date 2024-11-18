#!/bin/bash -e
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <domain-name> <bind path> <keyfile location>"
    exit 1
fi

ZONE_NAME="$1"
BIND_PATH="$2"
KEYFILE="$3"
ZONE_FILE="$BIND_PATH/dynamic/${ZONE_NAME}db"
# ZONE_FILE_SERVER="/var/lib/bind/dynamic/${ZONE_NAME}db"

echo $PATH

# Attempt to delete the zone using rndc
if rndc -k $KEYFILE delzone "$ZONE_NAME"; then
    echo "Zone $ZONE_NAME has been successfully deleted from BIND."
else
    RESULT=$?
    echo "Failed to delete zone $ZONE_NAME. rndc returned "$RESULT"."
    if [ $RESULT -eq 1 ] ; then
      echo "Zone doesn't exist, continuing."
    else
      exit 1
    fi
fi


# Optionally, remove the zone file to clean up
if [ -f "$ZONE_FILE" ]; then
    rm -f "$ZONE_FILE"
    rm -f "$ZONE_FILE".jnl
    echo "Zone file $ZONE_FILE has been removed."
fi
