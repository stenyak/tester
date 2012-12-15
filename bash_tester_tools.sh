#!bash_tester.sh
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

results=""
test_ret=0
lastline=0
filename="$1"
function results()
{
    echo "======================================="
    if [ "$results" == "" ]
    then
        echo "Ran 0 tests"
    else
        echo "$results"
    fi
    exit $test_ret
}
function fail ()
{
    local ret=$1 # error status
    local funcname="$3"
    local line=$lastline # LINENO
    local command="$2"
    if [ "$funcname" != "" ]
    then
        lastlineno=${BASH_LINENO[0]}
        linenos=("${BASH_LINENO[@]}")
        unset linenos[0]
        command="$(cat $0 |head -n $lastlineno |tail -n 1 |sed "s/^\s*//g;")"
        echo "$filename:$lastlineno: error $ret returned by command: '$command'"
        for lno in ${linenos[@]}
        do
            if [ "$lno" -ne "0" ]
            then
                command="$(cat $0 |head -n $lno |tail -n 1 |sed "s/^\s*//g;")"
                echo "   called from line $lno: '$command'"
            fi
        done
        echo ""
    else
        command="$(cat $0 |head -n $line |tail -n 1)"
        echo "$filename:$line: error $ret returned by command: '$command'"
        echo ""
    fi
}
function debug ()
{
    local ret=$1 # error status
    local line=$2 # LINENO
    if [ "$ret" -eq 0 ]
    then
        results="${results}."
        lastline=$line
    else
        results="${results%?}F"
        test_ret=1
    fi
}
set -o errtrace
trap results 0
trap 'fail $? "$BASH_COMMAND" $FUNCNAME'  ERR
trap 'debug $? $LINENO "$BASH_COMMAND"'  debug

