#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

function die()
{
    local message="$1"; shift
    echo "$message"
    exit 1
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
    python -c "import os.path; print os.path.relpath('$(real_path "$path")', '$PWD')"
}
function tmp_file()
{
    local result=""
    if [ "$OSTYPE" == "linux-gnu" ]; then result="$(tempfile)"
    else result="$(mktemp -t "$0")"; fi
    touch "$result"
    echo "$result"
}
function get_interpreter()
{
    local input="$1"; shift
    local result=""
    head -n 1 "$input" |grep "^#!..*" &>/dev/null || die "Script has to start with a shebang line"
    if echo "$input" |grep "\.sh$" &>/dev/null; then result="bash"
    elif echo "$input" |grep "\.py$" &>/dev/null; then result="python"
    else die "Only .sh and .py files are supported: $input"
    fi
    head -n 1 "$input" |grep "$result" &>/dev/null || die "File extension and shebang combination not supported: $input"
    echo "$result"
}
function get_results_line()
{
    local test_interpreter="$1"; shift
    local output="$1"; shift
    if [ "$test_interpreter" == "bash" ]; then
        cat "$output" | tail -1
    elif [ "$test_interpreter" == "python" ]; then
        cat "$output" | head -1
    else
        die "Unknown type of test: $test_interpreter"
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
    local test_interpreter="$1"; shift
    local input="$1"; shift
    local output="$1"; shift
    local timeout=1
    local ret=1
    local command="$test_interpreter"
    test "$test_interpreter" == "bash" && command="./bash_tester.sh"
    if ! test -f "$tp"
    then
        #echo "Error: helper timeout script not found: $tp"
        "$command" "$input" &> "$output"
    else
        $tp -t $timeout "$command" "$input" &> "$output"
    fi
    ret="$?"
    return "$ret"
}
verbose=false
for arg
do
    if [ "$arg" == "-v" ]; then verbose=true
    else input="$arg"
    fi
done
input="$(relative_path $input)"
output="$(tmp_file)"
tp="/home/visual/venom/src/build/venom/timeout.sh"

test_interpreter="$(get_interpreter "$input")"
ret="$?"
if [ "$ret" -ne 0 ]
then
    echo "Shebang line, file extension, or interpreter are not correct. ($test_interpreter)" > "$output"
    echo "WHAT $(pwd) $input $output $ret"
    exit $ret
fi


run_test "$test_interpreter" "$input" "$output"
ret=$?

line="$(get_results_line "$test_interpreter" "$output")"
if is_unittest_results "$line"
then
    fail=$(echo $line | grep -o F |wc -l)
    pass=$(echo $line | grep -o "\." |wc -l)
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
        if cat $output | grep "^Ran 0 tests" &>/dev/null
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
exit $ret
