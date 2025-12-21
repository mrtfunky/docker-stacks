#!/bin/sh

docker exec --user www-data nextcloud-app-1 php occ maintenance:repair --include-expensive
