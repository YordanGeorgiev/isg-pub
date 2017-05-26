#!/bin/bash
# set -x

export ts=$(date "+%Y%m%d_%H%M%S")
export app_version=''
#export mysql_host='doc-pub-host'
#export mysql_port='13306'
#export mysql_user='root' 
#export mysql_user_pw='0024plapla'
#
#export app_db='isg_pub_en'
#export web_host='doc-pub-host'
# export web_port='3000'


export sql="
select ItemModel.TableName , ExportFile.BranchId , CONCAT ( ExportFile.RelativePath ,
ExportFile.Name) as Name from ExportFile 
INNER JOIN ItemView on
ExportFile.ItemViewId = ItemView.ItemViewId 
INNER JOIN ItemController
on ItemView.ItemControllerId = ItemController.ItemControllerId 
INNER JOIN ItemModel on
ItemView.ItemControllerId = ItemModel.ItemControllerId 
WHERE 1=1 
AND ItemView.Type='document' 
AND ItemView.doExportToPdf=1 
AND ExportFile.Type='md'
;" ; 

mysql -NBA -u"$mysql_user" -p"$mysql_user_pw" --port "$mysql_port" -D"$app_db" -h "$mysql_host" -e "$sql"| { 
while read -r l ; do \
	t=$(echo $l|cut -d" " -f 1); 
	b=$(echo $l|cut -d" " -f 2); 
	n=$(echo $l|cut -d" " -f 3-);
	echo start $t,$b; 
wget -O "$n.md" 'http://'"$web_host"':'"$web_port"'/export?to=githubmd&db='"$app_db"'&path-id='$b'&item='$t'&order-by=SeqId&filter-by=Level&filter-value=1,2,3,4,5,6' ;
done }
