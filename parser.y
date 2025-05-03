%{
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <string>
#include "table.h"
#include <variant>

using namespace std;


SymTable *globalSymTable = nullptr;
SymTable *currentSymTable = nullptr;

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int yylineno;
void yyerror(const char *s);
EvalResult evalAST(ASTNode *node);

using EvalResult = variant<int, float, string, char, bool>;

%}
%code requires{
#include "table.h"
#include <vector>
#include <string>
#include <variant>
}
%union {
    int ival;
    float fval;
    char *sval;
    char cval;
    char *type;  
    vector<Parameter>* paramList;
    vector<string>* strList;
    ASTNode* ast; 
}

%token <ival> INT_VAL
%token <fval> FLOAT_VAL
%token <sval> STRING_VAL
%token <cval> CHAR_VAL
%token <sval> TRUE FALSE


%token <sval> ID
%token RETURN
%token IF ELSE FOR WHILE
%token EQ NEQ GEQ LEQ
%token THIS
%token '.' 
%token AND OR NOT
%token INT FLOAT CHAR STRING BOOL CLASS MAIN PRINT TYPEOF

%type <ast> condition 
%type <ast> comparison
%type <ast> artihmetic_op
%type <type> numbers
%type <strList> function_method
%type <paramList> array_declaration
%type <paramList> parameter_list 

%type <sval> type_declaration variable_declaration
%type <sval> basic_declaration object_declaration array_declaration_dynamic

%type <sval>  ID_list

%left '<' '>' GEQ LEQ EQ NEQ
%left '[' ']'
%left '+' '-'
%left '*' '/' '%'
%right '='
%left ';'
%left '.' 
%left OR
%left AND
%right NOT
%precedence ELSE
%precedence IF

%nonassoc '(' ')' 

%%

program: classes_section global_vars_section function_defs_section main_function
        | classes_section main_function
        | classes_section global_vars_section function_defs_section
        | classes_section function_defs_section main_function
        | classes_section global_vars_section main_function
        | main_function
        | classes_section
        | global_vars_section
        | function_defs_section
        | global_vars_section main_function
        | function_defs_section main_function
        | function_defs_section global_vars_section main_function
        | global_vars_section function_defs_section classes_section main_function
        ;

classes_section: class_definition
                | classes_section class_definition
                ;

global_vars_section: global_var_declaration ';'
                    | global_vars_section global_var_declaration ';'
                    ;

function_defs_section: function_definition
                      | function_defs_section function_definition
                      ;

main_function: INT MAIN '(' ')' '{'
              {
                currentSymTable = currentSymTable->createChildScope("function main");
              }
              main_statements 
              '}' 
              {
                  popScope();
                  printf("Main function defined\n");
              }
              ;


class_definition: CLASS ID '{'
                {
                  currentSymTable->addClass(ClassInfo($2));
                  char scopeName[128];
                  sprintf(scopeName, "class %s", $2);
                  currentSymTable = currentSymTable->createChildScope(scopeName);
                }
                class_body 
                '}' ';'
                {
                  popScope();
                }
                ;

class_body: variable_declarations function_defs_section
          | function_defs_section
          | constructor_def
          | variable_declarations
          | variable_declarations constructor_def
          | variable_declarations constructor_def function_defs_section
          | /*empty*/
          ;


constructor_def: constr
               | constructor_def constr
               ;

constr: ID '(' ')' '{' constructor_declarations '}' 
      | ID '(' parameter_list ')' '{' constructor_declarations '}'
      ;

constructor_declarations: assignment_statement ';'
                        | constructor_declarations assignment_statement ';'
                        ;

variable_declarations: variable_declaration ';'
                     | variable_declarations variable_declaration ';'
                     ;

variable_declaration: basic_declaration
                    | array_declaration
                    | array_declaration_dynamic
                    | object_declaration
                    ;


statement: PRINT '(' condition ')' ';'
          {
            ASTNode* ast1 = $3;
            EvalResult result = ASTNode::evalAST($3);

            if (holds_alternative<int>(result)) {
                printf("%d\n", get<int>(result));
            } 
            else if (holds_alternative<float>(result)) {
                printf("%f\n", get<float>(result));
            } 
            else if (holds_alternative<string>(result)) {
                printf("%s\n", get<string>(result).c_str());
            } 
            else if (holds_alternative<char>(result)) {
                printf("%c\n", get<char>(result));
            } 
            else if (holds_alternative<bool>(result)) {
                printf("%s\n", get<bool>(result) ? "true" : "false");
            } 
         }
         | TYPEOF '(' condition ')' ';' 
         {
            ASTNode* ast1 = $3;
            EvalResult result = ASTNode::evalAST($3);
            
           if (holds_alternative<int>(result)) {
                printf("int\n");
            } 
            else if (holds_alternative<float>(result)) {
                printf("float\n");
            } 
            else if (holds_alternative<string>(result)) {
                printf("string\n");
            } 
            else if (holds_alternative<char>(result)) {
                printf("char\n");
            } 
            else if (holds_alternative<bool>(result)) {
                printf("bool\n");
            }
         }
         | control_statement
         | returning
         ;

returning: RETURN to_return ';' 
         | RETURN THIS '.' ID ';'
         ;

to_return: artihmetic_op
          | comparison
          ;

assignment_statement: ID '=' condition 
                    {
                      Variable *var1 = currentSymTable->findVariable($1);
                      ASTNode* ast1 = $3;

                      if (!var1) {
                          cerr << "ERROR: Variabila '" << $1 << "' nu e declarata (Linia " << yylineno << ")\n";  YYERROR;
                      }

                      string exprType = ast1->getDataTypeAsString();

                      if (var1->type != exprType) {
                          cerr << "ERROR: Tipurile nu se potrivesc la asignarea cu'" << $1<< "' (Linia " << yylineno << "): Avem nevoie de '" << var1->type<< "', dar am primit '" << exprType << "'\n"; YYERROR;
                      }

                      EvalResult result = ASTNode::evalAST($3);

                      if (var1->type == "int" && holds_alternative<int>(result)) {
                          var1->value = to_string(get<int>(result));
                      } else if (var1->type == "float" && holds_alternative<float>(result)) {
                          var1->value = to_string(get<float>(result));
                      } else if (var1->type == "string" && holds_alternative<string>(result)) {
                          var1->value = get<string>(result);
                      } else if (var1->type == "bool" && holds_alternative<bool>(result)) {
                          var1->value = get<bool>(result) ? "true" : "false";
                      } else {
                          cerr << "ERROR: Asignare invalida la '" << $1 << "' (Linia " << yylineno << ").\n";  YYERROR;

                      } 
                    }
                    | ID '[' INT_VAL ']' '=' condition
                    {
                      Variable *var1 = currentSymTable->findVariable($1);
                      ASTNode* ast1 = $6;

                      if (!var1) {
                          cerr << "ERROR: Variabila '" << $1 << "' nu e declarata (Linia " << yylineno << ")\n";YYERROR;
                      }

                      string exprType = ast1->getDataTypeAsString();

                      if (var1->type != exprType) {
                          cerr << "ERROR: Tipurile nu se potrivesc la asignarea cu '" << $1<< "' (Linia " << yylineno << "):  Avem nevoie de '" << var1->type<< "', dar am primit'" << exprType << "'\n";YYERROR;
                      }

                      EvalResult result = ASTNode::evalAST($6);

                      if (var1->type == "int" && holds_alternative<int>(result)) {
                          var1->value = to_string(get<int>(result));
                      } else if (var1->type == "float" && holds_alternative<float>(result)) {
                          var1->value = to_string(get<float>(result));
                      } else if (var1->type == "string" && holds_alternative<string>(result)) {
                          var1->value = get<string>(result);
                      } else if (var1->type == "bool" && holds_alternative<bool>(result)) {
                          var1->value = get<bool>(result) ? "true" : "false";
                      } else {
                          cerr << "ERROR: Asignare invalida la '" << $1 << "' (Linia " << yylineno << ").\n";YYERROR;
                      }
                    }
                    | ID '.' ID '=' artihmetic_op
                    {
                      Variable *objVar = currentSymTable->findVariable($1);
                      if (!objVar) {
                          cerr << "ERROR: Obiectul '" << $1 << "' nu e declarat (Linia " << yylineno << ")\n";YYERROR;
                      }

                      ASTNode *ast1 = $5;
                      EvalResult result = ASTNode::evalAST($5);

                      string valueStr;
                      if (holds_alternative<int>(result)) {
                          valueStr = to_string(get<int>(result));
                      } else if (holds_alternative<float>(result)) {
                          valueStr = to_string(get<float>(result));
                      } else if (holds_alternative<char>(result)) {
                          valueStr = string(1, get<char>(result));
                      } else if (holds_alternative<string>(result)) {
                          valueStr = get<string>(result);
                      } else if (holds_alternative<bool>(result)) {
                          valueStr = get<bool>(result) ? "true" : "false";
                      } else {
                          cerr << "ERROR: Asignare invalida la '" << $1 << "." << $3 << "' (Linia " << yylineno << ")\n";YYERROR;
                      }
                    }
                    ;

control_statement: if_statement
                 | while_statement
                 | for_statement
                 ;

if_statement: IF '(' comparison ')' block_statement
            | IF '(' comparison ')' block_statement ELSE block_statement
            ;

block_statement:'{'
               {
                 currentSymTable = currentSymTable->createChildScope("block");
               }
               main_statements
              '}'
               {
                 popScope();
               }
               ;

while_statement: WHILE '(' comparison ')' block_statement
               ;

for_statement: FOR '(' assignment_statement ';' comparison ';' assignment_statement ')' block_statement
             ;

comparison: artihmetic_op EQ artihmetic_op {$$ = ASTNode::buildAST("==", $1, $3, OPERATOR); }
          | artihmetic_op '<' artihmetic_op {$$ = ASTNode::buildAST("<", $1, $3, OPERATOR); }
          | artihmetic_op '>' artihmetic_op {$$ = ASTNode::buildAST(">", $1, $3, OPERATOR);}
          | artihmetic_op GEQ artihmetic_op {$$ = ASTNode::buildAST(">=", $1, $3, OPERATOR);}
          | artihmetic_op LEQ artihmetic_op {$$ = ASTNode::buildAST("<=", $1, $3, OPERATOR);}
          | artihmetic_op NEQ artihmetic_op { $$ = ASTNode::buildAST("!=", $1, $3, OPERATOR); }
          | NOT comparison{$$ = ASTNode::buildAST("!", $2, nullptr , BOOLEAN);}
          | comparison AND comparison {$$ = ASTNode::buildAST("&&", $1, $3, BOOLEAN);}
          | comparison OR comparison {$$ = ASTNode::buildAST("||", $1, $3, BOOLEAN);}
          ;


condition: artihmetic_op
         | comparison
        ;

artihmetic_op: artihmetic_op '+' artihmetic_op {$$ = ASTNode::buildAST("+", $1, $3, OPERATOR);}
              | artihmetic_op '-' artihmetic_op {$$ = ASTNode::buildAST("-", $1, $3, OPERATOR);}
              | artihmetic_op '*' artihmetic_op {$$ = ASTNode::buildAST("*", $1, $3, OPERATOR);}
              | artihmetic_op '/' artihmetic_op {$$ = ASTNode::buildAST("/", $1, $3, OPERATOR);}
              | artihmetic_op '%' artihmetic_op {$$ = ASTNode::buildAST("%", $1, $3, OPERATOR);}
              | ID 
              {
                Variable *var = currentSymTable->findVariable($1);
                if (!var) {
                  cerr << "ERROR: Variabila '" << $1 << "' nu e declarata (Linia " << yylineno << ")\n"; YYERROR;
                }
                $$ = ASTNode::buildAST($1, NULL, NULL, IDENTIFIER);
              }
              | ID '(' function_method ')' 
              {
                vector<string>* params = $3;
                if (currentSymTable->checkFunctionCall($1, *params)){
                    string result = $1 + string("()");
                }
                else {
                    cerr << "ERROR: Functia '" << $1 << "' nu e declarata (Linia " << yylineno << ")\n";YYERROR;
                }
                $$ = ASTNode::buildAST("0", NULL, NULL, NUMBER);
              }
              | ID '[' INT_VAL ']' 
              {
                Variable *var = currentSymTable->findVariable($1);
                if (!var) {
                  cerr << "ERROR: Variabila '" << $1 << "' nu e declarata (Linia " << yylineno << ")\n";YYERROR;
                }
                $$ = ASTNode::buildAST("0", NULL, NULL, NUMBER);
              }
              | STRING_VAL {$$ = ASTNode::buildAST($1, nullptr, nullptr, OTHER);}
              | CHAR_VAL {$$ = ASTNode::buildAST("'" + string(1, $1) + "'", nullptr, nullptr, OTHER);}
              | INT_VAL {$$ = ASTNode::buildAST(to_string($1), nullptr, nullptr, NUMBER);}
              | FLOAT_VAL {$$ = ASTNode::buildAST(to_string($1), nullptr, nullptr, NUMBER);}
              | TRUE {$$ = ASTNode::buildAST("true", nullptr, nullptr, BOOLEAN);}
              | FALSE {$$ = ASTNode::buildAST("false", nullptr, nullptr, BOOLEAN);}
              | ID '.' ID {
                Variable *objVar = currentSymTable->findVariable($1);
                if (!objVar) {
                    cerr << "ERROR: Obiectul '" << $1 << "' nu e declarat (Linia " << yylineno << ")\n";YYERROR;
                }
                $$ = ASTNode::buildAST("0", NULL, NULL, NUMBER);
              }
              | ID '.' ID '(' INT_VAL ')' {
                Variable *objVar = currentSymTable->findVariable($1);
                if (!objVar) {
                  cerr << "ERROR: Obiectul '" << $1 << "' nu e declarat (Linia " << yylineno << ")\n";YYERROR;
                }
                $$ = ASTNode::buildAST("0", NULL, NULL, NUMBER);
              }
              ;

function_method: ID 
              {
                $$ = new vector<string>();
                $$->push_back($1);
              }
              | ID ',' function_method 
              {
                $$ = $3;
                $$->insert($$->begin(), $1);
              }
              | numbers {
                $$ = new vector<string>();
                $$->push_back($1);
              }
              | numbers ',' function_method 
              {
                $$ = $3;
                $$->insert($$->begin(), $1);
              }
              ;


global_var_declaration: type_declaration ID 
                      {
                        currentSymTable->declareVar($1, $2, "");
                      }
                      | type_declaration ID '=' condition 
                      { 
                        currentSymTable->declareVar($1, $2, "");
                        Variable *var1 = currentSymTable->findVariable($2);
                        ASTNode* ast1 = $4;

                        if (!var1) {
                          cerr << "ERROR: Variabila '" << $2 << "' nu e declarata (Linia " << yylineno << ")\n";YYERROR;
                        }

                        string exprType = ast1->getDataTypeAsString();

                        if (var1->type != exprType) {
                          cerr << "ERROR: Tipurile nu se potrivesc la asignarea cu  '" << $2<< "' (Linia " << yylineno << "): Avem nevoie de '" << var1->type<< "', dar avem '" << exprType << "'\n";YYERROR;
                        }

                        EvalResult result = ASTNode::evalAST($4);

                        if (var1->type == "int" && holds_alternative<int>(result)) {
                            var1->value = to_string(get<int>(result));
                        } else if (var1->type == "float" && holds_alternative<float>(result)) {
                            var1->value = to_string(get<float>(result));
                        } else if (var1->type == "string" && holds_alternative<string>(result)) {
                            var1->value = get<string>(result);
                        } else if (var1->type == "char" && holds_alternative<char>(result)) {
                            var1->value = string(1, get<char>(result)); 
                        } else if (var1->type == "bool" && holds_alternative<bool>(result)) {
                            var1->value = get<bool>(result) ? "true" : "false";
                        } else {
                            cerr << "ERROR: Asignare invalida la '" << $2 << "' (Linia " << yylineno << ")\n";YYERROR;
                        }
                      }  
                      | type_declaration ID ',' ID_list 
                      {
                        currentSymTable->declareVar($1, $2, ""); 
                        char* p = strtok($4, ",");  
                        while (p != NULL) {
                          currentSymTable->declareVar($1, p, "");
                          p = strtok(NULL, ",");
                        }
                      }
                      | array_declaration
                      | array_declaration_dynamic
                      | object_declaration
                      ;

function_definition: type_declaration ID '(' parameter_list ')'  
                  {
                    Function func($2, $1, *$4, currentSymTable->scopeName);
                    currentSymTable->addFunction(func);

                    pushScope("function_" + string($2));
                    for (const auto &param : *$4) {
                          currentSymTable->declareNotVar(param.type, param.name);
                    }
                  }
                  '{' main_statements '}' 
                  {
                    popScope();
                  }
                  | type_declaration ID '(' ')' '{'
                    {
                      currentSymTable->addFunction(Function($2, $1, {}));
                      char scopeName[128];
                      sprintf(scopeName, "function %s", $2);
                      currentSymTable = currentSymTable->createChildScope(scopeName);
                    }
                    main_statements'}' 
                    {
                      popScope();
                    }
                    ;

parameter_list: type_declaration ID 
              {
                $$ = new vector<Parameter>();
                $$->emplace_back(Parameter($2, $1));
              }
              | parameter_list ',' type_declaration ID {
                  $1->emplace_back(Parameter($4, $3));  
                  $$ = $1;
              }
              | array_declaration
              ;



main_statements: main_statement
                | main_statements main_statement
                ;

main_statement: variable_declaration ';'
              | assignment_statement ';'
              | statement
              ;

ID_list: ID {$$ = strdup($1); }
        | ID_list ',' ID 
        {
              char* temp = (char*)malloc(strlen($1) + strlen($3) + 2);
              sprintf(temp, "%s,%s", $1, $3); 
              $$ = temp;
        }
        ;


basic_declaration: type_declaration ID 
                  {
                     currentSymTable->declareVar($1, $2, "");
                  }
                  | type_declaration ID '=' condition 
                  {
                    currentSymTable->declareVar($1, $2, "");

                    Variable *var1 = currentSymTable->findVariable($2);
                    ASTNode* ast1 = $4;

                    if (!var1) {
                        cerr << "ERROR: Variabila '" << $2 << "' nu e declarata (Linia " << yylineno << ")\n";YYERROR;
                    }

                    string exprType = ast1->getDataTypeAsString();

                    if (var1->type != exprType) {
                        cerr << "ERROR: Tipurile nu se potrivesc la asignarea cu '" << $2<< "' (Linia " << yylineno << "): Avem nevoie de '" << var1->type<< "', dar avem '" << exprType << "'\n";YYERROR;
                      }

                      EvalResult result = ASTNode::evalAST($4);

                      if (var1->type == "int" && holds_alternative<int>(result)) {
                          var1->value = to_string(get<int>(result));
                      } else if (var1->type == "float" && holds_alternative<float>(result)) {
                          var1->value = to_string(get<float>(result));
                      } else if (var1->type == "string" && holds_alternative<string>(result)) {
                          var1->value = get<string>(result);
                      } else if (var1->type == "bool" && holds_alternative<bool>(result)) {
                          var1->value = get<bool>(result) ? "true" : "false";
                      } else {
                          cerr << "ERROR: Asignare invalida la '" << $2 << "' (Linia " << yylineno << ")\n";YYERROR;
                      }
                  }

                  | type_declaration ID ',' ID_list {
                        currentSymTable->declareVar($1, $2, ""); 
                        char* p = strtok($4, ",");  
                        while (p != NULL) {
                          currentSymTable->declareVar($1, p, "");
                          p = strtok(NULL, ",");
                      }
                  }
                  ;

object_declaration: ID ID 
                  {
                    currentSymTable->declareNotVar($1, $2);
                  }
                  | ID ID '=' ID '(' ')' {
                      currentSymTable->declareNotVar($1, $2);
                  }
                  | ID ID '=' ID '(' function_method ')' {
                      currentSymTable->declareNotVar($1, $2);
                  }
                  ;

array_declaration: type_declaration ID '[' INT_VAL ']' {
                      char arrayType[128];
                      sprintf(arrayType, "%s", $1);  
                      currentSymTable->declareNotVar(arrayType, $2);
                  }
                  | type_declaration ID '[' INT_VAL ']' '=' '{' function_method '}' {
                      char arrayType[128];
                      sprintf(arrayType, "%s", $1);
                      currentSymTable->declareNotVar(arrayType, $2);
                  }
                  ;

array_declaration_dynamic: type_declaration ID '[' ']' {
                              char arrayType[128];
                              sprintf(arrayType, "%s[]", $1);
                              currentSymTable->declareNotVar(arrayType, $2);
                          }
                          | type_declaration ID '[' ']' '=' '{' function_method '}' {
                              char arrayType[128];
                              sprintf(arrayType, "%s[]", $1);
                              currentSymTable->declareNotVar(arrayType, $2);
                          }
                          ;

numbers: INT_VAL {
            char buffer[32];
            sprintf(buffer, "%d", $1);
            $$ = strdup(buffer);
        }
        | FLOAT_VAL {
            char buffer[32];
            sprintf(buffer, "%f", $1);
            $$ = strdup(buffer);
        }
        | STRING_VAL {
            string strVal = "\"";
            strVal += $1;
            strVal += "\"";
            $$ = strdup(strVal.c_str());
        }
        | CHAR_VAL {
            char buffer[4]; 
            sprintf(buffer, "'%c'", $1);
            $$ = strdup(buffer);
        }
        | TRUE {
            $$ = strdup("true");
        }
        | FALSE {
            $$ = strdup("false");
        }
        ;

type_declaration: INT{ $$ = strdup("int"); }
                | FLOAT  { $$ = strdup("float"); }
                | CHAR   { $$ = strdup("char"); }
                | STRING { $$ = strdup("string"); }
                | BOOL   { $$ = strdup("bool"); }
                ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Eroare la linia %d: %s\n", yylineno, s);
}
