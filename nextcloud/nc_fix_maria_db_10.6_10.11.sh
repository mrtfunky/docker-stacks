#!/bin/sh

# docker exec --user www-data nextcloud-app-1 php occ maintenance:repair --include-expensive

docker exec nextcloud-db-1 mysql nextcloud -pdbrootpasswordpassword -e "ALTER TABLE mysql.column_stats MODIFY histogram longblob;"
docker exec nextcloud-db-1 mysql nextcloud -pdbrootpasswordpassword -e "ALTER TABLE mysql.column_stats MODIFY hist_type enum('SINGLE_PREC_HB','DOUBLE_PREC_HB','JSON_HB');"
