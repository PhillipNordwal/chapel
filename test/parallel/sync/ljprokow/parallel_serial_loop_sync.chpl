config const n = 100, m = 100;
var tempvar: int;
var x$: sync int = 0;

forall i in 1..n do
  for j in 1..m do
    x$ = x$ + 1;

tempvar = x$;
if (tempvar == (n * m))
  then writeln("PASSED");
  else writeln("FAILED: x$ is ", tempvar);