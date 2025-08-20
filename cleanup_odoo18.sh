#!/bin/bash
# cleanup_odoo18.sh - Clean Odoo 18 multi-instance stack from this VPS
# Modes:
#   safe   -> stop services, remove containers & network, keep volumes + image + files
#   nuke   -> EVERYTHING: containers, network, images, volumes, systemd unit, files
#   purge-nginx -> purge host nginx (if previously installed) to free 80/443
#
# Usage:
#   sudo bash cleanup_odoo18.sh safe
#   sudo bash cleanup_odoo18.sh nuke
#   sudo bash cleanup_odoo18.sh purge-nginx
#
set -euo pipefail

MODE="${1:-}"
USER_TARGET="salam"
BASE_DIR="/home/${USER_TARGET}/odoo18"
SERVICE_NAME="odoo18-multi.service"

CONTAINERS=(odoo18_nginx odoo18_sand1 odoo18_sand2 odoo18_sand3 odoo18_postgres)
VOLUMES=(odoo18_postgres_data odoo18_sand1_filestore odoo18_sand2_filestore odoo18_sand3_filestore)
IMAGE="odoo18-custom:latest"
NETWORK="odoo_network"

green(){ echo -e "\033[0;32m$1\033[0m"; }
yellow(){ echo -e "\033[1;33m$1\033[0m"; }
red(){ echo -e "\033[0;31m$1\033[0m"; }

stop_systemd(){
  yellow "[systemd] stopping $SERVICE_NAME (if exists)"
  systemctl stop "$SERVICE_NAME" 2>/dev/null || true
  systemctl disable "$SERVICE_NAME" 2>/dev/null || true
  if [ -f "/etc/systemd/system/$SERVICE_NAME" ]; then
    rm -f "/etc/systemd/system/$SERVICE_NAME"
    systemctl daemon-reload
    green "[systemd] removed unit $SERVICE_NAME"
  else
    yellow "[systemd] unit not found, skip remove"
  fi
}

docker_down(){
  yellow "[docker] stopping/removing containers"
  for c in "${CONTAINERS[@]}"; do
    docker rm -f "$c" 2>/dev/null || true
  done

  yellow "[docker] removing custom network (if exists)"
  docker network rm "$NETWORK" 2>/dev/null || true
}

docker_rm_volumes(){
  yellow "[docker] removing volumes (DATA LOSS!)"
  for v in "${VOLUMES[@]}"; do
    docker volume rm "$v" 2>/dev/null || true
  done
}

docker_rm_image(){
  yellow "[docker] removing image $IMAGE"
  docker image rm "$IMAGE" 2>/dev/null || true
}

purge_files(){
  if [ -d "$BASE_DIR" ]; then
    yellow "[files] removing $BASE_DIR"
    rm -rf "$BASE_DIR"
  else
    yellow "[files] $BASE_DIR not found, skip"
  fi
}

purge_nginx(){
  yellow "[nginx] purging nginx from host (free 80/443)"
  apt purge -y nginx nginx-common nginx-core 2>/dev/null || true
  rm -rf /etc/nginx 2>/dev/null || true
  apt autoremove -y 2>/dev/null || true
  green "[nginx] purged"
}

ufw_cleanup(){
  yellow "[ufw] removing common rules (ignore errors if not present)"
  ufw delete allow 80    2>/dev/null || true
  ufw delete allow 443   2>/dev/null || true
  ufw delete allow 8069  2>/dev/null || true
  ufw delete allow 8070  2>/dev/null || true
  ufw delete allow 8071  2>/dev/null || true
}

case "$MODE" in
  safe)
    green "[mode] SAFE CLEAN"
    stop_systemd
    docker_down
    ufw_cleanup
    green "Done. Volumes (DB & filestore), image, and files are KEPT at: $BASE_DIR"
    ;;
  nuke)
    red  "[mode] NUCLEAR CLEAN — this will DELETE DB & filestore volumes PERMANENTLY!"
    read -p "Type YES to continue: " ans
    if [ "$ans" != "YES" ]; then
      echo "Aborted."
      exit 1
    fi
    stop_systemd
    docker_down
    docker_rm_volumes
    docker_rm_image
    purge_files
    ufw_cleanup
    green "NUKE complete."
    ;;
  purge-nginx)
    purge_nginx
    ;;
  *)
    echo "Usage:"
    echo "  sudo bash cleanup_odoo18.sh safe        # remove containers, keep volumes/image/files"
    echo "  sudo bash cleanup_odoo18.sh nuke        # remove EVERYTHING (DATA LOSS)"
    echo "  sudo bash cleanup_odoo18.sh purge-nginx # purge nginx installed on host"
    exit 1
    ;;
esac
