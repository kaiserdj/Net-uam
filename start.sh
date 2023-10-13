#!/bin/bash

#Init
clear
source ./config
echo -e "${FC}
███╗   ██╗███████╗████████╗   ██╗   ██╗ █████╗ ███╗   ███╗
████╗  ██║██╔════╝╚══██╔══╝   ██║   ██║██╔══██╗████╗ ████║
██╔██╗ ██║█████╗     ██║█████╗██║   ██║███████║██╔████╔██║
██║╚██╗██║██╔══╝     ██║╚════╝██║   ██║██╔══██║██║╚██╔╝██║
██║ ╚████║███████╗   ██║      ╚██████╔╝██║  ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
${SC}                                                          
"

#Logs
DIR=/tmp
ID=$(uuidgen)
LOG_FILE="$DIR/$ID.log"

get_Time () { Time=$(date +%d-%m-%Y\ %H:%M:%S) ; }

Write() {
    if [[ "$CREATE_FILELOG" -eq 1 ]]; then
        echo "${Time}: ${@}" >> $LOG_FILE
    fi
    echo -e "${FC}${@}" 
}

Log()
{
get_Time

if [[ "${2}" == "info" ]]; then
    Write ""
    Write "--------------------------------------------------"
    Write ${1}
    Write "--------------------------------------------------"
    return 1
fi

if [ -n "${1}" ]; then
    IN="${1}"
    if [[ "$CREATE_FILELOG" -eq 1 ]]; then
        echo "${Time}: ${IN}" >> $LOG_FILE
    fi
    if [[ "$SHOW_LOG_CONSOLE" -eq 1 ]]; then
        echo -e "${FC}${IN}" 
    fi
else
    while read IN 
    do
        get_Time
        if [[ "$CREATE_FILELOG" -eq 1 ]]; then
            echo "${Time}: ${IN}" >> $LOG_FILE
        fi
        if [[ "$SHOW_LOG_CONSOLE" -eq 1 ]]; then
            echo -e "${FC}${IN}" 
        fi
    done
fi
}


#Request root
Log "Requesting root permissions" "info"
Log "User: $(whoami)"

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"


#Request root
Log "Configuration variables" "info"
cat ./config | Log


#Variable
Log "Generating network variables" "info"
IP=$(ifconfig ${EXT_INTERFACE} | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'  | cut -d' ' -f2)
NETWORK_ID=""
NETWORK_IP=""


#Check if the network is created and if not, create it
Log "Checking and generating network" "info"

iptables -v -P INPUT ACCEPT
iptables -v -P FORWARD ACCEPT
iptables -v -P OUTPUT ACCEPT
iptables -v -t nat -F
iptables -v -t mangle -F
iptables -v -F
iptables -v -X
#https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules-es
#systemctl restart systemd-networkd
#systemctl restart docker
#networkctl | grep docker0
service docker restart
if [ -z $(docker network ls --filter name=^${NETWORK_NAME}$ --format="{{ .Name }}") ] ; then 
    echo "Creating network docker with the name: ${NETWORK_NAME}"
    docker network create ${NETWORK_NAME} | Log
fi

NETWORK_ID=$(docker inspect --format '{{ .Id }}' "${NETWORK_NAME}")
NETWORK_ID=${NETWORK_ID::12}
NETWORK_IP=$(docker inspect --format '{{(index (index .IPAM.Config) 0).Gateway}}' "${NETWORK_NAME}" | grep -oP '(.*\..*\..*\.)')


#Upnp server image creation
Log "Upnp server image creation" "info"
docker build --build-arg NETWORK_ID=$NETWORK_ID --build-arg NETWORK_IP=$NETWORK_IP --build-arg EXT_INTERFACE=$EXT_INTERFACE -f ./upnp_server_dockerfile -t upnp . | Log


#Generate container server upnp
Log "Generate container server upnp" "info"
docker run -d -it --name=upnp --restart always --network=host --cap-add=NET_ADMIN --cap-add=NET_RAW upnp | Log


#Open port cleaning
Log "Open port cleaning" "info"
upnp=$(docker exec upnp upnpc -l | grep $NETWORK_NAME)

while IFS= read -r redirection
do
    data=(${redirection// / })
    protocol=${data[1]}
    port=(${data[2]//-/ }) && port=${port[0]}

    docker exec upnp upnpc -d ${port} ${protocol} | Log
done <<< "$upnp"


#Creation of uam clients
Log "Creation of uam clients" "info"
docker build -f ./uam_client_dockerfile -t uam . | Log

NUM_CURRENT_INSTANCE=0
IP_CLIENT=2
LOG_CLIENTS=""
for ((i=0;i<${NUM_INSTANCES};i++))
do
    PORT=$(( $INITIAL_PORT + $NUM_CURRENT_INSTANCE ))
    PORT_WEB=$(( $PORT + 1000 ))
    
    Log "Cleaning iptable host" "info"

    Log "Creating uam${NUM_CURRENT_INSTANCE} client" "info"

    LOG_CLIENTS="${LOG_CLIENTS}uam${NUM_CURRENT_INSTANCE}  PORT=${PORT}  WEB=http://${NETWORK_IP}${IP_CLIENT}:${PORT_WEB}\n"


    Log "Opening client port uam${NUM_CURRENT_INSTANCE}"
    docker exec upnp upnpc -e "$NETWORK_NAME:${PORT}" -a ${IP} ${PORT} ${PORT} tcp | Log
    
    Log "Starting uam${NUM_CURRENT_INSTANCE} client" "info"
    docker run -d -it --name=uam${NUM_CURRENT_INSTANCE} --restart always --cap-add=IPC_LOCK --network=$NETWORK_NAME -e PK=$PK -e PORT=$PORT -e PORT_WEB=$PORT_WEB --expose $PORT --expose $PORT_WEB uam | Log

    sleep 20

    NUM_CURRENT_INSTANCE=$(( $NUM_CURRENT_INSTANCE + 1 ))
    IP_CLIENT=$(( $IP_CLIENT + 1 ))
done

#Create file to save data of create clients -> /var/lib/net-uam
#Create file to create more uam-client
#Creation systemd
#https://blog.container-solutions.com/running-docker-containers-with-systemd


#Execution Information
Log "Execution Information" "info"
Log "\n$LOG_CLIENTS"
Log "Log file: $LOG_FILE" 


#Exit
echo -e "\033[0m"
