%{
	#include<string.h>
	#include<stdio.h>
	#include<stdlib.h>
	#include<ctype.h>
	#include"symbol.h"
	#include"node.h"
	
	// -------------------------- General -----------------------------
	int yyerror(char*);
	int yylex();
	extern FILE *yyin;
	
	// ------------------- Used for Symbol Table ----------------------
	int index1=0;
	extern int line_no; 
	extern int ind;
	int getValue(int , int , char*);
	void print_symbol_table();
	
	// ------------------------- Used for AST -------------------------
	typedef struct node node;
	node* make_node(char *,node *,node *);
	void print_tree_pre(node *);
	void print_tree_in(node *);
	void print_tree_post(node *);
	
	// ------------------------- Used for ICG --------------------------
	struct quad
	{
		char op[5];
		char arg1[10];
		char arg2[10];
		char result[10];
		int scope;
	}QUAD[30];
	
	int number;
	char label[10];
	extern int scope_count;
	int Index = 0;
	int rIndex=0; 
	void add_quadruple(char *op,char *arg1,char *arg2,char *result);
	
	/*struct stack 
	{
		int items[100];
		int top;
	}stk;*/
	
	//int StNo;
	//int Ind; 
	//int tInd;
	//int checkIndex = 0;
	
	
	//char* toString(int number);
	//void AddQuadruple(char op[5],char arg1[10],char arg2[10],char result[10]);
	
	//int checkSymbolTable(char *);
	
	//void label();
	
	//int globalIndex = 0;
	//int labelCount = 0;
	
%}
%union
{
	struct node *np;
	char var[10];
	//struct token *symbol_table[100];
}


%token <var> NUM VAR RELOP MAIN TYPE HEADER
%token WHILE IF ELSE FOR
%type <np> EXPR ASSIGNMENT RELEXPR PROGRAM Main STATEMENT CODE BLOCK VARASSIGN
%left '-' '+'
%left '*' '/'

%%
START: HEADERFILE Main
	|;
HEADERFILE: HEADER HEADERFILE {printf("Header file completed\n");}
	|;
Main : TYPE MAIN { strcpy(label,"main"); } '(' ')' '{' PROGRAM '}' {
						$$ = make_node("PROGRAM", make_node($1, NULL, NULL), $7);
						printf("\nPreorder Traversal \n"); 
						print_tree_pre($$);
						printf("\nInorder Traversal \n"); 
						print_tree_in($$); 
						printf("\nPostorder Traversal \n");
						print_tree_post($$);
					 };
PROGRAM : CODE { $$ = $1;}
;
BLOCK : '{' CODE '}' { $$ = $2; };
;
CODE : BLOCK { $$ = $1; }
     | STATEMENT CODE { $$ = make_node("STATEMENT",$1,$2); }
     | STATEMENT { $$ = $1; }
     ;
STATEMENT: VARASSIGN ';' { $$ = $1; }
	| WHILE { strcpy(label,"while"); } '(' RELEXPR ')' BLOCK { $$ = make_node("while",$4,$6); }  
	| IF { strcpy(label,"if"); } '(' RELEXPR ')' BLOCK { $$ = make_node("if",$4,$6); }
	| ERROR { $$ = NULL; }
	| error ';' { $$ = NULL; }
	;

ERROR: NUM {printf("Error at line: %d\n",line_no);}
        | VAR {printf("Error at line: %d\n",line_no);}
        ;

VARASSIGN: TYPE VAR {
			printf("Inside VARASSIGN\n");
			//print_symbols();
			//printf("$2 = %s\n",$2);
			index1 = getPosition($2);
			//printf("Index1 = %d\n",index1);
			strcpy(symbol_table[index1]->type,$1);
			$$ = make_node("Type",make_node($1,NULL,NULL),make_node($2,NULL,NULL));
		}
	 |TYPE VAR '=' EXPR {
	 		index1 = getPosition($2);
	 		strcpy(symbol_table[index1]->type,$1);
	 		symbol_table[index1]->value = atoi($4->expr_result);
	 		$$ = make_node("=",make_node("Type",make_node($1,NULL,NULL),make_node($2,NULL,NULL)),$4);
	 		
	 		// ------- ICG ----------
			strcpy(QUAD[Index].op,"=");
			strcpy(QUAD[Index].arg1,$4->expr_result);
			strcpy(QUAD[Index].arg2,"");
			strcpy(QUAD[Index].result,$2);
			QUAD[Index++].scope = scope_count;
	 	}
	 | ASSIGNMENT { $$ = $1; }
	 ;
ASSIGNMENT: VAR '=' EXPR{								
				printf("Inside Assignment\n");
				int index1 = getPosition($1);	
				if (index1 != -1) {
					symbol_table[index1]->value = atoi($3->expr_result);
				}else{
					printf("Error: variable undeclared\n");
				}
				$$ = make_node("=",make_node($1,NULL,NULL),$3);
				
				// ------- ICG ----------
				strcpy(QUAD[Index].op,"=");
				strcpy(QUAD[Index].arg1,$3->reg_name);
				strcpy(QUAD[Index].arg2,"");
				strcpy(QUAD[Index].result,$1);
				QUAD[Index++].scope = scope_count;		
			}
			;
EXPR : EXPR '+' EXPR { /*if(isdigit($1[0]) && isdigit($3[0])) {
				strcpy($$, itoa(atoi($1) + atoi($3))); //AddQuadruple("+",$1,$3,$$);
		    	}else{ 
			index = getPosition($3);			
			if(index != -1) {
				strcpy($$, itoa(atoi($1) + symbol_table[index].value)); 
				//AddQuadruple("+",$1,$3,$$);			
			} else {
				index = getPosition($1);
				strcpy($$, itoa(symbol_table[index].value + atoi($3))); 
				AddQuadruple("+",$1,$3,$$);		
			}				
			
		     }*/	//char temp[25];	     	
		     		     	
		     	$$ = make_node("+",$1,$3);
		     	sprintf($$->expr_result, "%d",(atoi($1->expr_result) + atoi($3->expr_result)));	
		     	
		     	// ---------------- ICG ------------
		     	add_quadruple("+",$1->reg_name,$3->reg_name,$$->reg_name);
		     		
			}
			
     | EXPR '-' EXPR { 
     			//sprintf($$,"%d",(atoi($1) - atoi($3)));
     			$$ = make_node("-",$1,$3);
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) - atoi($3->expr_result)));
     			
     			add_quadruple("-",$1->reg_name,$3->reg_name,$$->reg_name);	
     		     }
     | EXPR '*' EXPR { 
     			//sprintf($$,"%d",(atoi($1) * atoi($3)));
     			$$ = make_node("*",$1,$3); 
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) * atoi($3->expr_result)));	
     			
     			add_quadruple("*",$1->reg_name,$3->reg_name,$$->reg_name);
     		     }
     | EXPR '/' EXPR { 
     			//sprintf($$,"%d",(atoi($1) / atoi($3))); 
     			$$ = make_node("/",$1,$3);
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) / atoi($3->expr_result)));	
     			
     			add_quadruple("/",$1->reg_name,$3->reg_name,$$->reg_name);
     		     }
     
     | VAR	{
     			index1 = getPosition($1);
     			//sprintf($$,"%d",(symbol_table[index1]->value));     			
     			$$ = make_node($1,NULL,NULL);
     			sprintf($$->expr_result,"%d",(symbol_table[index1]->value));
     			
     			//sprintf($$->reg_name,"%d",symbol_table[index1]->value);
     			strcpy($$->reg_name,$1);
     		}
     | NUM      {
                        //printf("Inside Num\n");
                        $$ = make_node($1,NULL,NULL);
                        //sprintf($$->expr_result,"%d",atoi($1));
                        strcpy($$->expr_result,$1);
                        
                        strcpy($$->reg_name,$1);
                }
     ;

RELEXPR: VAR RELOP RELEXPR {
				index1 = getPosition($1); 
				/*if (isdigit($3[0])) {
					strcpy($$, itoa(getValue(symbol_table[index]->value, atoi($3), $2))); 
				} else {
					int index2 = getPosition($3);
					strcpy($$, itoa(getValue(symbol_table[index]->value, symbol_table[index2]->value, $2))); 
				}*/				
				$$ = make_node($2,make_node($1,NULL,NULL),$3);
				sprintf($$->expr_result,"%d",(getValue(symbol_table[index1]->value, atoi($3->expr_result), $2)));
				
				add_quadruple($2,$3->reg_name,$1,$$->reg_name);
			   }
	   | NUM RELOP RELEXPR { 	/*if (isdigit($3[0])) {
						strcpy($$, itoa(getValue(atoi($1), atoi($3), $2))); 
					} else {
						index = getPosition($3);
						strcpy($$, itoa(getValue(atoi($1), symbol_table[index]->value, $2))); 
					}*/					
					$$ = make_node($2, make_node($1, NULL, NULL), $3);
					sprintf($$->expr_result,"%d",(getValue(atoi($1), atoi($3->expr_result), $2)));
					
					add_quadruple($2,$3->reg_name,$1,$$->reg_name);
			     }
	   | VAR 	{
	   			index1 = getPosition($1);     				
     				$$ = make_node($1, NULL, NULL);
     				sprintf($$->expr_result,"%d",(symbol_table[index1]->value));
     				
     				//sprintf($$->reg_name,"%d",symbol_table[index1]->value);
     				strcpy($$->reg_name,$1);
	   		}
	   | NUM	{
	   			$$ = make_node($1, NULL, NULL);
	   			//sprintf($$->expr_result,"%d",(symbol_table[index1]->value));
	   			strcpy($$->expr_result,$1);
	   			
	   			strcpy($$->reg_name,$1);
	   		}
	   ;

%%

// ----------------- Symbol Table ----------------------
int getValue(int value1, int value2, char* operator){
	if(strcmp(operator, ">") == 0) 
		return value1 > value2;
	else if(strcmp(operator, "<") == 0) 
		return value1 < value2;
	else if(strcmp(operator, ">=") == 0) 
		return value1 >= value2;
	else if(strcmp(operator, "<=") == 0)
		return value1 <= value2;
	else if(strcmp(operator, "==") == 0)
		return value1 == value2;		
	else 
		return value1 != value2;	
}

void print_symbol_table()
{
	printf("\t\t\t\t Symbol Table \t\t\t\t\n");
	printf("\n\t%s\t|\t%s\t|\t%s\t|\t%s\t","Varibale Name","Value","Type","Scope");
	printf("\n\t-----------------------------------------------------------------------");	
	for (int i = 0; i <= ind; i++) 
	{
		if (strcmp(symbol_table[i]->variable_name,"") != 0)
			printf("\n\t\t%s\t|\t%d\t|\t%s\t|\t%s\t", symbol_table[i]->variable_name, symbol_table[i]->value, symbol_table[i]->type,symbol_table[i]->scope);
	}
	printf("\n\n");	
}

// ---------------- AST -----------------------------
node *make_node(char *value, node *left, node *right) 
{
	node *new_node = malloc(sizeof(node));
	strcpy(new_node->value, value);	
	new_node -> left = left;
	new_node -> right = right;
	return new_node;
}

void print_tree_pre(node *root)
{
	if (root == NULL)
		return;
	printf("%s ", root->value);
	print_tree_pre(root->left);	
	print_tree_pre(root->right);	
}

void print_tree_in(node *root)
{
	if (root == NULL)
		return;
	print_tree_in(root->left);
	printf("%s ", root->value);
	print_tree_in(root->right);
}

void print_tree_post(node *root)
{
	if (root == NULL)
		return;
	print_tree_post(root->left);	
	print_tree_post(root->right);
	printf("%s ", root->value);
}

// ----------------------------- ICG -------------------------------------
void add_quadruple(char *op,char *arg1,char *arg2,char *result)
{	 
	strcpy(QUAD[Index].op,op);
	strcpy(QUAD[Index].arg1,arg1);
	strcpy(QUAD[Index].arg2,arg2);
	sprintf(QUAD[Index].result,"r%d",rIndex++);
	strcpy(result,QUAD[Index].result); 
	QUAD[Index++].scope = scope_count;
}

void print_3addr_code()
{
	printf("\t\t\t\t Quadruples \t\t\t\t\n");
	printf("\n\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t","pos","op","arg1","arg2","result");
	printf("\n\t------------------------------------------------------------------------");
	for(int i=0;i<Index;i++)
	{
		printf("\n\t%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t", i,QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2,QUAD[i].result);
	}
	printf("\n\n\n\n");
	int scope[10] = {-1};
	int scopeIndex = 0;
	int gotoLabel = 0;
	for(int i=0;i<Index;i++)
	{	
		if (gotoLabel == 1) {
			//scopeIndex[scopeIndex] = QUAD[i].scope;			
			printf("L%d:\n",gotoLabel);
			gotoLabel = 0; 		
		}
		if(strcmp(QUAD[i].op,"=") == 0) {	
			if (i == Index - 1 && strcmp(label, "while") == 0)	
				printf("%s %s %s %s %s goto L%d \n",QUAD[i].result, "=", QUAD[i].arg1, QUAD[i].op, QUAD[i].arg2, gotoLabel);
			else 
				printf("%s %s %s %s\n",QUAD[i].result, QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2);
			//printf("%s %s %s %s\n",QUAD[i].result, QUAD[i].op, QUAD[i].arg1,QUAD[i].arg2);
		} else if (strcmp(QUAD[i].op,">") == 0 || strcmp(QUAD[i].op,"!=") == 0) {
			gotoLabel = 1;
			printf("L%d: %s %s %s %s %s goto L%d \n",QUAD[i].scope,QUAD[i].result, "=", QUAD[i].arg1, QUAD[i].op, QUAD[i].arg2, QUAD[i].scope+1);
		} else {
			printf("%s %s %s %s %s\n",QUAD[i].result, "=", QUAD[i].arg1, QUAD[i].op, QUAD[i].arg2);	
		}
	}
	printf("\n\n");

}

// ---------------- GENERAL -------------------
int yyerror(char *string)
{
	printf("\n Error on line no:%d\n",line_no);
	fprintf(stderr,"%s\n",string);
	yyparse();
	//return 0;
}

int main(int argc,char *argv[])
{
	int i;
	int a;
	if(argc > 1)
	{
		FILE *fp = fopen(argv[1], "r");
		if(fp)
		{
		    yyin = fp;
		}			
	}
	if(yyin==NULL)
	{
	     fprintf(stderr,"%s\n","Unable to open file\n");
	     return 0;
	}
	if(!(a = yyparse())) {
		printf("\nResult of parse: %d\n",a);
		print_symbol_table();
		print_3addr_code();

	}
	//printf("Error of parse: %d",a);
	return 0;
}

