function log() {
  echo "[$(date --iso-8601=seconds)] $1: $2"
}

function log_info() {
  log "INFO" "$1"
}

function log_error() {
  log "ERROR" "$1"
}

if [ -z "$(which docker)" ]; then
  log_error "Docker is not installed"
  exit 1
fi

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

DEVICES=("h1" "h2" "r1" "r2" "r3" "r4")
for DEVICE in $DEVICES; do
  DEVICE_UPPER=$(echo $DEVICE | tr '[:lower:]' '[:upper:]')
  CONTAINER=$(eval echo "\$CONTAINER_$DEVICE_UPPER")
  log_info "Fetching configuration for container $CONTAINER"
  docker container exec $CONTAINER ip -4 r > $DEVICE.routes.txt
  docker container exec $CONTAINER ip -4 a > $DEVICE.ip.txt
done
