#ifndef __STACK_H__
#define __STACK_H__

typedef struct stack *Stack;

Stack initStack();

int peekStack(Stack s);

int popStack(Stack s);

void pushStack(Stack s, int v);

#endif
