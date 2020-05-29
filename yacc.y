%{
	#include<string.h>
	#include<stdio.h>
	#include<stdlib.h>
	#include<ctype.h>
	#include"symbol.h"
	#include"node.h"
	#include"quad.h"

	// -------------------------- General -----------------------------
	int yyerror(char*);
	int yylex();
	extern FILE *yyin;
	
	// ------------------- Used for Symbol Table ----------------------
	int index1=0;
	extern int line_no; 
	extern int ind;
	int getValue(int , int , char*);
	int get_position(char*);
	void print_symbol_table();
	
	// ------------------------- Used for AST -------------------------
	typedef struct node node;
	node* make_node(char *,node *,node *);
	void print_tree_pre(node *);
	void print_tree_in(node *);
	void print_tree_post(node *);
	
	// ------------------------- Used for ICG --------------------------
	/*struct quad
	{
		char op[5];
		char arg1[10];
		char arg2[10];
		char result[10];
		int scope;
		char block[10];
	}QUAD[30];*/
	struct quad QUAD[30];
	
	int number;
	extern int scope_count;
	int Index = 0;
	int rIndex=0; 
	int offset = 0;
	void add_quadruple(char*,char*,char*,char*,int);
	
	// extra implementations
	struct stack 
	{
		char label[10][10];
		int top;
	}stk;
	void push(char *label);	
	void pop();
	char* get_top();
	void eprint(struct quad, char *opr);
	
	// ------------------------- codeopt ----------------
	struct quad QUAD2[30];
	struct table{
		char var[10];
		int val;
		char regval[10];
		int used;
	};
	struct table table[30];
	struct table table2[15];
	int q_ind = 0;
	int t_ind = 0;
	int t_ind2 = 0;
	struct quad QUAD3[30];
	int q3_ind = 0;
	
	int get_result(char*,int,int);
	int get_position2(char*);
	int get_position3(char* string);
	void add_quadruple2(char*,char*,char*,char*);
	void add_table(char*,int,int);
	void add_table2(char*,char*);
	void print_codeopt();
	void print_table();

	void add_quadruple3(char*, char*, char*, char*);
	int split_arg(char*, char*, char*, char*);
	int in_func(char *pattern, char *string);
	void write_quad_opt(char *filename);
	void write_symbol_table(char *filename);
	
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

FOR_UPDATE: RELEXPR ';' ASSIGNMENT { $$ = make_node("STATEMENT",$1,$3); }
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
			index1 = get_position($2);
			strcpy(symbol_table[index1]->type,$1);
			$$ = make_node("Type",make_node($1,NULL,NULL),make_node($2,NULL,NULL));
		}
	 |TYPE VAR '=' EXPR {
	 		index1 = get_position($2);
	 		strcpy(symbol_table[index1]->type,$1);
	 		symbol_table[index1]->value = atoi($4->expr_result);
	 		$$ = make_node("=",make_node("Type",make_node($1,NULL,NULL),make_node($2,NULL,NULL)),$4);
	 		
	 		// ------- ICG ----------
			/*strcpy(QUAD[Index].op,"=");
			strcpy(QUAD[Index].arg1,$4->expr_result);
			strcpy(QUAD[Index].arg2,"");
			strcpy(QUAD[Index].result,$2);
			strcpy(QUAD[Index].block,get_top());
			QUAD[Index++].scope = scope_count;*/
			add_quadruple("=",$4->expr_result,"",$2,0);
	 	}
	 | ASSIGNMENT { $$ = $1; }
	 ;
	 
ASSIGNMENT: VAR '=' EXPR{								
				printf("Inside Assignment\n");
				int index1 = get_position($1);	
				if (index1 != -1) {
					symbol_table[index1]->value = atoi($3->expr_result);
					if(strcmp(symbol_table[index1]->scope,"LOCAL") == 0 && strcmp(symbol_table[index1]->type,"") == 0)
					{
						int indx = getPosition($1);
						strcpy(symbol_table[index1]->type,symbol_table[indx]->type);
					}
				}else{
					printf("Error: variable undeclared\n");
				}
				$$ = make_node("=",make_node($1,NULL,NULL),$3);
				
				// ------- ICG ----------
				add_quadruple("=",$3->reg_name,"",$1,0);	
			}
			;
			
EXPR : EXPR '+' EXPR {  		     		     	
		     	$$ = make_node("+",$1,$3);
		     	sprintf($$->expr_result, "%d",(atoi($1->expr_result) + atoi($3->expr_result)));	
		     	
		     	// ---------------- ICG ------------
		     	add_quadruple("+",$1->reg_name,$3->reg_name,$$->reg_name,1);
		     		
			}
			
     | EXPR '-' EXPR { 
     			$$ = make_node("-",$1,$3);
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) - atoi($3->expr_result)));
     			
     			add_quadruple("-",$1->reg_name,$3->reg_name,$$->reg_name,1);	
     		     }
     | EXPR '*' EXPR { 
     			$$ = make_node("*",$1,$3); 
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) * atoi($3->expr_result)));	
     			
     			add_quadruple("*",$1->reg_name,$3->reg_name,$$->reg_name,1);
     		     }
     | EXPR '/' EXPR { 
     			$$ = make_node("/",$1,$3);
     			sprintf($$->expr_result, "%d",(atoi($1->expr_result) / atoi($3->expr_result)));	
     			
     			add_quadruple("/",$1->reg_name,$3->reg_name,$$->reg_name,1);
     		     }
     
     | VAR	{
     			index1 = get_position($1);    			
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
				printf("Relational exp called\n");
				printf("var: %s\n",$1);
				printf("relop: %s\n",$2);
				printf("reg name: %s\n",$3->reg_name);
				index1 = get_position($1); 				
				$$ = make_node($2,make_node($1,NULL,NULL),$3);
				sprintf($$->expr_result,"%d",(getValue(symbol_table[index1]->value, atoi($3->expr_result), $2)));
				
				//add_quadruple($2,$1,$3->reg_name,$$->reg_name,0);
				add_quadruple($2,$1,$3->reg_name,"",0);
			   }
	   | NUM RELOP RELEXPR {
					$$ = make_node($2, make_node($1, NULL, NULL), $3);
					sprintf($$->expr_result,"%d",(getValue(atoi($1), atoi($3->expr_result), $2)));
					
					//add_quadruple($2,$1,$3->reg_name,$$->reg_name,0);
					add_quadruple($2,$1,$3->reg_name,"",0);
			     }
	   | VAR 	{
	   			index1 = get_position($1);     				
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

int get_position(char* string)
{
    for(int i=0;i<=ind;i++)
	{
		if(strcmp(symbol_table[i]->variable_name,string) == 0 && symbol_table[i]->scope_count == scope_count)
		{
			return i;
		}
	}
	return -1;

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
void add_quadruple(char *op,char *arg1,char *arg2,char *result,int option)
{	 
	strcpy(QUAD[Index].op,op);
	
	strcpy(QUAD[Index].arg1,arg1);
	strcpy(QUAD[Index].arg2,arg2);
	if(option == 0)
	{
		strcpy(QUAD[Index].result,result);
	}
	else
	{
		sprintf(QUAD[Index].result,"r%d",rIndex++);
		strcpy(result,QUAD[Index].result); 
	}	
	strcpy(QUAD[Index].block,get_top());
	QUAD[Index++].scope = scope_count + offset;
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
	int infor = 0;
	
	char temp[10];
	char temp2[10];
	
	
	for(int i=0; i<Index; i++)
	{
		// statements in same scope or within blocks
		if(i != 0 && QUAD[i].scope >= QUAD[i-1].scope){
			if(strcmp(QUAD[i].block,"main") == 0)
			{
				eprint(QUAD[i], "");
			}
			if(strcmp(QUAD[i].block,"if") == 0)
			{
				if(QUAD[i-1].scope != QUAD[i].scope)
				{
					label_stk[++ltop] = label_no;
					sprintf(temp,"%s%s%s",QUAD[i].arg1,QUAD[i].op,QUAD[i].arg2);
					sprintf(temp2,"L%d",label_no);
					add_quadruple2("if",temp,"",temp2);
					printf("if(!(%s%s%s)) goto L%d\n",QUAD[i].arg1,QUAD[i].op,QUAD[i].arg2,label_no++);
				}
				else
				{	
					eprint(QUAD[i], "");	
				}
			}
			if(strcmp(QUAD[i].block,"else") == 0)
			{
				if(estart == 1)
				{
					sprintf(temp,"L%d",label_stk[ltop]+1);
					add_quadruple2("goto","","",temp);
					printf("goto L%d\n",label_stk[ltop]+1);
					
					sprintf(temp,"L%d",label_stk[ltop]);
					add_quadruple2("L","","",temp);
					printf("L%d:\n",label_stk[ltop]);
					
					label_stk[ltop]++;
					estart = 0;
				}
				eprint(QUAD[i], "");
			}
			if(strcmp(QUAD[i].block,"while") == 0)
			{
				if(QUAD[i-1].scope != QUAD[i].scope)
				{
					sprintf(temp,"L%d",label_no);
					add_quadruple2("L","","",temp);
					
					printf("L%d:\n if(!(%s%s%s)) goto L%d\n",label_no++,QUAD[i].arg1,QUAD[i].op,QUAD[i].arg2,label_no);
					sprintf(temp,"%s%s%s",QUAD[i].arg1,QUAD[i].op,QUAD[i].arg2);
					sprintf(temp2,"L%d",label_no);
					add_quadruple2("if",temp,"",temp2);
					label_stk[++ltop] = label_no;
					label_no++;
				}
				else
				{
					eprint(QUAD[i], "while");
				}
			}
			if(strcmp(QUAD[i].block,"for") == 0)
			{
				if(QUAD[i-1].scope != QUAD[i].scope || infor)
				{
					if(fstates == 0)
					{
						if(strcmp(QUAD[i].result,"r") < 47){
							fstates++;
						}
						eprint(QUAD[i], "");
						infor = 1;
					}
					else if(fstates == 1)
					{
						sprintf(temp,"L%d",label_no);
						add_quadruple2("L","","",temp);
						
						printf("L%d:\n if(!(%s%s%s)) goto L%d\n",label_no++,QUAD[i].arg1,QUAD[i].op,QUAD[i].arg2,label_no);
						sprintf(temp,"%s%s%s",QUAD[i].arg1,QUAD[i].op,QUAD[i].arg2);
						sprintf(temp2,"L%d",label_no);
						add_quadruple2("if",temp,"",temp2);
						label_stk[++ltop] = label_no;
						label_no++;
						fstates++;
					}
					else if(fstates == 2)
					{
						fsteps[++ftop].start_index = i;
						fsteps[ftop].step = 1; 
						if(strcmp(QUAD[i].result,"r") < 47)
						{
							fstates = 0;
							infor = 0;
						}
						else{
							fstates++;
						}
					}
					else if(fstates > 2)
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
					eprint(QUAD[i], "");
				}
			}
		} // if they come out of block
		else
		{
			if(i == 0) 
			{ 
				add_quadruple2("L","","",QUAD[i].block);
				printf("%s:\n",QUAD[i].block);
				//in_block[++top] = 0;
			}
			else
			{
				if(strcmp(QUAD[i-1].block,"while") == 0) 
				{
					sprintf(temp,"L%d",label_stk[ltop]-1);
					add_quadruple2("goto","","",temp);
					printf("goto L%d\n",label_stk[ltop]-1);
				}
				if(strcmp(QUAD[i-1].block,"for") == 0)
				{
					int sind = fsteps[ftop].start_index;
					int steps = fsteps[ftop].step;
					for(int k=sind;k<sind+steps;k++)
					{
						eprint(QUAD[k], "for");
					}
					ftop--;
					sprintf(temp,"L%d",label_stk[ltop]-1);
					add_quadruple2("goto","","",temp);
					printf("goto L%d\n",label_stk[ltop]-1);
					
				}
				sprintf(temp,"L%d",label_stk[ltop]);
				add_quadruple2("L","","",temp);
				printf("L%d:\n",label_stk[ltop--]);
			}
			eprint(QUAD[i], "");
			estart = 1;
		}
		
	}
	
	printf("\n\n");	

}

void eprint(struct quad quad, char *opr)
{
	int res;
	char temp[10];
	
	if(strcmp(quad.op,"=") == 0)
	{
		printf("%s %s %s\n", quad.result,quad.op,quad.arg1);
		int iindex;
		// --------- codeopt ---------
		if(isdigit(quad.arg1[0]))
		{
			res = atoi(quad.arg1);
			//printf("Inside isdigit for var=%d\n",res);
			add_quadruple2("",quad.arg1,"",quad.result);
			iindex = get_position2(quad.result);
			if(iindex >= 0)
			{	
				table[iindex].val = res;
				table[iindex].used = 1;
			} else{
				//printf("Adding table entry\n");
				add_table(quad.result,res,1);
				//print_table();
			}
		} else{
			iindex = get_position2(quad.arg1);
			if(iindex >= 0)
			{
				res = table[iindex].val;
				sprintf(temp,"%d",res);
				add_quadruple2("",temp,"",quad.result);
			} else{
				add_quadruple2("",quad.arg1,"",quad.result);
			}
		}
		
		
		return;
	}
	printf("%s %s %s %s %s\n",quad.result, "=", quad.arg1, quad.op, quad.arg2);
	
	// ------ codeopt ---------
	
	int arg1,arg2;	
	int iindex1;
	int iindex2;
	if(isdigit(quad.arg1[0]) && isdigit(quad.arg2[0]))
	{
		res = get_result(quad.op,atoi(quad.arg1),atoi(quad.arg2));
		sprintf(temp,"%d",res);
		add_quadruple2("",temp,"",quad.result);
		iindex1 = get_position2(quad.result);
		if(iindex1 >= 0)
		{
			table[iindex1].val = res;
			table[iindex1].used = 1;
		} else{
			add_table(quad.result,res,1);
		}
	} else{
		if(isdigit(quad.arg1[0]))
		{
			//printf("Inside isdigit arg1\n");
			iindex1 = get_position2(quad.arg2);
			arg2 = table[iindex1].val;
			table[iindex1].used = 0;
			sprintf(temp,"%d",arg2);
			add_quadruple2(quad.op,quad.arg1,temp,quad.result);
		} else if(isdigit(quad.arg2[0])){
			//printf("Inside isdigit arg2\n");
			iindex1 = get_position2(quad.arg1);
			//printf("Index is %d\n",iindex1);
			arg1 = table[iindex1].val;
			table[iindex1].used = 0;
			sprintf(temp,"%d",arg1);
			add_quadruple2(quad.op,temp,quad.arg2,quad.result);
		} else{
			iindex1 = get_position2(quad.arg1);
			iindex2 = get_position2(quad.arg2);
			if(iindex1 >= 0 && iindex2 >= 0)
			{
				arg1 = table[iindex1].val;
				arg2 = table[iindex2].val;
				table[iindex1].used = 0;
				table[iindex2].used = 0;
				sprintf(temp,"%d",arg1);
				char temp2[10];
				sprintf(temp2,"%d",arg2);
				add_quadruple2(quad.op,temp,temp2,quad.result);
			} else{
				if(iindex1 >= 0)
				{
					arg1 = table[iindex1].val;
					table[iindex1].used = 0;
					sprintf(temp,"%d",arg1);
					add_quadruple2(quad.op,temp,quad.arg2,quad.result);
				} else if(iindex2 >= 0)
				{
					arg2 = table[iindex2].val;
					table[iindex2].used = 0;
					sprintf(temp,"%d",arg2);
					add_quadruple2(quad.op,quad.arg1,temp,quad.result);
				} else{
					add_quadruple2(quad.op,quad.arg1,quad.arg2,quad.result);
				}
			}
			
		}
	}
	
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

// ---------------- Code Opt ------------------

int get_result(char *op, int arg1, int arg2)
{
	if(strcmp(op,"+") == 0)
	{
		return arg1 + arg2;
	} else if(strcmp(op,"-") == 0)
	{
		return arg1 - arg2;
	} else if(strcmp(op,"*") == 0)
	{
		return arg1 * arg2;
	} else if(strcmp(op,"/") == 0)
	{
		return arg1 / arg2;
	}
}

void add_quadruple2(char *op, char* arg1, char* arg2, char* result)
{
	char temp[10];	
	if(strcmp(result,"r") >= 47 && strlen(op) != 0)
	{
		sprintf(temp,"%s%s%s",arg1,op,arg2);
		strcpy(QUAD2[q_ind].arg1,temp);
		strcpy(QUAD2[q_ind].arg2,"");
		strcpy(QUAD2[q_ind].op,"");
	} else{
		strcpy(QUAD2[q_ind].op,op);
		strcpy(QUAD2[q_ind].arg1,arg1);
		strcpy(QUAD2[q_ind].arg2,arg2);
	}
	strcpy(QUAD2[q_ind++].result,result);
}

void add_quadruple3(char *op, char *arg1, char *arg2, char *result)
{
	strcpy(QUAD3[q3_ind].op, op);
	strcpy(QUAD3[q3_ind].arg1, arg1);
	strcpy(QUAD3[q3_ind].arg2, arg2);
	strcpy(QUAD3[q3_ind].result, result);
	q3_ind++;
}

void add_table(char *var, int val, int used)
{
	strcpy(table[t_ind].var,var);
	table[t_ind].val = val;
	table[t_ind++].used = used;
}

void add_table2(char *var, char* args)
{
	strcpy(table2[t_ind2].var,var);
	strcpy(table2[t_ind2++].regval,args);
}

int get_position2(char* string)
{
    for(int i=0;i<=t_ind;i++)
	{
		if(strcmp(table[i].var,string) == 0)
		{
			return i;
		}
	}
	return -1;

}

int get_position3(char* string)
{
    for(int i=0;i<=t_ind2;i++)
	{
		if(strcmp(table2[i].var,string) == 0)
		{
			return i;
		}
	}
	return -1;

}

int in_func(char *pattern, char *string)
{
	int m = strlen(pattern);
	int n = strlen(string);
    for (int i = 0; i <= n - m; i++) { 
        int j;   
        for (j = 0; j < m; j++) 
            if (string[i + j] != pattern[j]) 
                break; 
  
        if (j == m) return 1; 
            //printf("Pattern found at index %d \n", i); 
    }
	return 0;
}

int split_arg(char *exp, char *arg1, char *arg2, char *op)
{
	char *token;
	if(in_func("<=", exp)) strcpy(op, "<=");
	else if(in_func(">=", exp)) strcpy(op, ">=");
	else if(in_func(">", exp)) strcpy(op, ">");
	else if(in_func("<", exp)) strcpy(op, "<");
	else if(in_func("==", exp)) strcpy(op, "==");
	else if(in_func("!=", exp)) strcpy(op, "!=");
	else if(in_func("+", exp)) strcpy(op, "+");
	else if(in_func("-", exp)) strcpy(op, "-");
	else if(in_func("*", exp)) strcpy(op, "*");
	else if(in_func("/", exp)) strcpy(op, "/");
	else strcpy(op, "");
	token = strtok(exp, op);
	strcpy(arg1, token);
	token = strtok(NULL, op);
	if(token != NULL) strcpy(arg2, token);
	if(strcmp(op, "") == 0)
	{
		return 0;
	}
	return 1;
}

void print_codeopt()
{
	char temp[10];
	char arg1[10],arg2[10], op[10];
	printf("\t\t\t\t Quadruples \t\t\t\t\n");
	printf("\n\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t","pos","op","arg1","arg2","result");
	printf("\n\t------------------------------------------------------------------------");
	for(int i=0;i<q_ind;i++)
	{
		printf("\n\t%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t", i,QUAD2[i].op, QUAD2[i].arg1,QUAD2[i].arg2,QUAD2[i].result);
	}
	printf("\n\n\n\n");
	printf("\t\t\t\t Optimized Code \t\t\t\t\n");
	for(int i=0;i<q_ind;i++)
	{
		if(strcmp(QUAD2[i].op,"L") == 0)
		{
			printf("%s:\n",QUAD2[i].result);
			add_quadruple3("LABEL", "","",QUAD2[i].result);
		} else if(strcmp(QUAD2[i].op,"goto") == 0){
			printf("%s %s\n",QUAD2[i].op,QUAD2[i].result);
			add_quadruple3("goto", "", "", QUAD2[i].result);
		} else if(strcmp(QUAD2[i].op,"if") == 0){
			printf("%s(!(%s)) goto %s\n",QUAD2[i].op,QUAD2[i].arg1,QUAD2[i].result);
			split_arg(QUAD2[i].arg1, arg1, arg2, op);
			sprintf(temp, "r%d", rIndex++);
			add_quadruple3(op, arg1, arg2, temp);
			add_quadruple3("ifFalse", temp, "", QUAD2[i].result);
		} else{
			if(strcmp(QUAD2[i].result,"r") >= 47)
			{
				sprintf(temp,"%s%s%s",QUAD2[i].arg1,QUAD2[i].op,QUAD2[i].arg2);
				add_table2(QUAD2[i].result,temp);
				//printf("Added register %s in new table\n",QUAD2[i].result);
			} else{
				strcpy(arg1,QUAD2[i].arg1);
				strcpy(arg2,QUAD2[i].arg2);
				if(strcmp(arg1,"r") >= 47)
				{
					int iindex = get_position3(arg1);
					strcpy(arg1,table2[iindex].regval);
				}
				if(strcmp(arg2,"r") >= 47)
				{
					int iindex = get_position3(arg2);
					strcpy(arg2,table2[iindex].regval);
				}
				printf("%s = %s %s %s\n",QUAD2[i].result,arg1,QUAD2[i].op,arg2);
				if (split_arg(arg1, temp, arg2, op)) 
				{
					add_quadruple3(op, temp, arg2, QUAD2[i].result);
				}
				else add_quadruple3("=", arg1, "", QUAD2[i].result); 
			}
			
		}
	}	
	printf("\n\n\n\n");
	printf("Eliminated intermediate variables\n");
	for(int i=0;i<t_ind2;i++){
		printf("%s = %s\n",table2[i].var,table2[i].regval);
	}
}

void write_quad_opt(char *filename)
{
	FILE *fp;
	fp = fopen(filename, "w+");
	if(fp == NULL)
	{
		fprintf(stderr, "Error opening file");
	}
	fprintf(fp, "op|arg1|arg2|res\n");
	for(int i = 0; i<q3_ind; i++)
	{
		fprintf(fp, "%s|%s|%s|%s\n",QUAD3[i].op, QUAD3[i].arg1, QUAD3[i].arg2, QUAD3[i].result);
	}
	fclose(fp);
}

void write_symbol_table(char *filename)
{
	FILE *fp;
	fp = fopen(filename, "w+");
	if(fp == NULL)
	{
		fprintf(stderr, "Error opening file");
	}
	fprintf(fp, "name:scope:type:value\n");
	for (int i = 0; i <= ind; i++) 
	{
		if (strcmp(symbol_table[i]->variable_name,"") != 0)
		{
			if(strcmp(symbol_table[i]->scope,"LOCAL") != 0)
			{
				fprintf(fp, "%s:id:%s:%d\n", symbol_table[i]->variable_name, symbol_table[i]->type, symbol_table[i]->value);
			}
		}
			//printf("\n\t\t%s\t|\t%d\t|\t%s\t|\t%s\t", symbol_table[i]->variable_name, symbol_table[i]->value, symbol_table[i]->type,symbol_table[i]->scope);
	}
}

void print_table()
{
	printf("\t\t\t\t Symbol Table \t\t\t\t\n");
	printf("\n\t%s\t|\t%s\t|\t%s\t","Varibale Name","Value","Used");
	printf("\n\t-----------------------------------------------------------------------");	
	for (int i = 0; i <= t_ind; i++) 
	{
		if (strcmp(symbol_table[i]->variable_name,"") != 0)
			printf("\n\t\t%s\t|\t%d\t|\t%d\t", table[i].var, table[i].val, table[i].used);
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
		print_codeopt();
		if(argc == 3 || argc == 4) write_quad_opt(argv[2]);
		else write_quad_opt("opt.txt");
		if(argc == 4) write_symbol_table(argv[3]);
		else write_symbol_table("st.txt");
	}
	//printf("Error of parse: %d",a);
	return 0;
}

