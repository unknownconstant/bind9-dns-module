#!/bin/bash -e

# Ensure a domain name is provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <domain-name> <ns1-ip> <bind path> <keyfile location>"
    exit 1
fi

ZONE_NAME="$1"
NS1_IP="$2"
DUMMY="$3"
BIND_PATH="$4"
KEYFILE="$5"
ZONE_FILE="$BIND_PATH/dynamic/${ZONE_NAME}db"

ZONE_FILE_SERVER="/var/lib/bind/dynamic/${ZONE_NAME}db"

sleep 1
rndc -k "$KEYFILE" sync

CURRENT_SERIAL=$(awk '/SOA/ {getline; print $1}' "$ZONE_FILE")
NEW_SERIAL=$((CURRENT_SERIAL + 10))

IFS=',' read -ra NAMESERVERS_LIST <<< "$NAMESERVERS"

echo "current_serial = $CURRENT_SERIAL"
echo "new_serial     = $NEW_SERIAL"
if [ "$DUMMY" = "add-dummy" ] ; then
cat << EOF > /tmp/update."$ZONE_NAME"txt
server 127.0.0.1
zone $ZONE_NAME
update add dummy-ns1.$ZONE_NAME 60 A $NS1_IP
update add $ZONE_NAME 3600 IN NS dummy-ns1.$ZONE_NAME
update add $ZONE_NAME 3600 SOA dummy-ns1.$ZONE_NAME admin.$ZONE_NAME $NEW_SERIAL 3600 1800 604800 30
$(
# update delete $ZONE_NAME NS ns1.$ZONE_NAME
for nameserver in "${NAMESERVERS_LIST[@]}"; do
    echo update delete $ZONE_NAME 3600 IN NS $nameserver
done
)
send
EOF

else
cat << EOF > /tmp/update."$ZONE_NAME"txt
server 127.0.0.1
zone $ZONE_NAME
$(
# update add $ZONE_NAME 3600 IN NS ns1.$ZONE_NAME
for nameserver in "${NAMESERVERS_LIST[@]}"; do
    echo update add $ZONE_NAME 3600 IN NS $nameserver
done
)
update add $ZONE_NAME 3600 SOA ${NAMESERVERS_LIST[0]} admin.$ZONE_NAME $NEW_SERIAL 3600 1800 604800 30
update delete $ZONE_NAME NS dummy-ns1.$ZONE_NAME
update delete dummy-ns1.$ZONE_NAME
send
EOF
fi

echo "cat /tmp/update."$ZONE_NAME"txt: "
cat /tmp/update."$ZONE_NAME"txt

echo "Do update:"
nsupdate -k $KEYFILE /tmp/update."$ZONE_NAME"txt
RESULT=$?
if [ $RESULT -eq 0 ] ; then
    echo "Success!"
    exit 0
else
    echo "Failed with code $RESULT"
    exit 1
fi

