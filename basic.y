%{
  #include <stdio.h>
  #include <stdlib.h>
  extern int yylex();
  extern int yyparse();
  extern FILE* yyin;
  void yyerror(const char* s);

  int vari; 
%}

%start Phrase
%token T_INT
%token T_VAR
%token T_FLOAT
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
            | T_RUN 
            | T_LIST 
            | T_QUIT
            ;
Program     : Line '\n'
            | Line Program '\n'
Line        : T_INT Command
            ;
Command     : T_GOTO T_INT
            | T_LET T_VAR T_EQUAL Expression
            | T_LET T_VAR T_OS Expression T_CS T_EQUAL Expression
            | T_DIM T_VAR T_AS T_OS Expression T_CS
            | T_PRINT Expression
            | T_INPUT T_VAR
            | T_IF Expression T_THEN T_INT
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

int main() {
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
