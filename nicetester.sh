#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

verbose=false
timeout_ms=1000
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
        files="$files$(sh -c "find '$dir' $filters; printf '\n'" 2>/dev/null)"
    done
    printf "\n$files\n" | sort
}
function reason_to_text()
{
    local reason="$1"; shift
    local reason_text=""
    case "$reason" in
       "PASS")
        reason_text="all tests passed"
    ;; "FAIL")
        reason_text="some tests failed"
    ;; "TOUT")
        reason_text="timed out while running tests"
    ;; "WHAT")
        reason_text="incorrect test format"
    ;; "NOOP")
        reason_text="no tests were defined"
    ;; *)
        reason_text="unknown reason"
    ;; esac
    echo "$reason_text"
}
function tmp_file()
{
    local result=""
    if [ "$OSTYPE" == "linux-gnu" ]; then result="$(tempfile -p "test.")"
    else result="$(mktemp -t "test.")"; fi
    touch "$result"
    echo "$result"
}
function real_path()
{
    local path="$1"; shift
    if [ "$OSTYPE" == "linux-gnu" ]; then readlink -f "$path"
    else echo "$(cd "$(dirname "$path")"; pwd)/$(basename "$path")"; fi
}
function relative_path()
{
    local path="$1"; shift
    echo "$(python -c "import os.path; print os.path.relpath('$(real_path "$path")', '$PWD')")"
}
function run_test()
{
    local file="$1"; shift
    local max_path_len="$1"; shift
    echo -ne "== Running $(relative_path "$file") : \t" |expand -t "$(($max_path_len+14))"
    local tester_path="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/tester.sh"
    if ! test -f "$tester_path"; then echo "Error: helper timeout script not found at $tester_path"; exit 1; fi

    local temp_output="$(tmp_file)"  #test is not run in a $() subshell, otherwise the timeout script in tester.sh won't work
    pushd "$(dirname "$file")" &>/dev/null
    local relative_file="$(relative_path "$file")"
    local now="$(date +%s%N)"                   #start the clock
    $tester_path -t "$timeout_ms" "$relative_file" &> "$temp_output"         #actually run the test
    local elapsed_ns="$(($(date +%s%N)-$now))"  #stop the clock
    popd &>/dev/null
    local info="$(cat "$temp_output"; rm -f "$temp_output")"

    local elapsed="$(echo "scale=2; $elapsed_ns / 1000000000" | bc | sed "s/^\./0./")"  # seconds w/ decimals

    local reason="$(echo $info | awk '{print $1}')"
    local dir="$(echo $info | awk '{print $2}')"
    local input="$(echo $info | awk '{print $3}')"
    local output="$(echo $info | awk '{print $4}')"
    local ret="$(echo $info | awk '{print $5}')"
    local fail="$(echo $info | awk '{print $6}')"
    local pass="$(echo $info | awk '{print $7}')"
    local total="$(echo $info | awk '{print $8}')"
    fail=${fail:-0}
    pass=${pass:-0}
    total=${total:-0}
    test -f "$output" || { printf "\nIncorrect output from tester.sh:\n$info\n" >&2; exit 2; }

    local result=0
    if [ "$reason" == "PASS" ]
    then
        echo -ne "${DGREEN}"
            echo -e "   passed${RESET} $pass/$total in ${elapsed}s"
    else
        echo -ne "${DRED}"
        case "$reason" in
           "FAIL")
            echo -ne "   failed"
        ;; "TOUT")
            echo -ne "timed out"
        ;; "WHAT")
            echo -ne "  unknown"
        ;; "NOOP")
            echo -ne "    empty"
        ;; *)
            echo -ne "     huh?"
            reason_text="unknown reason"
        ;; esac
        echo -ne "${RESET} $fail/$total in "
        if [ "$elapsed_ns" -gt "${timeout_ms}000000" ]
        then
            echo -e "${DRED}${elapsed}s${RESET}"
        else
            echo -e "${elapsed}s"
        fi
        result="$(($result+1))"
        local out="$DRED"
        local DRED="$RESET"
        if $verbose
        then
            local nlines=50
            echo -e "\t${DRED}Return code:${RESET} $ret\t\t${DRED}Working dir:${RESET} $dir"
            echo -e "\t${DRED}Reason:${RESET} $(reason_to_text "$reason")"
            echo -e "\t${out}Output${RESET} (only showing last $nlines lines, full output at $output ):${RESET}"
            cat "$output" | tail -n "$nlines" |sed "s/^/\t\t/g"
            #echo -e "\t${DRED}Full status:${RESET} $info"
        fi
    fi
    nicetester_pass="$(($nicetester_pass+$pass))"
    nicetester_fail="$(($nicetester_fail+$fail))"
    nicetester_total="$(($nicetester_total+$total))"
    return "$result"
}
function show_results
{
    local ret="$1"; shift
    local fail="$1"; shift
    local total="$1"; shift
    local elapsed="$1"; shift

    echo "($total tests run in ${elapsed}s)"
    if [ "$total" -eq "0" ]
    then
        echo -e "${YELLOW}WARNING! No tests were found.$RESET"
        echo -e "${DYELLOW} Get to work and write some tests!$RESET"
    else
        if [ "$fail" -eq "0" -a "$ret" -eq "0" ]
        then
            echo -e "${GREEN}CONGRATULATIONS! ALL $total TESTS PASSED.$RESET"
            echo -e "$DGREEN Here, have a cookie!$RESET"
            echo -e "$DYELLOW    ____     $RESET"
            echo -e "$DYELLOW   /· . \    $RESET"
            echo -e "$DYELLOW   | . '|    $RESET"
            echo -e "$DYELLOW   \____/    $RESET"
        else
            if [ "$fail" -eq "0" ]
            then
                echo -e "${YELLOW}WARNING! Some file has no tests.$RESET"
                echo -e "${DYELLOW} Get to work and write those tests!$RESET"
            else
                echo -e "${RED}EPIC FAIL. $fail tests failed (out of $total)."
                echo -e "${DRED} No cookies for you!$RESET"
            fi
        fi
    fi
}
function run_tests()
{
    local files="$1"; shift
    local result=0
    local IFS=$'\n'
    local max_path_len=0
    for file in $files
    do
        local len="$(echo "$(relative_path "$(real_path "$file")")" | wc -c)"
        if [ "$len" -gt "$max_path_len" ]
        then
            max_path_len="$len"
        fi
    done
    for file in $files
    do
        file="$(real_path "$file")"
        run_test "$file" "$max_path_len"
        ret=$?
        result=$(($result+$ret))
    done
    return "$result"
}


function main()
{
    local GREEN="\033[01;32m"
    local DGREEN="\033[00;32m"
    local YELLOW="\033[01;33m"
    local DYELLOW="\033[00;33m"
    local RESET="\033[00m"
    local RED="\033[01;31m"
    local DRED="\033[00;31m"
    local BLUE="\033[01;34m"
    local WHITE="\033[01;37m"

    local nicetester_pass=0
    local nicetester_fail=0
    local nicetester_total=0

    echo -n "Finding candidate tests..."
    files="$(find_files "$@")"
    nfiles="$((printf "$files") |wc -l |sed "s/ *//g")"
    echo " $nfiles files found."
    local now="$(date +%s%N)"                   #start the clock
    run_tests "$files"
    local ret="$?"
    local elapsed="$(echo "scale=2; $(($(date +%s%N)-$now)) / 1000000000" | bc | sed "s/^\./0./")"  # seconds w/ decimals
    echo ""
    show_results "$ret" "$nicetester_fail" "$nicetester_total" "$elapsed"
    return "$ret"
}

main "$@"
