My Programming Language
This project implements a custom programming language with syntax, semantic analysis, and expression evaluation using Abstract Syntax Trees (AST). The language includes type declarations, function definitions, control structures, symbol tables, and error handling.

Features
1. Syntax Requirements
Type Declarations: Supports int, float, char, string, bool, and array types.
Classes:
Allow initialization and use of objects.
Provide syntax for accessing fields and methods.
Can only be defined in the global scope.
Variable and Function Definitions.
Control Statements: if, for, while.
Assignment Statements: left_value = expression where left_value can be an identifier or array element.
Expressions: Arithmetic and boolean expressions with true and false values.
Function Calls: Support for expressions, function calls, and identifiers as parameters.
Predefined Functions:
Print(expr): Evaluates and prints expr.
TypeOf(expr): Prints the type of expr.
Program Structure:
Class definitions.
Global variables.
Function definitions.
Main function (entry point).
2. Symbol Tables
Maintains scopes for variables and functions:
Global Scope: Covers entire program.
Block Scope: Introduced by if, for, while.
Function Scope: Introduced by function definitions.
Class Scope: Introduced by class definitions.
Implemented using SymTable class with a pointer to parent scope.
Stores information about variables, functions, and classes.
Symbol tables are printed to a separate file after parsing.
3. Semantic Analysis
Ensures:
Variables/functions are defined before use.
No duplicate variable declarations in the same scope.
Operands in an expression have the same type (no implicit casting).
Left and right sides of an assignment have the same type.
Function call arguments match function definition.
Provides detailed error messages with line numbers.
4. AST-Based Expression Evaluation
AST Representation:
Single node for literals, identifiers, function calls, etc.
Operator nodes with left/right subtrees for binary expressions.
Unary operator nodes with a single subtree.
Evaluation:
If the root is a literal, return its value.
If the root is an identifier, fetch value from the symbol table.
Otherwise, recursively evaluate subtrees and apply operations.
Usage:
Print(expr): Evaluates expr and prints value and type.
TypeOf(expr): Prints type of expr.
Evaluates right-hand side expressions in assignments.
