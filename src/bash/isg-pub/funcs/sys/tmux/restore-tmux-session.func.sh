#!/bin/bash 
# source & courtesy of:
# https://github.com/mislav/dotfiles/blob/master/bin/tmux-session
# TODO: persist and restore_tmux_session the state & position of panes.


# v1.1.0
# ---------------------------------------------------------
# restores a tmux session
# ---------------------------------------------------------
doRestoreTmuxSession(){
   set -x
   source "$product_instance_dir/src/bash/$run_unit/funcs/sys/tmux/tmux-common.sh"

	doCheckTmuxIsInstalled

   set +e

	local count=0
	local dimensions="$(terminal_size)"

	while IFS=$'\t' read session_name window_name dir; do
	 if [[ -d "$dir" && $window_name != "log" && $window_name != "man" ]]; then
      echo session_name $session_name
      echo window_name $window_name
		if session_exists "$session_name"; then
		  add_window "$session_name" "$window_name" "$dir"
		else
		  new_tmux_session "$session_name" "$window_name" "$dir" "$dimensions"
		  count=$(( count + 1 ))
		fi
	 fi
	done < ~/.tmux-session
	
	doLog "restore_tmux_sessiond $count sessions"
	tmux list-sessions | column -t | sort

}
#eof func doRestoreTmuxSession
