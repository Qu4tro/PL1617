#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hashmap.h"
#include "compilador.h"

#define OK 0
#define ERRO_A_VAR_JA_EXISTE -1
#define ERRO_A_VAR_NAP_EXISTE -2
#define ERRO_TIPO_INVALIDO -3
#define ERRO_FUNCAO_NAO_EXISTE -4
#define ERRO_A_FUNCAO_JA_EXISTE -5
#define ERRO_A_COLUNA_ZERO -6
#define ERRO -7


void yyerror(char *s);

struct variavel{
    Tipo tipo;
    char *nome;
    int memAdr;
};
typedef struct funcaoArg
{
    struct variavel* v; 
    struct funcaoArg *next;
}* FuncaoArg;
struct funcao{
    Tipo tipo;
    char *nome;
    FuncaoArg args;
    FuncaoArg argsEnd;
    int numeroArg;
};
typedef struct sScope{
    map_t vars;
    int addrCount;
}*Scope;

static Funcao emUsoFun;
static Funcao funcaoAux;
static Scope vGlobal;
static Scope vInterna;/*variaveis da função tanto internas como as que recebe*/

static map_t mFuncMap;

Variavel static existeVar(Scope fun, char* varName);


int initVGlobalMap()
{
    vGlobal = (Scope) malloc(sizeof(struct sScope));
    vGlobal->vars = hashmap_new();
    vGlobal->addrCount = 0;
    mFuncMap = hashmap_new();
    return 0;
}


Funcao existeFuncao(char * func) {

    Funcao tmp;

    if(!(hashmap_get(mFuncMap,func,(any_t*)&tmp)==MAP_OK)) {

        tmp=NULL;
    }		

    return tmp;
}


Variavel static existeVar(Scope fun, char* varName)
{
    Variavel tmp;
    if (fun==NULL)
        fun = vGlobal;

    if(!(hashmap_get(fun->vars, varName, (any_t*) &tmp) == MAP_OK))
        tmp = NULL;
    return tmp;	
}

/* insere uma funcao, retorna ok se estiver todo bem*/
int inserFuncao(Tipo tipo,char * name) {

    int ret=0;
    /* se a funcao não existir retorna nulo, logo eu posso declarala*/

    if(!(existeFuncao(name))) {

        Funcao nova=(Funcao) malloc(sizeof(struct funcao));
        nova->nome=strdup(name);
        nova->tipo=tipo;
        nova->args=NULL;
        nova->argsEnd=NULL;
        nova->numeroArg=0;

        hashmap_put(mFuncMap,name,(any_t)nova);
        funcaoAux=nova;

        vInterna=(Scope)malloc(sizeof(struct sScope));
        vInterna->vars=hashmap_new();
        vInterna->addrCount=0;
        ret=OK;
    }

    else {

        //yyerror("Funcão já declarada");
        ret=ERRO_A_FUNCAO_JA_EXISTE;


    }
    return ret;

}


int  decVar(char* varName, int linha,char tipo) {

    Scope context; 
    int erro = 0;


    /* se não houver declarações locais irá ver existe variaveis globais com o mesmo nome*/

    if (vInterna== NULL) { 
        context = vGlobal;
        erro += (existeVar(vGlobal, varName) != NULL);
    } else {
        context = vInterna;         /* se for NULL dá como resultado zero, senão dá um*/
        erro += (existeVar(vInterna, varName) != NULL);
        erro += (existeVar(vGlobal, varName) != NULL);
    }

    /*se der diferente de zero*/

    if(!erro) {

        Variavel variavel=(Variavel)malloc(sizeof(struct variavel));



        if(linha>2 && tipo=='M') {
            variavel->tipo= _INTM;
        } else {
            if(linha>1 && tipo=='A') {
                (variavel->tipo)= _INTA;
            } else {
                variavel->tipo= _INTS;
            }
        }


        variavel -> nome = strdup(varName);
        variavel -> memAdr = context -> addrCount;
        context -> addrCount = context -> addrCount + linha;

        hashmap_put(context->vars, varName, (any_t)variavel);

        erro=OK;
    } else {
        yyerror("Variável já declarada anteriormente");
        erro=ERRO_A_VAR_JA_EXISTE;
    }

    return erro;
}


/* declarar os argumentos que uma funcao recebe */
int decArgumentos(char * nome) {
    int erro=0;

    if(funcaoAux->argsEnd==NULL) {
        funcaoAux->argsEnd=(FuncaoArg)malloc(sizeof(struct funcaoArg));
        funcaoAux->args=funcaoAux->argsEnd;
    } else {
		/* senão continua a inserir elementos no fim da lista */
        funcaoAux->argsEnd->next=(FuncaoArg)malloc(sizeof(struct funcaoArg));
        funcaoAux->argsEnd=funcaoAux->argsEnd->next;
    }

    funcaoAux->argsEnd->next=NULL;

    erro= decVar(nome,1,'S');

    if( erro == OK) {
        /* senão houver variaveis com o mesmo nome insere na ultima posição a variavel */
        funcaoAux->numeroArg++;
        hashmap_get(vInterna->vars, nome, (any_t*) &(funcaoAux->argsEnd->v));
    } else {
        yyerror("Variável já declarada anteriormente");
    }

    return erro;
}

/* verifica se a funcao existe*/

int funcaoExiste(char * nome) {

    emUsoFun=existeFuncao(nome);
    /* se retornar nulo a função não existe */
    if(emUsoFun==NULL) {
        //yyerror("Erro funcao não existe");
        return ERRO_FUNCAO_NAO_EXISTE;
    }

    else {
        /* o argsEnd passa a apontar para o sitio do argumento inicial*/
        emUsoFun->argsEnd=emUsoFun->args;

        return OK;
    }

}

int proximoArgumento(Tipo type) {
    if(emUsoFun->argsEnd==NULL) {
        yyerror("Erro numero invalido de argumentos");
        return ERRO;
    }

    if(type!=(emUsoFun->argsEnd->v->tipo)) {
        yyerror("Erro tipo invalido");
        return ERRO;
    }

    emUsoFun->argsEnd=emUsoFun->argsEnd->next;
    return OK;
}
/* quando for nulo significa que acabei de percorrer os argumentos que a funcao recebe, por isso retorno o numero de argumentos que recebe*/

int numeroArgumentos(){
    if(emUsoFun->argsEnd!=NULL) {
        yyerror("Erro numero de argumentos invalido");
        return ERRO;
    }

    else {
        return emUsoFun->numeroArg;
    }
}


int decFunRetAddr(){
    return -(funcaoAux->numeroArg) - 1;
}


void decFunArgRefresh(){
    FuncaoArg i = funcaoAux->args;
    while(i != NULL){
        i->v->memAdr -= funcaoAux->numeroArg;
        i = i->next;
    }
}



void fim(){
    funcaoAux = NULL;
    vInterna = NULL;
}




Endereco getEndereco(char * varName) {
    Variavel tmp;
    int memoria;
    char tipoVar;
    Tipo type ;


    if(vInterna==NULL) {

        tmp=existeVar(vGlobal,varName);
        tipoVar='g';
    }

    else {
        tmp=existeVar(vInterna,varName);
        tipoVar='l';

        if(tmp==NULL) {

            tmp=existeVar(vGlobal,varName);
            tipoVar='g';
        }
    }

    if(tmp != NULL) {
        memoria = tmp->memAdr;
        type = tmp->tipo;
    } else {
        memoria = ERRO_A_VAR_NAP_EXISTE;
        yyerror("Variável não declarada");
    }


    Endereco ret = {memoria,tipoVar,type};


    return ret;

}
