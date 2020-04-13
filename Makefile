g++: lex.yy.c y.tab.c
	gcc -o g++ lex.yy.c y.tab.c -ll -w

y.tab.c: yacc.y
	yacc yacc.y -d

lex.yy.c: lex.l
	lex lex.l
