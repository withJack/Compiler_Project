# C-Minus project

## project #2. Parser

### Compilers course, CSE, Hanyang University
> ##### 2014004948
> ##### Lee Seung Jae (이승재)
> Leading professor: _prof. Park Yong Jun_
> 
> Assistant: Kang Suk Won 


-----

#### __What are we doing?__
> Implementing C-minus parser using yacc. 
> 
> Scanner is implemented using flex(fast lex). 

#### __How to compile?__
> This project was done in Ubuntu 16.04 (linux)
> 
> Compile: `$make` ![image](/uploads/32e0f77d050e7d295e48ed88802214e3/image.png)

#### __How to run test codes?__
> There are 3 test codes: 1.cm, 2.cm, 3.cm.
> 
> Run: `./cminus (test code file name)` ![image](/uploads/861b6eacc052184c4d1af6912dbfc6e7/image.png)

#### __How to implement?__
##### 1. main.c
> Change the flags for parser-only compiler. (what our project wants)
> 
> ![image](/uploads/caaff5376efb9e4d814d08d7f311b28e/image.png)

##### 2. globals.h
> Change globals.h file from project 1-Scanner. 
>
> Add 3 kinds of nodes for implementing Declarations, Parameters, Types.
>
> ![image](/uploads/9a6044ef9b0fcad9dd9a679cf8a36098/image.png)
   
> With updated node kinds, change treeNode structure. 
> 
> It is implemented with union, because each node can only choose one of them. 
>
> arrayAttr structure is added for arrays. Either it is used for parameters, variables, etc.
>
> Arrays can have additional information, which is size.
>
> ![image](/uploads/a44d1df62012f5abae02dbb4efad47f0/image.png)

##### 3. util.h
> Functions creating new kinds of nodes are implemented in util.c file. 
> 
> For widely usage in other files, I added in header file.
>
> ![image](/uploads/b1cc18f902f155772bfff78d5fabfb2a/image.png)

##### 4. util.c
> New fucntions are added for creating and initializing new kinds of nodes written in globals.h file. 
> 
> `newDeclNode()` 
>
> ![image](/uploads/002ac13152271ad8cf9f47e089e49cef/image.png)
>
> Also, printTree() function was updated accordance to new kinds of nodes.
> 
> Below screenshot shows how printing for Declaration nodes is implemented.
>
> ![image](/uploads/7639aed16decdec13730040ced082ec9/image.png)

##### 5. cminus.y 
> cminus.y file is main implementation where specific rules (BNF Grammar) are implemented. 
>
> BNF grammars are written based on Appendix A.2 in compiler construction principles and practice book.
>
> Terminal인 ID와 NUM은 추가로 non-terminal인 iden, number를 거쳐가게 만들었다. 그 이유는 RHS 중간에 terminal이 나오는 경우에는 token이 저장되지 않고 넘어가기 때문이다. Non-terminal을 추가해 줌으로써 savedName과 savedNumber(추가된 전역변수)을 저장해준다.
>
> ![image](/uploads/5159b50d15db03fc2956e331260a761b/image.png)
>
> LHS에 call이나 fun_decl과 같이 RHS에 args나 params가 나오는 경우에는 attr.name을 args나 params까지 parsing되기 전에 savedName을 저장해주어야한다. 
>
> ![image](/uploads/c3ab7d126c6a5ef2903f0274abaf7f9e/image.png)
>
> ![image](/uploads/a1bf460f14cd0b55894557b2955a7ac8/image.png)
>
> 함수의 parameter가 void인 경우도 예외처리를 해줘야 했다. AST를 출력하는 과정에서 void가 정체는 알려주지 않으면서 딸랑 출력되는 문제가 생긴다. 이를 해결하기 위한 두가지 방법이 있는데, 첫 번째는 non-terminal을 추가해주는 것이다.  본인은 void라는 non-terminal을 하나 추가해 주어서 새로운 node를 추가해 주는 작업을 해주었다. 두 번째 방법은 LHS에 params 가 오는 production rule에서 직접 추가해주는 방법이다. 
>
> ![image](/uploads/6ef06fe98b38e94a2ca5803edb0dba89/image.png)

#### __Results for test cases__
> 1.cm 
>
> ![image](/uploads/4e0f3e35ed832a6bd71eb9eec3e4e558/image.png)
>
> `./cminus 1.cm`
>
> ![image](/uploads/72e24833ede5c21e264ca4597e269bc3/image.png)
>
> 3.cm
>
> ![image](/uploads/58fc72ec50bc112e8afb2ba1a5e5fcf9/image.png)
>
> `./cminus 3.cm`
>
> ![image](/uploads/6b0b7d98d4baeaa10e031a4776f7e237/image.png)
