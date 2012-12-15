#!bash_tester.sh

function function_c()
{
    cp $1 $2
    true
    cp --dieeee
    true
}

function function_b()
{
    true
    function_c foobar $1
}
function function_a ()
{
    true
    function_b
    true
    true
    false
    true
}
foobar bazinga
true
false
true
cp
true
function_a
true
true
jfaskdl
true
true
true
