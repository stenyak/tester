#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

function get_relative_path()
{
    python -c "import os.path; print os.path.relpath('$(readlink -f $1)', '$PWD')"
}
input="$(get_relative_path $1)"
input="$(readlink -f $1)"
output="$(tempfile)"
tp="/home/visual/venom/src/build/venom/timeout.sh"

function is_bashtest()
{
    head -n 1 "$input" |grep '^#!.*\(bash\|bash_tester\)' &>/dev/null
    #should be a bash or bash_tester script with a shebang
}

if ! is_bashtest "$input"
then
    echo "Error: in order to work, insert a shebang line at the beginning of $input" > $output
    ret=1
    text="WHAT $(pwd) $input $output $ret"
else
    input_tmp="$input.tmp"
    tools="$(readlink -f bash_tester_tools.sh)"
    cat "$input" | sed "1 s%^.*$%source $tools $input_tmp%g" > "$input_tmp"
    $tp -t 1 bash "$input_tmp" &> "$output"
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
