#!/bin/sh

function _containers() {
    echo -e "\033[1;33m--------------------------------\033[0m"
    echo -e "\033[1;33m<Running: Up>\033[0m"
    docker ps | grep -v Restarting | grep toybox_ | tail -n +2 | awk 'BEGIN{OFS=" "}
        function red(f,s) { printf "\033[1;31m" f "\033[0m",s }
        function green(f,s) { printf "\033[1;32m" f "\033[0m",s }
        function yellow(f,s) { printf "\033[1;33m" f "\033[0m",s }
        function blue(f,s) { printf "\033[1;34m" f "\033[0m",s }
        { printf "%-2d: ",NR }{ printf "%-18.17s",$1 }
        { blue("%-25.24s",$2) }{ green("%s",$NF) }{ printf "\n"  }'
    echo -e "\033[1;33m--------------------------------\033[0m"
    echo -e "\033[1;33m<Stopped>\033[0m"
    docker ps -a | grep "Exited \([0-9]*\)" | grep toybox_ | awk 'BEGIN{OFS=" "}
        function red(f,s) { printf "\033[1;31m" f "\033[0m",s }
        function green(f,s) { printf "\033[1;32m" f "\033[0m",s }
        function yellow(f,s) { printf "\033[1;33m" f "\033[0m",s }
        function blue(f,s) { printf "\033[1;34m" f "\033[0m",s }
        { printf "%-2d: ",NR }{ printf "%-18.17s",$1 }
        { blue("%-25.24s",$2) }{ green("%s",$NF) }{ printf "\n"  }'
    echo -e "\033[1;33m--------------------------------\033[0m"
    echo -e "\033[1;33m<Stopped: Created>\033[0m"
    docker ps -a | grep "Created" | grep toybox_ | awk 'BEGIN{OFS=" "}
        function red(f,s) { printf "\033[1;31m" f "\033[0m",s }
        function green(f,s) { printf "\033[1;32m" f "\033[0m",s }
        function yellow(f,s) { printf "\033[1;33m" f "\033[0m",s }
        function blue(f,s) { printf "\033[1;34m" f "\033[0m",s }
        { printf "%-2d: ",NR }{ printf "%-18.17s",$1 }
        { blue("%-25.24s",$2) }{ green("%s",$NF) }{ printf "\n"  }'
    echo -e "\033[1;33m--------------------------------\033[0m"
    echo -e "\033[1;33m<Error:Dead>\033[0m"
    docker ps -a | grep "Dead" | grep toybox_ | awk 'BEGIN{OFS=" "}
        function red(f,s) { printf "\033[1;31m" f "\033[0m",s }
        function green(f,s) { printf "\033[1;32m" f "\033[0m",s }
        function yellow(f,s) { printf "\033[1;33m" f "\033[0m",s }
        function blue(f,s) { printf "\033[1;34m" f "\033[0m",s }
        { printf "%-2d: ",NR }{ printf "%-18.17s",$1 }
        { blue("%-25.24s",$2) }{ green("%s",$NF) }{ printf "\n"  }'
    echo -e "\033[1;33m--------------------------------\033[0m"
    echo -e "\033[1;33m<Error: Restarting>\033[0m"
    docker ps -a | grep "Restarting \([0-9]*\)" | grep toybox_ | awk 'BEGIN{OFS=" "}
        function red(f,s) { printf "\033[1;31m" f "\033[0m",s }
        function green(f,s) { printf "\033[1;32m" f "\033[0m",s }
        function yellow(f,s) { printf "\033[1;33m" f "\033[0m",s }
        function blue(f,s) { printf "\033[1;34m" f "\033[0m",s }
        { printf "%-2d: ",NR }{ printf "%-18.17s",$1 }
        { blue("%-25.24s",$2) }{ green("%s",$NF) }{ printf "\n"  }'
}

function _images() {
    echo -e "\033[1;33m--------------------------------\033[0m"
    echo -e "\033[1;33m<IMAGES>\033[0m"
    docker images | tail -n +2 | grep toybox/ | awk 'BEGIN{OFS="\t"} \
        function red(f,s) { printf "\033[1;31m" f "\033[0m \t",s }
        function green(f,s) { printf "\033[1;32m" f "\033[0m \t",s }
        function yellow(f,s) { printf "\033[1;33m" f "\033[0m",s }
        function blue(f,s) { printf "\033[1;34m" f "\033[0m \t",s }
        { printf "%-2d: ",NR }
        { blue("%-25.23s",$1) }{ green("%-15.14s",$2) }
        { printf "%-15.14s",$3 }{ printf "%-6.5s",$(NF - 1) }{ print $NF }'
}


