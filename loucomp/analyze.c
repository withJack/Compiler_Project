/****************************************************/
/* File: analyze.c                                  */
/* Semantic analyzer implementation                 */
/* for the TINY compiler                            */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#include "globals.h"
#include "symtab.h"
#include "analyze.h"

#define SIZE 211

/* counter for variable memory locations */

static int location = 0;

/* Procedure traverse is a generic recursive 
 * syntax tree traversal routine:
 * it applies preProc in preorder and postProc 
 * in postorder to tree pointed to by t
 */

static ExpType curFuncType;
static int preserve = FALSE;
static int elseCheck = FALSE;
static char *scopeName;
static void traverse( TreeNode * t,
               void (* preProc) (TreeNode *),
               void (* postProc) (TreeNode *) )
{ if (t != NULL)
  { preProc(t);
    { int i;
      for (i=0; i < MAXCHILDREN; i++)
        traverse(t->child[i],preProc,postProc);
    }
    postProc(t);
    traverse(t->sibling,preProc,postProc);
  }
}

/* nullProc is a do-nothing procedure to 
 * generate preorder-only or postorder-only
 * traversals from traverse
 */
static void nullProc(TreeNode * t)
{ if (t==NULL) return;
  else return;
}

// 문자열을 뒤집는 함수 (itoa에서 사용)
void reverse(char s[]) {
  int i, j;
  char c;
 
  for (i = 0, j = strlen(s)-1; i<j; i++, j--) {
    c = s[i];
    s[i] = s[j];
    s[j] = c;
  }
}

// 비표준함수 itoa 직접 구현
char* itoa(int val, char * buf, int radix) {
  char* p = buf;
  while(val) {
    if(radix <= 10)
      *p++ = (val % radix) + '0';
    else {
      int t = val % radix;
      if (t <= 9)
        *p++ = t + '0';
      else
        *p++ = t - 10 + 'a';
    }
    val /= radix;
  }
  *p = '\0';

  reverse(buf);
  return buf;
}

// if, while처럼 이름만으로는 구분할 수 없는 함수들에 lineno을 붙여
// 구분 가능한 tag 형태로 만들어주는 함수
char* getTagString(char *funcName, int lineno) {
  char *tag = (char*)malloc(strlen(funcName));
  strcpy(tag, funcName);
  char buf[100];
  itoa(lineno, buf, 10);
  strcat(tag, buf);
  return tag;
}

static void symbolError(TreeNode * t, char * message)
{ fprintf(listing,"Symbol error at line %d: %s\n",t->lineno,message);
  Error = TRUE;
}

/* Procedure insertNode inserts 
 * identifiers stored in t into 
 * the symbol table 
 */

static void insertNode( TreeNode * t)
{ switch (t->nodekind)
  { case StmtK: {
      switch (t->kind.stmt)
      { case CompK: {
          // 현재 노드가 속한 scope는 현재 scope (새로운 scope를 추가하기 전에 확인)
          t->scopename = ss_top()->name;
          if(preserve) 
            preserve = FALSE;
          else 
            ss_push(scopeName, t->lineno);
          break;
        }
        case IterK: {
          if(t->child[1]->kind.stmt == CompK) 
            scopeName = getTagString("while:", t->lineno);
          break;
        }
        case IfK: {
          if(t->child[1]->kind.stmt == CompK) 
            scopeName = getTagString("if:", t->lineno);
          if(t->child[2] != NULL && t->child[2]->kind.stmt == CompK)  
            elseCheck = TRUE;
          break;
        }
        default:
          break;
      }
      break;
    }
    case ExpK: {
      switch (t->kind.exp)
      { case IdK: {
          // 보이는 변수 읽음: scopeStack에 기록
          if(ss_lookup(t->attr.name) != NULL)
            ss_line_add(t->attr.name, t->lineno, t);
          // 보이지 않은 변수 읽음 : error
          else 
            symbolError(t, "reference to undefined variable");
          break;
        }
        case ArrIdK: {
          // 보이는 변수 읽음: scopeStack에 기록
          if(ss_lookup(t->attr.arr.name) != NULL) 
            ss_line_add(t->attr.arr.name, t->lineno, t);
          // 보이지 않은 변수 읽음 : error
          else 
            symbolError(t, "reference to undefined array");
          break;
        }
        case CallK: {
          // 위에서 정의된 함수 부름 : scopeStack에 기록
          if(ss_lookup(t->attr.name) != NULL) {
            ss_line_add(t->attr.name, t->lineno, t);
            TreeNode *arg = t->child[0];

            if(arg != NULL) { 
              // 보이지 않는 변수가 argument 인 경우 : error
              if(ss_lookup(arg->attr.name) == NULL) 
                symbolError(t, "argument of undefined variable");
              else 
                arg = arg->sibling;
            }
          // 정의되지 않은 함수 부름 : error
          } else {
            symbolError(t, "call undefined function");
          }
          break;
        }
        default:
          break;
      }
      break;
    }
    case DeclK: {
      switch (t->kind.decl)
      { case FuncK: {
          // 현재 scope내에 같은 이름의 함수가 있나 체크
          if (ss_lookup_excluding_parent(t->attr.name) == NULL) {
            // function의 return type 체크 후, treeNode의 type에 저장
            if(t->child[0]->attr.type == INT) 
              t->type = Integer;
            else if(t->child[0]->attr.type == VOID) 
              t->type = Void;
            
            ss_bucket_add(t->attr.name, t->type, t->lineno, t);
            t->scopename = ss_top()->name;

            // scope 추가
            // CompK에서 또 scope 추가하지 않도록 preserve를 true로 바꿔줌
            ss_push(t->attr.name, t->lineno);
            preserve = TRUE;
          } else {
            symbolError(t, "function name duplicated");
          }
          break;
        }
        case VarK: {
          // 현재 scope내에 같은 이름의 변수가 있나 체크
          if (ss_lookup_excluding_parent(t->attr.name) == NULL) {
            if(t->child[0]->attr.type == INT) 
              t->type = Integer;
            // void type 변수 : error
            else if(t->child[0]->attr.type == VOID) 
              symbolError(t, "void type variable");
        
            ss_bucket_add(t->attr.name, t->type, t->lineno, t);
            t->scopename = ss_top()->name;
          } else {
            symbolError(t, "variable name duplicated");
          }
          break;
        }
        case ArrVarK: {
          // 현재 scope내에 같은 이름의 변수가 있나 체크
          if (ss_lookup_excluding_parent(t->attr.arr.name) == NULL) {
            if(t->child[0]->attr.type == INT) 
              t->type = IntegerArray;
            // void type 변수 : error
            else if(t->child[0]->attr.type == VOID) 
              symbolError(t, "void type array variable");

            ss_bucket_add(t->attr.arr.name, t->type, t->lineno, t);
            t->scopename = ss_top()->name;
          } else {
            symbolError(t, "array name duplicated");
          }
          break;
        }
        default:
          break;
      }
      break;
    }
    case ParamK: 
      switch(t->kind.param) {
        case SingleParamK: {
          // parameter가 void가 아닌 경우 : scopeStack에 기록
          if(t->attr.name != NULL) {
            if(t->child[0]->attr.type == INT) 
              t->type = Integer;

            // 이름이 같은 parameter가 존재하나 체크
            if (ss_lookup_excluding_parent(t->attr.name) == NULL) {
              ss_bucket_add(t->attr.name, t->type, t->lineno, t);
              t->scopename = ss_top()->name;
            } else {
              symbolError(t, "parameter name duplicated");
            }
          }
          break;
        }
        case ArrParamK: {
          // parameter가 void가 아닌 경우 : scopeStack에 기록
          if(t->attr.name != NULL) {
            if(t->child[0]->attr.type == INT) 
             t->type = IntegerArray;

            // 이름이 같은 parameter가 존재하나 체크
            if (ss_lookup_excluding_parent(t->attr.arr.name) == NULL) {
              ss_bucket_add(t->attr.arr.name, t->type, t->lineno, t);
              t->scopename = ss_top()->name;
            } else {
              symbolError(t, "array parameter name duplicated");
            }
          }
          break;
        }
        default:
          break;
      }
      break;
    default:
      break;
  }
}

static void postInsertNode(TreeNode *t) 
{ switch(t->nodekind) 
  { case StmtK:
      switch(t->kind.stmt)
      { case CompK:
          st_insert();
          // stmt가 CompK인 else가 이어지는 if가 끝난 경우 : scope 추가
          // CompK에서 또 scope 추가하지 않도록 preserve를 true로 바꿔줌
          if(elseCheck) {
            ss_push(getTagString("else:", t->lineno), t->lineno);
            elseCheck = FALSE;
            preserve = TRUE;
          }
          break;
      }
      break;
  }
}

/* Function buildSymtab constructs the symbol 
 * table by preorder traversal of the syntax tree
 */
void buildSymtab(TreeNode * syntaxTree)
{ initScopeStack();
  traverse(syntaxTree,insertNode,postInsertNode);
  st_insert();
  if (TraceAnalyze)
  { printSymTab(listing);
  }
}

static void typeError(TreeNode * t, char * message)
{ fprintf(listing,"Type error at line %d: %s\n",t->lineno,message);
  Error = TRUE;
}

static void preCheckNode(TreeNode * t)
{ switch (t->nodekind)
  { case DeclK:
      switch (t->kind.decl)
      { case FuncK:
          if(t->child[0]->attr.type == INT) {
            curFuncType = Integer;
          } else if(t->child[0]->attr.type == VOID) {
            curFuncType = Void;
          }
          break;
        default:
          break;
      }
      break;
    default:
      break;
  }
}

/* Procedure checkNode performs
 * type checking at a single tree node
 */
static void checkNode(TreeNode * t)
{ switch (t->nodekind)
  { case StmtK: {
      switch (t->kind.stmt)
      { case IterK: {
          if (t->child[0]->type == Void)
            typeError(t->child[0],"while test has void value");
          break;
        }
        case RetK: {
          TreeNode* expr = t->child[0];
          if (curFuncType == Void &&
            (expr != NULL && expr->type != Void)) {
            typeError(t,"expected no return value");
          } else if (curFuncType == Integer &&
            (expr == NULL || expr->type != Integer)) {
            typeError(t,"expected integer return value");
          }
          break;
        }
        default:
          break;
      }
      break;
    }
    case ExpK: {
      switch (t->kind.exp)
      { case AssignK: {
          if (t->child[0]->type == IntegerArray)
          /* no value can be assigned to array variable */
            typeError(t->child[0], "assignment to array variable");
          else if (t->child[1]->type == Void)
          /* r-value cannot have void type */
            typeError(t->child[0],"assignment of void value");
          break;
        }
        case OpK: {
          ExpType leftType, rightType;
          TokenType op;

          if(t->child[0]->attr.type == INT) leftType = Integer;

          leftType = t->child[0]->type;
          rightType = t->child[1]->type;
          op = t->attr.op;

          if(leftType == Void || rightType == Void) 
            typeError(t,"two operands should have non-void type");
          else if(leftType != rightType)
            typeError(t, "type of two operands are different");
          else 
            t->type = Integer;
          break;
        }
        case ConstK: {
          t->type = Integer;
          break;
        }
        case IdK: {
          if(t->scopename == NULL || st_lookup(t->scopename, t->attr.name) == NULL) {
            typeError(t, "can't type check undefined variable");

          }
          break;
        }
        case ArrIdK: {
          if(t->scopename == NULL || st_lookup(t->scopename, t->attr.name) == NULL) 
            typeError(t, "can't type check undefined arr variable");
          else if(t->child[0]->type != Integer)
            typeError(t, "index expression should have integer type");
          else 
            t->type = Integer;
          break;
        }
        case CallK: {
          if(t->scopename == NULL || st_lookup(t->scopename, t->attr.name) == NULL) {
            typeError(t, "can't type check undefined function");
            break;
          }
          TreeNode * funcDecl = st_lookup(t->scopename, t->attr.name)->treeNode;
          TreeNode *arg;
          TreeNode *param;

          arg = t->child[0];
          param = funcDecl->child[1];

          if (funcDecl->kind.decl != FuncK) { 
            typeError(t,"expected function symbol");
            break;
          }

          while (arg != NULL) { 
            /* the number of arguments does not match tothat of parameters */
            if (param == NULL)
              typeError(arg,"the number of parameters is wrong");
            else if(arg->type != param->type) 
              typeError(arg,"type of arg and param is different");
            else {  // no problem!
              arg = arg->sibling;
              param = param->sibling;
              continue;
            }
            break;
          }
          /* the number of arguments does not match to that of parameters */
          if (arg == NULL && param != NULL)
            
            typeError(t,"the number of parameters is wrong");
          break;
        }
        default:
          break;
      }
      break;
    }
    default:
      break;
  }
}

/* Procedure typeCheck performs type checking 
 * by a postorder syntax tree traversal
 */
void typeCheck(TreeNode * syntaxTree)
{ traverse(syntaxTree,preCheckNode,checkNode);
}
