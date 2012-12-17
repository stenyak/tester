#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

verbose=false
for arg; do if [ "$arg" == "-v" ]; then verbose=true; fi; done
function find_files()
{
    local -a dirs=()
    local is_filter_param=false
    local filters=""
    while [ "$#" -gt 0 ]
    do
        if $is_filter_param
        then
            filters="$filters '$1'"
            is_filter_param=false
        else
            if [ "$1" == "-name" -o "$1" == "-iname" ]
            then
                filters="$filters $1"
                is_filter_param=true
            elif [ "$1" == "-v" ]
            then
                :
            else
                dirs+=("$1")
            fi
        fi
        shift
    done
    filters="${filters:-"-iname *_test.??"}"

    local files=""
    for dir in "${dirs[@]}"
    do
        if [ "$files" != "" ]
        then
            files="$files\n"
        fi
        files="$files$(sh -c "find '$dir' $filters" 2>/dev/null)"
    done
    printf "$files\n" |grep -v "^$"
}
function run_test()
{
    local file="$1"; shift
    local info=$(./tester.sh "$file")

    local status="$(echo $info | awk '{print $1}')"
    local dir="$(echo $info | awk '{print $2}')"
    local input="$(echo $info | awk '{print $3}')"
    local output="$(echo $info | awk '{print $4}')"
    local ret="$(echo $info | awk '{print $5}')"
    local fail="$(echo $info | awk '{print $6}')"
    local pass="$(echo $info | awk '{print $7}')"
    local total="$(echo $info | awk '{print $8}')"

    local GREEN="\033[01;32m"
    local YELLOW="\033[01;33m"
    local RESET="\033[00m"
    local RED="\033[01;31m"

    if [ "$status" == "PASS" ]
    then
        echo -e "-- ${GREEN}PASS${RESET} $file"
    else
        echo -e "-- ${RED}FAIL${RESET} $file"
        if $verbose
        then
            echo $info
            cat "$output" |tail -n 5
        fi
    fi
}
function run_tests()
{
    local files="$1"; shift
    local result=0
    local IFS=$'\n'
    for file in $files
    do
        run_test "$file"
        ret=$?
        result=$(($result+$ret))
    done
    return $result
}

echo -n "Finding candidate tests..."
files="$(find_files "$@")"
nfiles="$((echo; printf "$files") |wc -l |sed "s/ *//g")"
echo " $nfiles files found."
run_tests "$files"
echo "Total return is $?"
