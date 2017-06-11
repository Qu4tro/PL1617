%{
#include "compilador.h"
#include "y.tab.h"

%}

%option noyywrap
%option yylineno

%%

int         { return (INT);    }
while       { return (WHILE);  }
for         { return (FOR);    }
if          { return (IF);     }
else        { return (ELSE);   }
return      { return (RETURN); }
void        { return (VOID);   }
print     	{ return (PRINT);  }
scan     	{ return (SCAN);   }
do          { return (DO);     }
\=	 		{ return ('='); }
\.        	{ return ('.'); }
\;        	{ return (';'); }
\(        	{ return ('('); }
\)        	{ return (')'); }
\{   	    { return ('{'); }
\}      	{ return ('}'); }
\[ 	        { return ('['); }
\]	        { return (']'); }
\,        	{ return (','); }
\<	        { return ('<'); }
\>	        { return ('>'); }
\+	        { return ('+'); }
\-	        { return ('-'); }
\*	        { return ('*'); }
\/	        { return ('/'); }
\%	        { return ('%'); }
\#          { return ('#'); }
\|			{ return ('|'); }			
\&			{ return ('&'); }
[a-zA-Z]+  	{ yylval.var_nome = strdup(yytext); return (id);}
[0-9]+     	{ yylval.valor    = atoi(yytext);   return (num);}
[\n]        { ; }
\/\/.*      { ; }     
.           { ; }


%%
