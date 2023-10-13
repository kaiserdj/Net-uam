#!/bin/bash

source ./config
#Check if the network is created and if not, create it
#if [ -z $(docker network ls --filter name=^${NETWORK_NAME}$ --format="{{ .Name }}") ] ; then 
#    echo "Creating network docker with the name: ${NETWORK_NAME}"
#    docker network create ${NETWORK_NAME} ; 
#fi
#
#NETWORK_ID=$(docker inspect --format '{{ .Id }}' "net-uam")
#NETWORK_ID=${NETWORK_ID::12}
#NETWORK_IP=$(docker inspect --format '{{(index (index .IPAM.Config) 0).Gateway}}' "net-uam" | grep -oP '(.*\..*\..*\.)')
#
#echo ${IP}
#echo ${NETWORK_ID}
#echo ${NETWORK_IP}

#logs
CREATE_FILELOG=0    # 1->ON   0->OFF
SHOW_LOG_CONSOLE=1  # 1->ON   0->OFF

DIR=/tmp
ID=$(uuidgen)
LOG_FILE="$DIR/$ID.log"

get_Time () { Time=$(date +%d-%m-%Y\ %H:%M:%S) ; }

Write() {
    if [[ "$CREATE_FILELOG" -eq 1 ]]; then
        echo -e "${SC}${Time}: ${FC}${@}" >> $LOG_FILE
    fi
    echo -e "${SC}${Time}: ${FC}${@}" 
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
        echo -e "${SC}${Time}: ${FC}${IN}" >> $LOG_FILE
    fi
    if [[ "$SHOW_LOG_CONSOLE" -eq 1 ]]; then
        echo -e "${SC}${Time}: ${FC}${IN}" 
    fi
else
    while read IN 
    do
        if [[ "$CREATE_FILELOG" -eq 1 ]]; then
            echo -e "${SC}${Time}: ${FC}${IN}" >> $LOG_FILE
        fi
        if [[ "$SHOW_LOG_CONSOLE" -eq 1 ]]; then
            echo -e "${SC}${Time}: ${FC}${IN}" 
        fi
    done
fi
}

#Request root
Log "Configuration variables" "info"
cat ./config | Log

NETWORK_IP=$(docker inspect --format '{{(index (index .IPAM.Config) 0).Gateway}}' "${NETWORK_NAME}" | grep -oP '(.*\..*\..*\.)')
NUM_CURRENT_INSTANCE=0
IP_CLIENT=2
LOG_CLIENTS=""
for ((i=0;i<${NUM_INSTANCES};i++))
do
    Log "Creating uam${NUM_CURRENT_INSTANCE} client" "info"
    PORT=$(( $INITIAL_PORT + $NUM_CURRENT_INSTANCE ))
    PORT_WEB=$(( $PORT + 1000 ))

    LOG_CLIENTS="${LOG_CLIENTS}uam${NUM_CURRENT_INSTANCE}  PORT=${PORT}  WEB=https://${NETWORK_IP}${IP_CLIENT}:${PORT_WEB}\n"

    NUM_CURRENT_INSTANCE=$(( $NUM_CURRENT_INSTANCE + 1 ))
    IP_CLIENT=$(( $IP_CLIENT + 1 ))
done

#Execution Information
Log "Execution Information" "info"
Log "Clients list:"
Log "\n$LOG_CLIENTS"
Log "Log file: $LOG_FILE" 