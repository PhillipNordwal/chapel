proc foo(inout x: int) {
  writeln(x);
  on rootLocale.getLocales()(1) {
    writeln(x);
    x += 1;
    writeln(x);
  }
  writeln(x);
}

var x: int = 3;

writeln(x);
foo(x);
writeln(x);
