#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

function tmp_file()
{
    local result=""
    if [ "$OSTYPE" == "linux-gnu" ]; then result="$(tempfile -p "test.")"
    else result="$(mktemp -t "test.")"; fi
    touch "$result"
    echo "$result"
}
function check_extension()
{
    local input="$1"; shift
    local output="$1"; shift
    if ! echo "$input" |grep "\.\(sh\|py\)$" &>/dev/null
    then
        local ret=2
        echo "Only .sh and .py files are supported: $input" > "$output"
        echo "WHAT $(pwd) $input $output $ret"
        exit "$ret"
    fi
}
function get_interpreter()
{
    local input="$1"; shift
    local bash_tester_path="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/bash_tester.sh"
    if echo "$input" |grep "\.py$" &>/dev/null; then echo "python"
    else echo "$bash_tester_path"
    fi
}
function get_timeout_ms()
{
    local input="$1"; shift
    cat "$input" |grep "#\s*tester_timeout_ms.*#" |sed "s/\s*#\s*tester_timeout_ms\s*=\s*\([0-9]*\)\s*#\s*$/\1/g"
}
function is_unittest_results()
{
    local line="$1"; shift
    #unittest results line looks like: FFFEEEF.F.FF..F
    if [ "$line" == "" ]
    then
        #empty first line, not a results line
        false
    else
        #if first line has anything other than 'F' , "E" or '.' its not a results line
        echo "$line" | grep -v "[^FE\.]" &>/dev/null
    fi
}
function run_test()
{
    local input="$1"; shift
    local output="$1"; shift
    local timeout_ms="$1"; shift
    local command="$(get_interpreter "$input")"
    local file_timeout_ms="$(get_timeout_ms "$input")"
    test "$file_timeout_ms" != "" && timeout_ms="$file_timeout_ms"
    local ret=1

    local timeout_path="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/timeout.sh"
    if ! test -f "$timeout_path"
    then
        echo "Error: helper timeout script not found at $timeout_path" &> "$output"
    else
        exec 4<&1 #stdout
        exec 5<&2 #stderr
        exec > /dev/null 2>&1
        "$timeout_path" -t "$timeout_ms" bash -c "$command '$input' &> '$output'"
        ret="$?"
        exec 1<&4
        exec 2<&5
    fi
    return "$ret"
}
function process_parameters()
{
    # global variables
    input=""
    verbose=false
    timeout_ms="2000" #default value
    while [ "$#" -gt 0 ]
    do
        if [ "$1" == "-v" ]; then verbose=true
        elif [ "$1" == "-t" ]; then shift; timeout_ms="$1"
        else input="$1"
        fi
        shift
    done
    if [ "$input" == "" ]; then
        echo "Missing input parameter value. E.g. $0 test.sh"
        exit 1
    fi
    if [ "$timeout_ms" == "" ]; then
        echo "Missing timeout_ms parameter value. E.g. $0 $input -t 500"
        exit 1
    fi
}

process_parameters "$@"
output="$(tmp_file)"

check_extension "$input" "$output"
run_test "$input" "$output" "$timeout_ms"
ret=$?

line="$(head -n 1 "$output")"
if is_unittest_results "$line"
then
    fail=$(echo "$line" | grep -o "\(F\|E\)" |wc -l)
    pass=$(echo "$line" | grep -o "\." |wc -l)
    total=$(($fail + $pass))
    if [ "$fail" -gt "0" ]
    then
        text="FAIL $(pwd) $input $output $ret $fail $pass $total"
    else
        text="PASS $(pwd) $input $output $ret $fail $pass $total"
    fi
else
    if [ "$ret" -eq 143 ]
    then
        text="TOUT $(pwd) $input $output"
    else
        if cat "$output" | grep "^Ran 0 tests" &>/dev/null
        then
            text="NOOP $(pwd) $input $output $ret"
        else
            text="WHAT $(pwd) $input $output $ret"
        fi
    fi
fi

if $verbose
then
    cat "$output"
fi
echo "$text"
exit "$ret"
