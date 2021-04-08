%{
	#define YYSTYPE char*
	#include "y.tab.h"
    #include <stdio.h>
    extern void yyerror(const char *);
    int line = 1;
%}

separator   [ \t\n\r]
letter      [a-zA-Z]
digit       [0-9]
number      0|[1-9]{digit}*|-[1-9]{digit}*
id          ("_"|{letter})({letter}|{digit}|"-")*

%%

[\n]				        {line++;}
"="				            {yylval = strdup(yytext);return T_EQUAL;}
":"				            {yylval = strdup(yytext);return T_COLON;}
"("				            {}
")"				            {}	

"-"					        {yylval = strdup(yytext);return('-'); }
"+"					        {yylval = strdup(yytext);return('+'); }
"*"					        {yylval = strdup(yytext);return('*'); }
"/"					        {yylval = strdup(yytext);return('/'); }
"%"			    	        {yylval = strdup(yytext);return T_MOD_OP; }
"<"					        {yylval = strdup(yytext);return('<'); }
">"					        {yylval = strdup(yytext);return('>'); }
"=="				        {yylval = strdup(yytext);return T_EQ_OP;} 
"||"				        {yylval = strdup(yytext);return T_OR_OP;} 
"&&"				        {yylval = strdup(yytext);return T_AND_OP;}
"!"	    			        {yylval = strdup(yytext);return T_NOT;}


"GOTO"				        {yylval = strdup(yytext);return T_GOTO;}
"if"			            {yylval = strdup(yytext);return T_IF;}
"print"                     {yylval = strdup(yytext);return T_PRINT;}

{number}	    	        {yylval = strdup(yytext);return T_NUMBER;} 
\"({letter}|" "|{digit})*\" {yylval = strdup(yytext);return(T_STRING);}
{id}            			{yylval = strdup(yytext);return T_IDENTIFIER;}
{separator}                 { ; }
.					        { printf("No Match, Invalid Expression %s\n", yytext); }

%%
