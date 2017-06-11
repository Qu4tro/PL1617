

gramatica: y.tab.c lex.yy.c stack.o compilador.o hashmap.o
		gcc -o gramatica y.tab.c stack.c compilador.c hashmap.c

lex.yy.c: gramatica.l 
			flex gramatica.l

y.tab.c: gramatica.y
			yacc -d gramatica.y

stack.o: stack.c stack.h
			gcc -c stack.c 
compilador.o :	compilador.c compilador.h 
			gcc -c compilador.c
hashmap.o: hashmap.c hashmap.h
			gcc -c hashmap.c

clean: 
	rm  *.o lex.yy.c y.tab.c y.tab.h gramatica assembly.txt

