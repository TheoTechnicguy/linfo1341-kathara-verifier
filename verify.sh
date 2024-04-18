#!/bin/sh
#
# file: verify.sh
# author: theo technicguy
#
# This file verifies the Kathara Lab configuration
# for UCLouvain's LINFO1341 class

function log() {
  echo "[$(date --iso-8601=seconds)] $1: $2"
}

function log_info() {
  log "INFO" "$1"
}

function log_error() {
  log "ERROR" "$1"
}

function config_from_url() {
  URL="https://raw.githubusercontent.com/TheoTechnicguy/linfo1341-kathara-verifier/master/expect/$1.$2.txt"
  curl -fsSL $URL | sed "s/{PREFIX}/$3/g"
}

if [ -z "$(which docker)" ]; then
  log_error "Docker is not installed"
  exit 1
fi

if [ $# -ne 1 ]; then
  log_error "Usage: $0 <NOMA>"
  exit 1
fi

PREFIX=${1:0:2}
log_info "Verifying Kathara Lab configuration for NOMA $1 (prefix $PREFIX)"

CONTAINERS=$(docker container list --format "{{ .Names }}" --filter "name=kathara_" | sort)
CONTAINER_H1=$(echo $CONTAINERS | sed "s/ /\n/g" | grep h1)
CONTAINER_H2=$(echo $CONTAINERS | sed "s/ /\n/g" | grep h2)
CONTAINER_R1=$(echo $CONTAINERS | sed "s/ /\n/g" | grep r1)
CONTAINER_R2=$(echo $CONTAINERS | sed "s/ /\n/g" | grep r2)
CONTAINER_R3=$(echo $CONTAINERS | sed "s/ /\n/g" | grep r3)
CONTAINER_R4=$(echo $CONTAINERS | sed "s/ /\n/g" | grep r4)
CONTAINERS=$(echo $CONTAINERS | tr '\n' ' ')

log_info "Found containers H1: $CONTAINER_H1"
log_info "Found containers H2: $CONTAINER_H2"
log_info "Found containers R1: $CONTAINER_R1"
log_info "Found containers R2: $CONTAINER_R2"
log_info "Found containers R3: $CONTAINER_R3"
log_info "Found containers R4: $CONTAINER_R4"

if [ -z "$CONTAINER_H1" ] || [ -z "$CONTAINER_H2" ] || [ -z "$CONTAINER_R1" ] || [ -z "$CONTAINER_R2" ] || [ -z "$CONTAINER_R3" ] || [ -z "$CONTAINER_R4" ]; then
  log_error "Missing some containers"
  exit 1
fi

log_info "All containers are present"

DEVICES=("h1" "h2" "r1" "r2" "r3" "r4")
EXIT_CODE=0

for DEVICE in ${DEVICES[@]}; do
  DEVICE_UPPER=$(echo $DEVICE | tr '[:lower:]' '[:upper:]')
  CONTAINER=$(eval echo "\$CONTAINER_$DEVICE_UPPER")
  log_info "Verifying container $CONTAINER"

  ACTUAL_IP_CONFIG=$(docker exec $CONTAINER ip -4 a)
  EXPECTED_IP_CONFIG=$(config_from_url $DEVICE "ip" $PREFIX)

  DIFF_IP_CONFIG=$(diff --ignore-blank-lines --ignore-all-space -y <(echo "$EXPECTED_IP_CONFIG") <(echo "$ACTUAL_IP_CONFIG"))
  DIFF_IP_CONFIG_STATUS=$?

  if [ $DIFF_IP_CONFIG_STATUS -ne 0 ]; then
    log_error "IP configuration is incorrect"
    echo "$DIFF_IP_CONFIG"
  fi

  EXIT_CODE=$(($EXIT_CODE + $DIFF_IP_CONFIG_STATUS))

  ACTUAL_ROUTE_CONFIG=$(docker exec $CONTAINER ip -4 r)
  EXPECTED_ROUTE_CONFIG=$(config_from_url $DEVICE "routes" $PREFIX)

  DIFF_ROUTE_CONFIG=$(diff --ignore-blank-lines --ignore-all-space -y <(echo "$EXPECTED_ROUTE_CONFIG") <(echo "$ACTUAL_ROUTE_CONFIG"))
  DIFF_ROUTE_CONFIG_STATUS=$?

  if [ $DIFF_ROUTE_CONFIG_STATUS -ne 0 ]; then
    log_error "Route configuration is incorrect"
    echo "$DIFF_ROUTE_CONFIG"
  fi

  EXIT_CODE=$(($EXIT_CODE + $DIFF_ROUTE_CONFIG_STATUS))
done

if [ $EXIT_CODE -eq 0 ]; then
  log_info "All configurations are correct"
  echo "+---------------------------------------------------------------------------+"
  echo "|                                                                           |"
  echo "|               Configuration for NOMA $1 correct!                    |"
  echo "|                                                                           |"
  echo "+---------------------------------------------------------------------------+"
else
  log_error "Some configurations are incorrect"
fi
