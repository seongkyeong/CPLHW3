%{
  #include <ctype.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  #define MAX_VARIABLE 10000
  #define MAX_CODELINE 10000
  #define MAX_VAR_NAME 1000
  #define MAX_CODE_LENGTH 1000
  #define MAX_PRINT_LENGTH 1000


  extern int yylex();
  extern int yyparse();
  extern FILE* yyin;
  void yyerror(char* const s);

  typedef enum { type_rem, type_goto, type_let, type_dim,  type_print, type_input, type_if } type;

  typedef struct{
    char name[MAX_VAR_NAME];
    int value;
  } var;

  typedef struct{
    int next;
  } goto_node;

  typedef struct{
    int value;
    char str[MAX_PRINT_LENGTH];
  } print_node;

  typedef struct{
    char str[MAX_CODE_LENGTH];
    type t;
    int line;

    goto_node gt;
    print_node pt;
  } triple;

  typedef struct{
    int type;
    var variable;
    ast_node *left;
    ast_node *right;
  } ast_node;

  

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

  int execute(triple L){
    int input = 0;
    switch(L.t){
      case type_goto:
        return L.gt.next;
        break;
      case type_let:
        break;
      case type_dim:
        break;
      case type_print:
        break;
      case type_input:
        scanf("%d", &input);
        
        break;
      case type_if:
        break;
    }
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

%start Program
%token T_INT T_VAR T_STRING_LITERAL T_STRING
%token T_REM T_GOTO T_LET T_DIM T_AS T_PRINT T_INPUT T_IF T_THEN
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
%left T_PLUS T_MINUS
%left T_MULTI T_DIVIDE
%left T_UMINUS
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
Command     : T_GOTO T_INT                                        {codes[total_idx].t = type_goto; codes[total_idx].gt.next = $2;}
            | T_LET T_VAR T_EQUAL Expression                      {codes[total_idx].t = type_let; let($2, $4, 0);}
            | T_LET T_VAR T_OS Expression T_CS T_EQUAL Expression {codes[total_idx].t = type_let; let($2, $7, $4);}
            | T_DIM T_VAR T_AS T_OS Expression T_CS               {codes[total_idx].t = type_dim; dim($2, $5);}
            | T_PRINT Expression                                  {codes[total_idx].t = type_print; print(}
            | T_PRINT T_STRING                                    {codes[total_idx].t = type_print; strcpy(codes[total_idx].pt.str, $2);}
            | T_INPUT T_VAR                                       {codes[total_idx].t = type_input;}
            | T_IF Expression T_THEN T_INT                        {codes[total_idx].t = type_if;}
            | T_REM                                               {}
            ;
Expression  : T_INT                                 { $$ = $1; }
            | T_VAR                                 { $$ = $1; }
            | '-' Expression %prec NEG              { $$ = -$2; }
            | T_NOT Expression                      { $$ = !$2; }
            | Expression T_PLUS Expression          { $$ = $1 + $3; }
            | Expression T_MINUS Expression         { $$ = $1 - $3; }
            | Expression T_MULTI Expression         { $$ = $1 * $3; }
            | Expression T_MOD Expression           { $$ = $1 % $3; }
            | Expression T_EQUAL Expression         { $$ = $1 == $3; }
            | Expression T_LEFT Expression          { $$ = $1 < $3; }
            | Expression T_RIGHT Expression         { $$ = $1 > $3; }
            | Expression T_LEFT_EQUAL Expression    { $$ = $1 <= $3; }
            | Expression T_RIGHT_EQUAL Expression   { $$ = $1 >= $3; }
            | Expression T_LEFT_RIGHT Expression    { $$ = $1 != $3; }
            | T_OP Expression T_CP                  { $$ = $2; }
            ;

%%

int main(int argc, char *argv[]) {
  FILE *fp = fopen("src.txt", "r");
  char command[5];
  if(fp == NULL) exit(EXIT_FAILURE);

  while(!feof(fp)){
    fgets(codes[total_idx].str, 1000, fp);
    total_idx++;
  }
  fclose(fp);

  total_idx = 0;
  yyin = fopen("src.txt", "r");

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
      run();
    }
    else if( strcmp(command, "QUIT") == 0 ){
      quit();
    }
    else if( isnumber(command) ){
      check(atoi(command));
    }
  }while(!feof(stdin));
  
  return 0;
}

void yyerror(char* const s) {
  fprintf(stderr, "Parse error: %s\n", s);
  exit(1);
}
