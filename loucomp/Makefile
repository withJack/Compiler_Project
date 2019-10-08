CC = gcc

CFLAGS = -Wall -w 

OBJS = y.tab.o lex.yy.o main.o util.o symtab.o analyze.o

cminus: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o cminus -lfl

main.o: main.c globals.h util.h scan.h parse.h analyze.h cgen.h
	$(CC) $(CFLAGS) -c main.c

util.o: util.c util.h globals.h
	$(CC) $(CFLAGS) -c util.c

# scan.o: scan.c scan.h util.h globals.h
# 	$(CC) $(CFLAGS) -c scan.c

# parse.o: parse.c parse.h scan.h globals.h util.h
# 	$(CC) $(CFLAGS) -c parse.c

symtab.o: symtab.c symtab.h globals.h util.h
	$(CC) $(CFLAGS) -c symtab.c

analyze.o: analyze.c globals.h symtab.h analyze.h
	$(CC) $(CFLAGS) -c analyze.c

# code.o: code.c code.h globals.h
# 	$(CC) $(CFLAGS) -c code.c

# cgen.o: cgen.c globals.h symtab.h code.h cgen.h
# 	$(CC) $(CFLAGS) -c cgen.c


# by flex
# cminus_flex: main.o util.o lex.yy.o
# 	$(CC) $(CFLAGS) main.o util.o lex.yy.o -o cminus_flex -lfl

lex.yy.o: cminus.l scan.h util.h globals.h
	flex cminus.l
	$(CC) $(CFLAGS) -c lex.yy.c -lfl

y.tab.o: cminus.y globals.h util.h scan.h parse.h
	yacc -v -d cminus.y
	$(CC) $(CFLAGS) -c y.tab.c

clean:
	-rm -f cminus
	-rm -f $(OBJS)
	-rm -f lex.yy.c
	-rm -f y.tab.c
	-rm -f y.tab.h


all: cminus
