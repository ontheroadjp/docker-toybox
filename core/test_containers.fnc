#!/bin/sh

function __test_containers() {
    if [ ${#containers[@]} -eq 0 ]; then
        echo "skip test container(s)."
        return 1
    fi

    echo ">>> TEST Containers"
        
    # get Container(s) and IP Address(s)
    while [ ${#containers[@]} -ne ${#ips[@]} ]; do
        sleep 3
        tmp=($(toybox ${url} ip))
        for i in "${tmp[@]}"; do
            cons+=($(echo $i | cut -d ":" -f1))
            ips+=($(echo $i | cut -d ":" -f2))
        done
    done

    # ping test
    local num=3
    if [ ${#ips[@]} -ne 0 ]; then
        for i in "${ips[@]}"; do
            printf "ping(${i})..." && (( tests++ ))
            if ping -c ${num} $i | grep "${num} packets transmitted, ${num} received, 0% packet loss," > /dev/null 2>&1; then
                printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
            else
                printf "\033[1;31m%-10s\033[0m" "NG" && "\n" && (( failed++ ))
            fi
        done
    fi
}