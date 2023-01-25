#!/bin/bash
#
# Automate DeConz zll.db Backup
#

# H. Mercusot 2023 - 
#
# Usage: system_backup.sh {backup path to store backuped DB} {DB path to find zll.db}
#
# Below you can set the default values if no command line args are sent.
#

# Declare vars and set standard values
backup_path=/home/pi/.local/share/dresden-elektronik/deCONZ
db_path=/home/pi/.local/share/dresden-elektronik/deCONZ
db_file=zll

# Check to see if we got command line args
if [ ! -z $1 ]; then
   backup_path=$1
fi

if [ ! -z $2 ]; then
   db_path=$2
fi

FILE="$db_path/$db_file-backup.db"
#echo "$FILE"
if [[ -f "$FILE" ]]; then
    echo "=» Removing $FILE"
    rm -f $FILE
fi

echo "=» Backup of $db_path/$db_file.db to $FILE"
sql_cmd="VACUUM main INTO '$FILE';"
#echo $sql_cmd
sqlite3 $db_path/$db_file.db "$sql_cmd"

if [ "$backup_path" != "$db_path" ]; then 
   echo "=» Moving backup DB to $backup_path"
   mv $FILE $backup_path/.
fi
