#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

if [ "$OSTYPE" == "darwin10.0"  ]; then platform="osx"; fi
if [ "$OSTYPE" == "msys"        ]; then platform="win"; fi
if [ "$OSTYPE" == "linux-gnu"   ]; then platform="lin"; fi
function path_file()
{
    if [ "$platform" == "lin" ]; then readlink -f "$1"
    else echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
}
function get_relative_path()
{
    if [ "$platform" == "lin" ]; then python -c "import os.path; print os.path.relpath('$(path_file "$1")', '$PWD')"
    else echo "$1"
    fi
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
input="$(get_relative_path $1)"
input="$(path_file $1)"
output="$(tmp_file)"
tp="/home/visual/venom/src/build/venom/timeout.sh"

function is_bashtest()
{
    head -n 1 "$input" |grep '^#!.*\(bash\|bash_tester\)' &>/dev/null
    #should be a bash or bash_tester script with a shebang
}

if ! is_bashtest "$input"
then
    echo "Error: in order to work, insert a shebang line at the beginning of $input" > "$output"
    ret=1
    text="WHAT $(pwd) $input $output $ret"
else
    input_tmp="$input.tmp"
    tools="$(path_file bash_tester_tools.sh)"
    cat "$input" | sed "1 s%^.*$%source $tools $input%g" > "$input_tmp"
    $tp -t 1 bash "$input_tmp" &> "$output"
    if ! test -f "$tp"
    then
        echo "Error: helper timeout script not found: $tp"
        bash "$input_tmp" &> "$output"
    else
        $tp -t 1 bash "$input_tmp" &> "$output"
    fi
    ret=$?

    line=$(cat $output | tail -1)
    if is_bashtest "$input"
    then
        #unittests
        fail=$(echo $line | grep -o F |wc -l)
        pass=$(echo $line | grep -o "\." |wc -l)
        total=$(($fail + $pass))
        if [ "$fail" -gt "0" ]
        then
            text="FAIL $(pwd) $input $output $ret $pass $total"
        else
            text="PASS $(pwd) $input $output $ret $pass $total"
        fi
    else
        #not unittests
        if [ "$ret" -eq 143 ]
        then
            text="TOUT $(pwd) $input $output"
        else
            if cat $output | grep "^Ran 0 tests in " &>/dev/null
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
