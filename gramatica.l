%{
#include "compilador.h"
#include "y.tab.h"

%}

%option noyywrap
%option yylineno

%%

int         { return (INT);    }
if          { return (IF);     }
else        { return (ELSE);   }
while       { return (WHILE);  }
print     	{ return (PRINT);  }
scan     	{ return (SCAN);   }
\=	 		{ return ('='); }
\.        	{ return ('.'); }
\;        	{ return (';'); }
\(        	{ return ('('); }
\)        	{ return (')'); }
\[ 	        { return ('['); }
\]	        { return (']'); }
\{   	    { return ('{'); }
\}      	{ return ('}'); }
\<	        { return ('<'); }
\>	        { return ('>'); }
\,        	{ return (','); }
\+	        { return ('+'); }
\-	        { return ('-'); }
\*	        { return ('*'); }
\/	        { return ('/'); }
\%	        { return ('%'); }
\|			{ return ('|'); }			
\&			{ return ('&'); }
[a-zA-Z]+  	{ yylval.varName  = strdup(yytext); return (id);}
[0-9]+     	{ yylval.varValue = atoi(yytext);   return (num);}
[\n]        { ; }
\/\/.*      { ; }     
.           { ; }


%%
