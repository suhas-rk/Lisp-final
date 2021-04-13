%{
	#include <cstdio>
	#include <cstring>
	#include <cstdlib>

	using namespace std;

	void yyerror(const char *);
	#define YYSTYPE char*
	int yylex();
	extern int line;
	FILE *opt;

	typedef struct symbol_table_node
	{
		char name[30];
		char value[150];
	}NODE;

	NODE table[100];
	int top = -1;
	int stop_prop = 0;
	void add_or_update(char*,char*);
	char* getVal(char*);
	char* calculate(char*,char*,char*);
	char* Not(char*);
%}

%token T_EQUAL T_NOT T_COLON T_STRING T_PRINT T_IDENTIFIER T_NUMBER T_GOTO T_IF T_EQ_OP T_NE_OP T_OR_OP T_AND_OP T_MOD_OP


%%
supreme_start
	:start supreme_start
	|start
	;

start
	:T_PRINT T_STRING   								{
															fprintf(opt,"print ( %s )\n",$2);
														}
	|T_PRINT T_NUMBER   								{
															fprintf(opt,"print ( %s )\n",$2);
														}
	|T_PRINT T_IDENTIFIER   							{
															if(stop_prop)
															{
																fprintf(opt,"print ( %s )\n",$2);
															}
															else
															{
																fprintf(opt,"print ( %s )\n",getVal($2));
															}
														}
	|T_NOT T_IDENTIFIER	T_IDENTIFIER  					{
															stop_prop = 1;
															fprintf(opt,"! %s %s\n",$2,$3);
														}
	|T_EQUAL T_STRING T_IDENTIFIER  					{
															if(stop_prop)
															{
																fprintf(opt,"= %s %s\n",$2,$3);
															}
															else
															{
																add_or_update($3,$2);
																fprintf(opt,"= %s %s\n",$2,$3);
															}
														}
	|T_EQUAL T_NUMBER T_IDENTIFIER  					{
															if(stop_prop)
															{
																fprintf(opt,"= %s %s\n",$2,$3);
															}
															else
															{
																add_or_update($3,$2);
																fprintf(opt,"= %s %s\n",$2,$3);
															}
														}
	|T_EQUAL T_IDENTIFIER T_IDENTIFIER  					{
															if(stop_prop)
															{
																fprintf(opt,"= %s %s\n",$2,$3);
															}
															else
															{
																add_or_update($3,getVal($2));
																fprintf(opt,"= %s %s\n",getVal($2),$3);	
															}
														}
	|opr T_IDENTIFIER T_IDENTIFIER T_IDENTIFIER  				{
															if(stop_prop)
															{
																fprintf(opt,"%s %s %s %s\n",$1,$2,$3,$4);
															}
															else
															{
																add_or_update($4,calculate($1,getVal($2),getVal($3)));
																fprintf(opt,"= %s %s\n",calculate($1,getVal($2),getVal($3)),$4);
															}
														}
	|opr T_NUMBER T_IDENTIFIER T_IDENTIFIER  					{
															if(stop_prop)
															{
																fprintf(opt,"%s %s %s %s\n",$1,$2,$3,$4);
															}
															else
															{
																add_or_update($4,calculate($1,$2,getVal($3)));
																fprintf(opt,"= %s %s\n",calculate($1,$2,getVal($3)), $4);
															}
														}
	|opr T_IDENTIFIER T_NUMBER T_IDENTIFIER  					{
															if(stop_prop)
															{
																fprintf(opt,"%s %s %s %s\n",$1,$2,$3,$4);
															}
															else
															{
																add_or_update($4,calculate($1,getVal($2),$3));
																fprintf(opt,"= %s %s\n",calculate($1,getVal($2),$3),$4);
															}
														}
	|opr T_NUMBER T_NUMBER T_IDENTIFIER			{	
															if(stop_prop)
															{
																fprintf(opt,"= %s %s\n", calculate($1,$2,$3), $4);
															}
															else
															{
																add_or_update($4,calculate($1,$2,$3));
																fprintf(opt,"= %s %s\n",calculate($1,$2,$3),$4);
															}
														}
	|T_GOTO T_IDENTIFIER 								{
															fprintf(opt,"%s %s\n",$1,$2);
														}
	|T_IF T_IDENTIFIER T_GOTO T_IDENTIFIER 				{
															stop_prop = 1;
															fprintf(opt,"%s %s \n%s %s\n",$1,$2,$3,$4);
														}
	|T_IDENTIFIER T_COLON 								{
															stop_prop = 1;
															fprintf(opt,"%s :\n",$1);
														}
	;

opr
	:'+' 
	|'-'
	|'*'
	|'/'
	|'<'
	|'>'
	|T_MOD_OP
	|T_EQ_OP
	|T_NE_OP
	|T_OR_OP
	|T_AND_OP
	;
%%

int main()
{
opt = fopen("Optimize.txt", "w");
if(!yyparse())
{	printf("-----------------------------------\n");
	printf("Intermediate Code Optimized\nPlease check Optimize.txt for the Optimized IC");
	printf("\n-----------------------------------\n");
}

return 1;
}

void yyerror(const char *msg)
{

	printf("\n");
  	printf("------\n");
	printf("ERROR\n");
	printf("------\n");
	printf("Parsing Unsuccesful\n");
	printf("Message: %s\n", msg);
	printf("Syntax Error at line %d\n\n",line-1);

}

void add_or_update(char* name,char* value)
{
	if(top==-1)
	{
		
		top++;
		strcpy(table[top].name,name);
		strcpy(table[top].value,value);
		return;
	}
	for(int i = top;i>=0;i--)
	{
		if(strcmp(table[i].name,name)==0)
		{
			strcpy(table[i].value,value);
			return;
		}
	}
	
	top++;
	
	strcpy(table[top].name,name);
	
	strcpy(table[top].value,value);



}
char* getVal(char* name)
{
	for(int i = top;i>=0;i--)
	{
		if(strcmp(table[i].name,name)==0)
		{
			return table[i].value;
		}
	}

	// This will eventually cause a memory leak so yikes
	char* emergencyRetString = (char*) malloc(2 * sizeof(char));
	strcpy(emergencyRetString, "a");
	return emergencyRetString;
}
char* calculate(char* opr,char* op1,char* op2)
{	
	char* result;
	result = (char*)malloc(sizeof(char)*30);
	int oper1 = atoi(op1);
	int oper2 = atoi(op2);
	int res;
	if(strcmp(opr,"+")==0)
		res = oper1 + oper2;
	if(strcmp(opr,"-")==0)
		res = oper1 - oper2;		
	if(strcmp(opr,"*")==0)
		res = oper1 * oper2;
	if(strcmp(opr,"/")==0)
		res = oper1 / oper2;
	if(strcmp(opr,">")==0)
		res = oper1 > oper2;
	if(strcmp(opr,"<")==0)
		res = oper1 < oper2;
	if(strcmp(opr,"%")==0)
		res = oper1 % oper2;
	if(strcmp(opr,"==")==0)
		res = oper1 == oper2;
	if(strcmp(opr,"!=")==0)
		res = oper1 != oper2;
	if(strcmp(opr,"&&")==0)
		res = oper1 && oper2;
	if(strcmp(opr,"||")==0)
		res = oper1 || oper2;


	snprintf(result,30*sizeof(char),"%d",res);
	return result;
}

char* Not(char* op1)
{	
	char* result;
	result = (char*)malloc(sizeof(char)*30);
	int oper = atoi(op1);
	int res;
	res = (!oper);
	snprintf(result,30*sizeof(char),"%d",res);
	return result;
}
