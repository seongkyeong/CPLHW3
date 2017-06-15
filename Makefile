all: basic

basic.tab.c basic.tab.h: basic.y
	bison -d basic.y

lex.yy.c: basic.l basic.tab.h
	flex basic.l

basic: lex.yy.c basic.tab.c basic.tab.h
	gcc -Wall -o basic basic.tab.c lex.yy.c

clean:
	rm basic basic.tab.c lex.yy.c basic.tab.h
