#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

btt_results=""
btt_test_ret=0
btt_lastline=0
btt_filename="$1"
function btt_print_results()
{
    if [ "$btt_results" == "" ]
    then
        echo "Ran 0 tests"
    else
        echo "$btt_results"
    fi
    exit $btt_test_ret
}
function btt_fail ()
{
    local ret=$1 # error status
    local funcname="$3"
    local line=$btt_lastline # LINENO
    local command="$2"
    if [ "$funcname" != "" ]
    then
        local lastlineno=${BASH_LINENO[0]}
        local linenos=("${BASH_LINENO[@]}")
        unset linenos[0]
        command="$(cat $0 |head -n $lastlineno |tail -n 1 |sed "s/^\s*//g;")"
        echo "$btt_filename:$lastlineno: error $ret returned by command: '$command'"
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
        echo "$btt_filename:$line: error $ret returned by command: '$command'"
        echo ""
    fi
}
function btt_debug ()
{
    local ret=$1 # error status
    local line=$2 # LINENO
    if [ "$ret" -eq 0 ]
    then
        btt_results="${btt_results}."
        btt_lastline=$line
    else
        btt_results="${btt_results%?}F"
        btt_test_ret=1
    fi
}
set -o errtrace
trap btt_print_results 0
trap 'btt_fail $? "$BASH_COMMAND" $FUNCNAME'  ERR
trap 'btt_debug $? $LINENO "$BASH_COMMAND"'  debug

