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
static int savedNumber;
static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void); // added 11/2/11 to ensure no conflict with lex

%}

%token IF ELSE INT RETURN VOID WHILE
%token ID NUM 
%token ASSIGN EQ NE LT LE GT GE PLUS MINUS TIMES OVER LPAREN RPAREN RBRACE LBRACE LCURLY RCURLY SEMI COMMA
%token ERROR ENDFILE

%% /* Grammar for TINY */

/* YYSTYPE is for recursive operation */
/* $$->lineno = lineno;  is for debugging & error checking */

program		: decl_list { savedTree = $1; }
		;
decl_list	: decl_list decl 
	  	  	{ YYSTYPE t = $1;
		  	  if (t != NULL)
		  	  { while (t->sibling != NULL)
		  	  	t = t->sibling;
		  	    t->sibling = $2;
		  	    $$ = $1;
		  	  }
		  	  else $$ = $2; 
			}
		| decl { $$ = $1;}
		;
/* declaration 2types : variable, function */
decl		: var_decl { $$ = $1; }
		| fun_decl { $$ = $1; }
		;
/* variable including arrays */
var_decl	: type_spec iden SEMI 
	 	 {
		   $$ = newDeclNode(VarK);
		   $$->child[0] = $1;
		   $$->attr.name = savedName;
		   $$->lineno = savedLineNo;
		 }
/* arrays */
	 	| type_spec iden LBRACE number RBRACE SEMI 
		 {
		   $$ = newDeclNode(ArrVarK);
		   $$->child[0] = $1;
		   $$->attr.arr.name = savedName;
		   $$->attr.arr.size = savedNumber;
		   $$->lineno = savedLineNo;
		 }
		;
/* (return) types for variable or function */
type_spec	: INT 
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
/* function */
fun_decl	: type_spec iden
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
/* parameter for functions */
void		: VOID
      		 {
		   $$ = newTypeNode(TypeNameK);
		   $$->attr.type = VOID;
		 }
		;
params		: param_list { $$ = $1; }
		| void
		 {
		   $$ = newParamNode(SingleParamK);
		   $$->attr.name = NULL;
		   $$->child[0] = $1;
		 }
		;
param_list	: param_list COMMA param
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
/* 1D variable for parameter */
param		: type_spec iden 
       		 {
                   $$ = newParamNode(SingleParamK);
                   $$->child[0] = $1;
                   $$->attr.name = savedName;
		 }
/* array for parameter */
       		| type_spec iden LBRACE RBRACE 
		 {
                   $$ = newParamNode(ArrParamK);
                   $$->child[0] = $1;
                   $$->attr.arr.name = savedName;
		 }
		;
/* variable declarations and statements */
comp_stmt	: LCURLY local_decl stmt_list RCURLY 
	  	 {
                   $$ = newStmtNode(CompK);
                   $$->child[0] = $2; /* local_decl */
                   $$->child[1] = $3; /* stmt_lis */
		 }
	  	;
/* number of variable declarations */
local_decl	: local_decl var_decl 
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
/* statements */
stmt_list	: stmt_list stmt 
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
stmt		: expr_stmt { $$ = $1; }
      		| comp_stmt { $$ = $1; }
		| selec_stmt { $$ = $1; }
		| iter_stmt { $$ = $1; }
		| return_stmt { $$ = $1; }
		;
/* expressions */
expr_stmt	: expr SEMI { $$ = $1; }
	  	| SEMI { $$ = NULL; }
		;
/* if statements */
selec_stmt	: IF LPAREN expr RPAREN stmt 
	   	 {
                   $$ = newStmtNode(IfK);
                   $$->child[0] = $3; /* expression */
                   $$->child[1] = $5; /* statement */
                   $$->lineno = lineno;
		 }
	   	| IF LPAREN expr RPAREN stmt ELSE stmt
		 {
                   $$ = newStmtNode(IfK);
                   $$->child[0] = $3; /* expression */
                   $$->child[1] = $5; /* statement */
                   $$->child[2] = $7; /* else statement */
		 }
		;
/* while statements */
iter_stmt	: WHILE LPAREN expr RPAREN stmt 
	  	 {
                   $$ = newStmtNode(IterK);
                   $$->child[0] = $3; /* expression */
                   $$->child[1] = $5; /* statement */
                   $$->lineno = lineno;
		 }
	  	;
/* return statements */
return_stmt	: RETURN SEMI { $$ = newStmtNode(RetK); }
	    	| RETURN expr SEMI 
		 { 
		   $$ = newStmtNode(RetK); 
		   $$->child[0] = $2; 
		 }
		;
expr		: var ASSIGN expr 
      		 {
		   $$ = newExpNode(AssignK);
		   $$->child[0] = $1; /* variable */
		   $$->child[1] = $3; /* expression */
		 }
      		| simple_expr { $$ = $1; }
		;
var		: iden 
     		 {
		   $$ = newExpNode(IdK);
		   $$->attr.name = savedName;
		 }
     		| iden 
		 {
		   $$ = newExpNode(ArrIdK);
		   $$->attr.arr.name = savedName;
		 }
		LBRACE expr RBRACE 
		 {
		   $$ = $2;
		   $$->child[0] = $4; /* expression */
		 }
		;
/* AST is set with priority between operators */
/* parens, mulops, addops */
simple_expr	: add_expr relop add_expr 
	    	 {
		   $$ = $2;
		   $$->child[0] = $1;
		   $$->child[1] = $3;
		 }
	    	| add_expr { $$ = $1; }
		;
/* relation operators */
relop		: LE 
       		 {
		   $$ = newExpNode(OpK);
		   $$->attr.op = LE;
		 }
       		| LT
       		 {
		   $$ = newExpNode(OpK);
		   $$->attr.op = LT;
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
add_expr	: add_expr addop term 
	 	 {
		   $$ = $2;
		   $$->child[0] = $1; /* recursive */
		   $$->child[1] = $3; /* term */
		 }
	    	| term { $$ = $1; }
		;
/* plus & minus */
addop		: PLUS 
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
term		: term mulop factor 
      		 {
		   $$ = $2;
		   $$->child[0] = $1; /* term */
		   $$->child[1] = $3; /* factor */
		 }
      		| factor { $$ = $1; }
		;
/* times & divided by */
mulop		: TIMES
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
/* parens, id, calls, numbers */
factor		: LPAREN expr RPAREN { $$ = $2; }
		| var { $$ = $1; }
		| call { $$ = $1; }
		| NUM 
		 {
		   $$ = newExpNode(ConstK);
		   $$->attr.val = atoi(tokenString);
		 }
		;
/* calls for functions */
call		: iden
     		 {
		   $$ = newExpNode(CallK);
		   $$->attr.name = savedName;
		 }
		LPAREN args RPAREN 
		 {
		   $$ = $2;
		   $$->child[0] = $4; /* arguments */
		 }
      		;
/* arguments (parameters) */
args		: arg_list { $$ = $1; }
      		| /* empty */ { $$ = NULL; }
		;
arg_list	: arg_list COMMA expr 
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
	 	| expr { $$ = $1; }
		;
/* IDs */
iden		: ID 
	   	 { savedName = copyString(tokenString);
		   savedLineNo = lineno; 
		 }
		;
/* numbers */
number		: NUM
	 	 { savedNumber = atoi(tokenString);
		   savedLineNo = lineno; 
		 }
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

