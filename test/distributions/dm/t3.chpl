// This exposes a (performance) bug where 'dmarr' is not local in privTest().

use d, r, u;

config const s1 = 2;
config const s2 = 2;
setupLocales(s1, s2);

var vdf = new vdist(s1);
var sdf = new sdist(s2, 1, 3);
var ddf = new DimensionalDist(mylocs, vdf, sdf, "ddf");
const dmbase = [1..3,1..4];
var dmdom: domain(2) dmapped new dmap(ddf);
dmdom = dmbase;
var dmarr: [dmdom] int;

hd("privatization tests");
privTest(dmarr, (0,0), (1,2), 0);
privTest(dmarr, (0,1), (2,3), 0);
privTest(dmarr, (1,0), (3,1), 0);
privTest(dmarr, (1,1), (3,3), 0);
tl();