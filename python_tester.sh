#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

test_interpreter="python"
if [ "$OSTYPE" == "darwin10.0"  ]; then platform="osx"; fi
if [ "$OSTYPE" == "msys"        ]; then platform="win"; fi
if [ "$OSTYPE" == "linux-gnu"   ]; then platform="lin"; fi
function die()
{
    local message="$1"; shift
    echo "Error: $message"
    exit 1
}
function real_path()
{
    if [ "$platform" == "lin" ]; then readlink -f "$1"
    else echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}
function relative_path()
{
    python -c "import os.path; print os.path.relpath('$(real_path "$1")', '$PWD')"
}
function tmp_file()
{
    local result=""
    if [ "$platform" == "lin" ]; then result="$(tempfile)"
    else result="$(mktemp -t "$0")"
    fi
    touch "$result"
    echo "$result"
}
input="$(relative_path $1)"
output="$(tmp_file)"
tp="/home/visual/venom/src/build/venom/timeout.sh"

function is_test()
{
    local test_interpreter="$1"; shift
    local input="$1"; shift
    if [ "$test_interpreter" == "bash" ]; then
        head -n 1 "$input" |grep '^#!.*\(bash\|bash_tester\)' &>/dev/null
        #should be a bash or bash_tester script with a shebang
    elif [ "$test_interpreter" == "python" ]; then
        head -n 1 "$input" |grep '^#!.*python' &>/dev/null
        #should be a python script with a shebang
    else
        die "Unknown type of test: $test_interpreter"
    fi
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
    if [ "$test_interpreter" == "bash" ]; then
        local tools="$(real_path bash_tester_tools.sh)"
        cat "$input" | sed "1 s%^.*$%source $tools $input%g" > "$input.tmp"
        input="$input.tmp"
    fi
    if ! test -f "$tp"
    then
        #echo "Error: helper timeout script not found: $tp"
        "$test_interpreter" "$input" &> "$output"
    else
        $tp -t $timeout "$test_interpreter" "$input" &> "$output"
    fi
    ret="$?"
    return "$ret"
}

if ! is_test "$test_interpreter" "$input"
then
    echo "Error: in order to work, insert a shebang line at the beginning of $input" > "$output"
    ret=1
    text="WHAT $(pwd) $input $output $ret"
else
    run_test "$test_interpreter" "$input" "$output"
    ret=$?

    line="$(get_results_line "$test_interpreter" "$output")"
    if is_test "$test_interpreter" "$input" && is_unittest_results "$line"
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
fi

echo "$text"
exit $result
