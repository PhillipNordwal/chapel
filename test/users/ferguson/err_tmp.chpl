use SysBasic;

proc doDebugWrite(x, y):err_t {
  writeln("Debug Write: ", x, y);
  return chpl_int_to_err(1);
}

proc test(arg:string, out error:err_t):bool {
  error = ENOERR;
  on rootLocale.getLocales()[0] {
    if ! error {
      error = doDebugWrite("test ", arg);
    }
  }
}

var e:err_t = ENOERR;
test("hello", e);
