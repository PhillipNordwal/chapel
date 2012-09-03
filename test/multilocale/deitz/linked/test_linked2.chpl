record C {
  var x: int;
}

class D {
  var cs: [0..numLocales-1] C;

  proc initialize() {
    coforall i in 0..numLocales-1 do 
      on rootLocale.getLocales()(i) do cs[i] = new C(i);
  }
}

var d = new D();
writeln(d);
writeln(d.cs);
for i in 0..numLocales-1 do
  writeln(d.cs[i].locale.id);
