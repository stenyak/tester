#!/bin/bash
##############################################
# Public helper functions (for use by test scripts)

# Like grep, but outputs all lines (not just matched lines). E.g.:
#    echo "all is correct" |& catgrep "correct"    #OK
#    echo "an error occurred" |& catgrep "correct"  #FAIL
function catgrep
{
    local tmp="$(tempfile)"
    touch $tmp
    cat >$tmp
    echo "">>$tmp
    grep "$@" "$tmp" &>/dev/null
    local ret=$?
    cat $tmp
    rm -f $tmp
    return $ret
}

# Like catgrep, but returns 0 only when NO match was found. E.g.:
#    TEST echo "all is correct" |& catngrep "error"  #OK
#    TEST echo "an error occurred" |& catngrep "error"    #FAIL
function catngrep
{
    cat | catgrep "$@"
    local retn=$?
    if [ "$retn" == "1" ]
    then
        return 0
    else
        return 1
    fi
}
##############################################
