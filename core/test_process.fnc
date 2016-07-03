#!/bin/sh

function __test_process() {
    if [ ${#process[@]} -eq 0 ]; then
        echo "skip test process(s)."
        return 1
    fi

    count=0
    for i in ${containers[@]}; do
        if [ ${count} -gt 0 ]; then
            echo
        fi

        local id=$(docker ps | grep "toybox_${i}_" | cut -d " " -f1)
        echo ">>> TEST Process(${i}:${id})"

        local timeout=0
        while ! docker exec -it ${id} ps aux | grep "${process[${count}]}" > /dev/null 2>&1; do
            echo ${process[${count}]}
            sleep 3 && (( timeout+=3 ))
            if [ ${timeout} -gt 60 ]; then
                echo "Timeout!"
                exit 0
            fi
        done
            
        docker exec -t ${id} ps aux | grep "${process[${count}]}" && {
        printf "running..." && (( tests++ ))
            if [ $? -eq 0 ]; then
                printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
            else
                printf "\033[1;31m%-10s\033[0m" "NG" && printf "\n" && (( failed++ ))
            fi
        }

        printf "user(${process_user[${count}]})..." && (( tests++ ))
        docker exec -t ${id} ps aux | grep "${process_user[${count}]}" > /dev/null 2>&1 && {
            if [ $? -eq 0 ]; then
                printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
            else
                printf "\033[1;31m%-10s\033[0m" "NG" && printf "\n" && (( failed++ ))
            fi
        }
        (( count++ ))
    done 
}
