# MySQL backup script
## Description
 Bash shell script that automates process of creating backup and log files of a local or remote MySQL server database
## Features
Connecting to server, lisiting all databases, making dump and log files of all databases. 
Making dump and log files of selected database. 
## Prerequisites
Before you start using the script, you must: 
* Install the MySQL client on your machine
## Installation
To install, simply download the script file.

```
curl -0 https://raw.githubusercontent.com/PiotrKozyra/mysql_backup_script/master/mysql_backup.sh -o mysql_backup_script.sh
```

Before running a script file, you have to make it executable:

```
chmod +x mysql_backup_script.sh
```

If you want to make it system wide command:

```
sudo mv mysql_backup_script.sh /usr/local/bin/mysql_backup_script
```
## Running script with required parameters
### Description

Runs a script with specified username, password and host address. Connects to server and performs a data dump of all databases. For each database creates a dump file in the location of the script with name:
> *database_name*.dump[*current_date_and_time*].gz


Creates a log files in the location of the script with name:


> *database_name*.log

Mandatory arguments:

+ -u
  - specify user name to use when connecting to server

+ -p
  
	- specify password to use when connecting to server

+ -h

	- specify hostname to connect to (IP address or hostname)

#### Example
```
./mysql_backup.sh -u sqluser784 -p GaL6JhU62S  -h sql.freemysqlhosting.net
```

## Running script with optional parameters
### Description

Runs a script with given options. Connects to server and performs a data dump of all databases or one selected database(if specified). Creates dump and log files in given location:
> "file_path/database_name.dump[current_date_and_time].gz"

> "file_path/database_name.log"

Optional arguments:

+ -d
  - specify database name to create dump and log files of a single database

+ -f
  
	- specify path to folder where dump and log files will be created 
  
+ -r

	- specify parameters file path and name, parameters in file should follow this format:
  
 
  *parameter_name*=value 
  
ex.

> username=sqluser784 password=GaL6JhU62S host= sql.freemysqlhosting.net

#### Examples

##### Running script for one selected database, choosing location of dump and log files:

```
./mysql_backup.sh -u sqluser784 -p GaL6JhU62S  -h sql.freemysqlhosting.net -d sql673 -f "/home/user/Desktop"
```
##### Running with parameters from file (Recommended):

```
./mysql_backup.sh -r "/etc/mysql/.my.cnf"
```
_WARNING_ 
Do not use _-r_ flag with any mandatory flag (*-u, -p, -h*). Parameters from _.cnf_ file will override those provided with other flags. 
_WARNING_
