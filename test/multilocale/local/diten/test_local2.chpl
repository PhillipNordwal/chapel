proc main() {
  var x, y, z: int;
  on rootLocale.getLocales()(1) {
    x = 1;
    y = 2;
    z = x + y;
    var w = 4;
    on rootLocale.getLocales()(0) {
      local {
        x = y + z;
        x = x + w;
      }
      w = 4;
    }
  }
  writeln(x, y, z);
}
