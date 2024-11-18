#!/bin/bash

# Ensure a domain name is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <domain-name> <ns1-ip> <bind path> <keyfile location>"
    exit 1
fi

ZONE_NAME="$1"
NS1_IP="$2"
BIND_PATH="$3"
KEYFILE="$4"
ZONE_FILE="$BIND_PATH/dynamic/${ZONE_NAME}db"
sudo mkdir -p "$BIND_PATH/dynamic"
sudo chown root:bind "$BIND_PATH/dynamic"
ZONE_FILE_SERVER="/var/lib/bind/dynamic/${ZONE_NAME}db"

# Check if the zone file already exists
if [ ! -f "$ZONE_FILE" ]; then
    echo "Creating zone file for $ZONE_NAME ..."
    # Creating a basic zone file using here-doc and substituting the template variable
    cat > "$ZONE_FILE" <<EOF
\$TTL 86400
@   IN  SOA dummy-ns1.$ZONE_NAME admin.$ZONE_NAME (
    $(date +%Y%m%d%H) ; Serial
    3600       ; Refresh
    1800       ; Retry
    604800     ; Expire
    60 )    ; Negative Cache TTL
    IN  NS  dummy-ns1.$ZONE_NAME
dummy-ns1 IN  A   $NS1_IP
EOF
    echo "Added zone file."
    chown :bind "$ZONE_FILE"
    chown g+w "$ZONE_FILE"
else
    echo "Zone file for $ZONE_NAME already exists."
fi

rndc -k $KEYFILE sync
if rndc -k $KEYFILE showzone "$ZONE_NAME" > /dev/null 2>&1; then
    echo "Zone $ZONE_NAME already exists."
else
    echo "Creating zone $ZONE_NAME ..."
    
    # Add zone using rndc
    rndc -k $KEYFILE addzone "$ZONE_NAME" '{ type master; file "'"$ZONE_FILE_SERVER"'"; };'
    RESULT=$?

    if [ $RESULT -eq 0 ]; then
      echo "Zone $ZONE_NAME added successfully."
      exit 0
    fi
    echo "Failed to add zone."
    echo "Deleting created zonefile: "$ZONE_FILE": "
    cat "$ZONE_FILE" 
    rm -f "$ZONE_FILE"
    exit 1
fi