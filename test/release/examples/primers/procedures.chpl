/*
 * Procedures Example
 *
 * This example contains several types of procedure, to illustrate
 * function overloading, intents and dynamic dispatch.
 * 
 * For examples of generic (template) functions, see generics.chpl.
 *
 */

//
// A procedure groups computations that can be called from another part
// of the program.  
// The procedure can be defined with zero or more "formal" arguments.
// Each formal argument can have a default value associated with it.
//
// Formal arguments are supplied with values when the procedure is called.
// The arguments supplied at the call site are the "actual" parameters.
// If a name is supplied with an actual argument, the value is assigned
// to the formal argument with the same name.  Any remaining (unnamed) actual
// arguments are assigned to the remaining formal arguments in lexical order.
//
// A procedure can return zero, one or more values (as a tuple).
// The return value type can be specified after the formal argument list.
// If no explicit return value type is supplied, the Chapel compiler infers the
// return value type.  
//

//
// Here is a procedure which takes an integer argument and returns and integer
// result.  It computes the factorial of the argument.
//
proc factorial(x: int) : int
{
  if x < 0 then
    halt("factorial -- Sorry, this is not the gamma function!");
  return if x == 0 then 1 else x * factorial(x-1);
}

writeln("A simple procedure");
writeln("6! is ", factorial(6));
writeln();

//
// Integers are somewhat small, so we might want to specify a larger return
// type.  Also, we can optimize a bit, compressing the call stack by a factor of 2.
//
proc factorial(x: int(64)) : int(64)
{
  if x < 1 then
    halt("factorial -- Invalid operand.");
  if x < 3 then return x;
  return x * (x-1) * factorial(x-2);
}
//
// The argument type of this version must be different, so the two versions of 
// factorial can be differentiated.
// We must also cast the actual argument to a 64-bit integer to select the "wide"
// version of factorial.
//
writeln("Another simple procedure");
writeln("33! is ", factorial(33: int(64)));
writeln();

//
// Procedure definitions allow you to overload operators, too.
//
record Point { var x, y: real; }

// Tell how to add two points together.
proc +(p1: Point, p2: Point)
{
  // Vector addition in 2-space.
  return new Point(p1.x + p2.x, p1.y + p2.y);
}

//
// We can also overload the writeThis() routine called by writeln.
//
proc Point.writeThis(w: Writer)
{
  // Writes it out as a coordinate pair.
  "(".writeThis(w);
  this.x.writeThis(w);
  ", ".writeThis(w);
  this.y.writeThis(w);
  ")".writeThis(w);
}

writeln("Using operator overloading");
var down = new Point(10.0, 0.0);
var over = new Point(0.0, -5.0);
writeln("down + over = ", down + over);
writeln();

//
// Using named actual arguments can prevent confusion.
//
class Circle {
  var center : Point;
  var radius : real;
}

proc create_circle(x = 0.0, y = 0.0, diameter = 0.0)
{
  var result = new Circle();
  result.radius = diameter / 2;
  result.center.x = x;
  result.center.y = y;
  return result;
}

writeln("Using named arguments");
// Creates a circle at (2.0, 0.0) with a radius of 1.5.
var c = create_circle(diameter=3.0,2.0);
writeln(c);
writeln();

//
// This configuration parameter allows automated tests to run faster
//  by skipping the sleep delays.
// You can try this yourself by adding -suseSleep=false as a compiler option.
//
config param useSleep = true;
use Time;

//
// Normal (blank) intent means that a formal argument cannot be modified
// in the body of a procedure.
// To allow changing the formal (but not the actual), use the "in" intent.
//
proc countDown(in n : uint = 10) : void
{
  while n > 0 
  {
    writeln(n, " ...");
    if useSleep then sleep(1);
    n -= 1;
  }
  writeln("Blastoff!");
}

writeln("Using the \"in\" intent");
var s = 5 : uint;
countDown(s);
writeln("s is still ", s);	// 5
writeln();

//
// The inout intent will write back the final value of a formal parameter when
// the procedure exits.
//
proc countDownToZero(inout n : uint = 10) : void
{
  while n > 0 
  {
    writeln(n, " ...");
    if useSleep then sleep(1);
    n -= 1;
  }
  writeln("Boink?");
}

writeln("Using the inout intent");
var t = 3 : uint;
countDownToZero(t);
writeln("t is now ", t);	// 0
writeln();

//
// The out intent causes an argument to be ignored when the procedure starts,
// but its value is written back when the routine exits.
//
// This arctan routine puts the result in res and returns the number of
// iterations it needed to converge.
//
// atan x = x - x^3/3 + x^5/5 + sum_3^inf (-1)^i x^(2i+1)/(2i+1).
//
// This actually converges very slowly for x close to 1 in absolute value.
// So we set the error limit to be 3 significant digits.
//
proc atan(x : real, out result : real)
{
  result = 0.0;
  var count = 0;
  var lastresult = 0.0;
  for i in 1.. by 2
  {
    var twoIP1 = 2 * count + 1;
    var term = x ** twoIP1 / twoIP1;
    result += if count % 2 == 0 then term else -term;
    count += 1;
    if abs(result - lastresult) < 1.0e-3 then break;
    lastresult = result;
  }
  return count;
}

writeln("Using the out intent");
var theta : real;
var n = atan(1.0, theta);
writeln("Computed Pi as about ", 4.0 * theta, " in ", n, " iterations.");
writeln();

//
// A procedure can take a variable number of arguments -- of indeterminate type.
// It is expanded like a generic procedure, with the required number of arguments
// having types which match the actual arguments.
//
proc writeList(x ...?k) {
  var first = true;
  for param i in 1..k {
    if first then first = false; else write(" ");
    write(x(i));
  }
  writeln();
}

writeln("Using variable argument lists.");
writeList(1, "red", 8.72, 1..4);
writeln();


