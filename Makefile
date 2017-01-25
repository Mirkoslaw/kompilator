all: kompilator

kompilator.tab.c kompilator.tab.h: kompilator.y
	bison -d kompilator.y

lex.yy.c: kompilator.l kompilator.tab.h
	flex kompilator.l

kompilator: kompilator.tab.c kompilator.tab.h lex.yy.c
	g++ -o kompilator -std=c++11 lex.yy.c kompilator.tab.c 
	rm kompilator.tab.c lex.yy.c kompilator.tab.h
