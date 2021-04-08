%{
    #include <string.h>
    #include "ASTTree.hh"
    #include "y.tab.h"
    extern "C" {
        int yylex();
    }
%}
separator   [ \t\n\r]
letter      [a-zA-Z]
digit       [0-9]
number      0|[1-9]{digit}*|-[1-9]{digit}*
id          ("_"|{letter})({letter}|{digit}|"-")*

%%

[\n]				        {}
"="				            {return T_EQUAL;}
":"				            {return T_COLON;}
"("				            {}
")"				            {}	

"-"					        {return('-'); }
"+"					        {return('+'); }
"*"					        {return('*'); }
"/"					        {return('/'); }
"%"			    	        {return T_MOD_OP; }
"<"					        {return('<'); }
">"					        {return('>'); }
"=="				        {return T_EQ_OP;} 
"||"				        {return T_OR_OP;} 
"&&"				        {return T_AND_OP;}
"!"	    			        {return T_NOT;}


"GOTO"				        {return T_GOTO;}
"if"			            {return T_IF;}
"print"                     {return T_PRINT;}

{number}	    	        {sscanf(yytext, "%d", &yylval.intVal) ; return O_NUMBER;} 
\"({letter}|" "|{digit})*\" {yylval.str = strdup(yytext) ; return O_STRING;}
{id}            			{yylval.id = strdup(yytext) ; return O_IDENTIFIER;}
{separator}                 { ; }
.					        { printf("No Match, Invalid Expression %s\n", yytext); }
%%



int yywrap()
{
    return(1);
}
