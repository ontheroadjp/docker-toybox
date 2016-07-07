#!/bin/sh

function __test_images() {
    if [ ${#images[@]} -eq 0 ]; then
        echo "skip test image(s)."
        return 1
    fi

    echo ">>> TEST Images"
    for i in "${images[@]}"; do
        printf "${i}..." && (( tests++ ))
        if docker images | cut -d " " -f1 | grep -w "${i}" > /dev/null 2>&1; then
            printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
        else
            printf "\033[1;31m%-10s\033[0m" "NG" && pfintf "\n" && (( failed++ ))
        fi
    done
}
