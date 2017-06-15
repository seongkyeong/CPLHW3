%{
  #include <ctype.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>

  extern int yylex();
  extern int yyparse();
  extern FILE* yyin;
  void yyerror(const char* s);

  typedef enum { type_rem, type_goto, type_let, type_dim,  type_print, type_input, type_if } type;

  typedef struct{
    char name[1000];
    int value;
    int dim;
  } var;

  typedef struct{
    int next;
  } gt;

  typedef struct{
    char str[1000];
    type t;
    int line;
  } triple;

  triple codes[10000];    
  int total_idx = 0;

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

  void run(){
  }
  
  void list(){
    int i=0;
    sort();
    for(i=0; i<total_idx; i++){
      printf("%s", codes[i].str);
    }  
  }

  void quit(){
    printf("Bye...\n");
    exit(0);
  }
%}

%start Phrase
%token T_INT T_VAR T_STRING
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

Phrase      : Program 
            | T_RUN       { run(); } 
            | T_LIST      { list(); }
            | T_QUIT      { quit(); }
            ;
Program     : Line '\n'
            | Line Program '\n'
Line        : T_INT Command         { 
                codes[total_idx].line = $1;
                total_idx++; 
              } 
            ;
Command     : T_GOTO T_INT                                        {codes[total_idx].t = type_goto;}
            | T_LET T_VAR T_EQUAL Expression                      {codes[total_idx].t = type_let;}
            | T_LET T_VAR T_OS Expression T_CS T_EQUAL Expression {codes[total_idx].t = type_let;}
            | T_DIM T_VAR T_AS T_OS Expression T_CS               {codes[total_idx].t = type_dim;}
            | T_PRINT Expression                                  {codes[total_idx].t = type_print;}
            | T_INPUT T_VAR                                       {codes[total_idx].t = type_input;}
            | T_IF Expression T_THEN T_INT                        {codes[total_idx].t = type_if;}
            ;
Expression  : T_INT                                 { $$ = $1; }
            | T_VAR                                 { $$ = (int) $1; }
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
  if(fp == NULL) exit(EXIT_FAILURE);

  while(!feof(fp)){
    //fscanf(fp, "%s\n", codes[total_idx].str);
    fgets(codes[total_idx].str, 1000, fp);
    total_idx++;
  }

  yyin = stdin;
  do { 
    yyparse();
  } while(!feof(yyin));
  return 0;
}
void yyerror(const char* s) {
  fprintf(stderr, "Parse error: %s\n", s);
  exit(1);
}
