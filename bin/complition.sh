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
    
    local urls_file="$TOYBOX_HOME/stack/applications.txt"
    local urls=''
    if [ -f ${urls_file} ]; then
        urls=$(cat ${urls_file} | awk '{print "http://" $1}')
    fi

	COMPREPLY=()
	if (( $COMP_CWORD <= 1 )); then
        list="${urls} ${applist} reset env version containers"
		COMPREPLY=( $(compgen -W '${list}' -- $cur) );
	elif [ $COMP_CWORD = 2 ]; then
		if [[ "$prev" =~ ^http:\/\/.*$ ]]; then
	        local list="start stop restart rm clear ps logs info"
		    COMPREPLY=( $(compgen -W '${list}' -- $cur) );
        elif echo ${applist} | grep ${prev} > /dev/null 2>&1; then
		    local list="new logs"
		    COMPREPLY=( $(compgen -W '${list}' -- $cur) );
		fi
	fi
}
complete -F __toyboxcomplete toybox
