#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

function tmp_file()
{
    local result=""
    if [ "$OSTYPE" == "linux-gnu" ]; then result="$(tempfile)"
    else result="$(mktemp -t "$0")"; fi
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
function is_unittest_results()
{
    local line="$1"; shift
    #unittest results line looks like: FFFF..F.F.FF..F
    if [ "$line" == "" ]
    then
        #empty first line, not a results line
        false
    else
        #if first line has anything other than 'F' and '.' its not a results line
        echo "$line" | grep -v "[^F\.]" &>/dev/null
    fi
}
function run_test()
{
    local input="$1"; shift
    local output="$1"; shift
    local timeout=1
    local ret=1
    local command="$(get_interpreter "$input")"
    local timeout_path="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/timeout.sh"
    if ! test -f "$timeout_path"
    then
        echo "Error: helper timeout script not found at $timeout_path" &> "$output"
    else
        exec 4<&1 #stdout
        exec 5<&2 #stderr
        exec > /dev/null 2>&1
        "$timeout_path" -t "$timeout" bash -c "$command '$input' &> '$output'"
        ret="$?"
        exec 1<&4
        exec 2<&5
    fi
    return "$ret"
}
verbose=false
for arg
do
    if [ "$arg" == "-v" ]; then verbose=true
    else input="$arg"
    fi
done
output="$(tmp_file)"

check_extension "$input" "$output"
run_test "$input" "$output"
ret=$?

line="$(head -n 1 "$output")"
if is_unittest_results "$line"
then
    fail=$(echo "$line" | grep -o "F" |wc -l)
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
