
ption noyywrap
%{
#include <stdio.h>
#define YY_DECL int yylex()
#include "basic.tab.h"
%}
%%
[ \t]	; // ignore all whitespace
[alpha]+ 	{yylval.sval = yytext; return variable;}
[0-9]+		{yylval.ival = atoi(yytext); return integer;}
\n		{return T_NEWLINE;}

"REM"		{return T_REM;}
"GOTO"		{return T_GOTO;}
"LET"		{return T_LET;}
"PRINT"		{return T_PRINT;}
"INPUT"	{return T_INPUT;}
"IF"		{return T_IF;}
"THEN"		{return T_THEN;}

"RUN"		{return T_RUN;}
"LIST"		{return T_LIST;}
"QUIT"		{return T_END;}

"!"		{return T_NOT;}

"+"		{return T_PLUS;}
"-"		{return T_MINUS;}
"*"		{return T_MULTI;}
"/"		{return T_DIVIDE;}
"%"		{return T_MOD;}

"="		{return T_EQUAL;}
"<"		{return T_LEFT;}
">"		{return T_RIGHT;}
"<="		{return T_LEFT_EQUAL;}
">="		{return T_RIGHT_EQUAL;}
"<>"		{return T_LEFT_RIGHT;}

"&"		{return T_AND;}
"|"		{return T_OR;}
%%


