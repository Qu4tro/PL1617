%{ 
#define instruction(...) do { \
    fprintf(f, __VA_ARGS__); \
    fprintf(f, "\n"); \
} while (0);

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "y.tab.h"
#include "stack.h"
#include "libCompile.h"

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

FILE *f;

int total_labels = 0;
Environment env;
Stack s;

Address address;

%}

%union {
    char* varName;
    int varValue;
    int varType;
    struct sVarAtr {
        char* varName;
        int varValue;
        int size;
    } varAtr;   
}

%token INT WHILE IF ELSE PRINT SCAN
%token <varValue>num 
%token <varName>id 

%type <varType> Type
%type <varAtr> Var

%%

Start       : Declarations                      {instruction("start");
                                                 instruction("jump inicio");
                                                }	 	
			  Stataments    		            {instruction("stop");}                                                         
            ; 

Declarations :                            
             | Declarations Declaration 
             ;

Stataments   : Statement                               
             | Stataments Statement                                    
             ;

Type 		: INT                               {$$ = (int) IntType;} 

Declaration : Type id ';'                       {declareVar(env, $2, 1, 'S');
                                                 instruction("pushi 0");
                                                }   			                
            | Type id '[' num ']' ';'           {declareVar(env, $2, $4, 'A');
                                                 instruction("pushn %d", $4);
                                                }
            ;


Var 		: id                                {address = getGlobalAddress(env, $1);
                                                 $$.varName = strdup($1);
                                                 $$.varValue = 0;
                                                }
			;


Block    :
            | '{' Stataments '}'
            ;

Statement   : If ';'
            | Declaration ';'
            | While ';'
            | Atrib ';'
            | Print';'
            | Scan ';'
            ;

Atrib       : Var '=' Exp                       {address = getGlobalAddress(env, $1.varName); 
                                                 instruction("storeg %d", address.addr);
                                                } 

            | Var '+' '+'                        {address = getGlobalAddress(env, $1.varName); 
                                                 must(address.varType == (int) IntType, "Wrong type");
                                                 instruction("pushi 1");
                                                 instruction("pushg %d", address.addr);
                                                 instruction("add");
                                                 instruction("storeg %d", address.addr);
                                                }

            | Var '[' Exp ']' '=' Exp            {address = getGlobalAddress(env, $1.varName);
                                                 instruction("pushgp");
                                                 instruction("pushg %d", address.addr);
                                                 instruction("padd");
                                                 instruction("storen");
                                                }
            ;

// IO
Print       : PRINT '(' PrintAtom ')'                          
            ;

Scan        : SCAN '(' Var ')'                  {address = getGlobalAddress(env, $3.varName); 
                                                 instruction("read");
                                                 instruction("atoi");
                                                 instruction("storeg %d", address.addr);
                                                }       
            ;

PrintAtom   : num                               {instruction("writei %d",$1 );}           
            | Var                               {address = getGlobalAddress(env, $1.varName);
                                                 instruction("pushg %d", address.addr);
                                                 instruction("writei");
                                                } 
            | Var '['Exp ']'                    {address = getGlobalAddress(env, $1.varName); 
                                                 instruction("pushgp");
                                                 instruction("pushg %d", address.addr);
                                                 instruction("padd");
                                                 instruction("loadn");
                                                }  
            ;                    

// Conditionals
If          :  IF                               {pushStack(s, total_labels++);}
			'(' ExpRel ')'   	                {instruction("jz end_condition_%d", peekStack(s));}
			Block  		                        {instruction("end_condition_%d", popStack(s));}	
			Else
            ;

Else        :       
            | ELSE Block 
            ;


// Loops
While       : WHILE                             {pushStack(s, total_labels++);
                                                 instruction("loop_%d: nop", peekStack(s));
                                                }
            '(' ExpRel ')'                      {instruction("jz end_loop%d", peekStack(s)); }
            Block                               {instruction("jump loop_%d", peekStack(s));
                                                 instruction("end_loop%d", peekStack(s));
                                                 popStack(s);
                                                }                                
            ;

// Expressions
Exp 		: Term
			| Exp '+' Term  			        {instruction("add");}
			| Exp  '-' Term 			        {instruction("sub");}
			| Exp '|''|' ExpRel                 {instruction("add");
                                                 instruction("jz end_condition_%d: nop", peekStack(s));
                                                 instruction("nequal");
                                                }
            | Exp '%' Term                      {instruction("mod");}
			; 

ExpRel 		: Exp 
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


Term		: Atom
			| Term '/' Atom 			        {instruction("div");}
			| Term '*' Atom 			        {instruction("mul");}
			| Term '&''&' ExpRel                {instruction("pushi 1");
                                                 instruction("nequal");
                                                 instruction("jz end_condition_%d: nop",peekStack(s));
                                                }
			; 

Atom 	   	: num                               {instruction("pushi %d", $1);}           
            | Var  	                            {address = getGlobalAddress(env, $1.varName);
                                                 instruction("pushg %d", address.addr);
                                                } 	
            | Var '[' Exp ']'                   {address = getGlobalAddress(env, $1.varName); 
                                                 instruction("pushgp");
                                                 instruction("pushg %d", address.addr);
                                                 instruction("padd");
                                                 instruction("loadn");
                                                }  
            | '(' Exp ')'                  
            ;                                  

%%

#include "lex.yy.c"

int main(int argc, char* argv[]){
    env = initEnvironment();
    s   = initStack();

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
