class C {
  var left, right: C;
  
  proc countNodes(): int {
    var lnodes, rnodes: int;
    cobegin ref(lnodes, rnodes) {
            lnodes = if left == nil then 0 else left.countNodes();
            rnodes = if right == nil then 0 else right.countNodes();
    }
    return lnodes + rnodes + 1;
  }
}

var c = new C(new C(), new C(new C(), new C()));

writeln("c has ", c.countNodes(), " nodes");

delete c.left;
delete c.right.left;
delete c.right.right;
delete c.right;
delete c;
