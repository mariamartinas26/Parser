# My Programming Language

This project implements a **custom programming language** featuring a full pipeline including syntax parsing, semantic analysis, symbol tables, and expression evaluation using **Abstract Syntax Trees (ASTs)**. The language supports typed variables, classes, functions, and standard control flow structures.

---

## Features

### 1. Syntax Support

- **Primitive Types**: `int`, `float`, `char`, `string`, `bool`, and `array`.
- **Classes**
  - Initialization and object usage.
  - Access fields and methods via dot notation.
  - Must be defined in the global scope.
- **Variable and Function Declarations**
- **Control Structures**
  - `if`, `for`, and `while` blocks.
- **Assignment Statements**
  - Format: `left_value = expression`
  - `left_value` can be an identifier or array element.
- **Expressions**
  - Support for arithmetic and boolean expressions.
  - Uses `true` and `false` for boolean literals.
- **Function Calls**
  - Parameters can be expressions, function calls, or identifiers.
- **Predefined Functions**
  - `Print(expr)`: Evaluates and prints the value and type of `expr`.
  - `TypeOf(expr)`: Prints the type of `expr`.

---

### 2. Program Structure

- Global class definitions.
- Global variable declarations.
- Function definitions.
- Mandatory `main` function as the entry point.

---

### 3. Symbol Table Management

- Scoped symbol resolution via a `SymTable` class.
- **Scope Types**:
  - **Global Scope**: Accessible throughout the program.
  - **Block Scope**: Created by `if`, `for`, and `while` blocks.
  - **Function Scope**: Defined within function bodies.
  - **Class Scope**: Inside class definitions.
- Each scope maintains a pointer to its parent.
- Stores identifiers for variables, functions, and class types.
- Symbol tables are exported to a separate file after parsing.

---

### 4. Semantic Analysis

- Ensures:
  - All variables and functions are defined before use.
  - No duplicate variable declarations within the same scope.
  - Expression operands are of the same type (no implicit casting).
  - Assignment types match on both sides.
  - Function calls use correct number and types of arguments.
- **Error Reporting**:
  - Detailed messages with line numbers for easier debugging.

---

### 5. AST-Based Expression Evaluation

- **AST Node Types**:
  - **Leaf Nodes**: Literals, identifiers, function calls.
  - **Binary Operator Nodes**: Hold left/right subtrees.
  - **Unary Operator Nodes**: Hold a single subtree.
- **Evaluation Strategy**:
  - Literals return their value.
  - Identifiers fetch values from the symbol table.
  - Operators recursively evaluate subtrees and apply operations.
- Used in predefined functions like `Print()` and `TypeOf()`.

---

##  Technologies Used

- Custom Lexer/Parser
- Tree-based data structures (for AST and symbol tables)

---

## Output

- Generated symbol tables are written to a file for inspection.
- Runtime errors are clearly reported with context and source lines.

---

##  Example

```c
class Point {
    int x;
    int y;
}

function int add(int a, int b) {
    return a + b;
}

main() {
    int z = add(3, 4);
    Print(z); // Output: 7
    TypeOf(z); // Output: int
}
