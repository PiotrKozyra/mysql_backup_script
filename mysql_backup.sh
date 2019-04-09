#!/bin/bash

usage() { echo "Usage: $(basename $0) -u <USERNAME> -p <PASSWORD> -h <HOST> [-d DATABASE] [-f FILE PATH] [-r PARAMFILE]" >&2; exit 1; }


while getopts :h:u:p:r:d:f: option 
do
	case "${option}" in
		u) username=$OPTARG;;
		p) password=$OPTARG;;
		h) host_address=$OPTARG;;
		r) username="$(grep user $OPTARG | cut -b 10-)"
    	   password="$(grep password $OPTARG | cut -b 10-)"
           host_address="$(grep host $OPTARG | cut -b 6-)";;
		d) database=$OPTARG;;
		f) file_path=$OPTARG;;
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
    
	mysql -u $username -p$password -h $host_address -D $1 -e "
	SELECT NOW() AS 'Log Time';

	SELECT char(13) AS '';

	SELECT table_name AS 'Table', round(((data_length + index_length) / 1024 / 1024), 3) 'Size in MB', table_type, engine, table_rows, avg_row_length, create_time, update_time
	FROM information_schema.TABLES 
	WHERE table_schema='$1' AND table_name!='checksumTable';

	SELECT char(13) AS '';

    select GROUP_CONCAT(table_name SEPARATOR ', ') into @nazwy_tabel FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$1';

    SET @tw = CONCAT('checksum table ', @nazwy_tabel); 
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
