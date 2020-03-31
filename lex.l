%{
    #include<stdio.h>
    #include<string.h>
    #include"symbol.h"
    #include"y.tab.h"
    int scope_count = -1;
    /*struct token {
        char variable_name[10];
        char type;
        int value;
        int line_no;
        int scope_count;
        char scope[10];
    };*/
    struct token *symbol_table[100];
    int ind =-1;
    int type = 0;
    int line_no = 1;
    int getPosition(char *);
    void print_symbols();
%}
identifier [a-zA-Z][_a-zA-Z0-9]*
number [0-9]+|([0-9]*\.[0-9]+)
%%

\/\/(.*)		{}
\/\*(.*\n)*.*\*\/ 	{}
"#include<stdio.h>"     {return HEADER;}
"#include<iostream>"    {return HEADER;} 		 					
"while" {printf("while: %s\n",yytext);;return WHILE;}
"if" {printf("if %s in line %d\n",yytext,line_no);return IF;}
"else" {printf("else %s in line %d\n",yytext,line_no);return ELSE;}
"for" {printf("for %s in line %d\n",yytext,line_no);return FOR;}
"main"	{ printf("main %s in line %d\n",yytext,line_no);strcpy(yylval.var,yytext);return MAIN;}
"int"|"char"|"float" {	type=1; printf("Keyword %s in line %d\n",yytext,line_no);strcpy(yylval.var,yytext);return TYPE;}
{number}+{identifier} {printf("Error %s in line %d\n",yytext,line_no);}
{identifier} {
	    printf("Identifier %s in line %d\n",yytext,line_no);
	    if(type > 0){
        type = 0;
        //int pos = getPosition(yytext);
		/*if(pos < 0)
		{
			symbol_table[++index] = (token*)malloc(sizeof(token));
			strcpy(symbol_table[index].variable_name,yytext);
			symbol_table[index].line_no = line_no;
			symbol_table[index].scope_count = scope_count;
			if(scope_count == 0)
			{
				strcpy(symbol_table[index],"GLOBAL");
			}
			else{
				strcpy(symbol_table[index],"LOCAL");
			}
		}
		else
		{
			
		}*/
		int pos = getPosition(yytext);
		if(pos >= 0){
			if(symbol_table[pos]->scope_count != scope_count)
			{
				ind++;
				symbol_table[ind] = (struct token*)malloc(sizeof(struct token));
				strcpy(symbol_table[ind]->variable_name,yytext);
				symbol_table[ind]->line_no = line_no;
				symbol_table[ind]->scope_count = scope_count;
				if(scope_count == 0)
				{
					strcpy(symbol_table[ind]->scope,"GLOBAL");
				}
				else
				{
					strcpy(symbol_table[ind]->scope,"LOCAL");
				}
			}
		} else{
			ind++;
			symbol_table[ind] = (struct token*)malloc(sizeof(struct token));
			strcpy(symbol_table[ind]->variable_name,yytext);
			symbol_table[ind]->line_no = line_no;
			symbol_table[ind]->scope_count = scope_count;
			if(scope_count == 0)
			{
				strcpy(symbol_table[ind]->scope,"GLOBAL");
			}
			else
			{
				strcpy(symbol_table[ind]->scope,"LOCAL");
			}
		}
    }
    //print_symbols();
    strcpy(yylval.var,yytext);
    return VAR;
}
{number} {printf("Number %s in line %d\n",yytext,line_no);strcpy(yylval.var,yytext);return NUM;}
\<|\>|\>=|\<=|==|!= {printf("Relational Operator %s in line %d\n",yytext,line_no);return RELOP;}
(\+\+)|(--)|(\+)|(-) {printf("Increment Operator %s in line %d\n",yytext,line_no);return *yytext;}
= {printf("Assignment operator %s in line %d\n",yytext,line_no);return '=';}
"{"	{ scope_count++; printf("Opening braces %s in line %d\n",yytext,line_no); return '{';}
"}"	{ scope_count--; printf("Closing braces %s in line %d\n",yytext,line_no);return '}';}
"(" {printf("Opening brackets %s in line %d\n",yytext,line_no); return '(';}
")" {printf("Closing brackets %s in line %d\n",yytext,line_no); return ')';}
[ \t] ;
\n {line_no++;}
; {type=0; printf("SEMI %s in line %d\n",yytext,line_no);return ';';}
. {printf("Error %s in line %d\n",yytext,line_no);return *yytext;}

%%

int getPosition(char* string)
{
    for(int i=0;i<=ind;i++)
	{
		if(strcmp(symbol_table[i]->variable_name,string) == 0)
		{
			return i;
		}
	}
	return -1;

}

void print_symbols()
{
	printf("Symbol Table\n\n\n\n");
	//printf("Value of ind: %d\n",ind); 		
	for(int i=0;i<=ind;i++)
	{
		printf("Varible name: %s\n",symbol_table[i]->variable_name);
		printf("Line no: %d\n",symbol_table[i]->line_no);
		printf("Type: %s\n",symbol_table[i]->type);
		printf("Value: %d\n",symbol_table[i]->value);
		printf("\n\n");
	}
}
/*
int main(int argc, char* argv[])
{
    if(argc > 1)
    {
        FILE *fp = fopen(argv[1], "r");
		if(fp)
        {
            yyin = fp;
        }			
    }
    yylex();
    print_symbols();

    return 1;
}*/
