#!/bin/bash

verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

check=$(dpkg-query -W --showformat='${Status}\n' uam)

if [ "$check" == "install ok installed" ]; 
then
    uam_id=$(pidof uam)
    if [[ $uam_id ]]; then
        echo "detecta uam pid"
        echo $uam_id
    else
        echo "no detecta"
        cd /tmp
        wget https://update.u.is/downloads/uam/linux/uam-latest_amd64.deb
        if  verlt $(dpkg-query -W --showformat='${Version}\n' uam) $(dpkg-deb -f /tmp/uam-latest_amd64.deb Version) ; then
            dpkg -i uam-latest_amd64.deb
        fi
        rm /tmp/uam-latest_amd64.deb

        if [[ "${PORT_WEB}" ]]; then
            /opt/uam/uam --pk ${PK} --http [0.0.0.0]:${PORT_WEB} --no-ui
        else
            /opt/uam/uam --pk ${PK} --no-ui
        fi
    fi
else
    cd /tmp
    wget https://update.u.is/downloads/uam/linux/uam-latest_amd64.deb
    dpkg -i uam-latest_amd64.deb
    rm /tmp/uam-latest_amd64.deb
    timeout 10 /opt/uam/uam --pk ${PK} --no-ui
    sed -r "s/(listens=.*:).*/\1${PORT}/g" /root/.uam/uam.ini >> /root/.uam/uam.ini
    if [[ "${PORT_WEB}" ]]; then
        /opt/uam/uam --pk ${PK} --http [0.0.0.0]:${PORT_WEB} --no-ui
    else
        /opt/uam/uam --pk ${PK} --no-ui
    fi
fi