%{
  #include <ctype.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <limits.h>

  #define MAX_VARIABLE 10000
  #define MAX_CODELINE 10000
  #define MAX_VAR_NAME 1000
  #define MAX_CODE_LENGTH 1000
  #define MAX_PRINT_LENGTH 1000


  extern int yylex();
  extern int yyparse();
  extern FILE* yyin;
  void yyerror(char* const s);

  typedef enum { type_rem, type_goto, type_let, type_let_dim, type_dim, type_print, type_input, type_if, type_while } type;
  typedef enum { op_uminus, op_not, op_plus, op_minus, op_multi, op_divide, op_mod, op_equal, op_left, op_right, op_left_equal, op_right_equal, op_left_right } op_type;
  typedef enum { ast_int, ast_var, ast_op } ast_type;

  typedef struct{
    char name[MAX_VAR_NAME];
    int *value;
    int size;
    struct ast_node *node;
  } var;

  typedef struct ast_node{
    ast_type at;
    op_type ot;
    var variable;
    int value;
    struct ast_node *left;
    struct ast_node *right;
  } ast_node;

  typedef struct{
    int next;
  } goto_node;

  typedef struct{
    int value;
    char str[MAX_PRINT_LENGTH];
    ast_node *node;
  } print_node;

  typedef struct{
    char name[MAX_VAR_NAME];
    ast_node *node1;
    ast_node *node2;  
  } let_node;

  typedef struct{
    char name[MAX_VAR_NAME];
    ast_node *node;
  } dim_node;

  typedef struct{
    char name[MAX_VAR_NAME];
  } input_node;

  typedef struct{
    ast_node *node;
    int next;
  } if_node;
  
  typedef struct{
    ast_node *node;
    int end; 
  } while_node;

  typedef struct{
    char str[MAX_CODE_LENGTH];
    type t;
    int line;

    goto_node gn;
    print_node pn;
    let_node ln;
    dim_node dn;
    input_node in;
    if_node ifn;
    while_node wn;
  } triple;

  
  triple codes[MAX_CODELINE];    
  var table[MAX_VARIABLE];
  int total_idx = 0;
  int var_idx = 0;

  void sort(){
    int i=0, j=0;
    triple temp;
    for(i=0; i<total_idx-1; i++){
      for(j=0; j<total_idx-i-1; j++){
        if( codes[j].line > codes[j+1].line ){
          memcpy(&temp, &codes[j+1], sizeof(triple));
          memcpy(&codes[j+1], &codes[j], sizeof(triple));
          memcpy(&codes[j], &temp, sizeof(triple));
        }
      } 
    }
  }

  int check_variable_name(char *name){
    int i=0;
    for(i=0; i<var_idx; i++){
      if( strcmp(table[i].name, name) == 0 ) return i;
    }
    return -1;
  }

  int traval(ast_node *tree){
    int left=0, right=0, temp=0, value=0;
    
    if( tree->at == ast_int ) {
      return tree->value;
    } else if( tree->at == ast_var ) {
      temp=check_variable_name(tree->variable.name);
      if( temp > -1 ){
        if( table[temp].size > 0 ){
          value = traval(tree->variable.node);
          if( value >= table[temp].size ){
            fprintf(stderr, "Array out of index : %s, size: %d, index : %d\n", table[temp].name, table[temp].size, value);
            exit(1);
          }
          return table[temp].value[value];
        } else {
          return table[temp].value[0];
        }
      } else {
        fprintf(stderr, "No declaration variable : %s\n", tree->variable.name); 
        exit(1);
      }
    } else if( tree->at == ast_op ){
      switch(tree->ot){
        case op_uminus      : return -1 * traval(tree->left); break;
        case op_not         : return !traval(tree->left); break;
        case op_plus        : {
          left = traval(tree->left);
          right = traval(tree->right);
          if ((left >= 0 && right >= 0 && left + right < 0) ||
              (left <= 0 && right <= 0 && left + right > 0)) {
            fprintf(stderr, "Integer Overflow error \n");
            exit(1);
          }
          return left + right;
          break;
        }
        case op_minus       : {
          left = traval(tree->left);
          right = traval(tree->right);
          if ((left >= 0 && right <= 0 && left - right < 0) ||
              (left <= 0 && right >= 0 && left - right > 0)) {
            fprintf(stderr, "Integer Overflow error \n");
            exit(1);
          }
          return left - right;
          break;
        }
        case op_multi       : {
          left = traval(tree->left);
          right = traval(tree->right);
          if (right != 0 && left > INT_MAX / right) {
            fprintf(stderr, "Integer Overflow error \n");
            exit(1);
          }
          return traval(tree->left) * traval(tree->right);
          break;
        }
        case op_divide      : {
          right = traval(tree->right);
          if( right == 0 ){
            fprintf(stderr, "Integer Overflow error \n");
            exit(1);
          }
          return traval(tree->left) / right;
          break;
        }
        case op_mod         : {
          right = traval(tree->right);
          if( right == 0 ){
            fprintf(stderr, "Fault Error : Divide by zero\n");
            exit(1);
          }
          return traval(tree->left) % traval(tree->right);
          break;
        }
        case op_equal       : return traval(tree->left) == traval(tree->right); break;
        case op_left        : return traval(tree->left) < traval(tree->right); break;
        case op_right       : return traval(tree->left) > traval(tree->right); break;
        case op_left_equal  : return traval(tree->left) <= traval(tree->right); break;
        case op_right_equal : return traval(tree->left) >= traval(tree->right); break;
        case op_left_right  : return traval(tree->left) != traval(tree->right); break;
        default : return 0;
      }
    }
    return 0;
  }

  int execute(triple L){
    int i=0;
    int temp=0;
    int input = 0;
    int array_idx = -1;
    int array_size = 0;
    switch(L.t){
      case type_rem: 
        return INT_MAX;
        break;
      case type_goto:
        return L.gn.next;
        break;
      case type_let:
        if( (temp=check_variable_name(L.ln.name)) == -1 ){
          strcpy(table[var_idx].name, L.ln.name);
          temp = var_idx;
          var_idx++;
          table[temp].value = (int *) malloc(sizeof(int));
        }
        table[temp].value[0] = traval(L.ln.node1);
        table[temp].size = 0;
        return INT_MAX;
        break;
      case type_let_dim:
        if( (temp=check_variable_name(L.ln.name)) == -1 ){
          fprintf(stderr, "Undefined array variable : %s\n", L.ln.name);
          exit(1);
          return -1;
        }
        array_idx = traval(L.ln.node2);
        if( table[temp].size <= array_idx || 0 > array_idx){
          fprintf(stderr, "Array out of index : %s, size: %d, index : %d\n", L.ln.name, table[temp].size, array_idx);
          exit(1);
          return -1;
        }
        table[temp].value[array_idx] = traval(L.ln.node1);
        return INT_MAX;
        break;
      case type_dim:
        array_size = traval(L.dn.node);
        if( array_size < 1 ){
          fprintf(stderr, "Array size more than 1\n");
          exit(1);
          return -1;
        }
        if( (temp=check_variable_name(L.dn.name)) == -1 ){
          strcpy(table[var_idx].name, L.dn.name);
          temp = var_idx;
          var_idx++;
        }
        table[temp].value = (int *) malloc(sizeof(int) * array_size);
        table[temp].size = array_size;
        for(i=0; i<array_size; i++){
          table[temp].value[i] = 0;
        }
        
        return INT_MAX;
        break;
      case type_print:
        if( L.pn.node == NULL ){
          printf("%s\n", L.pn.str);
        } else {
          printf("%d\n", traval(L.pn.node));
        }
        return INT_MAX;
        break;
      case type_input:
        scanf("%d", &input);
        if( (temp=check_variable_name(L.in.name)) == -1 ){
          strcpy(table[var_idx].name, L.in.name);
          temp = var_idx;
          var_idx++;
          table[temp].value = (int *) malloc(sizeof(int));
        }
        table[temp].value[0] = input; 
        table[temp].size = 0;
        return INT_MAX;
        break;
      case type_if:
        if( traval(L.ifn.node) ){
          return L.ifn.next;
        }
        return INT_MAX;
        break;
      case type_while:
        if( traval(L.wn.node) ){
          return INT_MAX;
        }
        return L.wn.end;
        break;
    }
    return 0;
  }

  ast_node * new_ast_node(ast_type at, op_type ot, ast_node * left, ast_node * right, int value, char * name){
    ast_node * new_node =  (ast_node *) malloc (sizeof(ast_node));
    new_node->at = at;
    switch(at){
      case ast_int :
        new_node->value = value;
        break;
      case ast_var :
        strcpy(new_node->variable.name, name);
        new_node->variable.node = left;
        break;
      case ast_op :
        new_node->ot = ot;
        new_node->left = left;
        new_node->right = right;
        break;
    }
    return (ast_node *) new_node;
  }

  void let(int idx, char *name, ast_node * node1, ast_node * node2){
    strcpy(codes[idx].ln.name, name);
    codes[idx].t = type_let;
    codes[idx].ln.node1 = node1;
    if( node2 != NULL ){
      codes[idx].t = type_let_dim;
      codes[idx].ln.node2 = node2;
    }
  }
  
  void dim(int idx, char *name, ast_node *node){
    codes[idx].t = type_dim;
    strcpy(codes[idx].dn.name, name);
    codes[idx].dn.node = node;    
  }

  void print(int idx, ast_node *node){
    codes[idx].t = type_print;
    codes[idx].pn.node = node;
  }
  
  void input(int idx, char *name){
    codes[idx].t = type_input;
    strcpy(codes[idx].in.name, name);
  }

  void ifnode(int idx, ast_node *node, int next){
    codes[idx].t = type_if;
    codes[idx].ifn.node = node;
    codes[idx].ifn.next = next;
  }

  void whilenode(int idx, ast_node *node, int end){
    codes[idx].t = type_while;
    codes[idx].wn.node = node;
    codes[idx].wn.end = end;
  }

  void list(){
    int i=0;
    sort();
    for(i=0; i<total_idx; i++){
      printf("%s", codes[i].str);
    }  
  }
  
  void check(int line){
    int i=0;
    for(i=0; i<total_idx; i++){
      if(codes[i].line == line){
        printf("%s", codes[i].str);
        return ;
      }
    }  
    printf("There is no line number %d\n", line);
  }

  void quit(){
    printf("Bye...\n");
    exit(0);
  }

  int isnumber(const char*s) {
   char* e = NULL;
   (void) strtol(s, &e, 0);
   return e != NULL && *e == (char)0;
  }
%}

%union{
  int integer;
  char * string;
  struct ast_node * ast;
}

%start Program
%token <integer> T_INT
%token <string> T_VAR T_STRING
%type <ast> Expression
%token T_STRING_LITERAL
%token T_REM T_GOTO T_LET T_DIM T_AS T_PRINT T_INPUT T_IF T_THEN T_WHILE T_EXIT
%token T_RUN T_LIST T_QUIT
%token T_NOT
%token T_PLUS T_MINUS T_MULTI T_DIVIDE T_MOD
%token T_EQUAL T_LEFT T_RIGHT T_LEFT_EQUAL T_RIGHT_EQUAL T_LEFT_RIGHT
%token T_AND T_OR
%token T_OP T_CP
%token T_OS T_CS
%token T_NEWLINE
%left T_NOT
%left T_AND T_OR
%left T_EQUAL T_LEFT T_LEFT_EQUAL T_RIGHT T_RIGHT_EQUAL T_LEFT_RIGHT
%left T_MOD
%left T_PLUS '-'
%left T_MULTI T_DIVIDE
%nonassoc NEG

%%

Program     : Line
            | Line T_NEWLINE     
            | Program Line
            | Program Line T_NEWLINE
            ;
Line        : T_INT Command         { 
                codes[total_idx].line = $1;
                total_idx++; 
              } 
            ;
Command     : T_GOTO T_INT                                        {codes[total_idx].t = type_goto; codes[total_idx].gn.next = $2;}
            | T_LET T_VAR T_EQUAL Expression                      {codes[total_idx].t = type_let; let(total_idx, $2, $4, NULL);}
            | T_LET T_VAR T_OS Expression T_CS T_EQUAL Expression {codes[total_idx].t = type_let; let(total_idx, $2, $7, $4);}
            | T_DIM T_VAR T_AS T_OS Expression T_CS               {codes[total_idx].t = type_dim; dim(total_idx, $2, $5);}
            | T_PRINT Expression                                  {codes[total_idx].t = type_print; print(total_idx, $2);}
            | T_PRINT T_STRING                                    {codes[total_idx].t = type_print; strcpy(codes[total_idx].pn.str, $2);}
            | T_INPUT T_VAR                                       {codes[total_idx].t = type_input; input(total_idx, $2);}
            | T_IF Expression T_THEN T_INT                        {codes[total_idx].t = type_if; ifnode(total_idx, $2, $4);}
            | T_WHILE Expression T_EXIT T_INT                       {codes[total_idx].t = type_while; whilenode(total_idx, $2, $4);} 
            | T_REM                                               {}
            ;
Expression  : T_INT                                 { $$ = new_ast_node(ast_int, -1, NULL, NULL, $1, NULL); }
            | T_VAR                                 { $$ = new_ast_node(ast_var, -1, NULL, NULL, -1, $1); }
            | T_VAR T_OS Expression T_CS            { $$ = new_ast_node(ast_var, -1, $3, NULL, -1, $1); }
            | '-' Expression %prec NEG              { $$ = new_ast_node(ast_op, op_uminus, $2, NULL, -1, NULL); }
            | T_NOT Expression                      { $$ = new_ast_node(ast_op, op_not, $2, NULL, -1, NULL); }
            | Expression T_PLUS Expression          { $$ = new_ast_node(ast_op, op_plus, $1, $3, -1, NULL); }
            | Expression '-' Expression             { $$ = new_ast_node(ast_op, op_minus, $1, $3, -1, NULL); }
            | Expression T_MULTI Expression         { $$ = new_ast_node(ast_op, op_multi, $1, $3, -1, NULL); }
            | Expression T_DIVIDE Expression        { $$ = new_ast_node(ast_op, op_divide, $1, $3, -1, NULL); }
            | Expression T_MOD Expression           { $$ = new_ast_node(ast_op, op_mod, $1, $3, -1, NULL); }
            | Expression T_EQUAL Expression         { $$ = new_ast_node(ast_op, op_equal, $1, $3, -1, NULL);  }
            | Expression T_LEFT Expression          { $$ = new_ast_node(ast_op, op_left, $1, $3, -1, NULL); }
            | Expression T_RIGHT Expression         { $$ = new_ast_node(ast_op, op_right, $1, $3, -1, NULL); }
            | Expression T_LEFT_EQUAL Expression    { $$ = new_ast_node(ast_op, op_left_equal, $1, $3, -1, NULL);  }
            | Expression T_RIGHT_EQUAL Expression   { $$ = new_ast_node(ast_op, op_right_equal, $1, $3, -1, NULL);  }
            | Expression T_LEFT_RIGHT Expression    { $$ = new_ast_node(ast_op, op_left_right, $1, $3, -1, NULL);  }
            | T_OP Expression T_CP                  { $$ = $2; }
            ;

%%

int main(int argc, char *argv[]) {
  FILE *fp;
  char command[5];
  int i=0, j=0, next = 0, is_while = 0, while_end = 0, while_idx = 0;

  if( argc < 2 ){
    fprintf(stderr, "Useage : ./basic <Basic File Name>\n");
    exit(1);
  }
  fp = fopen(argv[1], "r");
  if(fp == NULL) exit(EXIT_FAILURE);

  while(!feof(fp)){
    fgets(codes[total_idx].str, 1000, fp);
    total_idx++;
  }
  fclose(fp);

  total_idx = 0;
  yyin = fopen(argv[1], "r");

  while(!feof(yyin)){
    yyparse();
  }
  fclose(yyin);

  do{
    scanf("%s", command);
    if( strcmp(command, "LIST") == 0 ){
      list();
    }
    else if( strcmp(command, "RUN") == 0 ){
      i = 0;
      while(1){
        if( i == total_idx ) break;
        if( codes[i].t == type_while ){
          is_while = 1;
          while_end = codes[i].wn.end;
          while_idx = i;
        }
        next = execute(codes[i]);
        if( next <= 0 ) {
          break;
        } else if( next == INT_MAX ) {
          i++;
          if( is_while == 1 && codes[i].line >= while_end ){
            i = while_idx;
          }
        } else {
          for(j=0; j<total_idx; j++){
            if(codes[j].line == next){
              i = j;
              break;
            }
          }
          if( codes[i].line >= while_end ){
            is_while = 0;
            while_end = 0;
            while_idx = 0;
          }
        }
      }
    }
    else if( strcmp(command, "QUIT") == 0 ){
      quit();
    }
    else if( isnumber(command) ){
      check(atoi(command));
    }
  }while(1);
  
  return 0;
}

void yyerror(char* const s) {
  fprintf(stderr, "Parse error: %s\n", s);
  exit(1);
}
