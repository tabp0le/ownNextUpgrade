#!/bin/bash

#    ownNextUpgrade - ownCloud/nextCloud upgrade and migration script
#    Copyright (C) 2017 Tab Fitts (Spry Servers, LLC)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo "ownCloud/nextCloud manual upgrade beginning..."

echo "First we need some info..."

echo -n "Enter the filename of the downloaded new version and press [ENTER]: "
read NEW_VERSION

PS3="Which software are you upgrading to? [Select a number]: "
options=("ownCloud" "nextCloud")
select opt in "${options[@]}"
do
   case $opt in
       ownCloud)
            export TYPE=owncloud
            break
            ;;
       nextCloud)
            export TYPE=nextcloud
            break
            ;;
   esac
done

echo "Backing up current core..."

export BACKUP_NUMBER=$(date +%Y%m%d_%H%M%S)

mv httpdocs httpdocs-backup-$BACKUP_NUMBER  

echo "De-compressing archive"

unzip -q $NEW_VERSION

echo "Renaming unzipped folder"

mv $TYPE httpdocs

echo "Restoring config.php"

cp -R httpdocs-backup-$BACKUP_NUMBER/config/config.php httpdocs/config/

echo "Fixing directory permissions...."
find httpdocs/ -type d -exec chmod 750 {} \;
chmod 0755 httpdocs
echo "Fixing file permissions...."
find httpdocs/ -type f -exec chmod 644 {} \;
echo "Fixing CLI permissions...."
chmod +x httpdocs/occ

echo "All permissions fixed!"

php httpdocs/occ upgrade

echo "Upgrade complete"



