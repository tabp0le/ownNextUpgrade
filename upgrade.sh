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

echo -n "Enter the target webroot folder name  (ie. httpdocs) and press [ENTER]: "
read TARGET_WEBROOT

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

PS3="Would you like to restore apps? (Not recommended for migrations) [Select a number]: "
options=("Yes" "No")
select opt in "${options[@]}"
do
   case $opt in
        Yes)
            export APPS_RESTORE=1
            break
            ;;
        No)
            export APPS_RESTORE=0
            break
            ;;
   esac
done

export DATADIR=$(echo $(ls $TARGET_WEBROOT |grep data))

echo "Backing up current core..."

export BACKUP_NUMBER=$(date +%Y%m%d_%H%M%S)

mv $TARGET_WEBROOT $TARGET_WEBROOT-backup-$BACKUP_NUMBER

echo "De-compressing archive..."

unzip -q $NEW_VERSION

echo "Renaming unzipped folder..."

mv $TYPE $TARGET_WEBROOT

echo "Restoring config.php..."

cp -R $TARGET_WEBROOT-backup-$BACKUP_NUMBER/config/config.php $TARGET_WEBROOT/config/

if [ "$DATADIR" -ne "" ]; then
   PS3="How do you want to restore your data? [Select a number]: "
   options=("Copy" "Move")
   select opt in "${options[@]}"
   do
      case $opt in
           Copy)
               export DATA_COPY=1
               break
               ;;
           Move)
               export DATA_COPY=0
               break
               ;;
     esac
  done
fi

if [$DATA_COPY -eq 1];
then
  echo "Restoring data via copy..."
  cp -aR $TARGET_WEBROOT-backup-$BACKUP_NUMBER/$DATADIR $TARGET_WEBROOT/
fi

if [$DATA_COPY -eq 0];
then
  echo "Restoring data via move..."
  mv $TARGET_WEBROOT-backup-$BACKUP_NUMBER/$DATADIR $TARGET_WEBROOT/
fi

if [ $APPS_RESTORE -eq 1 ];
then
echo "Restoring apps from backup"
   for i in $TARGET_WEBROOT-backup-$BACKUP_NUMBER/apps/*; do
      name=$(basename "$i")
      if [[ ! -e "$TARGET_WEBROOT/apps/$name" ]]; then
         cp -aR $TARGET_WEBROOT-backup-$BACKUP_NUMBER/apps/$name $TARGET_WEBROOT/apps/
         echo "Apps restored"
      fi
   done
else
   echo "Apps not restored"
fi

echo "Fixing directory permissions...."
#find $TARGET_WEBROOT/ -type d -exec chmod 750 {} \;
chmod 0755 $TARGET_WEBROOT
chmod 0750 $TARGET_WEBROOT/config
echo "Fixing file permissions...."
#find $TARGET_WEBROOT/ -type f -exec chmod 644 {} \;
chmod 0640 $TARGET_WEBROOT/config/config.php
echo "Fixing CLI permissions...."
chmod +x $TARGET_WEBROOT/occ

echo "All permissions fixed!"

php $TARGET_WEBROOT/occ upgrade

echo "Upgrade complete"
