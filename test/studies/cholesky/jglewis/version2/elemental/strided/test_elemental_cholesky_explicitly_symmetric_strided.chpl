module test_elemental_explicitly_strided_cholesky {

  // +------------------------------------------------------------------------+
  // |  TEST DRIVER FOR VARIATIONS ON DENSE SYMMETRIC CHOLESKY FACTORIZATION  |
  // +------------------------------------------------------------------------+
  // |  Special Driver to test changes needed to standard elemental Cholesky  |
  // |  factorization code to explicitly code for striding in the input       |
  // |  matrix.                                                               |
  // |                                                                        |
  // |  This version expects A to be a matrix with identical, but strided,    |
  // |  row and column indices.                                               |
  // |                                                                        |
  // |  (Allowing unequal strides creates complications similar to allowing   |
  // |   different row and column index sets.)                                |
  // +------------------------------------------------------------------------+

  use Random;

  use CyclicDist, Time;

  use cholesky_execution_config_consts;

  use elemental_cholesky_symmetric_strided,
      elemental_cholesky_symmetric_index_ranges;

  proc main {

    var Rand = new RandomStream ( seed = 314159) ;

    const unstrided_MatIdx = { index_base .. #n, index_base .. #n };

    const strided_MatIdx   = { index_base .. by stride #n , 
		               index_base .. by stride #n };

    const strided_mat_dom : domain (2, stridable = true) 
          dmapped Cyclic ( startIdx = strided_MatIdx.low )
      =   strided_MatIdx;

    const unstrided_mat_dom : domain (2, stridable = false) 
          dmapped Cyclic ( startIdx = unstrided_MatIdx.low )
      =   unstrided_MatIdx;

    const distribution_type = "cyclic";

    var A : [unstrided_mat_dom] real,
        B : [unstrided_mat_dom] real,
        L_unstrided : [unstrided_mat_dom] real,
        L : [strided_mat_dom] real;

    var positive_definite : bool;

    writeln ("Cholesky Factorization Tests for Strided Index Ranges");
    writeln ("   Matrix Dimension  : ", n);
    writeln ("   Block Size        : ", block_size);
    writeln ("   Indexing Base     : ", index_base);
    writeln ("   Array distribution: ", distribution_type );
    writeln ("");
    writeln ("Parallel Environment");
    writeln ("   Number of Locales         : ", numLocales );
   if !reproducible_output then
     writeln ("   Number of cores per locale: ", rootLocale.getLocales().numCores );

    // ---------------------------------------------------------------
    // create a test problem, starting with a random general matrix B.
    // ---------------------------------------------------------------

    Rand.fillRandom (B);

    // -------------------------------------------------------------
    // create a positive definite matrix A by setting A equal to the
    // matrix-matrix product B B^T.  This normal equations matrix is 
    // positive-definite as long as B is full rank.
    // -------------------------------------------------------------

    A = 0.0;

    forall (i,j) in unstrided_mat_dom do
      A (i,j) = + reduce (  [k in unstrided_mat_dom.dim (1) ] 
    			    B (i, k) * B (j, k) );

    // factorization algorithms overwrite a copy of A, leaving
    // the factor L in its place

    L_unstrided = A;

    if print_matrix_details then {
      writeln ("test matrix");
      print_lower_triangle ( L_unstrided );
    }

    var clock : Timer;
          
    writeln ("\n\n");
    writeln ("elemental cholesky factorization symmetric index range code\n " + 
	     "on symmetric index range");

    clock.clear ();
    clock.start ();

    positive_definite = 
      elemental_cholesky_symmetric_index_ranges ( L_unstrided );

    clock.stop ();
    if !reproducible_output then {
      writeln ( "Cholesky Factorization time:    ", clock.elapsed () );
      writeln ( " collective speed in megaflops: ", 
		( (n**3) / 3.0 )  / (10.0**6 * clock.elapsed () ) );
    }

    print_lower_triangle ( L_unstrided );

    if positive_definite then
      check_factorization ( A, L_unstrided );
    else
      writeln ("factorization failed for non-positive semi-definite matrix");

    L = A;

    writeln ("elemental cholesky factorization");
    writeln ("   symmetrically strided        ");
    writeln ("   symmetric index array input  ");
    writeln ("");

    clock.clear ();
    clock.start ();

    positive_definite = elemental_cholesky_strided ( L );

    clock.stop ();
    if !reproducible_output then {
      writeln ( "Cholesky Factorization time:    ", clock.elapsed () );
      writeln ( " collective speed in megaflops: ", 
		( (n**3) / 3.0 )  / (10.0**6 * clock.elapsed () ) );
    }

    print_lower_triangle ( L );

    if positive_definite then
      check_factorization ( A, L );
    else
      writeln ("factorization failed for non-positive semi-definite matrix");
  }


  proc check_factorization ( A : [], L_formal : [] )

    // -----------------------------------------------------------------------
    // Check the factorization by forming L L^T and comparing the result to A.
    // The factorization is successful if the results are within the
    // point-wise perturbation bounds of Demmel, given as Theorem 10.5 in
    // Higham's "Accuracy and Stability of Numerical Algorithms, 2nd Ed."
    // -----------------------------------------------------------------------

    where ( A.domain.rank == 2 ) {

    assert ( A.domain.dim (1)               == A.domain.dim (2)         &&
	     L_formal.domain.dim (1).length == A.domain.dim (1).length  &&
	     L_formal.domain.dim (2).length == A.domain.dim (2).length 
	     );
    
    const mat_dom  = A.domain,
          mat_rows = A.domain.dim(1),
          n        = A.domain.dim(1).length;

    var L : [ mat_dom ] => L_formal;

    print_lower_triangle ( L );

    const unit_roundoff = 2.0 ** (-53), // IEEE 64 bit floating point
          gamma_n1      = (n * unit_roundoff) / (1.0 - n * unit_roundoff);

    var   resid : real,
          max_ratio = 0.0;

    var   d : [mat_rows] real;

    for i in mat_rows do
      d (i) = sqrt ( A (i,i) );
    
    forall (i,j) in mat_dom do {
      resid  = abs (A (i,j) - 
		    + reduce ( [k in mat_dom.dim(1) (..min (i,j))]
			       L (i,k) * L (j,k) ) ) ;
      max_ratio = max ( max_ratio,
			resid * (1 - gamma_n1) /
			( gamma_n1 * d (i) * d (j) ) );
    }

    if max_ratio <= 1.0 then
      writeln ("factorization successful");
    else
      writeln ("factorization error exceeds bound by ratio:", max_ratio);
  }


  proc print_lower_triangle ( L : [] ) {
   
    if print_matrix_details then
      for (i_row, i_col) in ( L.domain.dim(1), L.domain.dim(2) ) do
	writeln (i_row, ":  ", L(i_row, L.domain.dim(2)(..i_col)) );
  }

}
    
