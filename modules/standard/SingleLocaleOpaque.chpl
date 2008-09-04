use List;
class SingleLocaleOpaqueDomain: BaseOpaqueDomain {
  type idxType = _OpaqueIndex;
  var dist: DefaultDist;
  var adomain: SingleLocaleAssociativeDomain(idxType=_OpaqueIndex);

  def SingleLocaleOpaqueDomain(dist: DefaultDist) {
    this.dist = dist;
    adomain = new SingleLocaleAssociativeDomain(_OpaqueIndex, dist);
  }

  def create() {
    var i = new _OpaqueIndex();
    adomain.add(i);
    return i;
  }

  def getIndices() return adomain;

  def setIndices(b: SingleLocaleAssociativeDomain) {
    adomain.setIndices(b);
  }

  def these() {
    for i in adomain do
      yield i;
  }

  def member(ind: idxType) {
    return adomain.member(ind);
  }

  def numIndices {
    return adomain.numIndices;
  }

  def buildArray(type eltType) {
    var ia = new SingleLocaleOpaqueArray(eltType, idxType, dom=this);
    return ia;
  }
}

def SingleLocaleOpaqueDomain.writeThis(f: Writer) {
  adomain.writeThis(f);
}

def SingleLocaleOpaqueArray.writeThis(f: Writer) {
  anarray.writeThis(f);
}

class SingleLocaleOpaqueArray: BaseArray {
  type eltType;
  type idxType;

  var dom: SingleLocaleOpaqueDomain(idxType=idxType);
  var anarray = new SingleLocaleAssociativeArray(eltType, idxType, dom.adomain);

  def this(ind : idxType) var : eltType
    return anarray(ind);

  def these() var {
    for e in anarray do
      yield e;
  }

  def sorted() {
    for e in anarray.sorted() do
      yield e;
  }

  def numElements {
    return anarray.numElements;
  }

  def tupleInit(b: _tuple) {
    anarray.tupleInit(b);
  }
}

def SingleLocaleOpaqueDomain.remove(idx: idxType) {
  adomain.remove(idx);
}
