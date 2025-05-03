%{
#include "tema.tab.h"
#include "table.h" 
#include <vector>
extern int yylineno;
%}

%option noyywrap
%option yylineno

%%

"//".*                             { /* comentarii pe o linie */ }
"/*"([^*]|\*+[^*/])*\*+"/"         { /* comentarii pe mai multe linii */ }
[ \t\n]+                { /* ignora spatii */ }
"=" { return '='; }
"==" { return EQ; }
"%" { return '%';}
"&&" {return AND;}
"||" {return OR;}
"!" {return NOT;}
"-" { return '-'; }
"+" {return '+';}
"/" {return '/';}
">="                    { return GEQ; }
"<="                    { return LEQ; }
"!="                    { return NEQ; }
"."                     {return '.';}
"int"                   { return INT; }
"float"                 { return FLOAT; }
"char"                  { return CHAR; }
"string"                { return STRING; }
"bool"                  { return BOOL; }
"true"                  { return TRUE; }
"false"                 { return FALSE; }
"class"                 { return CLASS; }
"main"                  { return MAIN; }
"if"                    { return IF; }
"else"                  { return ELSE; }
"while"                 { return WHILE; }
"for"                   { return FOR; }
"print"                 { return PRINT; }
"["                     { return '['; }
"]"                     { return ']'; }
"typeof"                { return TYPEOF; }
"return"                { return RETURN; }
"this"                  { return THIS; }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.sval = strdup(yytext); return ID; }
[0-9]+"."[0-9]+         { yylval.fval = atof(yytext); return FLOAT_VAL; }
-?[1-9][0-9]*|0 {
    yylval.ival = atoi(yytext);  
    return INT_VAL;              
}
\"([^\\\"]|\\.)*\"  { yylval.sval = strdup(yytext); return STRING_VAL; }


\'[^\']\'   { yylval.cval = yytext[1]; return CHAR_VAL; }
.                       { return yytext[0]; }

\n  { yylineno++; }
%%
int main(int argc, char **argv) {
    globalSymTable = new SymTable("global");
    currentSymTable = globalSymTable;

    ++argv; 
    --argc;
    if (argc > 0)
        yyin = fopen(argv[0], "r");
    else
        yyin = stdin;

    yyparse();  

    if (globalSymTable) {
        globalSymTable->printTableToFile("symbol_tables.txt");

    }

    return 0;
}
