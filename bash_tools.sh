#!/bin/bash
##############################################
# Public helper functions (for use by test scripts)

# Like grep, but outputs all lines (not just matched lines) in case of error. E.g.:
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
    if [ "$ret" != "0" ]; then
        cat $tmp
    fi
    rm -f $tmp
    return $ret
}

# Like catgrep, but returns 0 only when NO match was found. E.g.:
#    TEST echo "all is correct" |& catngrep "error"  #OK
#    TEST echo "an error occurred" |& catngrep "error"    #FAIL
function catngrep
{
    local tmp="$(tempfile)"
    touch $tmp
    cat >$tmp
    echo "">>$tmp
    grep "$@" "$tmp" &>/dev/null
    local ret=$?
    if [ "$ret" == "0" ]; then
        cat $tmp
        ret=1
    else
        ret=0
    fi
    rm -f $tmp
    return $ret
}
##############################################
