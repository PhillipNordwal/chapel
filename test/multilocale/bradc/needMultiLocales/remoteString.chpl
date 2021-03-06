var s1: string;
var flag1: sync bool;
var done: sync bool;

extern proc printf(x...);

proc main() {
  s1 = "foo";
  on Locales(1) do begin ref(s1) {
    const tmp = flag1;
    printf("%s\n", "s1 is: " + s1);
    done = true;
  }
  s1 = "boohoo";
  flag1 = true;
  done;

  var s2: string;
  var flag2: sync bool;

  s2 = "foo";
  on Locales(1) do begin ref(s2) {
    const tmp = flag2;
    printf("%s\n", "s2 is: " + s2);
  }
  s2 = "boohoo";
  flag2 = true;
}
