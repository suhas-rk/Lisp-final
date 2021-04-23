%{
    #include <string.h>
    #include <iomanip>
    #include <iostream>
    #include "ASTTree.hh"
    #include "y.tab.h"
    using namespace std;

    extern "C" {
        int yylex();
    }
    int comment_open;
    int table_pointer;
    int line_number;
    int setting_value;
    int currHighest = 0;
    int ignore_id = 0;

    struct row symtab[256];

    int top = 0;
    int my_stack[256];
    int loop = 1;
    char* ERROR_TOKEN;
    char* COMMENT_OPEN_ERROR_TOKEN;
	void insert(char *id);
	void display();
    void push();
    void pop();
    int get_top();
    void set_num(char *value);
    void set_bool(char *value);
    void set_str(char *value);

    char *last_id;
    char *last_str;
    char last_bool;
    int last_num;
%}
separator  [ \t\n\r]
letter     [a-zA-Z]
digit      [0-9]
number     0|[1-9]{digit}*|-[1-9]{digit}*
id         {letter}({letter}|{digit}|"-")*
boolval   T|F
operator   [#*;@!%&]
%%
<<EOF>>                     { if (comment_open) { insert(COMMENT_OPEN_ERROR_TOKEN); }return 0; }
"\n"                        { ignore_id = 0; line_number++; }
{separator}                 { ; }
"+"                         { if(!comment_open) return(yytext[0]); }
"-"                         { if(!comment_open) return(yytext[0]); }
"*"                         { if(!comment_open) return(yytext[0]); }
"/"                         { if(!comment_open) return(yytext[0]); }
">"                         { if(!comment_open) return(yytext[0]); }
"<"                         { if(!comment_open) return(yytext[0]); }
"="                         { if(!comment_open) return(yytext[0]); }
"<="                        { if(!comment_open) return(T_leq); }
">="                        { if(!comment_open) return(T_geq); }
"'"                         { if(!comment_open) return(yytext[0]); }
"("                         {   
                                if(!comment_open) {
                                setting_value = 0 ;
                                loop = 0;
                                return(yytext[0]);
                                }
                            }
")"                         {
                                if(!comment_open) {
                                ignore_id = 0;
                                setting_value = 0 ;
                                int return_value;
                                if(loop)
                                {
                                    pop();
                                }   
                                loop = 1;
                                return(yytext[0]);
                                }
                            }
"mod"                       { if(!comment_open) return(T_mod); }
"and"                       { if(!comment_open) return(T_and); }
"or"                        { if(!comment_open) return(T_or); }
"not"                       { if(!comment_open) return(T_not); }
"setq"                      { if(!comment_open) { setting_value = 1 ; return(T_setq); } }
"if"                        { if(!comment_open) { push() ; return(T_if); } }
"case"                      { if(!comment_open) { push() ; return(T_case); } }
"print"                     { if(!comment_open) return(T_print); }
{number}                    { if(!comment_open) { sscanf(yytext, "%d", &yylval.intVal) ; set_num(yytext) ; setting_value = 0 ; return(T_number); } }
{boolval}                  { if(!comment_open) { yylval.id = strdup(yytext) ; set_bool(yytext) ; setting_value = 0 ; if(yytext[0] == 'T') yylval.boolVal = true; else yylval.boolVal = false ; return(T_bool_val); } }
\"({letter}|" "|{operator}|{digit})*\" { if(!comment_open) { yylval.str = strdup(yytext) ; set_str(yytext) ; setting_value = 0 ;  return(T_str); } }
{id}                        { 
                                if(!comment_open && !ignore_id) {
                                if(loop == 0)
                                {
                                    yylval.id = strdup(yytext);
                                    insert(yytext);
                                    return(T_id);
                                }
                                else
                                {
                                    insert(ERROR_TOKEN);
                                }
                                }
                            }
";".*			            { ; }
"#\|"                        { comment_open = 1; }
"\|#"                        { comment_open = 0; }
.                           { ignore_id = 1; printf("Syntax error at line: %d\n", line_number); insert(ERROR_TOKEN); }
%%

void insert(char *id)
{
        strcpy(symtab[table_pointer].id,id);
        symtab[table_pointer].line_no = line_number;
        symtab[table_pointer].scope = get_top();
        symtab[table_pointer].valid_value = 0;
        symtab[table_pointer].type = 0;
        table_pointer++;
}

void set_num(char *value)
{
    if(setting_value)
    {
        symtab[table_pointer-1].valid_value = 1;
        symtab[table_pointer-1].type = 1;
        symtab[table_pointer-1].num_value = atoi(value);
    }
}

void set_bool(char *value)
{
    if(setting_value)
    {
        symtab[table_pointer-1].valid_value = 1;
        symtab[table_pointer-1].type = 2;
        symtab[table_pointer-1].bool_value = value[0];
    }
}

void set_str(char *value)
{
    if(setting_value)
    {
        symtab[table_pointer-1].valid_value = 1;
        symtab[table_pointer-1].type = 3;
        symtab[table_pointer-1].str_value = new char[strlen(value)+1];
        strcpy(symtab[table_pointer-1].str_value, value);
    }

}

void display()
{
    cout << "_________________________________________\n";
    cout << "|" << setw(7) << "ID" << "|" << setw(7) << "Line" << "|" << setw(7) << "Scope" << "|" << setw(7) << "Type" << "|" << setw(7) << "Value" << "|" << "\n" ;
    cout << "_________________________________________\n";
    for(int i=0 ; i<table_pointer ; i++)
    {
        /*printf("Id    : %s\n", symtab[i].id);
        printf("line  : %d\n", symtab[i].line_no);
        printf("scope : %d\n", symtab[i].scope);*/
        
        cout << "|" << setw(7) << symtab[i].id << "|" << setw(7) << symtab[i].line_no << "|" << setw(7) << symtab[i].scope << "|" ;
        if(symtab[i].valid_value)
        {
            switch(symtab[i].type)
            {
                case 1: 
                        /*printf("type : %s\n", "NUM");
                        printf("value : %d\n", symtab[i].num_value);
                        break; */ 
                        cout << "|" <<  setw(7) << "NUM" << "|" << setw(7) << symtab[i].num_value << "|" ;
                        break;
                        
                case 2: 
                        /*printf("type : %s\n", "BOOL");
                        printf("value : %c\n", symtab[i].bool_value);
                        break;*/ 
                        cout << "|" << setw(7) << "BOOL" << "|" << setw(7) << symtab[i].bool_value << "|";
                        break;
                case 3: 
                        /*printf("type : %s\n", "STRING");
                        printf("value : %s\n", symtab[i].str_value);
                        break;*/ 
                        cout << "|" << setw(7) << "STRING" << "|" << setw(7) << symtab[i].str_value << "|";
                        break;
            }
        }
        cout << "\n_________________________________________\n";
        
    }
    cout << "_________________________________________\n"; 
    printf("\n\n");
}

void push()
{
    my_stack[++top] = ++currHighest;
}   

void pop()
{
    if(top == 0)
        return;
    top--;
}

int get_top()
{
    return my_stack[top];
}


int yywrap()
{
    return(1);
}
