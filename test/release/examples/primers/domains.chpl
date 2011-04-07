/*
 * Domains primer
 *
 * This primer showcases Chapel domains.  For other uses of domains
 * see the Arrays primer (arrays.chpl) and the Sparse arrays primer
 * (sparse.chpl).
 *
 */

config var n = 10;
//
// A domain is a first-class representation of an index set used to
// specify iteration spaces, define arrays, and aggregate operations
// such as slicing.
//

//
// Chapel provides two base domain types: rectangular and associative.
//
// Rectangular domains are used to represent rectangular index sets.
// Each dimesion of a rectangular domain is specified by a range and
// thus can take on the shape of any range.  See the Ranges primer
// (ranges.chpl) for more information.
//
// RD is an n by n by n domain.
//
var RD: domain(3) = [1..n, 1..n, 1..n];
writeln(RD);

// 
// Rectangular domains have a set of methods that enable convenient
// reuse of existing domains.
//
// The expand method returns a new domain that is expanded or
// contracted depending on the sign of the offset argument.
//
var RDbigger = RD.expand((1,1,1));
writeln(RDbigger);
var RDsmaller = RD.expand((-1,-1,-1));
writeln(RDsmaller);

//
// The exterior method returns a new domain that is the exterior
// portion of the current domain.  A positive offset specifies that
// the exterior should be taken from the high bound; a negative
// offset, the low bound.
//
var RDext_p = RD.exterior((1,1,1));
writeln(RDext_p);
var RDext_n = RD.exterior((-1,-1,-1));
writeln(RDext_n);

//
// The interior method returns a new domain that is the interior
// portion of the current domain.  The sign of the offset implies
// using the high or low bound as in the exterior case.
//
var RDint_p = RD.interior((1,1,1));
writeln(RDint_p);
var RDint_n = RD.interior((-1,-1,-1));
writeln(RDint_n);

//
// The translate method returns a new domain that is the current domain
// translated by the offset.
//
var RDtrans_p = RD.translate((1,1,1));
writeln(RDtrans_p);
var RDtrans_n = RD.translate((-1,-1,-1));
writeln(RDtrans_n);

//
// Associative domains represent an arbitrary index set of any type.
//
// AD is an associative array indexed by strings.  Associative domains
// start out empty.
//
var AD: domain(string);
writeln(AD);

//
// The '+' operator is used to add indices to an associative domain.
//
AD += "John";
AD += "Paul";
AD += "Stuart";
AD += "George";
writeln(AD);

//
// The '-' operator is used to remove indices to an associative domain.
//
AD -= "Stuart";
AD += "Ringo";
writeln(AD);


/*
 * For more information on domains, see the Domains chapter of the
 * Chapel Language Spec.
 */