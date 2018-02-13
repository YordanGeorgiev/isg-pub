#!/bin/bash

export src_dir=$1
test -z $src_dir && export src_dir=`pwd`

# build an absolute dir if only relative dir has been passed
[[ $src_dir == /* ]] || src_dir=`pwd`/$src_dir
	
tgt_dir=$src_dir
export tgt_dir=$(echo $src_dir|perl -nle s'#\/opt\/(.*)([\/|\\])(.*)#\/vagrant\/opt\/$1#g;print;')


mkdir -p $tgt_dir 

#flush the screen
printf "\033[2J";printf "\033[0;0H"
#prompt user 
echo "CHECK !!! going to rsync as follows:"
echo -e "\n"
echo "src_dir: $src_dir"
echo "tgt_dir: $tgt_dir"
sleep 3

echo "files which are opened on the Windows side will not get updated"
rsync -v -r --delete --partial --progress --human-readable --stats \
	"$src_dir" "$tgt_dir"
echo DONE !!!
sleep 1

#flush the screen
printf "\033[2J";printf "\033[0;0H"
