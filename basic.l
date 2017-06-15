
%option noyywrap
%{
#include <stdio.h>
#define YY_DECL int yylex()
#include "basic.tab.h"
%}

StringLiteral "\""{StringCharacters}?"\""
StringCharacters {StringCharacter}+
StringCharacter [^\"\\]|{EscapeSequence}
EscapeSequence \\b|\\t|\\n|\\f|\\r|\\\"|\\\'|\\\\

%%

"REM"		{return T_REM;}
"GOTO"		{return T_GOTO;}
"LET"		{return T_LET;}
"DIM"           {return T_DIM;}
"AS"            {return T_AS;}
"PRINT"		{return T_PRINT;}
"INPUT"		{return T_INPUT;}
"IF"		{return T_IF;}
"THEN"		{return T_THEN;}

"RUN"		{return T_RUN;}
"LIST"		{return T_LIST;}
"QUIT"		{return T_QUIT;}

[0-9]+		        {return T_INT;}
[a-zA-Z][a-zA-Z0-9]+ 	{return T_VAR;}

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

{StringLiteral} {return T_STRING;}
[ \t]	; // ignore all whitespace
\n		{return T_NEWLINE;}
.       ;
%%


