#!/bin/bash

export src_dir=$1
test -z $src_dir && export src_dir=`pwd`

# build an absolute dir if only relative dir has been passed
[[ $src_dir == /* ]] || src_dir=`pwd`/$src_dir \
	&& export src_dir=$(echo $src_dir|perl -nle s'#\/opt\/(.*)#\/vagrant\/$1#g;print;')
	

tgt_dir=$src_dir
#debug echo "1:src_dir: $src_dir"

# remove the latest dir level
export tgt_dir=$(echo $src_dir|perl -nle s'#\/vagrant\/(.*)#\/opt\/$1#g;print;')
export tgt_dir=$(echo $tgt_dir|perl -nle s'#(.*)([\/|\\])(.*)#$1#g;print;')

#flush the screen
printf "\033[2J";printf "\033[0;0H"
#prompt user 
echo "CHECK !!! going to rsync as follows:"
echo -e "\n"
echo "src_dir: \"$src_dir\""
echo "tgt_dir: \"$tgt_dir\""

mkdir -p $tgt_dir 
sleep 3
rsync -v -r --delete --partial --progress --human-readable --stats \
	"$src_dir" "$tgt_dir"
echo DONE !!!
sleep 1

#flush the screen
printf "\033[2J";printf "\033[0;0H"

echo " == START == setting file permissions" 
chown -Rv www-data:www-data "$tgt_dir" >/dev/null 
chmod -Rv 755 "$tgt_dir" >/dev/null 
echo " == STOP  == setting file permissions" 

#flush the screen
printf "\033[2J";printf "\033[0;0H"
