#include <stdio.h>
#include <stdlib.h>
#include "stack.h"

struct stack {
    int elems[256];
    int p;
}; 

Stack initStack(){
    Stack s = (Stack) malloc(sizeof(struct stack));
    s -> p = 0;

    return s;
}

int peekStack(Stack s){
    return s -> elems[s -> p];
}

int popStack(Stack s){
    return s -> elems[s -> p--];
}

void pushStack(Stack s, int v){
    s -> elems[++(s-> p)] = v;
}
