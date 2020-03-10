struct token {
        char variable_name[10];
        char type[10];
        int value;
        int line_no;
        int scope_count;
        char scope[10];
};

extern struct token *symbol_table[100];
