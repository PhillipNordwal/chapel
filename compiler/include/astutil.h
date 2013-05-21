#ifndef _ASTUTIL_H_
#define _ASTUTIL_H_

#include "baseAST.h"
#include "alist.h"

#include <vector>

class Type;
class FnSymbol;
class VarSymbol;
class ArgSymbol;
class BlockStmt;
class CallExpr;
class SymExpr;
class Expr;

void normalize(BaseAST* base);

// return vec of CallExprs of FnSymbols (no primitives)
void collectFnCalls(BaseAST* ast, Vec<CallExpr*>& calls);

// collect Stmts and Exprs in the AST and return them in vectors
// Versions ending in 'STL' use the C++ std::vector class
void collect_asts(BaseAST* ast, Vec<BaseAST*>& asts);
void collect_asts_STL(BaseAST* ast, std::vector<BaseAST*>& asts);
void collect_asts_postorder(BaseAST*, Vec<BaseAST*>& asts);
void collect_asts_postorder_STL(BaseAST*, std::vector<BaseAST*>& asts);
void collect_top_asts(BaseAST* ast, Vec<BaseAST*>& asts);
void collect_top_asts_STL(BaseAST* ast, std::vector<BaseAST*>& asts);
void collect_stmts(BaseAST* ast, Vec<Expr*>& stmts);
void collect_stmts_STL(BaseAST* ast, std::vector<Expr*>& stmts);
void collectDefExprs(BaseAST* ast, Vec<DefExpr*>& defExprs);
void collectDefExprsSTL(BaseAST* ast, std::vector<DefExpr*>& defExprs);
void collectCallExprs(BaseAST* ast, Vec<CallExpr*>& callExprs);
void collectCallExprsSTL(BaseAST* ast, std::vector<CallExpr*>& callExprs);
void collectMyCallExprs(BaseAST* ast, Vec<CallExpr*>& callExprs, FnSymbol* fn);
void collectGotoStmts(BaseAST* ast, Vec<GotoStmt*>& gotoStmts);
void collectGotoStmtsSTL(BaseAST* ast, std::vector<GotoStmt*>& gotoStmts);
void collectSymExprs(BaseAST* ast, Vec<SymExpr*>& symExprs);
void collectSymExprsSTL(BaseAST* ast, std::vector<SymExpr*>& symExprs);
void collectSymbols(BaseAST* ast, Vec<Symbol*>& symbols);
void collectSymbolsSTL(BaseAST* ast, std::vector<Symbol*>& symbols);

// utility routines for clearing and resetting lineno and filename
void reset_ast_loc(BaseAST* destNode, astlocT astloc);
void reset_ast_loc(BaseAST* destNode, BaseAST* sourceNode);

// compute call sites FnSymbol::calls
void compute_call_sites();

//
// collect set of symbols and vector of SymExpr; can be used to
// compute defMaps and useMaps below (these are computed when
// computing the defMaps and useMaps; precomputing them can help if
// you need to use them elsewhere too)
//
void collectSymbolSetSymExprVec(BaseAST* ast,
                                Vec<Symbol*>& symSet,
                                Vec<SymExpr*>& symExprs);

//
// Return value & 1 is true if se is a def
// Return value & 2 is true if se is a use
//
int isDefAndOrUse(SymExpr* se);

//
// build defMap and useMap such that defMap is a map from symbols to
// their defs and useMap is a map from symbols to their uses; these
// vectors are built differently depending on the other arguments
//
void buildDefUseMaps(Map<Symbol*,Vec<SymExpr*>*>& defMap,
                     Map<Symbol*,Vec<SymExpr*>*>& useMap);
// builds the vectors for every variable/argument in the entire
// program

void buildDefUseMaps(FnSymbol* fn,
                     Map<Symbol*,Vec<SymExpr*>*>& defMap,
                     Map<Symbol*,Vec<SymExpr*>*>& useMap);
// builds the vectors for every variable/argument in 'fn' and looks
// for uses and defs only in 'fn'

void buildDefUseMaps(Vec<Symbol*>& symSet,
                     Map<Symbol*,Vec<SymExpr*>*>& defMap,
                     Map<Symbol*,Vec<SymExpr*>*>& useMap);
// builds the vectors for every variable/argument in 'symSet' and
// looks for uses and defs in the entire program

void buildDefUseMaps(Vec<Symbol*>& symSet,
                     Vec<SymExpr*>& symExprs,
                     Map<Symbol*,Vec<SymExpr*>*>& defMap,
                     Map<Symbol*,Vec<SymExpr*>*>& useMap);
// builds the vectors for every variable/argument in 'symSet' and
// looks for uses and defs only in 'symExprs'

//
// add a def to a defMap or a use to a useMap
//
void addDef(Map<Symbol*,Vec<SymExpr*>*>& defMap, SymExpr* def);
void addUse(Map<Symbol*,Vec<SymExpr*>*>& useMap, SymExpr* use);


//
// free memory consumed by defMap and useMap
//
void freeDefUseMaps(Map<Symbol*,Vec<SymExpr*>*>& defMap,
                    Map<Symbol*,Vec<SymExpr*>*>& useMap);

//
// stylized loops over defs and uses: to loop over the defs/uses
// (SymExprs) stored in the map defMap/useMap for a symbol sym, use
// for_defs/for_uses and the resulting declared variable def/use will
// contain the defs/uses
//
#define for_defs(def, defMap, sym)                \
  for_uses(def, defMap, sym)

#define for_uses(use, useMap, sym)                \
  if (Vec<SymExpr*>* macro_vec = useMap.get(sym)) \
    forv_Vec(SymExpr, use, *macro_vec)

//
// build useSet and defSet for a vector of symbols 'syms' where the
// uses and defs are restricted to 'fn' such that the set useSet
// contains all of the uses of the symbols in 'syms' that occur in
// 'fn' and the set defSet contains all of the defs of the symbols in
// 'syms' that occur in 'fn'
//
void buildDefUseSets(Vec<Symbol*>& syms,
                     FnSymbol* fn,
                     Vec<SymExpr*>& defSet,
                     Vec<SymExpr*>& useSet);

// replace symbol use with another
void subSymbol(BaseAST* ast, Symbol* oldSym, Symbol* newSym);

void remove_help(BaseAST* ast, int trace_flag);
void parent_insert_help(BaseAST* parent, Expr* ast);
void sibling_insert_help(BaseAST* sibling, BaseAST* ast);
void insert_help(BaseAST* ast, Expr* parentExpr, Symbol* parentSymbol);

ArgSymbol* actual_to_formal( Expr *a);
Expr* formal_to_actual(CallExpr* call, Symbol* formal);

// move to resolve when scope resolution is put in resolution directory
BlockStmt* getVisibilityBlock(Expr* expr);
void flattenNestedFunctions(Vec<FnSymbol*>& nestedFunctions);

#endif
