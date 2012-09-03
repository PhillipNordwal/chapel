class C {
  var a: int;
  var next: C;
}

var A: [1..5] C;

on rootLocale.getLocales()(1) {
  [i in A.domain] A(i) = new C(i);
}

[i in A.domain] A(i).next = new C(i+1);

var B = A.next;
writeln("First local block");
local {
  B.next = new C(B.a + 1);
}

proc foo(c: C) {
  c.a = c.a - 3;
}

on rootLocale.getLocales()(1) {
  var localA: [A.domain.low..A.domain.high] C;
  localA = A;
writeln("Second local block");
  local {
    foo(localA);
  }
}


foo(A);
writeln("Third local block");
local {
  serial true do foo(A); // this line causes the error
}

writeln(A);

