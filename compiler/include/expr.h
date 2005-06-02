#ifndef _EXPR_H_
#define _EXPR_H_

#include <stdio.h>
#include "alist.h"
#include "analysis.h"
#include "baseAST.h"
#include "pragma.h"
#include "symbol.h"

class Stmt;
class AInfo;
class UserInitExpr;

enum precedenceType {
  PREC_LOWEST = 0,
  PREC_LOGOR,
  PREC_LOGAND,
  PREC_BITOR,
  PREC_BITXOR,
  PREC_BITAND,
  PREC_EQUALITY,
  PREC_COMPARE,
  PREC_BITS,
  PREC_PLUSMINUS,
  PREC_MULTDIV,
  PREC_UNOP, 
  PREC_EXP,
  PREC_HIGHEST
};


/************* IF CHANGING THIS, change cUnOp as well... *****************/
enum unOpType {
  UNOP_PLUS = 0,
  UNOP_MINUS,
  UNOP_LOGNOT,
  UNOP_BITNOT,

  NUM_UNOPS
};
/************* IF CHANGING THIS, change cUnOp as well... *****************/


/************* IF CHANGING THIS, change cBinOp as well... *****************/
enum binOpType {
  BINOP_PLUS = 0,
  BINOP_MINUS,
  BINOP_MULT,
  BINOP_DIV,
  BINOP_MOD,
  BINOP_EQUAL,
  BINOP_LEQUAL,
  BINOP_GEQUAL,
  BINOP_GTHAN,
  BINOP_LTHAN,
  BINOP_NEQUAL,
  BINOP_BITAND,
  BINOP_BITOR,
  BINOP_BITXOR,
  BINOP_LOGAND,
  BINOP_LOGOR,
  BINOP_EXP,

  BINOP_SEQCAT,
  BINOP_BY,

  BINOP_SUBTYPE,
  BINOP_NOTSUBTYPE,

  BINOP_OTHER,
  
  NUM_BINOPS
};
/************* IF CHANGING THIS, change cBinOp as well... *****************/


/************* IF CHANGING THIS, change cGetsOp as well... *****************/
enum getsOpType {
  GETS_NORM = 0,
  GETS_PLUS,
  GETS_MINUS,
  GETS_MULT,
  GETS_DIV,
  GETS_BITAND,
  GETS_BITOR,
  GETS_BITXOR,

  NUM_GETS_OPS
};
/************* IF CHANGING THIS, change cGetsOp as well... *****************/


class Expr : public BaseAST {
 public:
  Symbol* parentSymbol;
  Stmt* parentStmt;
  Expr* parentExpr;
  AInfo *ainfo;
  AList<Pragma> *pragmas;
  FnSymbol *resolved;


  Expr(astType_t astType = EXPR);

  Expr* copy(bool clone = false, Map<BaseAST*,BaseAST*>* map = NULL, Vec<BaseAST*>* update_list = NULL);
  Expr* copyInternal(bool clone = false, Map<BaseAST*,BaseAST*>* map = NULL);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void callReplaceChild(BaseAST* new_ast);
  virtual void verify(void); 
  virtual void traverse(Traversal* traversal, bool atTop = true);
  virtual void traverseDef(Traversal* traversal, bool atTop = true);
  virtual void traverseExpr(Traversal* traversal);

  virtual Type* typeInfo(void);
  virtual bool isComputable(void);
  
  virtual bool isParam(void);
  
  virtual bool isConst(void);
  virtual long intVal(void);
  virtual int rank(void);
  virtual precedenceType precedence(void);

  virtual void printCfgInitString(FILE* outfile);

  static Expr* newPlusMinus(binOpType op, Expr* l, Expr* r);

  bool isRead(void);
  bool isWritten(void);
  bool isRef(void);
  Stmt* Expr::getStmt();
};
#define forv_Expr(_p, _v) forv_Vec(Expr, _p, _v)


class Literal : public Expr {
 public:
  char* str;

  Literal(astType_t astType, char* init_str);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  bool isComputable(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class BoolLiteral : public Literal {
 public:
  bool val;

  BoolLiteral(char* init_str, bool init_val);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  bool boolVal(void);
  
  Type* typeInfo(void);
};


class IntLiteral : public Literal {
 public:
  long val;

  IntLiteral(char* init_str, int init_val);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  long intVal(void);

  Type* typeInfo(void);

  void codegen(FILE* outfile);
};


class FloatLiteral : public Literal {
 public:
  double val;

  FloatLiteral(char* init_str, double init_val);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
};


class ComplexLiteral : public Literal {
 public:
  double realVal;
  double imagVal;
  char* realStr;

  ComplexLiteral(char* init_str, double init_imag, double init_real = 0.0,
                 char* init_realStr = "");
  void addReal(FloatLiteral* init_real);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  void negateImag(void);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class StringLiteral : public Literal {
 public:
  StringLiteral(char* init_val);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
  void printCfgInitString(FILE* outfile);
};


class UnOp : public Expr {
 public:
  unOpType type;
  Expr* operand;

  UnOp(unOpType init_type, Expr* op);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  bool isComputable(void);
  long intVal(void);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
  precedenceType precedence(void);
};


class BinOp : public Expr {
 public:
  binOpType type;
  Expr* left;
  Expr* right;

  BinOp(binOpType init_type, Expr* l, Expr* r);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);
  bool isComputable(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
  precedenceType precedence(void);
};


class AssignOp : public BinOp {
 public:
  getsOpType type;

  AssignOp(getsOpType init_type, Expr* l, Expr* r);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
  precedenceType precedence(void);
};


class SpecialBinOp : public BinOp {
 public:
  SpecialBinOp(binOpType init_type, Expr* l, Expr* r);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  Type* typeInfo(void);

  precedenceType precedence(void);
};


class DefExpr : public Expr {
 public:
  Symbol* sym;
  UserInitExpr* init;

  DefExpr(Symbol* initSym = NULL, UserInitExpr* initInit = NULL);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  virtual void verify(void); 
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);

  Vec<VarSymbol*>* varDefSet();
};


class Variable : public Expr {
 public:
  Symbol* var;
  ForwardingSymbol* forward; // was this include by a use statement?
                             // if so, it might be renamed.
  Variable(Symbol* init_var, ForwardingSymbol* init_forward = NULL);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);
  virtual bool isConst(void);
  virtual bool isParam(void);
  virtual bool isComputable();
  virtual long intVal(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class MemberAccess : public Expr {
 public:
  Expr* base;
  Symbol* member;
  Type* member_type;
  int member_offset;

  MemberAccess(Expr* init_base, Symbol* init_member);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  bool isConst(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class Tuple : public Expr {
 public:
  AList<Expr>* exprs;

  Tuple(AList<Expr>* init_exprs);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class ParenOpExpr : public Expr {
 public:
  Expr* baseExpr;
  AList<Expr>* argList;

  ParenOpExpr(Expr* init_base, AList<Expr>* init_arg = new AList<Expr>);
  void setArgs(AList<Expr>* init_arg);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  virtual void print(FILE* outfile);
  virtual void codegen(FILE* outfile);
};


class ArrayRef : public ParenOpExpr {
 public:
  ArrayRef(Expr* init_base, AList<Expr>* init_arg);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  
  bool isConst(void);
  Type* typeInfo();

  void codegen(FILE* outfile);
};


class TupleSelect : public ParenOpExpr {
 public:
  /* baseExpr is TupleExpr, argList is indexing expression (single expression) */
  TupleSelect(Expr* init_base, Expr* init_arg);
  TupleSelect(Expr* init_base, AList<Expr>* init_arg);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  bool isConst(void);
  Type* typeInfo(void);

  void codegen(FILE* outfile);
};


class FnCall : public ParenOpExpr {
 public:
  FnCall(Expr* init_base, AList<Expr>* init_arg = new AList<Expr>());
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  Type* typeInfo(void);

  FnSymbol* findFnSymbol(void);

  void codegen(FILE* outfile);
};


class SizeofExpr : public Expr {
 public:
  Variable* variable;

  SizeofExpr(Variable* init_variable);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);
  
  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class CastExpr : public Expr {
 public:
  Type* newType;
  Expr* expr;

  CastExpr(Type* init_newType, Expr* init_expr);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class CastLikeExpr : public Expr {
 public:
  Variable* variable; // cast to type of this variable
  Expr* expr;

  CastLikeExpr(Variable* init_variable, Expr* init_expr);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class ReduceExpr : public Expr {
 public:
  Symbol* reduceType;
  AList<Expr>* redDim;
  Expr* argExpr;

  ReduceExpr(Symbol* init_reduceType, Expr* init_argExpr, 
             AList<Expr>* init_redDim = new AList<Expr>());
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class SeqExpr : public Expr {
 public:
  AList<Expr>* exprls;

  SeqExpr(AList<Expr>* init_exprls);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);
  Type* typeInfo(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class SimpleSeqExpr : public Expr {
 public:
  Expr* lo;
  Expr* hi;
  Expr* str;

  SimpleSeqExpr(Expr* init_lo, Expr* init_hi, 
                Expr* init_str = new IntLiteral("1", 1));
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class FloodExpr : public Expr {
 public:
  FloodExpr(void);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class CompleteDimExpr : public Expr {
 public:
  CompleteDimExpr(void);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class ForallExpr : public Expr {
 public:
  AList<Expr>* domains;
  AList<DefExpr>* indices;
  Expr* forallExpr;

  SymScope* indexScope;

  ForallExpr(AList<Expr>* init_domains, 
             AList<DefExpr>* init_indices = new AList<DefExpr>(),
             Expr* init_forallExpr = NULL);
  void setForallExpr(Expr* exp);
  void setIndexScope(SymScope* init_indexScope);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};

extern ForallExpr* unknownDomain;

void initExpr(void);

class LetExpr : public Expr {
 public:
  AList<DefExpr>* symDefs;
  Expr* innerExpr;

  SymScope* letScope;

  LetExpr(AList<DefExpr>* init_symDefs = new AList<DefExpr>(), 
          Expr* init_innerExpr = NULL);
  void setInnerExpr(Expr* expr);
  void setSymDefs(AList<DefExpr>* expr);
  void setLetScope(SymScope* init_letScope);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);

  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);

  Type* typeInfo(void);

  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class CondExpr : public Expr {
 public:
  Expr* condExpr;
  Expr* thenExpr;
  Expr* elseExpr;

  CondExpr(Expr* initCondExpr, Expr* initThenExpr, Expr* initElseExpr);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);
  Type* typeInfo(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class NamedExpr : public Expr {
 public:
  char* name;
  Expr* actual;
  NamedExpr(char* init_name, Expr* init_actual);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);
  Type* typeInfo(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class VarInitExpr : public Expr {
 public:
  Expr* expr;
  VarInitExpr(Expr* init_expr);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);
  Type* typeInfo(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


class UserInitExpr : public Expr {
 public:
  Expr* expr;
  UserInitExpr(Expr* init_expr);
  virtual Expr* copyExpr(bool clone, Map<BaseAST*,BaseAST*>* map);
  virtual void replaceChild(BaseAST* old_ast, BaseAST* new_ast);
  void traverseExpr(Traversal* traversal);
  Type* typeInfo(void);
  void print(FILE* outfile);
  void codegen(FILE* outfile);
};


#endif
