#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "hashmap.h"

#include "libCompile.h"

void yyerror(char *s);
void must(int cond, char *s);

struct var {
    Type type;
    char *nome;
    int memAdr;
};

struct sEnvironment {
    map_t vars;
    int stackPointer;
};

Environment initEnvironment(){
    Environment s = malloc(sizeof(struct sEnvironment));
    s -> vars = hashmap_new();
    s -> stackPointer = 0;
    return s;
}

Var existeVar(Environment scope, char* varName){
    Var tmp;
    if((hashmap_get(scope->vars, varName, (any_t*) &tmp) == MAP_OK))
        return tmp;
    return NULL;
}

void declareVar(Environment scope, char* varName, int nAddress, char type) {
    assert(nAddress > 0);

    if (!existeVar(scope, varName)){

        Var variavel = malloc(sizeof(struct var));

        if(type == 'A') {
            variavel -> type = ArrayType;
        } else {
            variavel -> type = IntType;
        }

        variavel -> nome = strdup(varName);
        variavel -> memAdr = scope -> stackPointer;
        scope -> stackPointer = scope -> stackPointer + nAddress;

        hashmap_put(scope -> vars, varName, (any_t) variavel);

    } else {
        yyerror("Variável já declarada anteriormente");
    }
}

Address getGlobalAddress(Environment scope, char * varName) {
    Var var;
    if ((var = existeVar(scope, varName))) {
        Address ret = {var -> memAdr, var -> type};
        return ret;
    } else {
        must(0, "Variável não declarada");
    }
}
