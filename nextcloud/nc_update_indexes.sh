#!/bin/sh

docker exec --user www-data nextcloud-app-1 php occ db:add-missing-indices
#docker exec --user www-data nextcloud-app-1 php occ files:scan --all