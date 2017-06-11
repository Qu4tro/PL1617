%{ 
#define instruction(...) do { \
    fprintf(f, __VA_ARGS__); \
    fprintf(f, "\n"); \
} while (0);

#include "compilador.h"
#include <stdio.h>
#include <string.h>
#include "stack.h"
#include <stdlib.h>
#include "y.tab.h"

int yylex();
int yylineno;

int yyerror(char *s) {
    fprintf(stderr,"Erro. Linha: %d\nMsg: %s\n", yylineno, s);
    return 0;
}

void must(int cond, char* msg){
    if (!cond){
        yyerror(msg);
        exit(1);
    }
}

static int total = 0;
FILE *f;
Stack s;

%}

%union{
    char* var_nome;
    int valor;
    Tipo tipo;
    struct sVarAtr
    {
        char* var_nome;
        int valor;
        int size;
    } varAtr;   
}

%token INT WHILE FOR IF ELSE RETURN VOID PRINT SCAN DO
%token <valor>num 
%token <var_nome>id 

%type <tipo> TipoFun
%type <tipo> Tipo
%type <var_nome> IdFun
%type <varAtr> Var

// --------------------PROGRAMA ------------------------------------
/**
Um programa é uma lista de declarações, lista de Funcões , e uma lista de Instruções 
*/

%%

Prog       :                    
            ListaDecla                      {instruction("start");
                                             instruction("jump inicio\n");
                                            }	 	
			ListaFun 			            {instruction("inicio: nop\n");}        		
			ListInst    		            {instruction("stop\n");}                                                         
                   				
            ; 

ListaDecla  :                            
            | ListaDecla Decla 
            ;

ListaFun    :   
            | ListaFun Funcao 
            ;

ListInst    : Inst                               
            | ListInst Inst                                    
            ;

// --------------------  FUNCAO ------------------------------------
/** A declaração de funções é precedida pelo símbolo terminal '\#'. 
 */

Funcao      : '#' TipoFun IdFun                 {inserFuncao($2,$3);}
                '(' ListaArg ')'                {decFunArgRefresh();
                                                 instruction("%s: nop",$3);}
                '{' ListaDecla ListInst '}'     {fim();}
            ;            

TipoFun     : VOID      	                    {$$ =_VOID;}
            | INT                               {$$ =_INTS;}
            ;

IdFun 		: id 
			;

ListaArg    :   
            | ListaArg2 ;

ListaArg2   : Tipo Var                          {decArgumentos($2.var_nome);}
            | ListaArg2  ','  Tipo Var          {decArgumentos($4.var_nome);}
            ;

Tipo 		: INT                               {$$ =_INTS;} 
			; 


// --------------------DECLARACAO ------------------------------------

Decla       : INT id ';'                        {decVar($2, 1, 'S');
                                                 instruction("pushi 0");
                                                }   			                
            | INT id '[' num ']' ';'            {decVar($2, $4, 'A');
                                                 instruction("pushn %d", $4);
                                                }
            | INT id '[' Var ']' ';'            {Endereco a = getEndereco($4.var_nome); 
                                                 decVar($2, a.addr, 'A');                                     
                                                 instruction("pushn %d", a.addr);
                                                }
            ;


Var 		: id                                {Endereco a=getEndereco($1);
                                                 $$.var_nome=strdup($1);
                                                 $$.valor=1;
                                                }
			;

// --------------------INSTRUCAO ------------------------------------

ConjInst    :
            |'{' ListInst '}'
            ;

Inst        : If
            | Decla
            | While
            | For
            | Atrib ';'
            | Print';'
            | Scan ';'
            | RETURN Exp ';'                    {instruction("storel %d", decFunRetAddr());
                                                 instruction("return");
                                                }
            | ELSE                              {must(0, "'Else' sem um 'If' anteriormente");}                          
            ;

// ------------------------------------ ATRIBUIÇAO ------------------------------------

Atrib       : Var '=' Exp                       {Endereco a = getEndereco($1.var_nome); 
                                                 instruction("store%c %d", a.tipoVar, a.addr);
                                                } 

            | Var '+''+'                        {Endereco a = getEndereco($1.var_nome); 
                                                 must(a.tipo == _INTS, "Tipos incompativeis");
                                                 instruction("pushi 1");
                                                 instruction("push%c %d", a.tipoVar, a.addr);
                                                 instruction("add");
                                                 instruction("store%c %d", a.tipoVar, a.addr);
                                                }

            | Var'[' Exp ']' '=' Exp            {Endereco a = getEndereco($1.var_nome);
                                                 instruction("push%cp", (a.tipoVar=='l') ? 'f' : 'g');
                                                 instruction("push%c %d", a.tipoVar, a.addr);
                                                 instruction("padd");
                                                 instruction("storen");
                                                }
            ;

// ------------------------------------ PRINT SCAN ------------------------------------
 
Print       : PRINT '(' Prints ')'                          
            ;

Scan        : SCAN '(' Var ')'                  {Endereco a = getEndereco($3.var_nome); 
                                                 instruction("read");
                                                 instruction("atoi");
                                                 instruction("store%c %d", a.tipoVar, a.addr);
                                                }       
            ;

Prints      : num                               {instruction("writei %d\n",$1 );}           
            | Var                               {Endereco a = getEndereco($1.var_nome);
                                                 instruction("push%c %d", a.tipoVar, a.addr);
                                                 instruction("writei");
                                                }   

            | Var '['Exp ']'                    {Endereco a = getEndereco($1.var_nome); 
                                                 instruction("push%cp", (a.tipoVar=='l') ? 'f' : 'g');
                                                 instruction("push%c %d", a.tipoVar, a.addr);
                                                 instruction("padd");
                                                 instruction("loadn");
                                                }  
            | id                                {instruction("pushs %s", $1);
                                                 instruction("writes");
                                                }
            ;                    
// ------------------------------------ IF THEN ELSE ------------------------------------

If          :  IF                               {total++; 
                                                 pushStack(s, total);
                                                }
			TestExpLog   	                    {instruction("jz end_condition_%d", peekStack(s));}
			ConjInst  		                    {instruction("end_condition_%d", popStack(s));}	
			Else
            ;

Else        :       
            | ELSE ConjInst 
            ;

// ------------------------------------# WHILE ---------------------------------------------

While       : WHILE                             {total++;
                                                 pushStack(s, total);
                                                 instruction("loop_%d: nop", peekStack(s));
                                                }
            TestExpLog                          {instruction("jz end_loop%d", peekStack(s)); }
            ConjInst                            {instruction("jump loop_%d", peekStack(s));
                                                 instruction("end_loop%d", peekStack(s));
                                                 popStack(s);
                                                }                                
            ;

// ------------------------------------# FOR ---------------------------------------------

For         : FOR ForHeader ConjInst            {instruction("jump loop_%dA", peekStack(s));
                                                 instruction("end_loop%d", peekStack(s));
                                                 popStack(s);
                                                }              
            ;

ForHeader   :  '(' ForAtrib ';'                 {total++; 
                                                 pushStack(s, total);
                                                 instruction("loop_%d: nop", peekStack(s));
                                                }
             ExpLog ';'                         {instruction("jz end_loop%d", peekStack(s));
                                                 instruction("jump loop_%dB", peekStack(s));
                                                 instruction("loop_%dA: nop", peekStack(s));
                                                }
             ForAtrib ')'                       {instruction("jump loop_%d", peekStack(s));
                                                 instruction("loop_%dB: nop", peekStack(s));
                                                }
            ; 


ForAtrib    : Atrib  
            ;

// -----------------------------------------------------------------CALCULO DE EXPRESSOES -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ExpLog 		: Exp 
			| Exp '=''=' Exp 		            {instruction("equal");}
			| Exp '!''=' Exp                    {instruction("equal");
                                                 instruction("pushi 0");
                                                 instruction("nequal");
                                                }
			| Exp '>''=' Exp 		            {instruction("supeq");}
			| Exp '<''=' Exp 		            {instruction("infeq");}
			| Exp '<' Exp 			            {instruction("inf");}
			| Exp '>' Exp 			            {instruction("sup");}
			; 


Exp 		: Termo
			|Exp '+' Termo  			        {instruction("add");}
			|Exp  '-' Termo 			        {instruction("sub");}
			|Exp '|''|' ExpLog                  {instruction("add");
                                                 instruction("jz end_condition_%d: nop", peekStack(s));
                                                 instruction("nequal");
                                                }
            |Exp '%' Termo                      {instruction("mod");}
			; 


Termo		: Fun
			| Termo '/' Fun 			        {instruction("div");}
			| Termo '*' Fun 			        {instruction("mul");}
			| Termo '&''&' ExpLog               {instruction("pushi 1");
                                                 instruction("nequal");
                                                 instruction("jz end_condition_%d: nop",peekStack(s));
                                                }
			; 

Fun 	   	: num                               {instruction("pushi %d", $1);}           
            | Var  	                            {Endereco a = getEndereco($1.var_nome);
                                                 instruction("push%c %d", a.tipoVar, a.addr);
                                                } 	
            | Var '['Exp ']'                    {Endereco a = getEndereco($1.var_nome); 
                                                 instruction("push%cp", (a.tipoVar=='l') ? 'f' : 'g');
                                                 instruction("push%c %d", a.tipoVar, a.addr);
                                                 instruction("padd");
                                                 instruction("loadn");
                                                }  

            | IdFun                             {funcaoExiste($1);
                                                 instruction("pushi 0");
                                                }
            '(' FunArgs')'                      {instruction("call %s", $1);
                                                 instruction("pop%d", numeroArgumentos());
                                                }

            | '(' Exp ')'                  
            ;                                  

FunArgs     :    
            | FunArgs2 
            ;

FunArgs2    : Exp                               {proximoArgumento(_INTS);}                            
            | FunArgs2 ',' Exp                  {proximoArgumento(_INTS);}             
            ;

TestExpLog  : '(' ExpLog ')'                                        
            ;

%%

#include "lex.yy.c"

int main(int argc, char* argv[]){
    initVGlobalMap(); 
    s = initStack();

    if (argc > 1){
        f = fopen(argv[1],"w+");
    } else {
        f = fopen("out.wm", "w+");
    }

	yyparse();
	fclose(f); 
    free(s);
	return 0; 
}
