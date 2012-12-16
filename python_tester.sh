#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

input="$(readlink -f $1)"
output="$(tempfile)"
tp="/home/visual/venom/src/build/venom/timeout.sh"

$tp -t 1 python "$input" &>$output
ret=$?

line=$(cat $output | head -1)
function is_unittest_results()
{
    #unittest results line looks like: FFFF..F.F.FF..F
    if [ "$line" == "" ]
    then
        #empty first line, not a results line
        false
    else
        #if first line has anything other than 'F' and '.' its not a results line
        echo "$1" | grep -v "[^F\.]" &>/dev/null
    fi
}
if is_unittest_results "$line"
then
    #is a bash test
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
    #not unittests
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

echo "$text"
exit $result
