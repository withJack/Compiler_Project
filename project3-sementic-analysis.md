# C-Minus project

## project #3. Semantic Analysis

### Compilers course, CSE, Hanyang University
> ##### 2014004948
> ##### Lee Seung Jae (이승재)
> Leading professor: _prof. Park Yong Jun_
> 
> Assistant: Kang Suk Won 


-----

#### __What are we doing?__
> tiny compiler를 수정하여 c-minus compiler의 Symbol table를 만들고 이를 이용해 type checking을 목표로하는 Semantic Analysis를 구현한다. 
> 
> Lexical analysis(scanner), Syntax analysis(parser)를 거쳐 front-end의 마지막 단계인 Semantic analysis를 거치면 결과물이 생성된다. 결과물에는 대표적으로 변수나 함수등의 scope와 type, 이름, 사용된 코드line number 등이 포함되어 있다.
>
> Scanner is implemented using flex(fast lex), Parser code is built using yacc.

#### __How to compile?__
> This project was done in Ubuntu 16.04 (linux)
> 
> Compile: `$make` ![image](/uploads/38281f5cdfc424034e0addc3ae7e8819/image.png)


#### __How to run test codes? What are results?__
> There are 6 test codes.
> 
> Run: `./cminus ./testcode/(test code file name)` 
> 
> ##### 1. gcd.cm testcase ![image](/uploads/c52daa37126170d629b51cdc71ab9b58/image.png)

> 
> `./cminus ./testcode/gcd.cm` ![image](/uploads/bc7e37fc7244a0bda2847544f3ba2443/image.png)

>
> ##### 2. sort.cm testcase ![image](/uploads/4f648104d8c832dc2867cacdea8e460c/image.png)

> 
> `./cminus ./testcode/sort.cm` ![image](/uploads/6ca2678bca5013d1ee23c3056520ee2f/image.png)

> 
> ##### 3. undefined.cm (error checking for undefined variable, undefined function) ![image](/uploads/524580a63be7b2499ab9efde459765fb/image.png)

>
> `./cminus ./testcode/undefined.cm` ![image](/uploads/8f1ba335af4247d9d64a292f824975ff/image.png)
 C-minus compiler failed building symbol table.
>
> ##### 4. voidvar.cm (error checking for void variable) ![image](/uploads/213a8b25c851d98681a7f0e8b6d6fbad/image.png)

>
> `./cminus ./testcode/voidvar.cm` ![image](/uploads/000da32446cb2d5a54035629fef52de8/image.png)
 C-minus compiler failed building symbol table.
>
> ##### 5. returntype1.cm (error checking for return type) ![image](/uploads/35dfb1caeccfb71c62aaa0fa77928dd4/image.png)

>
> `./cminus ./testcode/returntype1.cm` ![image](/uploads/b373b528f8c662717563563d3d12fbdd/image.png)

>
> ##### 6. returntype2.cm (error checking for return type) ![image](/uploads/031a5661d19110bc4c72249de10ec337/image.png)

>
> `./cminus ./testcode/returntype2.cm` ![image](/uploads/ac974aba528fe967254ff8f5573353ae/image.png)

> 

#### __How to implement?__
##### 1. main.c
> Change the flags for Compiler doing Semantic analysis. (what our project wants)
> 
> ![image](/uploads/b72d9f654b649ca461037d1babd3839f/image.png)

##### 2. globals.h
> Semantic analysis에서 type checking을 하기 위해서는 scope 개념을 도입하여야 한다. 따라서 treeNode 구조체에 scopename 이라는 scope의 이름을 저장하는 변수를 추가하였다. 또한, 위의 sort.cm 테스트 케이스에서 보이는 바와 같이 while:30의 의미는 30번 째 줄에 있는 while scope를 의미한다. 이는 while이나 if 같은 경우 같은 이름을 가지고 있는 scope들이 발생할 수 있기 때문에 구분을 두는 것이다. 
>
> ![image](/uploads/2b869a5f00148e0f7d0a45a7d41d607c/image.png)


##### 3. symtab.h
> symtab.h 파일에서는 구현에 필요한 각종 구조체들의 정의와 symtab.c 등의 파일에서 사용될 함수들이 정의 되어 있다. 
> 
> 예> ![image](/uploads/83ec967423e39d123f4977c05bac84e3/image.png)


##### 4. symtab.c
> ![image](/uploads/0feec003360c34bf274f5e3f09a943d2/image.png)
>
> symbol table 구현할 때, 과제 명세에 나와있는 예시를 그대로 사용하였다. 전체 Scope table( 그림에서는 list) 가 있고, 새로운 scope가 생길 때마다 현재 읽고 있는 scope를 관리해주기 위한 자료구조를 추가하였고 그 이름을 scope stack이라고 하겠다. 따라서 새로운 scope가 생기면 먼저 scope stack에 추가해주고(push), 다 만들었다면 scope stack에서 빼서(pop)을 해서 scope table에 추가해 주는 방식이다. 
>
> scope stack에서 완료된 scope를 전체 scope table에 추가하는 코드> ![image](/uploads/b000fdffb3153c3387851dd4a57caf88/image.png)
>
> 현재 scope에 새로운 symbol을 추가하는 경우에는 먼저 해당 scope에 같은 이름의 symbol이 있는지 확인합니다. 존재하지 않는다면 이제 scope에 추가해준다. (bucket_add) 추가해 줄 때, tiny compiler에서 사용하던 hash table을 그대로 사용하였다. 
>
> 새로운 symbol을 현재 scope에 추가해 주는 코드> ![image](/uploads/2520662b9e42acaf4ca772d6ac237db2/image.png)
>
> built-in 함수로 int input(void) 와 void output(int) 를 선언해줘야 하기에 처음 scope stack을 초기화할 때 추가해 주었다.
>
> built-in 함수 output() 추가 일부> ![image](/uploads/b0d414ba09f61c9011cc6ee7738a2026/image.png)
>
> 결과물은 scope의 이름이 같은 것끼리 붙어서 나오게끔 구현하였다. scope의 이름, 변수 혹은 함수의 이름, type, location, 쓰인 줄 번호(복수 가능)을 표시하였다. 
> 
> ![image](/uploads/8c12bd555f64db541c6389f84402caaa/image.png)


##### 5. analyze.c
> Scope의 이름 처리를 위해서 (위에서 설명했듯이 이름이 같은 scope의 경우 뒤에 코드 줄 번호를 붙여서 구분을 주었다) 여러가지 함수들을 추가하였다. 
> 
> ![image](/uploads/807385c56e8344744db6a8606c3fe410/image.png)
>
> insertNode() 함수에서는 각각의 treeNode가 어떤 종류의 node인지에 따라 예외처리를 해 주었다. 
>
> StmtK: 
>
> CompK의 경우, 이 treeNode에 도착하기 전에 파라미터들을 저장하기 위해(parser의 순서에 따라) scope를 추가해 주어야 한다는 것을 표시해야 한다. IterK(while문), IfK(if문)의 경우에는 scope의 이름이 겹칠 수 있기에 이름 뒤에 line number를 추가해 주어야한다. IfK의 경우 추가적으로 else문을 위한 처리도 해주어야 한다.
>
> ExpK:
>
> IdK, ArrIdK의 경우는 그냥 scope stack에 추가해 주면 된다. 그러나 CallK의 경우는 선언되어 있는 함수를 호출하는 것이기 때문에 argument type이 맞는지 확인해주어야 한다. 따라서 arg의 symbol도 처리해준다. 
>
> DeclK:
>
> FuncK의 경우는 함수를 선언하는 단계이다. 따라서 동일한 이름을 가진 함수가 있는지 확인 한 후, 없다면 return type을 treeNode의 type에 저장한다. 그리고 scope stack에 추가. varK와 ArrVarrK의 경우는 void형인 경우에는 symbol을 만들 수 없기 때문에 이와 같은 경우에는 symbol error를 낸다. 
>
> ParamK:
>
> SingleParamK와 ArrParamK인 경우에는 Void형인지 Integer 혹은 IntegerArray type인지 확인하고 이름 중복이 되는지 확인한다. 

##### 한 학기동안 수고 많으셨습니다.