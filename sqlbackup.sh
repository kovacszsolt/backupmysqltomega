#!/bin/bash
dirname=`date +%Y%m%d%H%m%M%S`
# temporary working directory
bckp_dir="/tmp"
#database user name  (recommended = root)
database_user="root"
#database password
database_pwd="password"
#database host name
database_host="localhost"
#mysqldump command 
mysqldumpcmd="/usr/bin/mysqldump"
#megatools path
megatoolsputpath="megaput"
#mega username
megausername="username"
#mega user password
megauserpassword="password"
#system e-mail address
systemmail="kovacs@greenroom.hu"
#mysql dump flags 
dumpflags="-u$database_user -p$database_pwd -h$database_host --allow-keywords --max_allowed_packet=16M --quote-names -e --add-drop-table"

#read databases
for i in `echo "show databases;" | mysql -u$database_user -p$database_pwd -h$database_host | grep -v Database | grep -v test`
do
	#dump mysql database to temporary direcory name like 201612012210-database.sql
    $mysqldumpcmd $dumpflags $i >$bckp_dir/$dirname-$i.sql ;
    #compress sql file
    cd $bckp_dir
    tar czfP $dirname-$i.sql.tar.gz $dirname-$i.sql > /dev/null
	#remove temporary sql file
    rm $bckp_dir/$dirname-$i.sql
	#read compressed file size
	size=$(stat --format %s $dirname-$i.sql.tar.gz)
	#read mega free space
	free=$(megadf -u $megausername -p $megauserpassword --free )
	#check mega
	if [ "$free" -ge "$size" ] 
	then
		#save file to mega.co.nz
		$megatoolsputpath --username=$megausername --password=$megauserpassword $bckp_dir/$dirname-$i.sql.tar.gz
	else 
		echo "NOT ENOUGHT SPACE IN MEGA.CO.NZ" | mail -s "BACKUP REPORT" "$systemmail"
		exit -1
	fi
	#remove temporary compressed sql file
    rm $bckp_dir/$dirname-$i.sql.tar.gz
done
