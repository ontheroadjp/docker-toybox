#!/bin/sh

export COMP_WORDBREAKS=${COMP_WORDBREAKS/\:/}
__toyboxcomplete() {
	local cur prev
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

    local files="$TOYBOX_HOME/lib/*.fnc"
    local applist=''
    for path in ${files}; do
        applist="${applist} $(echo $path | sed "s:^${TOYBOX_HOME}/lib/::" | sed "s/\.fnc$//")"
    done

	COMPREPLY=()
	if (( $COMP_CWORD <= 1 )); then
        local list=$(cat $TOYBOX_HOME/stack/applications.txt | awk '{print "http://" $1}')
        list="${list} ${applist}"
		COMPREPLY=( $(compgen -W '${list}' -- $cur) );
	elif [ $COMP_CWORD = 2 ]; then
		if [[ "$prev" =~ ^http:\/\/.*$ ]]; then
	        local list="start stop rm ps"
		    COMPREPLY=( $(compgen -W '${list}' -- $cur) );
        elif echo ${applist} | grep ${prev} > /dev/null 2>&1; then
		    local list="new"
		    COMPREPLY=( $(compgen -W '${list}' -- $cur) );
		fi
	fi
}
complete -F __toyboxcomplete toybox
