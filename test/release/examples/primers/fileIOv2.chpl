/*
 * 2nd File I/O Primer
 *
 * Show some of the more complicated features of I/O in Chapel
 */

/* First and Second examples: Binary I/O
   Third example: reading UTF-8 lines and printing them out.
   Fourth example: error handling.
   Fifth example: object-at-a-time writing.
   Sixth example: binary I/O with bits at a time
*/

config const n = 1*1024*1024;
config const example = 0;
config const testfile = "test.bin";

use IO;

/*
   In Examples 1 and 2, we will write numbers 0..n-1 to a file in binary,
   and then we'll open it up, and read the numbers in reverse,
   just to show how to 'seek' in a file.

   We show two versions of this example; a simple version, and
   a slightly more complicated version that has some performance hints.
*/

if example == 0 || example == 1 {
  writeln("Running Example 1");

  // Here comes the simple version!

  // First, open up a test file. Chapel's I/O interface allows
  // us to open regular files, temporary files, memory, or file descriptors;
  // we can also specify access with "r", "w", "r+", "w+", etc.
  var f = open(testfile, mode.wr);

  /* Since the typical 'file position' design leads to race conditions
   * all over, the Chapel I/O design separates a file from a channel.
   * A channel is a buffer to a particular spot in a file. Channels
   * can have a start and and end, so that if you're doing parallel I/O
   * to different parts of a file with different channels, you can
   * partition the file to be assured that they do not interfere.
   */

  {
    var w = f.writer(kind=native); // get a binary writing channel for the start of the file.

    for i in 0..#n { // for each i in [0,n)
      var tmp:uint(64) = i:uint(64);
      w.write(tmp); // writing a uint(64) will write 8 bytes.
    }

    // Now w goes out of scope, it will flush anything that is buffered.
    // Channels are reference-counted, so it should be easy, but if you want to make sure,
    // you can close the channel.
    w.close();
  }

  // OK, now we have written our data file. Now read it backwards.
  // Note -- this could be a forall loop to do I/O in parallel!
  for i in 0..#n by -1 {
    var r = f.reader(kind=native, start=8*i, end=8*i+8);
    var tmp:uint(64);
    r.read(tmp);
    assert(tmp == i:uint(64));
    r.close();
  }

  // Now close the file. Like channels, files are reference-counted,
  // and so should close when they go out of scope, but we close it
  // here anyway to be sure.
  f.close();

  // Finally, we can remove the test file.
  unlink(testfile);
}

if example == 0 || example == 2 {
  writeln("Running Example 2");

  /* Here comes a faster version of example 1, using some hints.
     This time we're not going to use a temporary file, because
     we want to open it twice for performance reasons.
     If you want to measure the performance difference, try:
       time ./fielIOv2 --example=1
       time ./fielIOv2 --example=2
   */

  // First, open up a file and write to it.
  {
    var f = open(testfile, mode.wr);
    /* When we create the writer, suppling locking=false will do unlocked I/O.
       That's fine as long as the channel is not shared between tasks.
      */
    var w = f.writer(kind=native, locking=false);

    for i in 0..#n {
      var tmp:uint(64) = i:uint(64);
      w.write(tmp);
    }

    w.close();
    f.close();
  }

  /* Now that we've created the file, when we open it for
     read access and hint 'random access' and 'keep data cached/assume data is cached',
     we can optimize better (using mmap, if you like details).
   */
  {
    var f = open(testfile, mode.r, hints=HINT_RANDOM|HINT_CACHED);

    // Note -- this could be a forall loop to do I/O in parallel!
    forall i in 0..#n by -1 {
      /* When we create the reader, suppling locking=false will do unlocked I/O.
         That's fine as long as the channel is not shared between tasks;
         here it's just used as a local variable, so we are O.K. 
        */
      var r = f.reader(kind=native, locking=false, start=8*i, end=8*i+8);
      var tmp:uint(64);
      r.read(tmp);
      assert(tmp == i:uint(64));
      r.close();
    }

    f.close();
  }

  // Finally, we can remove the test file.
  unlink(testfile);
}

/*
   In Example 3, we show that it's easy to read the lines in a file,
   including UTF-8 characters.
*/
if example == 0 || example == 3 {
  writeln("Running Example 3");

  var f = open(testfile, mode.wr);
  var w = f.writer();

  w.writeln("Hello");
  w.writeln("This");
  w.writeln(" is ");
  w.writeln(" a test ");
  // We only write the UTF-8 characters if unicode is supported,
  // and that depends on the current unix locale environment
  // (e.g. setting the environment variable LC_ALL=C will disable unicode support). 
  if unicodeSupported() then w.writeln(" of UTF-8 Euro Sign: €");

  // flush buffers, close the channel.
  w.close();
  
  var r = f.reader();
  var line:string;
  while( r.readline(line) ) {
    write("Read line: ", line);
  }
  r.close();

  // Or, if we just want all the lines in the file,
  // we can use file.lines, and we don't even have to make a reader:
  for line in f.lines() {
    write("Read line: ", line);
  }

  f.close();
  unlink(testfile);
}

/*
   In Example 4, we show that error handling is possible
   with the new I/O routines. Maybe one day this strategy will
   be replaced by exceptions, but until then... Chapel programs
   can still respond to errors.
   
*/
if example == 0 || example == 4 {
  writeln("Running Example 4");

  // Error handling.
  var err = ENOERR;
  // Who knows, maybe 1st unlink succeeds.
  unlink(testfile, error=err);

  // File does not exist by now, for sure.
  unlink(testfile, error=err);
  assert(err == ENOENT);
  
  // What happens if we try to open a non-existant file?
  var f = open(testfile, mode.r, error=err);
  assert(err == ENOENT);

  /* Note that if an error= argument is not supplied to an
     I/O function, it will call ioerror, which will
     in turn halt with an error message.
   */
}

/*
   In Example 5, we demonstrate that output from multiple tasks
   can use the same channel, and each write() call will be
   completed entirely before another one is allowed to begin.
*/
if example == 0 || example == 5 {
  writeln("Running Example 5");

  forall i in 1..4 {
    writeln("This should be a chunk: {", "\n a", "\n b", "\n}");
  }

  record MyThing {
    proc writeThis(w:Writer) {
      w.writeln("This should be a chunk: {");
      w.writeln(" a");
      w.writeln(" b");
      w.writeln("}");
    }
  }

  forall i in 1..4 {
    var t:MyThing;
    write(t);
  }
}

/*
   In Example 6, we demonstrate bit-level I/O.
 */
if example == 0 || example == 6 {
  writeln("Running Example 6");

  var f = open(testfile, mode.wr);

  {
    var w = f.writer(kind=native);

    // Write 011 0110 011110000
    w.writebits(0b011, 3);
    w.writebits(0b0110, 4);
    w.writebits(0b011110000, 9);
    w.close();
  }

  // Try reading it back the way we wrote it.
  {
    var r = f.reader(kind=native);
    var tmp:uint(64);

    r.readbits(tmp, 3);
    assert(tmp == 0b011);

    r.readbits(tmp, 4);
    assert(tmp == 0b0110);

    r.readbits(tmp, 9);
    assert(tmp == 0b011110000);
  }

  // Try reading it back all as one big chunk.
  // Read 01101100 11110000
  {
    var r = f.reader(kind=native);
    var tmp:uint(8);

    r.read(tmp);
    assert(tmp == 0b01101100);

    r.read(tmp);
    assert(tmp == 0b11110000);
  }
}
