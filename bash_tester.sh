#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

test "$_" == "$0" && btt_sourced=false || btt_sourced=true #is it run directly in subshell, or sourced?

btt_filename="$1"; shift
btt_results=""
btt_test_ret=1
btt_lastline=0

if ! $btt_sourced
then
    cat "$btt_filename" | sed "1 s%^.*$%source $0 $btt_filename%g" > "$btt_filename.tmp"
    bash "$btt_filename.tmp" "$@"
    btt_test_ret=$?
    rm -f "$btt_filename.tmp"
    exit $btt_test_ret
fi
function btt_print_results()
{
    echo "${btt_results:-Ran 0 tests}"
    exit $btt_test_ret
}
function btt_fail ()
{
    local ret=$1; shift # error status
    local command="$1"; shift
    local funcname="$1"; shift
    local line=$btt_lastline # LINENO
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
    local ret=$1; shift # error status
    local line=$1; shift # LINENO
    local cmd="$1"; shift
    if echo "$cmd" | grep btt_debug &>/dev/null; then return; fi
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
