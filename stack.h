#ifndef STACK_H
#define STACK_H

typedef struct stack *Stack;

Stack initStack();
int peekStack(Stack s);
int popStack(Stack s);
void pushStack(Stack s, int v);

#endif
