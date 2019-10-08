# C-Minus project

## project #1. Scanner

### Compilers course, CSE, Hanyang University
> ##### 2014004948
> ##### Lee Seung Jae (이승재)
> Leading professor: _prof. Park Yong Jun_
> 
> Assistant: Kang Suk Won 


-----


# Implementation of C-scanner (with 2 methods)

> ##### Lexical Convention of C-minus
> 		Keyword: else, if, int, return, void, while (lower case)
> 
> 		Symbol: + - * / < <= > >= == != = ; , ( ) [ ] { } /* */
> 
> 		Token:
> 			ID = letter letter*
> 			NUM = digit digit*
> 			letter = a | ... | z | A | ... | Z
> 			digit = 0 | 1 | ... | 9
> 			
> 		White space: space bar, Enter, tab
> 			- ignore other cases except WS between ID, NUM, and keywords. 
> 			- additionally do not ignore WS between Comment symbol '*/'.
> 			
> 		Comments (/* ... */) follow normal C notation. 
> 			- cannot be nested.

## 1. Implementation of C-scanner using c-code

> globals.h

```c
#define MAXRESERVED 12

typedef enum 
    /* book-keeping tokens */
   {ENDFILE,ERROR,
    /* reserved words */
    ELSE, IF, INT, RETURN, VOID, WHILE, /* DELETED  */ THEN, END, REPEAT, UNTIL, READ, WRITE,
    /* multicharacter tokens */
    ID,NUM,
    /* special symbols */
	// + - * / < <= > >= == != = ; , ( ) [ ] { } /* */
    PLUS, MINUS, TIMES, OVER, LT, LE, GT, GE, EQ, NE, ASSIGN, SEMI, COMMA, 
    LPAREN, RPAREN, LBRACE, RBRACE, LCURLY, RCURLY
   } TokenType;
```
- globals.h file is a header file for definitions that will be used in actual codes. You can see Keywords(aka. reserved words), symbols and other necessary tokens are mapped to TokenType numbers(enum structure)

> scan.c

```c
typedef enum
   { START, INEQ, INASSIGN, INCOMMENT, INNUM, INID, DONE, INLT, INGT, INNE, INOVER, INCOMMENT_ }
   StateType;
```
- Beginning of scan.c file, state types are also mapped to StateType numbers(enum structuer). 
- States are used when making Tokens that fit to lexical convention described above.

```c
static struct
    { char* str;
      TokenType tok;
    } reservedWords[MAXRESERVED]
   = {{"if",IF},{"then",THEN},{"else",ELSE},{"end",END},
      {"repeat",REPEAT},{"until",UNTIL},{"read",READ},
      {"write",WRITE},{"int",INT},{"return",RETURN},
      {"void",VOID},{"while",WHILE}};
```
- Reserved words are set up in look-up table. 
- When compiler finishes scanning and gets tokens, it compares with look-up table to see if the token is reserved word. ( implemented in the end of `getToken()` function as `reservedLookup()`)

```c
while (state != DONE)
   { int c = getNextChar();
     save = TRUE;
     switch (state)
     { case START:
         if (isdigit(c))
           state = INNUM;
         else if (isalpha(c))
           state = INID;
         else if ((c == ' ') || (c == '\t') || (c == '\n'))
        /*
         * ......shorten......
         */
		 else if (c == '/')
		   state = INOVER;
         else
         { state = DONE;
           switch (c)
           { case EOF:
               save = FALSE;
               currentToken = ENDFILE;
               break;
             case '+':
               currentToken = PLUS;
               break;
            /*
             * ......shorten...... 
             */
             default:
               currentToken = ERROR;
               break;
           }
         }
         break;
       case INOVER:
		 save = FALSE;
		 if (c == '*')
		 {
			 state = INCOMMENT;
			 tokenStringIndex--;
		 }
		 else
		 { state = DONE;
		   ungetNextChar();
		   currentToken = OVER;
		 }
		 break;
       case INCOMMENT:
         save = FALSE;
         if (c == EOF)
         { state = DONE;
           currentToken = ENDFILE;
         }
         else if (c == '*') state = INCOMMENT_;
         break;
       case INCOMMENT_:
		 save = FALSE;
		 if (c == EOF)
		 { state = DONE; 
		   currentToken = ENDFILE;
		 }
		 else if (c == '*') state = INCOMMENT_;
		 else if (c == '/') state = START;
		 else state = INCOMMENT;
		 break;
      /*
       * ......shorten......
       */
```
- Above codes(shorten a lot...) show how C-minus compiler tokenize given input string streams. 
- It keeps on tokenizing until it meets DONE state. (DONE means a single token is saved or skipped)
- If it has other state than DONE, it keeps calling `getNextChar()`. 
- Since managing comments(/* ... */) is most complicated, i will only explain how comments are handled.
	- Comments have total 3 states. INOVER, INCOMMENT, INCOMMENT\_. INOVER is state where compiler found /. This state figures out if '/' is used for OVER or beginning of comment '/*'. If compiler finds '*' after '/', the state changes to INCOMMENT state.
	- INCOMMENT state is when tokenizer is inside the comment string. it is looking for '\*'. this is not TIMES token, it is part of end comment, '\*/'. when compiler finds '\*' in INCOMMENT state, state changes to INCOMMENT\_ state.
	- INCOMMENT\_ state is now looking for '/' character to end the comment. if it finds other characters, it goes back to INCOMMENT state or stays in INCOMMENT\_ state when the character is '\*'. 
	- There are few more things about exceptions (ex. `EOF`, `ungetNextChar()`)

> util.c

```c
	/* ......shorten...... */
	case LT: fprintf(listing,"<\n"); break;
	case LE: fprintf(listing,"<=\n"); break;
	case GT: fprintf(listing,">\n"); break;
	case GE: fprintf(listing,">=\n"); break;
    case EQ: fprintf(listing,"==\n"); break;
	case NE: fprintf(listing,"!=\n"); break;
    case LPAREN: fprintf(listing,"(\n"); break;
    case RPAREN: fprintf(listing,")\n"); break;
	/* ......shorten...... */
```
- util.c file shows how to print tokens that the compiler tokenized. 

> test result
> 
> `make cminus`
> 
> `./cminus _filename_`

```
TINY COMPILATION: testfiles/test1.cm
   1: /* A program to perform Euclid's
   2: 	Algorithm to computer gcd */
   3: 
   4: int gcd (int u, int v)
	4: reserved word: int
	4: ID, name= gcd
	4: (
	4: reserved word: int
	4: ID, name= u
	4: ,
	4: reserved word: int
	4: ID, name= v
	4: )
   5: {
	5: {
   6: 	if (v == 0) return u;
	6: reserved word: if
	6: (
	6: ID, name= v
	6: ==
	6: NUM, val= 0
	6: )
	6: reserved word: return
	6: ID, name= u
	6: ;
   7: 	else return gcd(v,u-u/v*v);
	7: reserved word: else
	7: reserved word: return
	7: ID, name= gcd
	7: (
	7: ID, name= v
	7: ,
	7: ID, name= u
	7: -
	7: ID, name= u
	7: /
	7: ID, name= v
	7: *
	7: ID, name= v
	7: )
	7: ;
```


## 2. Implementation of C-scanner using flex(fast lex)

##### This part of implementation uses flex instead of scan.c in the first implementation.
##### Other files are same. ( globals.h, main.c util.c )

> cminus.l

```c
"}"				{return RCURLY;}
";"             {return SEMI;}
","				{return COMMA;}
{number}        {return NUM;}
{identifier}    {return ID;}
{newline}       {lineno++;}
{whitespace}    {/* skip whitespace */}
"/*"			{	char c1;
					char c2 = '\0';
					do
					{ c1 = input();
						if (c1 == EOF) break;
						if (c1 == '\n') lineno++;
						if (c2 == '*' && c1 == '/') break;
						c2 = c1;
					} while (1);
				}
.               {return ERROR;}
```
- flex, fast lex, is a program that creates c file that has all the lexical conventions given in .l files. 
- so, `flex cminus.l` => lex.yy.c => `gcc -c lex.yy.c -lfl` => lex.yy.o 
- now you can compile C-minus compiler with lex.yy.o file instead of scan.o file (generated from scan.c file).
- Above codes shows what to do when following string or character comes. 

> test result
> 
> `make cminus_flex`
> 
> `./cminus_flex _filename_`

```
C-minus COMPILATION: testfiles/test1.cm
	4: reserved word: int
	4: ID, name= gcd
	4: (
	4: reserved word: int
	4: ID, name= u
	4: ,
	4: reserved word: int
	4: ID, name= v
	4: )
	5: {
	6: reserved word: if
	6: (
	6: ID, name= v
	6: ==
	6: NUM, val= 0
	6: )
	6: reserved word: return
	6: ID, name= u
	6: ;
	7: reserved word: else
	7: reserved word: return
	7: ID, name= gcd
	7: (
	7: ID, name= v
	7: ,
	7: ID, name= u
	7: -
	7: ID, name= u
	7: /
	7: ID, name= v
	7: *
	7: ID, name= v
	7: )
	7: ;
```
- Difference between c implemented C-minus compiler result is that it only shows actual tokens. All comments and WS are skipped.