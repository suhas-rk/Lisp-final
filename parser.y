%{
    #include <iostream>
    #include <string.h>
    #include <stack>
    #include <map>
    #include <cstdio>
    #include "ASTTree.hh"
    #include<vector>
    using namespace std;

    #ifdef __linux__
    #define TEMP_FILE_LOCATION "/dev/null"
    #else
    #define TEMP_FILE_LOCATION "temp.txt"
    #endif

    extern "C" {
        extern int yylex();
        void yyerror(const char *message);
    }
    extern int comment_open;
    extern int table_pointer;
    extern int my_stack[];
    extern int line_number;
    extern int setting_value;
    extern struct row symtab[256];
    extern char* ERROR_TOKEN;
    extern char* COMMENT_OPEN_ERROR_TOKEN;
    extern void display();
    FILE *icg_file, *cp_icg_file, *temp_file;
    ASTNode *ast_root;
    int icg_line_number, icg_temp, icg_branch, icg_exit, icg_switch_nesting;
    int icg_case[100], icg_case_exit[100]; 
    vector<int> arr1[100];
    vector<int> arr2[100];
    int generate_code(ASTNode *);
    void print_code(ASTNode *);
    int ret_code(ASTNode *);
    void loop_unfolder(ASTNode *, int, int);
    
    // void print_id(ASTNode *);
    // int print_id_value(char *);

%}
%union {
    int intVal;
    bool boolVal;
    char* id;
    char* str;
    ASTNode *node;
}

%type <node> PROGRAM 
%type <node> STMTS PRINT_STMT SET_STMT
%type <node> EXP  
%type <node> NUM_OP LOGICAL_OP 
%type <node> PLUS MINUS MULTIPLY DIVIDE MODULES GREATER SMALLER EQUAL GREATER_EQUAL SMALLER_EQUAL
%type <node> AND_OP OR_OP NOT_OP
%type <node> VARIABLE
%type <node> IF_ELSE CASE DIFFCASES DIFFCASE
%type <node> NUM STR BOOL
%type <node> STMT

%token<intVal> T_number
%token<boolVal> T_bool_val
%token<id> T_id
%token<str> T_str
%token T_print T_setq T_if T_case T_geq T_leq

%left '>' '<' '='
%left '+' '-' 
%left '*' '/' T_mod 
%left T_and T_or T_not
%left '(' ')' 
/*%expect 1*/
%start S

%%
S                   : PROGRAM                       {
                                                        ast_root = $1;
                                                    }
  	                ;
PROGRAM             : STMT STMTS                    {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "PROGRAM");
                                                        $$ = makeNode2(temp, $1, $2);
                                                    }
                    | STMT                          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "PROGRAM");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    ;
STMTS               : STMT STMTS                    {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMTS");
                                                        $$ = makeNode2(temp, $1, $2);
                                                    }
                    | STMT                          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMTS");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    ;
STMT                : EXP                           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMT");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | SET_STMT                      {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMT");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | PRINT_STMT                    {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMT");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | IF_ELSE                        {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMT");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | CASE                          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STMT");
                                                        $$ = makeNode1(temp, $1);
                                                    } 
                    ;
PRINT_STMT          : '(' T_print EXP ')'            {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "PRINT_STMT");
                                                        $$ = makeNode1(temp, $3);
                                                    }
                    ;
EXP                 : BOOL                          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "EXP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | NUM                           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "EXP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | STR                           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "EXP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | VARIABLE                      {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "EXP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | NUM_OP                        {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "EXP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | LOGICAL_OP                    {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "EXP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    ;
NUM_OP              : PLUS                          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NUM_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | MINUS                         {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NUM_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | MULTIPLY                      {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NUM_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | DIVIDE                        {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NUM_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | MODULES                       {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NUM_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    ;
        PLUS        : '(' '+' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "+");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        MINUS       : '(' '-' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "-");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        MULTIPLY    : '(' '*' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "*");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        DIVIDE      : '(' '/' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "/");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        MODULES     : '(' T_mod EXP EXP ')'          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "%");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
LOGICAL_OP          : AND_OP                        {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | OR_OP                         {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | NOT_OP                        {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | GREATER                       {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | SMALLER                       {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | EQUAL                         {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                   | GREATER_EQUAL                 {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    }
                    | SMALLER_EQUAL                 {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "LOGICAL_OP");
                                                        $$ = makeNode1(temp, $1);
                                                    } 
                    ;
        AND_OP      : '(' T_and EXP EXP ')'          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "AND");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        OR_OP       : '(' T_or EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "OR");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        NOT_OP      : '(' T_not EXP ')'              {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NOT");
                                                        $$ = makeNode1(temp, $3);
                                                    }
                    ;
        GREATER     : '(' '>' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, ">");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        SMALLER     : '(' '<' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "<");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
        EQUAL       : '(' '=' EXP EXP ')'           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "=");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                     ;
       GREATER_EQUAL : '(' T_geq EXP EXP ')'         {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, ">=");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                     ;
       SMALLER_EQUAL : '(' T_leq EXP EXP ')'         {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "<=");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
SET_STMT            : '(' T_setq VARIABLE EXP ')'    {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "SET_STMT");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
    
IF_ELSE              : '(' T_if EXP STMT STMT ')'     {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "IF_ELSE_EXP");
                                                        $$ = makeNode3(temp, $3, $4, $5);
                                                    }
                    | '(' T_if EXP STMT ')'          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "IF_EXP");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
CASE              : '(' T_case VARIABLE DIFFCASES ')' {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "CASE");
                                                        $$ = makeNode2(temp, $3, $4);
                                                    }
                    ;
DIFFCASES           : DIFFCASE DIFFCASES             {
                                                       char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "DIFFCASES");
                                                        $$ = makeNode2(temp, $1,$2);
                                                    }
                    | DIFFCASE                    {
                                                       char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "DIFFCASES");
                                                        $$ = makeNode1(temp, $1);
                                                    }

                    ;
DIFFCASE            : '(' NUM STMTS ')'              {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "DIFFCASE");
                                                        $$ = makeNode2(temp, $2,$3);
                                                    }
                    ;
VARIABLE            : T_id                           {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "VARIABLE");
                                                        ASTNode *t = makeLeafNode_id($1);
                                                        $$ = makeNode1(temp, t);
                                                    }
                    ;
NUM                 : T_number                       {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "NUM");
                                                        ASTNode *t = makeLeafNode_num($1);
                                                        $$ = makeNode1(temp, t);
                                                    }
                    ;
BOOL                : T_bool_val                     {   
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "BOOL");
                                                        ASTNode *t = makeLeafNode_bool($1);
                                                        $$ = makeNode1(temp, t);
                                                    }
                    ;
STR                 : T_str                          {
                                                        char *temp = (char *)malloc(sizeof(char)*15);
                                                        strcpy(temp, "STR");
                                                        ASTNode *t = makeLeafNode_str($1);
                                                        $$ = makeNode1(temp, t);
                                                    }
                    ;
%%

void yyerror(const char *message) {
    fprintf (stderr, "%s\n",message);
}

int main(int argc, char *argv[]) {
    my_stack[0] = 0;
    setting_value = 0;
    table_pointer = 0;
    comment_open = 0;
    line_number = 1;
    ERROR_TOKEN = (char *)malloc(sizeof(char)*15);
    COMMENT_OPEN_ERROR_TOKEN = (char *)malloc(sizeof(char)*37);
    strcpy(ERROR_TOKEN, "Error_Token");
    strcpy(COMMENT_OPEN_ERROR_TOKEN, "Error: Multiline comment not closed!");
    icg_line_number = 0;
    icg_branch = 0;
    icg_exit = 0;
    icg_temp = 0;
    icg_switch_nesting = -1;
	icg_file = fopen("ic.3ac", "w");
    temp_file = fopen(TEMP_FILE_LOCATION, "w");
    cp_icg_file = NULL;
    int ret_code = 0;
    if(yyparse()==1)
	{
        // display();
		printf("Parsing failed\n");
        ret_code = 1;
	}
	else
	{
        display();
        generate_code(ast_root);
		printf("\n-----------------------------------\n");
        printf("LISP Code Converted to Intermediate Code\nPlease check ic.3ac for the Intermediate Code");
        printf("\n-----------------------------------\n");
        preorder_traversal(ast_root);
	}

	fclose(icg_file);
    fclose(temp_file);

#ifndef __linux__
    remove(TEMP_FILE_LOCATION);
#endif

    // printf("Printing IC:\n\n");
	// system("cat icg.txt");
    printf("\n\n");
    return ret_code;
}

int generate_code(ASTNode *root)
{
    if(root->type == 1)
    {       
        if( strcmp(root->ope, "PRINT_STMT") == 0 )
        {
            int op0 = generate_code(root->child[0]);
            if( op0 > 0)
            {
                fprintf(icg_file, "param t%d\n", op0);
            }
            else
            {
                fprintf(icg_file, "param");
                print_code(root->child[0]);
                fprintf(icg_file, "\n");
            }
            fprintf(icg_file, "call (print,1)\n");
        }
        else if( strcmp(root->ope, "+") == 0 || strcmp(root->ope, "-") == 0 || strcmp(root->ope, "*") == 0 || strcmp(root->ope, "/") == 0 || strcmp(root->ope, "%") == 0 || strcmp(root->ope, "<") == 0 || strcmp(root->ope, ">") == 0 || strcmp(root->ope, "<=") == 0 || strcmp(root->ope, ">=") == 0)
        {
            int tempvar = ++icg_temp;
            int op0 = generate_code(root->child[0]);
            int op1 = generate_code(root->child[1]);
            fprintf(icg_file, " %s ", root->ope);
            
            if( op0 > 0)
            {
                fprintf(icg_file, " t%d ", op0);
            }
            else
            {
                print_code(root->child[0]);
            }
            
            if( op1 > 0)
            {
                fprintf(icg_file, " t%d ", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            fprintf(icg_file, " t%d ", tempvar);
            fprintf(icg_file, "\n");
            return tempvar;
        }
        else if( strcmp(root->ope, "=") == 0 )
        {
            int tempvar = ++icg_temp;
            int op0 = generate_code(root->child[0]);
            int op1 = generate_code(root->child[1]);
            
            fprintf(icg_file, " == ");
            if( op0 > 0)
            {
                fprintf(icg_file, " t%d ", op0);
            }
            else
            {
                print_code(root->child[0]);
            }
            
            if( op1 > 0)
            {
                fprintf(icg_file, " t%d ", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            fprintf(icg_file, " t%d ", tempvar);
            fprintf(icg_file, "\n");
            return tempvar;
        }
        else if( strcmp(root->ope, "AND") == 0 )
        {
            int tempvar = ++icg_temp;
            int op0 = generate_code(root->child[0]);
            int op1 = generate_code(root->child[1]);
            fprintf(icg_file, " && ");
            if( op0 > 0)
            {
                fprintf(icg_file, "t%d", op0);
            }
            else
            {
                print_code(root->child[0]);
            }
            
            if( op1 > 0)
            {
                fprintf(icg_file, "t%d", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            fprintf(icg_file, "t%d  ", tempvar);
            fprintf(icg_file, "\n");
            return tempvar;
        }
        else if( strcmp(root->ope, "OR") == 0)
        {
            int tempvar = ++icg_temp;
            int op0 = generate_code(root->child[0]);
            int op1 = generate_code(root->child[1]);
            fprintf(icg_file, " || ");
            if( op0 > 0)
            {
                fprintf(icg_file, "t%d", op0);
            }
            else
            {
                print_code(root->child[0]);
            }
            
            if( op1 > 0)
            {
                fprintf(icg_file, "t%d", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            fprintf(icg_file, " t%d ", tempvar);
            fprintf(icg_file, "\n");
            return tempvar;
        }
        else if( strcmp(root->ope, "NOT") == 0)
        {
            int tempvar = ++icg_temp;
            int notvar = ++icg_temp;
            int op0 = generate_code(root->child[0]);
            if( op0 <= 0)
            {
                fprintf(icg_file, " = ");
                print_code(root->child[0]);
                fprintf(icg_file, " t%d ", notvar);
                
                fprintf(icg_file, "\n");
            }
            fprintf(icg_file, " ! ");
            if( op0 > 0)
            {
                fprintf(icg_file, " t%d ", op0);
            }
            else
            {
                fprintf(icg_file, " t%d ", notvar);
            }
            fprintf(icg_file, " t%d ", tempvar);
            fprintf(icg_file, "\n");
            return tempvar;
        }
        else if( strcmp(root->ope, "SET_STMT") == 0 )
        {
            int op1 = generate_code(root->child[1]);
            
            fprintf(icg_file, " = ");
            if( op1 > 0)
            {
                fprintf(icg_file, " t%d ", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            print_code(root->child[0]);
            fprintf(icg_file, "\n");
        }
        else if( strcmp(root->ope, "IF_ELSE_EXP") == 0 )
        {
            int op1 = generate_code(root->child[0]);
            fprintf(icg_file, "if ");
            if( op1 > 0)
            {
                fprintf(icg_file, "t%d", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            fprintf(icg_file, "\n");
            int branch1 = ++icg_branch;
            int branch2 = ++icg_branch;
            int exit = ++icg_exit;
            fprintf(icg_file, "GOTO _L%d\n", branch1);
            fprintf(icg_file, "GOTO _L%d\n", branch2);
            fprintf(icg_file, "_L%d :\n", branch1);
            generate_code(root->child[1]);
            fprintf(icg_file, "GOTO _EXIT%d\n", exit);
            fprintf(icg_file, "_L%d :\n", branch2);
            generate_code(root->child[2]);
            fprintf(icg_file, "_EXIT%d :\n", exit);
        }
        else if( strcmp(root->ope, "IF_EXP") == 0 )
        {
            int op1 = generate_code(root->child[0]);
            fprintf(icg_file, "if ");
            if( op1 > 0)
            {
                fprintf(icg_file, "t%d", op1);
            }
            else
            {
                print_code(root->child[1]);
            }
            fprintf(icg_file, "\n");
            int branch1 = ++icg_branch;
            int exit = ++icg_exit;
            fprintf(icg_file, "GOTO _L%d\n", branch1);
            fprintf(icg_file, "GOTO _EXIT%d\n", exit);
            fprintf(icg_file, "_L%d :\n", branch1);
            generate_code(root->child[1]);
            fprintf(icg_file, "_EXIT%d :\n", exit);
        }
        else if( strcmp(root->ope, "DIFFCASE") == 0 )
        {
            
            int branch = ++icg_branch;
            icg_case[icg_switch_nesting]++;
            int exit = icg_exit;
            fprintf(icg_file, "\n_L%d :\n", branch);
            arr2[icg_switch_nesting].push_back(branch);
            generate_code(root->child[1]);
            fprintf(icg_file, "GOTO _EXIT%d\n", icg_case_exit[icg_switch_nesting]);
            
            int x = ret_code(root->child[0]);
            
            arr1[icg_switch_nesting].push_back(x);
            
        }
        else if( strcmp(root->ope, "DIFFCASES") == 0 )
        {
        
            generate_code(root->child[0]);
            if (root->number_of_children == 2){ generate_code(root->child[1]);}
            
        }
        else if( strcmp(root->ope, "CASE") == 0 )
        {
            ++icg_switch_nesting;
            int op1 = generate_code(root->child[0]);
            arr1[icg_switch_nesting].resize(0);
            arr2[icg_switch_nesting].resize(0);
            
            int n,x;
            int exit = ++icg_exit;
            icg_case[icg_switch_nesting]=0;

            // Checkpoint state
            int cp_icg_temp = icg_temp;
            int cp_icg_branch = icg_branch;
            int cp_icg_exit = icg_exit;
            int flag = 0;

            if (cp_icg_file == NULL) {
                cp_icg_file = icg_file;
                icg_file = temp_file;
                flag = 1;
            }
            
            // Generate code to populate arr1 and arr2
            n = root->number_of_children;
            for(int i=0;i < n; i++){
                generate_code(root->child[i]);
            }
            n = icg_case[icg_switch_nesting];
            
            if (flag) {
                icg_file = cp_icg_file;
                cp_icg_file = NULL;
            }

            // Restore state
            icg_temp = cp_icg_temp;
            icg_branch = cp_icg_branch;
            icg_exit = cp_icg_exit;

            for(int i=0; i < n; i++){
                int tempvar = ++icg_temp;
                fprintf(icg_file, "==");
                print_code(root->child[0]);
                fprintf(icg_file, "%d t%d\n", arr1[icg_switch_nesting][i], tempvar);
                fprintf(icg_file, "if t%d\n\tGOTO _L%d\n", tempvar, arr2[icg_switch_nesting][i]);
            }
            fprintf(icg_file, "GOTO _EXIT%d\n",exit);
            
            icg_case_exit[icg_switch_nesting] = exit;
            n = root->number_of_children;

            for(int i=0;i < n; i++){
                generate_code(root->child[i]);
            }
            n = icg_case[icg_switch_nesting];

            fprintf(icg_file, "\n_EXIT%d :\n", exit);
            --icg_switch_nesting;
        }
        else
        {
            int return_value = generate_code(root->child[0]);
            for(int i=1 ; i<root->number_of_children ; i++)
            {
                generate_code(root->child[i]);
            }
            return return_value;
        }
    }
    return 0;
}

void print_code(ASTNode *root)
{
    switch(root->type)
    {
        case 1: 
                for(int i=0 ; i<root->number_of_children ; i++)
                {
                    print_code(root->child[i]);
                }
                break;
        case 2: 
                // if(!print_id_value(root->id))
                fprintf(icg_file, " $%s ", root->id);
                break;
        case 3:
                fprintf(icg_file, " %d ", root->num_value);
                break;
        case 4:
                fprintf(icg_file, " %d ", root->bool_value);
                break;
        case 5:
                fprintf(icg_file, " %s ", root->str_value);
                break;
    }
}

int ret_code(ASTNode *root)
{
    
    switch(root->type)
    {
        case 1: 
                
                return    ret_code(root->child[0]);
                
                break;
        case 2: 
                // if(!print_id_value(root->id))
                
                fprintf(icg_file, "%s", root->id);
                break;
        case 3:
                return root->num_value;
                break;
        case 4:
                fprintf(icg_file, "%d", root->bool_value);
                break;
        case 5:
                fprintf(icg_file, "%s", root->str_value);
                break;
    }

    return 0;
}



void loop_unfolder(ASTNode *root, int start, int end)
{
    if (start<end)
    {
        for( int i=start ; i<end ; i++)
        {
            print_code(root->child[0]->child[0]);
            fprintf(icg_file, " = %d\n", i);
            generate_code(root->child[1]);
            fprintf(icg_file, "\n");
        }
    }
    else
    {
        for( int i=start ; i>end ; i--)
        {
            print_code(root->child[0]->child[0]);
            fprintf(icg_file, " = %d\n", i);
            generate_code(root->child[1]);
            fprintf(icg_file, "\n");
        }
    }
}

// void print_id(ASTNode *root)
// {
//     switch(root->type)
//     {
//         case 1: 
//                 for(int i=0 ; i<root->number_of_children ; i++)
//                 {
//                     print_id(root->child[i]);
//                 }
//                 break;
//         case 2:
//                 fprintf(icg_file, "%s", root->id);
//                 break;
//     }
// }
// int print_id_value(char *id_value)
// {
//     int temp = table_pointer-1;
//     while (temp>=0) 
//     {
//         if(strcmp(symtab[temp].id, id_value) == 0 && symtab[temp].scope == 0)
//         {
//             // fprintf(icg_file, "\nID VALUE FOUND");
//             if(symtab[temp].valid_value == 1)
//             {
//                 // fprintf(icg_file, "\nID VALUE \n");
//                 switch(symtab[temp].type)
//                 {
//                     case 1: fprintf(icg_file, "%d", symtab[temp].num_value);
//                             break;
//                     case 2: fprintf(icg_file, "%c", symtab[temp].bool_value);
//                             break;
//                     case 3: fprintf(icg_file, "%s", symtab[temp].str_value);
//                             break;
//                 }
//                 return 1;
//             }
//             return 0;
//         }
//         temp--;
//     }
//     return 0;
// }
