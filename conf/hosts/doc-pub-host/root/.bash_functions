#
# ---------------------------------------------------------
# call by: doParseIniEnvVars sfw/sh/isg-pub/isg-pub.mini-nz.doc-pub-host.conf
#; file: mini-nz.sh.hostname.conf docs at the end 
#[MainSection]
#; the name of the project 
#project=mini-nz
#;
#; the alias of the project - used for the logical html link and the db names
#; eof file: mini-nz.sh.hostname.conf
#proj_alias=mini_nz
# ---------------------------------------------------------
doParseIniEnvVars(){
   ini_file=$1;shift 1;
   #debug ok   echo ini_file:: $ini_file
   #debug ok   sleep 2
   test -z "$ini_file" && ini_file="$component_dir/$component_name.$host_name.conf"
   test -f "$ini_file" || \
		cp -v $component_dir/$component_name.host_name.conf \
            $component_dir/$component_name.$host_name.conf
   eval `sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
      -e 's/;.*$//' \
      -e 's/[[:space:]]*$//' \
      -e 's/^[[:space:]]*//' \
      -e "s/^\(.*\)=\([^\"']*\)$/export \1=\"\2\"/" \
      < $ini_file \
      | sed -n -e "/^\[MainSection\]/,/^\s*\[/{/^[^;].*\=.*/p;}"`
}
#eof func doParseIniEnvVars

#
# ---------------------------------------------------------
# call by: doShowEnvVars PS1 ANOTHER_SHELL_VAR
# ---------------------------------------------------------
doShowEnvVars() {
	_hdr=false
	for _var in "$@"; do
	eval _val="\$$_var"
	if [ -n "$_val" ]; then
	$_hdr || echo ""
	_hdr=true
	printf '     %-20s = %s\n' "$_var" "$_val"
	fi
	done
	unset _hdr _var _val
}
