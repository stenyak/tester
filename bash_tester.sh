#!/bin/bash
# Copyright 2012 Bruno Gonzalez
# This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)

test "$_" == "$0" && btt_sourced=false || btt_sourced=true #is it run directly in subshell, or sourced?

function tmp_file()
{
    local result=""
    if [ "$OSTYPE" == "linux-gnu" ]; then result="$(tempfile)"
    else result="$(mktemp -t "$RANDOM")"; fi
    touch "$result"
    echo "$result"
}
btt_filename="$1"; shift
btt_output="$(tmp_file)"
btt_results=""
btt_test_ret=1
btt_lastline=0

if ! $btt_sourced
then
    if ! head -n 1 "$btt_filename" | grep "^#!.*bash" &>/dev/null; then 
        echo "Script has to start with a bash shebang line"
        exit 2
    fi
    cat "$btt_filename" | sed "1 s%^.*$%source $0 $btt_filename%g" > "$btt_filename.tmp"
    bash "$btt_filename.tmp" "$@"
    btt_test_ret=$?
    rm -f "$btt_filename.tmp"
    exit $btt_test_ret
fi

#temporarily redirect err and out to file, backing up stderr and stdout descriptors meanwhile
exec 4<&1 #stdout
exec 5<&2 #stderr
exec > "$btt_output" 2>&1

function btt_print_results()
{
    #restore stdout and stderr descriptors, allowing to output stuff normally
    exec 1<&4
    exec 2<&5
    echo "$btt_results"
    cat "$btt_output"
    echo "----------------------------------------------------------------------"
    echo "Ran $(echo $btt_results | grep -o "." | wc -l |sed "s/\ *//g") tests"
    echo ""
    local failed="$(echo $btt_results | grep -o "F" |wc -l |sed "s/\ *//g")"
    if [ "$failed" -gt 0 ]
    then
        echo "FAILED (failures=$failed)"
    else
        btt_test_ret=0
        echo "OK"
    fi
    exit $btt_test_ret
}
function btt_get_line ()
{
    local lineno="$1"; shift
    cat $0 |head -n $lineno |tail -n 1 |sed "s/^\s*//g;s/\s*$//g"
}
function btt_print_traceback ()
{
    local lines="$@"; shift
    echo "----------------------------------------------------------------------"
    echo "Traceback (most recent call last):"
    local traceback=""
    for line in $lines
    do
        if [ "$line" -ne "0" ]
        then
            traceback="  File \"$btt_filename\", line $line\n    $(btt_get_line $line)\n$traceback"
        fi
    done
    printf "$traceback"
}
function btt_fail ()
{
    local ret=$1; shift # error status
    local command="$1"; shift
    local funcname="$1"; shift
    local line=$btt_lastline # LINENO
    local lines=$line
    echo "======================================================================"
    if [ "$funcname" != "" ]
    then
        line=${BASH_LINENO[0]}
        lines="${BASH_LINENO[@]}"
    fi
    echo "FAIL: $btt_filename (line $line)"
    btt_print_traceback "$lines"
    echo "Exit status error: Expected 0, but got $ret"
    btt_results="${btt_results}F"
    btt_test_ret=1
    echo ""
}
function btt_debug ()
{
    local ret=$1; shift # error status
    local line=$1; shift # LINENO
    local cmd="$1"; shift
    if [ "$line" == "1" ]; then return; fi
    if echo "$cmd" | grep btt_debug &>/dev/null; then return; fi
    btt_results="${btt_results}."
    if [ "$ret" -eq 0 ]
    then
        btt_lastline=$line
    fi
}
#set -o functrace
set -o errtrace
trap btt_print_results 0
trap 'btt_fail $? "$BASH_COMMAND" $FUNCNAME'  ERR
trap 'btt_debug $? $LINENO "$BASH_COMMAND"'  debug

