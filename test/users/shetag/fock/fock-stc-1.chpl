module fock {
use blockindices;

type elemType = real(64);

config const natom = 5;
const bas_info : [1..natom] range = [i in 1..natom] (1..10/(i%2+1)) + 5*(i/2) + 10*((i-1)/2);

const n = (natom/2)*10 + ((natom+1)/2)*5;
const matD : domain(2) = {1..n, 1..n}; 
const dmat : [matD] elemType = [(i,j) in matD] 1.0/(i+j); 
var jmat2, kmat2, jmat2T, kmat2T : [matD] elemType; 

proc buildjk() {
  var loc = rootLocale.getLocaleSpace().low;
  sync {
    for iat in 1..natom do
      for (jat, kat) in {1..iat, 1..iat} {
        const lattop = if (kat==iat) then jat else kat;
        for lat in 1..lattop {
          on rootLocale.getLocales()(loc) do begin buildjk_atom4(new blockIndices(iat, jat, kat, lat));
          loc = (loc+1)%numLocales;
        }
      }
  }

  cobegin {
    [(i,j) in matD] jmat2T(i,j) = jmat2(j,i);
    [(i,j) in matD] kmat2T(i,j) = kmat2(j,i);
  }

  cobegin {
    jmat2 = (jmat2 + jmat2T) * 2;
    kmat2 += kmat2T;
  }

  writeln("\n1st row of coulomb matrix:-\n", jmat2(1..1,1..n));
  writeln("\n1st col of coulomb matrix:-\n", jmat2(1..n,1..1));
  writeln("\n1st row of exchange matrix:-\n", kmat2(1..1,1..n));
  writeln("\n1st col of exchange matrix:-\n", kmat2(1..n,1..1));
}

var oneAtATime: sync bool = true; // workaround because atomics don't work

proc buildjk_atom4(blk) {

  // BLC: TODO: Once we have arrays of differently-sized arrays, the
  // following sets of six statements can be replaced by arrays of
  // 1..6 (the number of pairs of ijkl) of domains and slices and ...

  const ijD = {blk.is, blk.js},
        ikD = {blk.is, blk.ks},
        ilD = {blk.is, blk.ls},
        jkD = {blk.js, blk.ks},
        jlD = {blk.js, blk.ls},
        klD = {blk.ks, blk.ls};

  const dij = dmat(ijD),  // BLC: TODO -- use array views here
        dik = dmat(ikD),
        dil = dmat(ilD),
        djk = dmat(jkD),
        djl = dmat(jlD),
        dkl = dmat(klD);

  var jij : [ijD] elemType,
      jkl : [klD] elemType,
      kik : [ikD] elemType,
      kil : [ilD] elemType,
      kjk : [jkD] elemType,
      kjl : [jlD] elemType;

  for (i,j,k,l,gijkl) in blk.genIndices() {
    jij(i,j) += dkl(k,l)*gijkl;
    jkl(k,l) += dij(i,j)*gijkl;
    kik(i,k) += djl(j,l)*gijkl;
    kil(i,l) += djk(j,k)*gijkl;
    kjk(j,k) += dil(i,l)*gijkl;
    kjl(j,l) += dik(i,k)*gijkl;
  }

  var tmp = oneAtATime;
  atomic jmat2(ijD) += jij;
  atomic jmat2(klD) += jkl;
  atomic kmat2(ikD) += kik;
  atomic kmat2(ilD) += kil;
  atomic kmat2(jkD) += kjk;
  atomic kmat2(jlD) += kjl;
  oneAtATime = tmp;
}

proc main() {
  buildjk();
}

}
