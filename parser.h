#ifndef TEST_H
#define TEST_H
#include <iostream>
#include <string>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <regex>
#include <variant>

using EvalResult = std::variant<int, float, std::string, char, bool>;
using namespace std;

int yylex();
int yyparse();
extern FILE *yyin;
extern int yylineno;
void yyerror(const char *s);

enum NodeType
{
    OPERATOR,
    IDENTIFIER,
    NUMBER,
    BOOLEAN,
    OTHER
};
enum DataType
{
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_STRING,
    TYPE_CHAR,
    TYPE_BOOL,
    TYPE_UNKNOWN
};

class Variable
{
public:
    string type;
    string name;
    string value;
    bool isConst;

    Variable(const string &t, const string &n, const string &v, bool c = false)
        : type(t), name(n), value(v), isConst(c) {}
};

class Parameter
{
public:
    string name;
    string type;
    Parameter(const string &n, const string &t) : name(n), type(t) {}
};

class Function
{
public:
    string name;
    string returnType;
    vector<Parameter> parameters;
    string definedIn;

    Function(const string &fnName,const string &retType,const vector<Parameter> &params,const string &className = "")
        : name(fnName),returnType(retType),parameters(params),definedIn(className) {}
};

class ClassInfo
{
public:
    string name;
    ClassInfo(const string &n) : name(n) {}
};

class SymTable
{
public:
    string scopeName;
    SymTable *parentScope;

    vector<Variable> variables;
    vector<Function> functions;
    vector<ClassInfo> classes;
    vector<SymTable *> children;

    SymTable(const string &name, SymTable *parent = nullptr)
        : scopeName(name), parentScope(parent) {}

    SymTable *createChildScope(const string &name)
    {
        SymTable *child = new SymTable(name, this);
        children.push_back(child);
        return child;
    }

    string getType(const string &expr)
    {
        Variable *var = findVariable(expr);
        if (var)
        {
            return var->type;
        }

        if (regex_match(expr, regex("^-?\\d+$")))
        {
            return "int";
        }

        if (regex_match(expr, regex("^-?\\d*\\.\\d+$")))
        {
            return "float";
        }

        if (expr.front() == '"' && expr.back() == '"')
        {
            return "string";
        }

        if (expr == "true" || expr == "false")
        {

            return "bool";
        }

        smatch match;
        if (regex_match(expr, match, regex("(.+)\\s*([+\\-*/])\\s*(.+)")))
        {
            string leftExpr = match[1];
            string rightExpr = match[3];

            string leftType = getType(leftExpr);
            string rightType = getType(rightExpr);

            if (leftType == rightType)
            {
                return leftType;
            }
            else
            {
                return "unknown";
            }
        }

        return "unknown";
    }

    void declareVar(const string &type, const string &varName, const string &initialValue = "", bool isConst = false)
    {
        for (auto &v : variables)
        {
            if (v.name == varName)
            {
                cerr << "ERROR: Variabila '" << varName << "' este deja declarata in scope-ul '" << scopeName << "' (Linia " << yylineno << ")\n";
                return;
            }
        }

        variables.push_back(Variable(type, varName, initialValue, isConst));
    }

    void declareNotVar(const string &type, const string &varName, const string &initialValue = "", bool isConst = false)
    {
        for (auto &v : variables)
        {
            if (v.name == varName)
            {
                cerr << "ERROR: Variabila '" << varName << "' este deja declarata in scope-ul '" << scopeName << "' (Linia " << yylineno << ")\n";
                return;
            }
        }

        variables.push_back(Variable(type, varName, initialValue, isConst));
    }

    Function *findFunction(const string &funcName)
    {
        for (auto &func : functions)
        {
            if (func.name == funcName)
            {
                return &func;
            }
        }
        if (parentScope)
        {
            return parentScope->findFunction(funcName);
        }
        return nullptr;
    }

    bool isLiteral(const string &value)
    {
        if (!value.empty() && all_of(value.begin(), value.end(), ::isdigit))
        {
            return true;
        }
        if (value == "true" || value == "false")
        {
            return true;
        }

        if (value.length() >= 2 && value.front() == '"' && value.back() == '"')
        {
            return true;
        }

        return false;
    }

    string getLiteralType(const string &value)
    {
        if (!value.empty() && std::all_of(value.begin(), value.end(), ::isdigit))
        {
            return "int";
        }

        if (value == "true" || value == "false")
        {
            return "bool";
        }

        if (value.length() >= 2 && value.front() == '"' && value.back() == '"')
        {
            return "string";
        }

        return "unknown";
    }

    bool checkFunctionCall(const string &funcName, const vector<string> &params)
    {
        Function *func = findFunction(funcName);

        if (!func)
        {
            cerr << "ERROR: Functia '" << funcName << "' nu e declarata\n";
            return false;
        }

        vector<string> argTypes;
        for (const auto &param : params)
        {
            Variable *var = findVariable(param);
            if (var)
            {
                argTypes.push_back(var->type);
            }
            else if (isLiteral(param))
            {
                argTypes.push_back(getLiteralType(param));
            }
            else
            {
                argTypes.push_back("undefined");
                cerr << "ERROR: Parametru nedefinit'" << param << "' in apelul functiei '" << funcName << "'\n";
            }
        }

        if (func->parameters.size() != argTypes.size())
        {
            cerr << "ERROR: Functia '" << funcName << "' necesita " << func->parameters.size() << " argumente, dar avem " << argTypes.size() << "\n";
            return false;
        }

        for (size_t i = 0; i < argTypes.size(); ++i)
        {
            if (func->parameters[i].type != argTypes[i])
            {
                cerr << "ERROR: In functia '" << funcName << "', argumentul " << (i + 1) << " ar trebui sa fie '" << func->parameters[i].type << "', dar avem '" << argTypes[i] << "'\n";
                return false;
            }
        }

        return true;
    }

    void addFunction(const Function &f)
    {
        for (auto &fun : functions)
        {
            if (fun.name == f.name)
            {
                cerr << "ERROR: Functia '" << f.name << "' este deja declarata in scope-ul '" << scopeName << "' (Linia " << yylineno << ")\n";
                return;
            }
        }

        functions.push_back(f);
    }

    void addClass(const ClassInfo &cls)
    {
        for (auto &c : classes)
        {
            if (c.name == cls.name)
            {
                cerr << "ERROR: Clasa '" << cls.name << "' este deja declarata in scope-ul '" << scopeName << "' (Linia " << yylineno << ")\n";
                return;
            }
        }

        classes.push_back(cls);
    }

    void printTableToFile(const string &filename)
    {
        FILE *fp = fopen(filename.c_str(), "w");

        fprintf(fp, "=== SYMBOL TABLES ===\n\n");
        printScopeRecursive(fp, 0);

        fclose(fp);
    }
    Variable *findVariable(const std::string &name)
    {
        for (auto &var : variables)
        {
            if (var.name == name)
                return &var;
        }

        if (parentScope)
            return parentScope->findVariable(name);
        return nullptr;
    }

private:
    void printScopeRecursive(FILE *fp, int indent)
    {
        string prefix(indent, ' ');

        if (scopeName.rfind("global", 0) == 0)
        {
            fprintf(fp, "%sGlobal Scope: %s\n", prefix.c_str(), scopeName.c_str());
        }
        else if (scopeName.rfind("class", 0) == 0)
        {
            fprintf(fp, "%sClass Scope: %s\n", prefix.c_str(), scopeName.c_str());
        }
        else if (scopeName.rfind("function", 0) == 0)
        {
            fprintf(fp, "%sFunction Scope: %s\n", prefix.c_str(), scopeName.c_str());
        }
        else
        {
            fprintf(fp, "%sBlock Scope: %s\n", prefix.c_str(), scopeName.c_str());
        }

        for (auto &v : variables)
        {
            fprintf(fp, "%s  Var: %s %s", prefix.c_str(), v.type.c_str(), v.name.c_str());
            if (!v.value.empty())
            {
                fprintf(fp, " = %s", v.value.c_str());
            }
            if (v.isConst)
            {
                fprintf(fp, " (const)");
            }
            fprintf(fp, "\n");
        }

        for (auto &func : functions)
        {
            fprintf(fp, "%s  Func: %s %s(", prefix.c_str(),
                    func.returnType.c_str(), func.name.c_str());

            for (size_t i = 0; i < func.parameters.size(); i++)
            {
                fprintf(fp, "%s %s", func.parameters[i].type.c_str(),
                        func.parameters[i].name.c_str());
                if (i < func.parameters.size() - 1)
                {
                    fprintf(fp, ", ");
                }
            }
            fprintf(fp, ")");

            if (!func.definedIn.empty())
            {
                fprintf(fp, " [in class %s]", func.definedIn.c_str());
            }
            fprintf(fp, "\n");
        }

        for (auto &cls : classes)
        {
            fprintf(fp, "%s  Class: %s\n", prefix.c_str(), cls.name.c_str());
        }

        for (auto *child : children)
        {
            child->printScopeRecursive(fp, indent + 2);
        }
    }
};

extern SymTable *currentSymTable;
extern SymTable *globalSymTable;

class ASTNode
{
private:
    std::string nume;
    ASTNode *st;
    ASTNode *dr;
    NodeType nodeType;
    DataType dataType;

public:
    ASTNode(const std::string &name, ASTNode *left, ASTNode *right, NodeType type, DataType dataType)
        : nume(name), st(left), dr(right), nodeType(type), dataType(dataType) {}

    DataType getDataType() const
    {
        return dataType;
    }
    std::string getName() const
    {
        return nume;
    }

    std::string getDataTypeAsString() const
    {
        // daca e frunza
        if (!st && !dr)
        {
            switch (dataType)
            {
            case TYPE_INT:
                return "int";
            case TYPE_FLOAT:
                return "float";
            case TYPE_STRING:
                return "string";
            case TYPE_CHAR:
                return "char";
            case TYPE_BOOL:
                return "bool";
            default:
                return "unknown";
            }
        }

        string leftType = st ? st->getDataTypeAsString() : "unknown";
        string rightType = dr ? dr->getDataTypeAsString() : "unknown";

        if (leftType != rightType)
        {
            return "unknown";
        }
        return leftType;
    }

    static ASTNode *buildAST(const std::string &name, ASTNode *left, ASTNode *right, NodeType type)
    {
        DataType dataType = TYPE_UNKNOWN;

        if (type == OPERATOR)
        {
            string leftType = left ? left->getDataTypeAsString() : "unknown";
            string rightType = right ? right->getDataTypeAsString() : "unknown";

            if (name == "<" || name == ">" || name == "==" || name == "!=" || name == "<=" || name == ">=")
            {

                if ((leftType == "int" || leftType == "float") && (rightType == "int" || rightType == "float"))
                {
                    dataType = TYPE_BOOL;
                }
            }

            else if (name == "+" || name == "-" || name == "*" || name == "/" || name == "%")
            {
                if (leftType != rightType)
                {
                    fprintf(stderr, "ERROR: Nu poti face operatii cu tipurile '%s' si '%s'\n", leftType.c_str(), rightType.c_str());
                    dataType = TYPE_UNKNOWN;
                }
                else
                {
                    if (leftType == "int")
                        dataType = TYPE_INT;
                    else if (leftType == "float")
                        dataType = TYPE_FLOAT;
                    else
                    {
                        fprintf(stderr, "ERROR: Operatorul '%s' nu suporta operatii pentru tipul '%s'\n", name.c_str(), leftType.c_str());
                        dataType = TYPE_UNKNOWN;
                    }
                }
            }
            else
            {
                fprintf(stderr, "ERROR: Operator gresit '%s'\n", name.c_str());
                dataType = TYPE_UNKNOWN;
            }
        }

        else if (type == NUMBER)
        {
            if (name.find('.') != string::npos)
            {
                dataType = TYPE_FLOAT;
            }
            else
            {
                dataType = TYPE_INT;
            }
        }
        else if (type == BOOLEAN)
        {
            if (name == "true" || name == "false")
            {
                dataType = TYPE_BOOL;
            }
            else if (name == "&&" || name == "||")
            {
                string leftType = left ? left->getDataTypeAsString() : "unknown";
                string rightType = right ? right->getDataTypeAsString() : "unknown";

                if (leftType == "bool" && rightType == "bool")
                {
                    dataType = TYPE_BOOL;
                }
            }
            else if (name == "!")
            {
                string leftType = left ? left->getDataTypeAsString() : "unknown";

                if (leftType == "bool")
                {
                    dataType = TYPE_BOOL;
                }
            }
        }

        else if (type == IDENTIFIER)
        {
            Variable *var = currentSymTable->findVariable(name);
            if (var)
            {
                if (var->type == "int")
                    dataType = TYPE_INT;
                else if (var->type == "float")
                    dataType = TYPE_FLOAT;
                else if (var->type == "string")
                    dataType = TYPE_STRING;
                else if (var->type == "char")
                    dataType = TYPE_CHAR;
                else if (var->type == "bool")
                    dataType = TYPE_BOOL;
            }
            else
            {
                dataType = TYPE_UNKNOWN;
            }
        }

        else if (type == OTHER)
        {
            if (!name.empty() && name.front() == '"' && name.back() == '"')
            {
                dataType = TYPE_STRING;
            }
            else if (name.front() == '\'' && name.back() == '\'' && name.size() == 3)
            {
                dataType = TYPE_CHAR;
            }
            else
            {
                dataType = TYPE_UNKNOWN;
            }
        }

        return new ASTNode(name, left, right, type, dataType);
    }

    static EvalResult evalAST(ASTNode *node)
    {
        if (!node)
        {
            return 0;
        }

        if (!node->st && !node->dr)
        {
            if (node->nodeType == NUMBER)
            {
                if (node->nume.find('.') != string::npos)
                {
                    return stof(node->nume);
                }
                else
                {
                    return stoi(node->nume);
                }
            }
            else if (node->nodeType == IDENTIFIER)
            {
                Variable *var = currentSymTable->findVariable(node->nume);
                if (var)
                {
                    if (var->type == "int")
                        return stoi(var->value);
                    if (var->type == "float")
                        return stof(var->value);
                    if (var->type == "string")
                        return var->value;
                    if (var->type == "char")
                        return var->value[0];
                    if (var->type == "bool")
                        return var->value == "true";
                }
                else
                {
                    return 0;
                }
            }
            else if (node->nodeType == BOOLEAN)
            {
                if (node->nume == "true")
                {
                    return true;
                }
                else if (node->nume == "false")
                {
                    return false;
                }
            }
            else if (node->nodeType == OTHER)
            {
                if (node->nume.front() == '"' && node->nume.back() == '"')
                {
                    return node->nume.substr(1, node->nume.size() - 2);
                }
                else if (node->nume.front() == '\'' && node->nume.back() == '\'' && node->nume.size() == 3)
                {
                    return node->nume[1];
                }
            }
        }

        EvalResult leftVal = evalAST(node->st);
        EvalResult rightVal = evalAST(node->dr);

        if (node->nume == "+")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return get<float>(leftVal) + get<float>(rightVal);
            }
            return get<int>(leftVal) + get<int>(rightVal);
        }
        else if (node->nume == "-")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return get<float>(leftVal) - get<float>(rightVal);
            }
            return get<int>(leftVal) - get<int>(rightVal);
        }
        else if (node->nume == "*")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return get<float>(leftVal) * get<float>(rightVal);
            }
            return get<int>(leftVal) * get<int>(rightVal);
        }
        else if (node->nume == "/")
        {
            if ((holds_alternative<int>(rightVal) && get<int>(rightVal) == 0) || (holds_alternative<float>(rightVal) && get<float>(rightVal) == 0.0f))
            {
                cerr << "ERROR: Nu poti imparti la 0\n";
                return 0;
            }

            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return get<float>(leftVal) / get<float>(rightVal);
            }
            return get<int>(leftVal) / get<int>(rightVal);
        }

        else if (node->nume == "<")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return static_cast<bool>(get<float>(leftVal) < std::get<float>(rightVal));
            }
            return static_cast<bool>(std::get<int>(leftVal) < std::get<int>(rightVal));
        }
        else if (node->nume == ">")
        {
            if (std::holds_alternative<float>(leftVal) || ::holds_alternative<float>(rightVal))
            {
                return static_cast<bool>(::get<float>(leftVal) > ::get<float>(rightVal));
            }
            return static_cast<bool>(std::get<int>(leftVal) > std::get<int>(rightVal));
        }
        else if (node->nume == "==")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return static_cast<bool>(get<float>(leftVal) == get<float>(rightVal));
            }
            else if (holds_alternative<int>(leftVal) && holds_alternative<int>(rightVal))
            {
                return static_cast<bool>(get<int>(leftVal) == get<int>(rightVal));
            }
            else if (holds_alternative<string>(leftVal) && holds_alternative<string>(rightVal))
            {
                return static_cast<bool>(get<string>(leftVal) == get<string>(rightVal));
            }
            else if (holds_alternative<char>(leftVal) && holds_alternative<char>(rightVal))
            {
                return static_cast<bool>(get<char>(leftVal) == get<char>(rightVal));
            }
            else if (holds_alternative<bool>(leftVal) && holds_alternative<bool>(rightVal))
            {
                return static_cast<bool>(get<bool>(leftVal) == get<bool>(rightVal));
            }
            else
            {
                cerr << "ERROR: Tipurile nu se potrivesc: ==\n";
                return false;
            }
        }
        else if (node->nume == "!=")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return static_cast<bool>(get<float>(leftVal) != get<float>(rightVal));
            }
            else if (holds_alternative<int>(leftVal) && holds_alternative<int>(rightVal))
            {
                return static_cast<bool>(get<int>(leftVal) != get<int>(rightVal));
            }
            else if (holds_alternative<string>(leftVal) && holds_alternative<string>(rightVal))
            {
                return static_cast<bool>(get<string>(leftVal) != get<string>(rightVal));
            }
            else if (holds_alternative<char>(leftVal) && holds_alternative<char>(rightVal))
            {
                return static_cast<bool>(get<char>(leftVal) != get<char>(rightVal));
            }
            else if (holds_alternative<bool>(leftVal) && holds_alternative<bool>(rightVal))
            {
                return static_cast<bool>(get<bool>(leftVal) != get<bool>(rightVal));
            }
            else
            {
                cerr << "ERROR: Tipurile nu se potrivesc: !=\n";
                return false;
            }
        }
        else if (node->nume == "<=")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return static_cast<bool>(get<float>(leftVal) <= get<float>(rightVal));
            }
            return static_cast<bool>(get<int>(leftVal) <= get<int>(rightVal));
        }
        else if (node->nume == ">=")
        {
            if (holds_alternative<float>(leftVal) || holds_alternative<float>(rightVal))
            {
                return static_cast<bool>(get<float>(leftVal) >= get<float>(rightVal));
            }
            return static_cast<bool>(get<int>(leftVal) >= get<int>(rightVal));
        }
        return 0;
    }
};

inline void pushScope(const string &name)
{
    currentSymTable = currentSymTable->createChildScope(name);
}

inline void popScope()
{
    if (currentSymTable->parentScope)
    {
        currentSymTable = currentSymTable->parentScope;
    }
}

#endif
