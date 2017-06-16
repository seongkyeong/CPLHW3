%option noyywrap
%option nounput
%option noinput
%{
  #include <stdio.h>
  #define YY_DECL int yylex()
  #include "basic.tab.h"

 //extern int yylval;
%}

StringLiteral "\""{StringCharacters}?"\""
StringCharacters {StringCharacter}+
StringCharacter [^\"\\\n\t]

%%

"REM"[^\n]*	{return T_REM;}
"GOTO"		{return T_GOTO;}
"LET"		{return T_LET;}
"DIM"           {return T_DIM;}
"AS"            {return T_AS;}
"PRINT"		{return T_PRINT;}
"INPUT"		{return T_INPUT;}
"IF"		{return T_IF;}
"THEN"		{return T_THEN;}
"WHILE"         {return T_WHILE;}
"EXIT"            {return T_EXIT;}

"RUN"		{return T_RUN;}
"LIST"  	{printf("TEst");return T_LIST;}
"QUIT"	        {return T_QUIT;}

[0-9]+		{yylval.integer = atoi(yytext); return T_INT;}
[[:alnum:]_]+ 	{yylval.string = strdup(yytext); return T_VAR;}

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

"("             {return T_OP;}
")"             {return T_CP;}

"["             {return T_OS;}
"]"             {return T_CS;}

{StringLiteral}    {yylval.string = strdup(yytext); return T_STRING;}
[\n\t]             {return T_NEWLINE;}
.       ;
%%


