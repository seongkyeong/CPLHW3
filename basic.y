%{
  #include <stdio.h>
  #include <stdlib.h>
  extern int yylex();
  extern int yyparse();
  extern FILE* yyin;
  void yyerror(const char* s);
%}

%union {
  int ival;
  char *sval;
}

%start Phrase
%token<ival> integer
%token<sval> variable
%token T_REM T_GOTO T_LET T_PRINT T_INPUT T_IF T_THEN
%token T_RUN T_LIST T_END
%token T_UMINUS T_NOT
%token T_PLUS T_MINUS T_MULTI T_DIVIDE T_MOD
%token T_EQUAL T_LEFT T_RIGHT T_LEFT_EQUAL T_RIGHT_EQUAL T_LEFT_RIGHT
%token T_AND T_OR
%left T_NOT
%left T_AND T_OR
%left T_EQUAL T_LEFT T_LEFT_EQUAL T_RIGHT T_RIGHT_EQUAL T_LEFT_RIGHT
%left T_MOD
%left T_PLUS T_MINUS
%left T_MULTI T_DIVIDE
%right T_EQUAL
%left T_UMINUS
%nonassoc NEG

%%

Phrase      : Program | T_RUN | T_LIST | T_END
            ;
Program     : Line '\n'
            | Line Program '\n'
Line        : integer Command
            ;
Command     : T_GOTO integer
            | T_LET variable T_EQUAL Expression
            | T_PRINT Expression
            | T_INPUT variable
            | T_IF Expression T_THEN integer
            ;
Expression  : integer                               { $$ = $1; }
            | variable                              { $$ = $1; }
            | T_UMINUS Expression %prec NEG         { $$ = -$2; }
            | T_NOT Expression                      { $$ = !$2; }
            | Expression T_PLUS Expression          { $$ = $1 + $3; }
            | Expression T_MINUS Expression         { $$ = $1 - $3; }
            | Expression T_MULTI Expression         { $$ = $1 * $3; }
            | Expression T_DIVIDE Expression        { $$ = $1 / (float)$3; }
            | Expression T_PERCENT Expression       { $$ = $1 % $3; }
            | Expression T_EQUAL Expression         { $$ = $1 == $2; }
            | Expression T_LEFT Expression         
            | Expression T_RIGHT Expression
            | Expression T_LEFT_EQUAL Expression
            | Expression T_RIGHT_EQUAL Expression
            | Expression T_LEFT_RIGHT Expression
            | Expression T_AND Expression
            | Expression T_OR Expression
            | '(' Expression ')'
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
