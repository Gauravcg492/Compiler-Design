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
		char block[10];
	}QUAD[30];
	
	int number;
	extern int scope_count;
	int Index = 0;
	int rIndex=0; 
	int offset = 0;
	void add_quadruple(char *op,char *arg1,char *arg2,char *result);
	
	// extra implementations
	struct stack 
	{
		char label[10][10];
		int top;
	}stk;
	void push(char *label);	
	void pop();
	char* get_top();
	void eprint(struct quad);
	
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
}


%token <var> NUM VAR RELOP MAIN TYPE HEADER
%token WHILE IF ELSE FOR
%type <np> EXPR ASSIGNMENT RELEXPR PROGRAM Main STATEMENT STATEMENTS BLOCK VARASSIGN IF_ELSE IFBLOCK FOR_STATEMENTS FOR_UPDATE
%left '-' '+'
%left '*' '/'

%%
START: HEADERFILE Main
	|;
HEADERFILE: HEADER HEADERFILE {printf("Header file completed\n");}
	|;
Main : TYPE MAIN { push("main"); } '(' ')' '{' PROGRAM '}' {
						$$ = make_node("PROGRAM", make_node($1, NULL, NULL), $7);
						printf("\nPreorder Traversal \n"); 
						print_tree_pre($$);
						printf("\nInorder Traversal \n"); 
						print_tree_in($$); 
						printf("\nPostorder Traversal \n");
						print_tree_post($$);
						pop();
					 };
PROGRAM : STATEMENTS { $$ = $1;}
;
BLOCK : '{' STATEMENTS '}' { $$ = $2; };
;
STATEMENTS : BLOCK { $$ = $1; }
	| STATEMENT STATEMENTS { $$ = make_node("STATEMENT",$1,$2); }
	| STATEMENT { $$ = $1; }
	;
STATEMENT: VARASSIGN ';' { $$ = $1; }
	| WHILE { push("while"); offset++; } '(' RELEXPR ')' { offset--; } BLOCK { $$ = make_node("while",$4,$7); pop(); } 
	| IF_ELSE { $$ = $1; }
	| FOR { push("for"); offset++; }'(' FOR_STATEMENTS ')' { offset--; } BLOCK { $$ = make_node("for",$4,$7); pop(); }
	| ERROR { $$ = NULL; }
	| error ';' { $$ = NULL; }
	;

FOR_STATEMENTS: VARASSIGN ';' FOR_UPDATE { $$ = make_node("STATEMENT",$1,$3); }
		;

FOR_UPDATE: RELEXPR ';' EXPR { $$ = make_node("STATEMENT",$1,$3); }
	;

IF_ELSE: IFBLOCK { $$ = $1; }
	| IFBLOCK ELSE { push("else"); } BLOCK { $$ = make_node("IF-ELSE",$1,$4); pop(); }
	;

IFBLOCK: IF { push("if"); offset++; } '(' RELEXPR ')' { offset--; } BLOCK { $$ = make_node("if",$4,$7); pop(); }
	;

ERROR: NUM {printf("Error at line: %d\n",line_no);}
        | VAR {printf("Error at line: %d\n",line_no);}
        ;

VARASSIGN: TYPE VAR {
			index1 = getPosition($2);
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
			strcpy(QUAD[Index].block,get_top());
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
				strcpy(QUAD[Index].block,get_top());
				QUAD[Index++].scope = scope_count;		
			}
			;
			
EXPR : EXPR '+' EXPR {  		     		     	
		     	$$ = make_node("+",$1,$3);
		     	sprintf($$->expr_result, "%d",(atoi($1->expr_result) + atoi($3->expr_result)));	
		     	
		     	// ---------------- ICG ------------
		     	add_quadruple("+",$1->reg_name,$3->reg_name,$$->reg_name);
		     		
			}
			
     | EXPR '-' EXPR { 
     			$$ = make_node("-",$1,$3);
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) - atoi($3->expr_result)));
     			
     			add_quadruple("-",$1->reg_name,$3->reg_name,$$->reg_name);	
     		     }
     | EXPR '*' EXPR { 
     			$$ = make_node("*",$1,$3); 
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) * atoi($3->expr_result)));	
     			
     			add_quadruple("*",$1->reg_name,$3->reg_name,$$->reg_name);
     		     }
     | EXPR '/' EXPR { 
     			$$ = make_node("/",$1,$3);
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) / atoi($3->expr_result)));	
     			
     			add_quadruple("/",$1->reg_name,$3->reg_name,$$->reg_name);
     		     }
     
     | VAR	{
     			index1 = getPosition($1);    			
     			$$ = make_node($1,NULL,NULL);
     			sprintf($$->expr_result,"%d",(symbol_table[index1]->value));
     			
     			strcpy($$->reg_name,$1);
     		}
     | NUM      {
                        //printf("Inside Num\n");
                        $$ = make_node($1,NULL,NULL);
                        strcpy($$->expr_result,$1);
                        
                        strcpy($$->reg_name,$1);
                }
     ;

RELEXPR: VAR RELOP RELEXPR {
				index1 = getPosition($1); 				
				$$ = make_node($2,make_node($1,NULL,NULL),$3);
				sprintf($$->expr_result,"%d",(getValue(symbol_table[index1]->value, atoi($3->expr_result), $2)));
				
				add_quadruple($2,$1,$3->reg_name,$$->reg_name);
			   }
	   | NUM RELOP RELEXPR {
					$$ = make_node($2, make_node($1, NULL, NULL), $3);
					sprintf($$->expr_result,"%d",(getValue(atoi($1), atoi($3->expr_result), $2)));
					
					add_quadruple($2,$1,$3->reg_name,$$->reg_name);
			     }
	   | VAR 	{
	   			index1 = getPosition($1);     				
     				$$ = make_node($1, NULL, NULL);
     				sprintf($$->expr_result,"%d",(symbol_table[index1]->value));
     				
     				strcpy($$->reg_name,$1);
	   		}
	   | NUM	{
	   			$$ = make_node($1, NULL, NULL);
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
	strcpy(QUAD[Index].block,get_top());
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
	/*
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
	printf("\n\n");*/
	
	// printing in proper 3 address code
	int label_no = 1;
	int add_label = 0;
	int label_stk[20];
	int ltop = -1;

	char gotos[20][10];
	int fstates = 0;
	struct fsteps{
		int start_index;
		int step;
	}fsteps[20];
	int ftop = -1;
	int estart = 1;
	
	
	for(int i=0; i<Index; i++)
	{
		// statements in same scope or within blocks
		if(i != 0 && QUAD[i].scope >= QUAD[i-1].scope){
			if(strcmp(QUAD[i].block,"main") == 0)
			{
				//printf("%s %s %s %s %s\n",QUAD[i].result, "=", QUAD[i].arg1, QUAD[i].op, QUAD[i].arg2);
				eprint(QUAD[i]);
			}
			if(strcmp(QUAD[i].block,"if") == 0)
			{
				if(QUAD[i-1].scope != QUAD[i].scope)
				{
					label_stk[++ltop] = label_no;
					//in_block[++itop] = 1;
					printf("if(%s%s%s) goto L%d\n",QUAD[i].arg2,QUAD[i].op,QUAD[i].arg1,label_no++);
				}
				else
				{
					//printf("%s %s %s %s %s\n",QUAD[i].result, "=", QUAD[i].arg1, QUAD[i].op, QUAD[i].arg2);	
					eprint(QUAD[i]);	
				}
			}
			if(strcmp(QUAD[i].block,"else") == 0)
			{
				if(estart == 1)
				{
					printf("goto L%d\n",label_stk[ltop]+1);
					printf("L%d:\n",label_stk[ltop]);
					label_stk[ltop]++;
					estart = 0;
				}
				eprint(QUAD[i]);
			}
			if(strcmp(QUAD[i].block,"while") == 0)
			{
				if(QUAD[i-1].scope != QUAD[i].scope)
				{
					//strcpy(gotos[++gtop],"goto L
					printf("L%d: if(%s%s%s) goto L%d\n",label_no++,QUAD[i].arg2,QUAD[i].op,QUAD[i].arg1,label_no);
					label_stk[++ltop] = label_no;
					label_no++;
				}
				else
				{
					eprint(QUAD[i]);
				}
			}
			if(strcmp(QUAD[i].block,"for") == 0)
			{
				if(QUAD[i-1].scope != QUAD[i].scope)
				{
					if(fstates == 0)
					{
						if(strcmp(QUAD[i].result,"r") < 47){
							fstates++;
						}
						eprint(QUAD[i]);
					}
					if(fstates == 1)
					{
						printf("L%d: if(%s%s%s) goto L%d\n",label_no++,QUAD[i].arg2,QUAD[i].op,QUAD[i].arg1,label_no);
						label_stk[++ltop] = label_no;
						label_no++;
						fstates++;
					}
					if(fstates == 2)
					{
						fsteps[++ftop].start_index = i;
						fsteps[ftop].step = 1; 
						if(strcmp(QUAD[i].result,"r") < 47)
						{
							fstates = 0;
						}
						else{
							fstates++;
						}
					}
					if(fstates > 2)
					{
						fsteps[ftop].step++;
						if(strcmp(QUAD[i].result,"r") < 47)
						{
							fstates = 0;
						}
						else{
							fstates++;
						}
					}
				}
				else
				{
					eprint(QUAD[i]);
				}
			}
		} // if they come out of block
		else
		{
			if(i == 0) 
			{ 
				printf("%s:\n",QUAD[i].block);
				//in_block[++top] = 0;
			}
			else
			{
				if(strcmp(QUAD[i-1].block,"while") == 0) printf("goto L%d\n",label_stk[ltop]-1);
				if(strcmp(QUAD[i-1].block,"for") == 0)
				{
					int sind = fsteps[ftop].start_index;
					int steps = fsteps[ftop].step;
					for(int k=sind;k<sind+steps;k++)
					{
						eprint(QUAD[k]);
					}
					ftop--;
					printf("goto L%d\n",label_stk[ltop]-1);
					
				}
				printf("L%d:\n",label_stk[ltop--]);
			}
			//start = 0;
			//printf("%s %s %s %s %s\n",QUAD[i].result, "=", QUAD[i].arg1, QUAD[i].op, QUAD[i].arg2);
			eprint(QUAD[i]);
			estart = 1;
		}
		
	}
	
	printf("\n\n");	

}

void eprint(struct quad quad)
{
	if(strcmp(quad.op,"=") == 0)
	{
		printf("%s %s %s\n", quad.result,quad.op,quad.arg1);
		return;
	}
	printf("%s %s %s %s %s\n",quad.result, "=", quad.arg1, quad.op, quad.arg2);
}

void push(char *label)
{
	strcpy(stk.label[++stk.top],label);
}

void pop()
{
	stk.top--;
}

char* get_top()
{
	return stk.label[stk.top];
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
	stk.top = 0;
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

