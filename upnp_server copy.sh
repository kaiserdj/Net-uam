#!/bin/bash

UUID=$(uuidgen)

cat <<EOF > /etc/miniupnpd/miniupnpd.conf
ext_ifname=eth0
listening_ip=br-${NETWORK_ID}
secure_mode=yes

allow 1024-65535 ${NETWORK_IP}0/24 1024-65535
deny 0-65535 0.0.0.0/0 0-65535

force_igd_desc_v1=no
uuid=${UUID}
system_uptime=yes
EOF

function cleanup()
 {
  /etc/miniupnpd/iptables_removeall.sh
  exit 0
 }

trap cleanup EXIT

/etc/miniupnpd/iptables_init.sh

miniupnpd -S -f /etc/miniupnpd/miniupnpd.conf -d