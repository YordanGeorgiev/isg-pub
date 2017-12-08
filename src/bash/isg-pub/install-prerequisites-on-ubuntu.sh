#!/bin/bash
# file: src/bash/issue-tracker/install-prerequisites-on-ubuntu.sh

# caveat package names are for Ubuntu !!!
set -eu -o pipefail # fail on error , debug all lines


# run as root
[ "$USER" = "root" ] || exec sudo "$0" "$@"

echo "=== $BASH_SOURCE on $(hostname -f) at $(date)" >&2

doIntallUtils(){
   echo installing the must-have pre-requisites
   while read -r p ; do
      if [ "" == "`which $p`" ];
      then echo "$p Not Found";
         if [ -n "`which apt-get`" ];
         then apt-get install -y $p ;
         elif [ -n "`which yum`" ];
         then yum -y install $p ;
         fi ;
      fi
   done < <(cat << "EOF"
      git
      vim
      perl
      zip
      unzip
      exuberant-ctags
      mutt
      curl
      wget
      libwww-curl-perl
      libxml-atom-perl
      tar
      gzip
EOF
   )

   echo installing the nice-to-have pre-requisites
   echo you have 5 seconds to proceed ...
   echo or
   echo hit Ctrl+C to quit
   echo -e "\n"
   sleep 6

   echo installing the nice to-have pre-requisites
   while read -r p ; do
      if [ "" == "`which $p`" ];
      then echo "$p Not Found";
         if [ -n "`which apt-get`" ];
         then apt-get install -y $p ;
         elif [ -n "`which yum`" ];
         then yum -y install $p ;
         fi ;
      fi
   done < <(cat << "EOF"
      tig
EOF
   )
}

# --- 
# fully automated call never tested !!!
# --- 
doInstallWklToPdf(){
   # src: https://stackoverflow.com/a/9685072/65706
   apt-get install xvfb
   apt-get install openssl build-essential xorg libssl-dev

   # src:://stackoverflow.com/a/41742260/65706 
   apt-get remove --purge wkhtmltopdf
   apt-get install openssl build-essential xorg libssl-dev
   # you might want to check the version as well ... 
   wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
   tar xvJf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
   cp -v wkhtmltox/bin/wkhtmlto* /usr/bin/

   cp -v conf/hosts/host-name/usr/local/bin/wkhtmltopdf.sh /usr/local/bin/wkhtmltopdf.sh
   chmod a+x /usr/local/bin/wkhtmltopdf.sh
}


main(){
   doIntallUtils
   # doInstallWklToPdf
}

main
# eof file: src/bash/issue-tracker/install-prerequisites-on-ubuntu.sh
