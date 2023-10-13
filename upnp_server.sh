#!/bin/bash

echo $(whoami)

if grep "#Checker server net-uam" /etc/miniupnpd/miniupnpd.conf; then
    miniupnpd -S -f /etc/miniupnpd/miniupnpd.conf -d
else    

    UUID=$(uuidgen)

    cat <<EOF > /etc/miniupnpd/miniupnpd.conf
    #Checker server net-uam
    ext_ifname=eth0
    listening_ip=br-${NETWORK_ID}
    secure_mode=yes

    allow 1024-65535 ${NETWORK_IP}0/24 1024-65535
    deny 0-65535 0.0.0.0/0 0-65535

    force_igd_desc_v1=no
    uuid=${UUID}
    system_uptime=yes
EOF

    iptables -L
    /etc/miniupnpd/iptables_init.sh
    iptables -L


    #function cleanup()
    #{
    #    /etc/miniupnpd/iptables_removeall.sh
    #    exit 0
    #}

    #trap cleanup EXIT
    #iptables -L

    sleep 5

    miniupnpd -S -f /etc/miniupnpd/miniupnpd.conf -d
fi