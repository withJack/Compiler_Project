/****************************************************/
/* File: tiny.y                                     */
/* The TINY Yacc/Bison specification file           */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static char * savedName; /* for use in assignments */
static int savedNumber; /* for use in assignments */
static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void); // added 11/2/11 to ensure no conflict with lex

%}

%token IF ELSE WHILE RETURN INT VOID
%token ID NUM 
%token ASSIGN EQ NE LT LE GT GE PLUS MINUS TIMES OVER LPAREN RPAREN LBRACE RBRACE LCURLY RCURLY SEMI COMMA
%token ENDFILE ERROR 

%% /* Grammar for TINY */

program     : decl_list { savedTree = $1; } 
            ;
decl_list   : decl_list decl
              { 
                YYSTYPE t = $1;
                if (t != NULL)
                { 
                  while (t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else $$ = $2;
              }
            | decl { $$ = $1; }
decl        : var_decl { $$ = $1; }
            | fun_decl { $$ = $1; }
            ;
name        : ID 
              {
                savedName = copyString(tokenString);
                savedLineNo = lineno;
              }
            ;
number      : NUM
              {
                savedNumber = atoi(tokenString);
                savedLineNo = lineno;
              }
            ;
var_decl    : type_spec name SEMI
              {
                $$ = newDeclNode(VarK);
                $$->child[0] = $1;
                $$-> attr.name = savedName;
                $$->lineno = savedLineNo;
              }
            | type_spec name LBRACE number RBRACE SEMI
              {
                $$ = newDeclNode(ArrVarK);
                $$->child[0] = $1;
                $$->attr.name = savedName;
                $$->attr.arr.name = savedName;
                $$->attr.arr.size = savedNumber;
                $$->lineno = savedLineNo;
              }
            ;
type_spec   : INT 
              { 
                $$ = newTypeNode(TypeNameK);
                $$->attr.type = INT;
              }           
            | VOID 
              { 
                $$ = newTypeNode(TypeNameK);
                $$->attr.type = VOID;
              }
            ;
fun_decl    : type_spec name 
              {
                $$ = newDeclNode(FuncK);
                $$->attr.name = savedName;
              }
              LPAREN params RPAREN comp_stmt
              {
                $$ = $3;
                $$->child[0] = $1; /* type_spec */
                $$->child[1] = $5; /* params */
                $$->child[2] = $7; /* comp_stmt */
              }
            ;
void_param  : VOID 
              {
                $$ = newTypeNode(TypeNameK);
                $$->attr.type = VOID;
              }
params      : param_list { $$ = $1; } 
            | void_param
              {
                $$ = newParamNode(SingleParamK);
                $$->attr.name = NULL;
                $$->child[0] = $1;
              }
            ;
param_list  : param_list COMMA param
              {
                YYSTYPE t = $1;
                if (t != NULL)
                { 
                  while (t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $3;
                  $$ = $1;
                }
                else $$ = $3;
              }
            | param { $$ = $1; }
            ;
param       : type_spec name
              {
                $$ = newParamNode(SingleParamK);
                $$->child[0] = $1;
                $$->attr.name = savedName;
              }
            | type_spec name LBRACE RBRACE
              {
                $$ = newParamNode(ArrParamK);
                $$->child[0] = $1;
                $$->attr.name = savedName;
                $$->attr.arr.name = savedName;
              }
            ;
comp_stmt   : LCURLY local_decl stmt_list RCURLY
              {
                $$ = newStmtNode(CompK);
                $$->child[0] = $2; /* local_decl */
                $$->child[1] = $3; /* stmt_lis */
              }
            ;
local_decl  : local_decl var_decl 
              {
                YYSTYPE t = $1;
                if (t != NULL)
                { 
                  while (t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else $$ = $2;
              }
            | /* empty */ { $$ = NULL; }
            ;
stmt_list   : stmt_list stmt 
              {
                YYSTYPE t = $1;
                if (t != NULL)
                { 
                  while (t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else $$ = $2;
              }
            | /* empty */ { $$ = NULL; }
            ;
stmt        : exp_stmt { $$ = $1; }
            | comp_stmt { $$ = $1; }
            | selec_stmt { $$ = $1; }
            | iter_stmt { $$ = $1; }
            | return_stmt { $$ = $1; }
            ;
exp_stmt    : exp SEMI { $$ = $1; }
            | SEMI { $$ = NULL; }
            ;
selec_stmt  : IF LPAREN exp RPAREN stmt
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $3;
                $$->child[1] = $5;
                $$->lineno = lineno;
              }
            | IF LPAREN exp RPAREN stmt ELSE stmt
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $3;
                $$->child[1] = $5;
                $$->child[2] = $7;
              }
            ;
iter_stmt   : WHILE LPAREN exp RPAREN stmt
              {
                $$ = newStmtNode(IterK);
                $$->child[0] = $3;
                $$->child[1] = $5;
                $$->lineno = lineno;
              }
            ;
return_stmt : RETURN SEMI { $$ = newStmtNode(RetK); }
            | RETURN exp SEMI
              {
                $$ = newStmtNode(RetK);
                $$->child[0] = $2;
              }
            ;
exp         : var ASSIGN exp 
              {
                $$ = newExpNode(AssignK);
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | simple_exp { $$ = $1; }
            ;
var         : name
              {
                $$ = newExpNode(IdK);
                $$->attr.name = savedName;
              }
            | name 
              {
                $$ = newExpNode(ArrIdK);
                $$->attr.name = savedName;
                $$->attr.arr.name = savedName;
              }
              LBRACE exp RBRACE
              {
                $$ = $2;
                $$->child[0] = $4; /* exp */
              }
            ;
simple_exp  : addit_exp relop addit_exp 
              {
                $$ = $2;
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | addit_exp { $$ = $1; }
            ;
relop       : LT 
              {
                $$ = newExpNode(OpK);
                $$->attr.op = LT;
              }
            | LE 
              {
                $$ = newExpNode(OpK);
                $$->attr.op = LE;
              }
            | GT 
              {
                $$ = newExpNode(OpK);
                $$->attr.op = GT;
              }
            | GE
              {
                $$ = newExpNode(OpK);
                $$->attr.op = GE;
              } 
            | EQ 
              {
                $$ = newExpNode(OpK);
                $$->attr.op = EQ;
              }
            | NE
              {
                $$ = newExpNode(OpK);
                $$->attr.op = NE;
              }
            ;
addit_exp   : addit_exp addop term 
              {
                $$ = $2;
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | term { $$ = $1; }
            ;
addop       : PLUS 
              {
                $$ = newExpNode(OpK);
                $$->attr.op = PLUS;
              }
            | MINUS
              {
                $$ = newExpNode(OpK);
                $$->attr.op = MINUS;
              }
            ;
term        : term mulop factor 
              {
                $$ = $2;
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | factor { $$ = $1; }
            ;
mulop       : TIMES 
              {
                $$ = newExpNode(OpK);
                $$->attr.op = TIMES;
              }
            | OVER
              {
                $$ = newExpNode(OpK);
                $$->attr.op = OVER;
              }
            ;
factor      : LPAREN exp RPAREN { $$ = $2; }
            | var { $$ = $1; }
            | call { $$ = $1; }
            | NUM 
              {
                $$ = newExpNode(ConstK);
                $$->attr.val = atoi(tokenString);
              }
            ;
call        : name 
              {
                $$ = newExpNode(CallK);
                $$->attr.name = savedName;
              }
              LPAREN args RPAREN
              {
                $$ = $2;
                $$->child[0] = $4; /* args */
              }
            ;
args        : arg_list { $$ = $1; }
            | /* empty */ { $$ = NULL; }
            ;
arg_list    : arg_list COMMA exp 
              {
                YYSTYPE t = $1;
                if (t != NULL)
                { 
                  while (t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $3;
                  $$ = $1;
                }
                else $$ = $3;
              }
            | exp { $$ = $1; }
            ;
%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the TINY scanner
 */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ yyparse();
  return savedTree;
}

