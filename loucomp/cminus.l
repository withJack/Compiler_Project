/****************************************************/
/* File: tiny.l                                     */
/* Lex specification for TINY                       */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

/* for line 64...                              */
/* if it is comment, ignore.                   */
/* use c2 variable as stack for previous input */

%{
#include "globals.h"
#include "util.h"
#include "scan.h"
/* lexeme of identifier or reserved word */
char tokenString[MAXTOKENLEN+1];
%}

digit       [0-9]
number      {digit}+
letter      [a-zA-Z]
identifier  {letter}+
newline     \n
whitespace  [ \t]+

%option noyywrap
%%

"if"            {return IF;}
"else"          {return ELSE;}
"int"			{return INT;}
"return"		{return RETURN;}
"void"			{return VOID;}
"while"			{return WHILE;}
"="				{return ASSIGN;}
"=="			{return EQ;}
"!="			{return NE;}
"<"             {return LT;}
"<="			{return LE;}
">"				{return GT;}
">="			{return GE;}
"+"             {return PLUS;}
"-"             {return MINUS;}
"*"             {return TIMES;}
"/"             {return OVER;}
"("             {return LPAREN;}
")"             {return RPAREN;}
"["				{return LBRACE;}
"]"				{return RBRACE;}
"{"				{return LCURLY;}
"}"				{return RCURLY;}
";"             {return SEMI;}
","				{return COMMA;}
{number}        {return NUM;}
{identifier}    {return ID;}
{newline}       {lineno++;}
{whitespace}    {/* skip whitespace */}
"/*"			{	char c1;
					char c2 = '\0';
					while(1)
					{ c1 = input();
						if (c1 == EOF) break;
						if (c1 == '\n') lineno++;
						if (c2 == '*' && c1 == '/') break;
						c2 = c1;
					}
				}
.               {return ERROR;}

%%

TokenType getToken(void)
{ static int firstTime = TRUE;
  TokenType currentToken;
  if (firstTime)
  { firstTime = FALSE;
    lineno++;
    yyin = source;
    yyout = listing;
  }
  currentToken = yylex();
  strncpy(tokenString,yytext,MAXTOKENLEN);
  if (TraceScan) {
    fprintf(listing,"\t%d: ",lineno);
    printToken(currentToken,tokenString);
  }
  return currentToken;
}

