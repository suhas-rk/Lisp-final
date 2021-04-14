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
	Precomp_dt last_param;

	typedef struct symbol_table_node
	{
		char name[30];
		char value[150];
	}NODE;

	NODE table[100];
	int top = -1;
	int stop_prop = 0;
	int ignore_until_label = 0;
	int op_enabled = 0;
	int nasm_enabled = 0;
	char* next_label = NULL;

	int calculate_val(char*, int, int);
	void add_or_update(char*,char*);
	char* getVal(char*);
	char* calculate(char*,char*,char*);
	char* Not(char*);
%}

%token T_EQUAL T_NOT T_COLON T_STRING T_PRINT T_IDENTIFIER T_NUMBER T_GOTO T_IF T_EQ_OP T_NE_OP T_OR_OP T_AND_OP T_MOD_OP T_PARAM


%%
supreme_start
	:start supreme_start
	|start
	;

start
	:T_PARAM T_STRING   			{
															fprintf(opt,"%s %s\n",$1,$2);
															
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
																Precomp_dt print_constant;
																print_constant.type = STRINGVAL;
																print_constant.value.str_val = $2;
																last_param = print_constant;
															}
														}
	|T_PARAM T_NUMBER   			{
															fprintf(opt,"%s %s\n",$1,$2);
															
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
																Precomp_dt print_constant;
																print_constant.type = INTVAL;
																print_constant.value.i_val = atoi($2);
																last_param = print_constant;
															}
														}
	|T_PARAM T_IDENTIFIER   	{
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
																string identifier($2);
																auto precomp_data = precomp_st.find(identifier);
																if (precomp_data != precomp_st.end()) {
																	last_param = precomp_data -> second;
																}
															}

															if(stop_prop)
															{
																fprintf(opt,"%s %s\n",$1,$2);
															}
															else
															{
																fprintf(opt,"%s %s\n",$1,getVal($2));
															}
														}
	|T_PRINT									{
															fprintf(opt, "%s\n", $1);
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
																print_l.push_back(last_param);
															}
														}
	|T_NOT T_IDENTIFIER	T_IDENTIFIER  					{
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
																ignore_until_label = 1;
																next_label = $2;
															}
															fprintf(opt,"%s %s\n",$1,$2);
														}
	|T_IF T_IDENTIFIER T_GOTO T_IDENTIFIER 				{
															if ((nasm_enabled || op_enabled) && !ignore_until_label) {
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
															if ((nasm_enabled || op_enabled) && ignore_until_label) {
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

int main(int argc, char **argv)
{
	for (int i = 0; i < argc; ++i) {
		if (strcmp(argv[i], "--optimize-precomp") == 0 ||
			strcmp(argv[i], "-OP") == 0 ||
			strcmp(argv[i], "-Op") == 0 ||
			strcmp(argv[i], "-oP") == 0 ||
			strcmp(argv[i], "-op") == 0) {
				op_enabled = 1;
			}

		if (strcmp(argv[i], "--gen-nasm") == 0 ||
			strcmp(argv[i], "-nasm") == 0) {
				nasm_enabled = 1;
			}
	}
	opt = fopen("Optimize.txt", "w");
	if(!yyparse())
	{	printf("-----------------------------------------------------------------\n");
		printf("Intermediate Code Optimized\nPlease check Optimize.txt for the Optimized IC");
		printf("\n-----------------------------------------------------------------\n");
	}

	if (op_enabled) {
		FILE* super_opt_file = fopen("super_optimized.txt", "w");

		for (auto iter = print_l.begin(); iter != print_l.end(); ++iter) {
			Precomp_dt data = *iter;
			if (data.type == STRINGVAL) {
				fprintf(super_opt_file, "param %s\ncall (print,1)\n", data.value.str_val);
			} else {
				fprintf(super_opt_file, "param %d\ncall (print,1)\n", data.value.i_val);
			}
		}

		fclose(super_opt_file);
		printf("\n-----------------------------------------------------------------\n");
		printf("Intermediate Code - Super Optimized\nPlease check super_optimized.txt for the Super Optimized IC.");
		printf("\n-----------------------------------------------------------------\n");
	}

	if (nasm_enabled) {
		FILE* nasm_file = fopen("lisp.asm", "w");

		fprintf(nasm_file, "\tglobal main\n\textern puts\n\n\tsection .text\nmain:\n");
		for (int i = 0; i < print_l.size(); ++i) {
			fprintf(nasm_file, "\tmov rdi, message%d\n\tcall puts\n", i);
		}

		fprintf(nasm_file, "\tret\n\tsection .data\n");
		for (int i = 0; i < print_l.size(); ++i) {
			Precomp_dt data = print_l[i];
			if (data.type == INTVAL) {
				fprintf(nasm_file, "message%d: db \"%d\", 0\n", i, data.value.i_val);
			} else {
				fprintf(nasm_file, "message%d: db %s, 0\n", i, data.value.str_val);
			}
		}

		fclose(nasm_file);
		printf("\n-----------------------------------------------------------------\n");
		printf("x86 NASM machine code generated for GNU/Linux\nPlease check lisp.asm for the generated NASM assembly code.");
		printf("\n-----------------------------------------------------------------\n");
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
