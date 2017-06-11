%{ 
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
            ListaDecla                      {fprintf(f,"start\n");fprintf(f,"jump inicio\n");}	 	
			ListaFun 			            {fprintf(f,"inicio:nop\n");}        		
			ListInst    		            {fprintf(f,"stop\n");}                                                         
                   				
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
                '(' ListaArg ')'                {decFunArgRefresh();fprintf(f,"%s:NOP\n",$3);}
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
                                                 fprintf(f,"pushi 0\n");
                                                }   			                
            | INT id '[' num ']' ';'            {decVar($2, $4, 'A');
                                                 fprintf(f,"pushn %d\n", $4);
                                                }
            | INT id '[' Var ']' ';'            {Endereco a = getEndereco($4.var_nome); 
                                                 decVar($2, a.addr, 'A');                                     
                                                 fprintf(f, "pushn %d\n", a.addr);
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
            | RETURN Exp ';'                    {fprintf(f,"storel %d\n",decFunRetAddr());fprintf(f,"return\n");}
            | ELSE                              {must(0, "'Else' sem um 'If' anteriormente");}                          
            ;

// ------------------------------------ ATRIBUIÇAO ------------------------------------

Atrib       : Var '=' Exp                       {Endereco a = getEndereco($1.var_nome); 
                                                 fprintf(f,"store%c %d\n",a.tipoVar, a.addr);
                                                } 

            | Var '+''+'                        {Endereco a = getEndereco($1.var_nome); 
                                                 must(a.tipo == _INTS, "Tipos incompativeis");
                                                 fprintf(f,"pushi 1\n push%c %d\n add\n store%c %d\n",a.tipoVar,a.addr, a.tipoVar, a.addr);
                                                }

            | Var'[' Exp ']' '=' Exp            {Endereco a = getEndereco($1.var_nome);
                                                 fprintf(f, "push%cp \n push%c %d padd\n", (a.tipoVar=='l')? 'f' : 'g', a.tipoVar, a.addr);
                                                 fprintf(f, "storen\n");}
            ;

// ------------------------------------ PRINT SCAN ------------------------------------
 
Print       : PRINT '(' Prints ')'                          
            ;

Scan        : SCAN '(' Var ')'                  {Endereco a = getEndereco($3.var_nome); 
                                                 fprintf(f,"read\n atoi\n store%c %d\n",a.tipoVar, a.addr);}       
            ;

Prints      : num                               {fprintf(f, "writei %d\n",$1 );}           
            | Var                               {Endereco a = getEndereco($1.var_nome); fprintf(f, "push%c %d\nwritei\n",a.tipoVar, a.addr);}   

            | Var '['Exp ']'                    {Endereco a = getEndereco($1.var_nome); 
                                                 fprintf(f, "push%cp\npush%c %d\npadd\n",(a.tipoVar=='l')?'f':'g', a.tipoVar, a.addr);
                                                 fprintf(f, "loadn\n");}  
            | id                                {fprintf(f, "pushs %s\nwrites", $1);}
            ;                    
// ------------------------------------ IF THEN ELSE ------------------------------------

If          :  IF                               {total++; 
                                                 pushStack(s,total);
                                                }
			TestExpLog   	                    {fprintf(f,"jz endCond%d\n", peekStack(s));}
			ConjInst  		                    {fprintf(f," endCond%d\n", popStack(s));}	
			Else
            ;

Else        :       
            | ELSE ConjInst 
            ;

// ------------------------------------# WHILE ---------------------------------------------

While       : WHILE                             {total++;
                                                 pushStack(s, total);
                                                 fprintf(f, "ciclo%d: NOP\n", peekStack(s));
                                                 }
            TestExpLog                          {fprintf(f, "jz endciclo%d\n", peekStack(s)); }
            ConjInst                            {fprintf(f, "jump ciclo%d\n endCiclo%d\n", peekStack(s), peekStack(s));
                                                 popStack(s);
                                                }                                
            ;

// ------------------------------------# FOR ---------------------------------------------

For         : FOR ForHeader ConjInst            {fprintf(f,"jump ciclo%dA\nendciclo%d\n", peekStack(s), peekStack(s)); popStack(s);}                  
            ;

ForHeader   :  '(' ForAtrib ';'                 {total++; 
                                                 pushStack(s,total);
                                                 fprintf(f,"ciclo%d: nop\n", peekStack(s));
                                                }
             ExpLog ';'                         {fprintf(f,"jz endciclo%d\njump ciclo%dB\nciclo%dA: nop\n", peekStack(s), peekStack(s), peekStack(s));}
             ForAtrib ')'                       {fprintf(f,"jump ciclo%d\nciclo%dB: nop\n", peekStack(s), peekStack(s));}
            ; 


ForAtrib    : Atrib  
            ;

// -----------------------------------------------------------------CALCULO DE EXPRESSOES -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ExpLog 		: Exp 
			| Exp '=''=' Exp 		            {fprintf(f, "equal\n");}
			| Exp '!''=' Exp                    {fprintf(f, "equal\npushi 0\nequal\n");}
			| Exp '>''=' Exp 		            {fprintf(f, "supeq\n");}
			| Exp '<''=' Exp 		            {fprintf(f, "infeq\n");}
			| Exp '<' Exp 			            {fprintf(f, "inf\n");}
			| Exp '>' Exp 			            {fprintf(f, "sup\n");}
			; 


Exp 		: Termo
			|Exp '+' Termo  			        {fprintf(f, "add\n");}
			|Exp  '-' Termo 			        {fprintf(f, "sub\n");}
			|Exp '|''|' ExpLog                  {fprintf(f, "add\n jz endCond%d:nop\n",peekStack(s));}
            |Exp '%' Termo                      {fprintf(f, "mod\n");}
			; 


Termo		: Fun
			| Termo '/' Fun 			        {fprintf(f, "div\n");}
			| Termo '*' Fun 			        {fprintf(f, "mul\n");}
			| Termo '&''&' ExpLog               {fprintf(f, "pushi 1\nequal\njz endCond%d: nop\n",peekStack(s));}
			; 

Fun 	   	: num                               {fprintf(f, "pushi %d\n",$1 );}           
            | Var  	                            {Endereco a = getEndereco($1.var_nome);
                                                 fprintf(f, "push%c %d\n",a.tipoVar, a.addr);} 	
            | Var '['Exp ']'                    {Endereco a = getEndereco($1.var_nome); 
                                                 fprintf(f, "push%cp\npush%c %d\npadd\n",(a.tipoVar=='l')?'f':'g', a.tipoVar, a.addr);
                                                 fprintf(f, "loadn\n");}  

            | IdFun                             {funcaoExiste($1);
                                                 fprintf(f, "pushi 0\n");}
            '(' FunArgs')'                      {fprintf(f, "call %s\n",$1);
                                                 fprintf(f, "pop%d\n",numeroArgumentos());
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
