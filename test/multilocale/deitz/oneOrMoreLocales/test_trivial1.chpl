proc main {
  var x: int;
  coforall i in 0..numLocales-1 {
    var y: int;
    on rootLocale.getLocales()(i) {
      y = i+3628800;
    }
    x += y;
  }
  writeln((x-(numLocales*(numLocales-1)/2))/numLocales);
}
