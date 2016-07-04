#!/bin/sh

function __test_volumes() {
    if [ ${#files[@]} -ne 0 ]; then
        echo ">>> TEST Volumes(files)"
        for i in ${files[@]}; do
            printf $(echo ${i} | sed -e "s:$TOYBOX_HOME:\$TOYBOX_HOME:")"..." && (( tests++ ))
            if [ -f ${i} ]; then
                printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
            else
                printf "\033[1;31m%-10s\033[0m" "NG" && printf "\n" && (( failed++ ))
            fi
        done
    else
        echo "skip test volumes(files)."
    fi

    echo

    if [ ${#dirs[@]} -ne 0 ]; then
        echo ">>> TEST Volumes(directories)"
        for i in ${dirs[@]}; do
            printf $(echo ${i} | sed -e "s:$TOYBOX_HOME:\$TOYBOX_HOME:")"..." && (( tests++ ))
            if [ -d ${i} ]; then
                printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
            else
                printf "\033[1;31m%-10s\033[0m" "NG" && printf "\n" && (( failed++ ))
            fi
        done
    else
        echo "skip test volumes(directories)."
    fi
}


