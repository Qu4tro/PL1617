compiler: y.tab.c lex.yy.c stack.o libCompile.o hashmap.o
		gcc -o compiler y.tab.c stack.c libCompile.c hashmap.c

lex.yy.c: compiler.l 
			flex compiler.l

y.tab.c: compiler.y
			yacc -d compiler.y

stack.o: stack.c stack.h
			gcc -c stack.c 

libCompile.o :	libCompile.c libCompile.h 
			gcc -c libCompile.c

hashmap.o: hashmap.c hashmap.h
			gcc -c hashmap.c

clean: 
	rm  *.o lex.yy.c y.tab.c y.tab.h compiler out.wm

