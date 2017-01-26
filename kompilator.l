%option noyywrap
%option yylineno
%{
#include "kompilator.tab.h" 
int yylex();
%}
%x COMMENT

%%

"{" BEGIN(COMMENT);
<COMMENT>"}" BEGIN(INITIAL);
<COMMENT>. ;

[ \t\r\n]+	{} 
VAR		{return (VAR);}
BEGIN		{return (MYBEGIN);}
WHILE		{return (WHILE);}
DO		{return (DO);}
IF		{return (IF);}
THEN		{return (THEN);}
ELSE		{return (ELSE);}
ENDIF		{return (ENDIF);}
ENDWHILE	{return	(ENDWHILE);}
END		{return (END);}
FOR		{return (FOR);}
FROM		{return (FROM);}
TO		{return (TO);}
DOWNTO		{return (DOWNTO);}
ENDFOR		{return (ENDFOR);}
READ		{return (READ);}
WRITE		{return (WRITE);}

"+"			{return (PLUS);}
"-"			{return (MINUS);}
"/"			{return (DIV);}
"*"			{return (MUL);}
"%"			{return (MOD);}
"["			{return (LBRACKET);}
"]"			{return (RBRACKET);}

"="		{return (EQUAL);}
"<>"		{return (NEQUAL);}
"<"		{return (SMALLER);}
">"		{return (GREATER);}
"<="		{return (LEQUAL);}
">="		{return (GEQUAL);}

":="		{return (ASSIGN);}

[0-9]+		{
                yylval.str = (char *) strdup(yytext);
            	return (NUM);
            }

[_a-z]+		{	yylval.str = (char *) strdup(yytext);
            	return (PIDENTIFIER);}

";"			{return (SEMICOLON) ;}

. ;
\n ;

%%
