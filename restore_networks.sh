#!/bin/sh

docker network create traefik_net
docker network create nextcloud_net
docker network create paperless_net
docker network create immich_net
