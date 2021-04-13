%{
	#include <cstdio>
	#include <cstring>
	#include <cstdlib>
	#include <string>
	#include <unordered_map>
	#include <vector>

	using namespace std;

	void yyerror(const char *);
	#define YYSTYPE char*
	int yylex();
	extern int line;
	FILE *opt;

	enum Precomp_vt {
		INTVAL,
		STRINGVAL,
	};

	typedef struct Precomp_dt {
		Precomp_vt type;
		union {
			int i_val;
			char* str_val;
		} value;
	} Precomp_dt;

	unordered_map<string, Precomp_dt> precomp_st;
	vector<Precomp_dt> print_l;

	typedef struct symbol_table_node
	{
		char name[30];
		char value[150];
	}NODE;

	NODE table[100];
	int top = -1;
	int stop_prop = 0;
	int ignore_until_label = 0;
	char* next_label = NULL;

	int calculate_val(char*, int, int);
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
															
															if (!ignore_until_label) {
																Precomp_dt print_constant;
																print_constant.type = STRINGVAL;
																print_constant.value.str_val = $2;
																print_l.push_back(print_constant);
															}
														}
	|T_PRINT T_NUMBER   								{
															fprintf(opt,"print ( %s )\n",$2);
															
															if (!ignore_until_label) {
																Precomp_dt print_constant;
																print_constant.type = INTVAL;
																print_constant.value.i_val = atoi($2);
																print_l.push_back(print_constant);
															}
														}
	|T_PRINT T_IDENTIFIER   							{
															if (!ignore_until_label) {
																string identifier($2);
																auto precomp_data = precomp_st.find(identifier);
																if (precomp_data != precomp_st.end()) {
																	print_l.push_back(precomp_data -> second);
																}
															}

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
															if (!ignore_until_label) {
																string identifier1($2);
																string identifier2($3);
																auto precomp_data = precomp_st.find(identifier1);
																if (precomp_data != precomp_st.end()) {
																	Precomp_dt not_constant;
																	not_constant.type = INTVAL;

																	Precomp_dt data = precomp_data -> second;
																	if (data.type == INTVAL) {
																		not_constant.value.i_val = ((data.value.i_val)? 0: 1);
																	} else {
																		not_constant.value.i_val = ((strcmp(data.value.str_val, "\"\""))? 0: 1);
																	}
																	precomp_st[identifier2] = not_constant;
																}
															}
															
															stop_prop = 1;
															fprintf(opt,"! %s %s\n",$2,$3);
														}
	|T_EQUAL T_STRING T_IDENTIFIER  					{
															if (!ignore_until_label) {
																string identifier($3);
																Precomp_dt str_constant;
																str_constant.type = STRINGVAL;
																str_constant.value.str_val = $2;

																precomp_st[identifier] = str_constant;
															}

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
															if (!ignore_until_label) {
																string identifier($3);
																Precomp_dt int_constant;
																int_constant.type = INTVAL;
																int_constant.value.i_val = atoi($2);

																precomp_st[identifier] = int_constant;
															}

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
															if (!ignore_until_label) {
																string identifier1($2);
																string identifier2($3);
																auto precomp_data = precomp_st.find(identifier1);
																if (precomp_data != precomp_st.end()) {
																	precomp_st[identifier2] = precomp_data -> second;
																}
															}


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
															if (!ignore_until_label) {
																string identifier1($2);
																string identifier2($3);
																auto precomp_data1 = precomp_st.find(identifier1);
																auto precomp_data2 = precomp_st.find(identifier1);
																if (precomp_data1 != precomp_st.end() && precomp_data2 != precomp_st.end()) {
																	Precomp_dt data1 = precomp_data1 -> second;
																	Precomp_dt data2 = precomp_data2 -> second;
																	if (data1.type == INTVAL && data2.type == INTVAL) {
																		int i1 = data1.value.i_val;
																		int i2 = data2.value.i_val;

																		Precomp_dt int_constant;
																		int_constant.type = INTVAL;
																		int_constant.value.i_val = calculate_val($1, i1, i2);

																		string identifier3($4);
																		precomp_st[identifier3] = int_constant;
																	} else {
																		string identifier3($4);
																		precomp_st[identifier3] = data1;
																	}
																}
															}

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
															if (!ignore_until_label) {
																string identifier1($3);
																auto precomp_data = precomp_st.find(identifier1);
																int ival = atoi($2);
																if (precomp_data != precomp_st.end()) {
																	Precomp_dt data = precomp_data -> second;

																	Precomp_dt int_constant;
																	int_constant.type = INTVAL;
																	if (data.type == INTVAL) {
																		int i1 = data.value.i_val;
																		int_constant.value.i_val = calculate_val($1, ival, i1);
																	} else {
																		int_constant.value.i_val = ival;
																	}

																	string identifier2($4);
																	precomp_st[identifier2] = int_constant;
																}
															}

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
															if (!ignore_until_label) {
																string identifier1($2);
																auto precomp_data = precomp_st.find(identifier1);
																int ival = atoi($3);
																if (precomp_data != precomp_st.end()) {
																	Precomp_dt data = precomp_data -> second;

																	Precomp_dt int_constant;
																	int_constant.type = INTVAL;
																	if (data.type == INTVAL) {
																		int i1 = data.value.i_val;
																		int_constant.value.i_val = calculate_val($1, i1, ival);
																	} else {
																		int_constant.value.i_val = ival;
																	}

																	string identifier2($4);
																	precomp_st[identifier2] = int_constant;
																}
															}

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
															if (!ignore_until_label) {
																string identifier($4);
																int ival1 = atoi($2);
																int ival2 = atoi($3);
																
																Precomp_dt int_constant;
																int_constant.type = INTVAL;
																int_constant.value.i_val = calculate_val($1, ival1, ival2);

																precomp_st[identifier] = int_constant;
															}

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
	|T_GOTO T_IDENTIFIER 			{
															if (!ignore_until_label) {
																ignore_until_label = 1;
																next_label = $2;
															}
															fprintf(opt,"%s %s\n",$1,$2);
														}
	|T_IF T_IDENTIFIER T_GOTO T_IDENTIFIER 				{
															if (!ignore_until_label) {
																string identifier($2);
																auto precomp_data = precomp_st.find(identifier);
																if (precomp_data != precomp_st.end()) {
																	Precomp_dt data = precomp_data -> second;
																	if ((data.type == INTVAL && data.value.i_val) ||
																			(data.type == STRINGVAL && strcmp(data.value.str_val, "\"\"") != 0)) {
																		ignore_until_label = 1;
																		next_label = $4;
																	} 
																}
															}
															stop_prop = 1;
															fprintf(opt,"%s %s \n%s %s\n",$1,$2,$3,$4);
														}
	|T_IDENTIFIER T_COLON 								{
															if (ignore_until_label) {
																if(strcmp($1, next_label) == 0) {
																	ignore_until_label = 0;
																	next_label = NULL;
																}
															}
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

printf("\n-------------Super Optimized Codegen!-------------\n");
for (auto iter = print_l.begin(); iter != print_l.end(); ++iter) {
	Precomp_dt data = *iter;
	if (data.type == STRINGVAL) {
		printf("print %s\n", data.value.str_val);
	} else {
		printf("print %d\n", data.value.i_val);
	}
}
printf("\n--------------------------------------------------\n");

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

int calculate_val(char* opr, int oper1, int oper2)
{	
	int res = 0;
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

	return res;
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
