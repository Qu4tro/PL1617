#include <stdio.h>
#include <stdlib.h>
#include "stack.h"

struct stack {
    int elems[100];
    int sp;
}; 

Stack initStack(){
    Stack s = (Stack) malloc(sizeof(struct stack));
    s -> sp = 0;
    return s;
}

int peekStack(Stack s){
    return s -> elems[s -> sp];
}

int popStack(Stack s){
    return s -> elems[s -> sp--];
}

void pushStack(Stack s, int v){
    s -> elems[++(s-> sp)] = v;
}
