class C {
  var x: int;
  proc foo() var {
    writeln(setter);
    return x;
  }
}

var c = new C();

c.foo() = 2;
writeln(c.foo());

delete c;
