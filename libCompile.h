#ifndef COMPILADOR_H
#define COMPILADOR_H

typedef struct var *Var;
typedef struct sEnvironment *Environment;

typedef enum eType {IntType, ArrayType} Type;
typedef struct sAddress {
    int addr;
    Type varType;
} Address;

Environment initEnvironment();
void declareVar(Environment scope, char* varName, int nAddress, char type);
Address getGlobalAddress(Environment scope, char * varName);

#endif
