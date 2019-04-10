#!/bin/bash

# Copyright (C) 2019 Kozyra Piotr, Kubiak Przemysław, Kurcab Jan
# This file is part of mysql_backup_script.
#
# mysql_backup_script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# mysql_backup_script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License

usage() { echo "Usage: $(basename $0) -u <USERNAME> -p <PASSWORD> -h <HOST> [-d DATABASE] [-f FILE PATH] [-r PARAMFILE]"; exit 1; }

while getopts :h:u:p:r:d:f: option
do
	case "${option}" in
		u) if [[ -z "$username" ]]; then username=$OPTARG; fi;;
		p) if [[ -z "$password" ]]; then password=$OPTARG; fi;;
		h) if [[ -z "$host_address" ]]; then host_address=$OPTARG; fi;;
		d) if [[ -z "$database" ]]; then database=$OPTARG; fi;;
		f) if [[ -z "$file_path" ]]; then file_path=$OPTARG; fi;;
		r) if [[ -z "$username" ]]; then username="$(grep user $OPTARG | cut -b 10-)"; fi
		   if [[ -z "$password" ]]; then password="$(grep password $OPTARG | cut -b 10-)"; fi
		   if [[ -z "$host_address" ]]; then host_address="$(grep host $OPTARG | cut -b 6-)"; fi
		   if [[ -z "$database" ]]; then database="$(grep database $OPTARG | cut -b 10-)"; fi
		   if [[ -z "$file_path" ]]; then file_path="$(grep file_path $OPTARG | cut -b 11-)"; fi;;
		\?) usage;; 		
		:) echo "Option -$OPTARG requires an argument."; exit 1;; 		
	esac
done
if [ $OPTIND -eq 1 ]; then echo "No options were passed";usage; fi

backup (){
	NOW=$(date +"%d-%m-%Y")

	if [[ -z "$file_path" ]]
	then
		FILE=$1.dump[$NOW-$(date +"%T")].gz
		echo $FILE 'CREATED IN THE LOCATION OF THE SCRIPT'
	else
		FILE=$file_path/$1.dump[$NOW-$(date +"%T")].gz
		echo $FILE 'CREATED IN THE SPECIFIED LOCATION'
	fi


	mysqldump --single-transaction --quick -u $username -h $host_address -p$password -B $1 | gzip > $FILE

	echo "BACKUP FILE CREATED"
}

log (){
	if [[ -z "$file_path" ]]
	then
		FILE=$1.log
		echo $FILE 'CREATED IN THE LOCATION OF THE SCRIPT'

	else
		FILE=$file_path/$1.log
		echo $FILE 'CREATED IN THE SPECIFIED LOCATION'
	fi
    
	mysql -u $username -p$password -h $host_address -B $1 -e "
	SELECT NOW() AS 'Log Time';

	SELECT char(13) AS '';

	SELECT table_name AS 'Table', round(((data_length + index_length) / 1024 / 1024), 3) 'Size in MB', table_type, engine, table_rows, avg_row_length, create_time, update_time
	FROM information_schema.TABLES 
	WHERE table_schema='$1';

	SELECT char(13) AS '';

   	select GROUP_CONCAT(table_name SEPARATOR ', ') into @table_names FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$1';

    	SET @tw = CONCAT('checksum table ', @table_names); 
            PREPARE stmt1 FROM @tw; 
            EXECUTE stmt1; 
            DEALLOCATE PREPARE stmt1; 

    	SELECT char(13) AS '';

	SELECT count(*) as 'Count of tables' 
	FROM information_schema.TABLES 
	WHERE table_schema='$1';

	SELECT char(13) AS '';

	select FORMAT(sum((data_length+index_length)/1024/1024),3) as 'Data Base Size in MB', FORMAT(sum((data_free)/1024/1024),3) as 'Free Space in MB' from information_schema.TABLES where table_schema='$1';


	SELECT char(13) AS '';SELECT char(13) AS '';SELECT char(13) AS '';SELECT char(13) AS '';
	" >> $FILE

	echo "LOG FILE CREATED"
}



if [[ -z "$database" ]]
then
	# backup for all databases
    DATABASES=$(
	mysql -u $username -p$password -h $host_address -e "SHOW DATABASES;" | tr -d "| " | grep -v 'information_schema\|Database'
	)

	echo 'Databases:'
	printf '%s\n' "${DATABASES[@]}"
	echo ""

	for database in $DATABASES
	do
		backup $database

		log $database

		echo 'BACKUP COMPLEATED'

	done
else
	# backup for database
    backup $database

    log $database

 	echo 'BACKUP COMPLEATED'
fi
