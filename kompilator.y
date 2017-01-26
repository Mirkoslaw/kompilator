%{
#include <stdio.h>
#include <string>
#include <vector>
#include <iostream>
#include <stack>
#include <cstdio>
#include <sstream>

using namespace std;
int yylex (void);
extern int yylineno;
void yyerror (char const *s);
typedef struct {
	string name;
	int address;
	bool declared;
	long long used_memory;
	int memoryIndex;
} Symbol;

bool check_if_var_was_declared(string symbol_name);
void declare_variable(string symbol_name);
void declare_array(string symbol_name, string size);
void assign(string symbol_name);
void load(string token);
void loadVar(string symbol_name);
void write(string symbol_name);
void make_registers_free();
void generate_value(int number, int register_number);
int get_first_free_register();
Symbol getVariable(string symbol_name);
int getVariableIndex(string symbol_name);
string convertInt(int value);
void loadIdentifier();
void add();
void sub();
void mul();
void div();


int errors = 0;
int jump = 0;
int k=0;
long long used_memory=10;
int first_free_register=1;

vector<Symbol> symbolTable;
vector<string> resultCode;
bool registers[5];


%}
%union{ char* str; long num; long id_address; bool isnum;}

%token <str> VAR
%token <str> MYBEGIN
%token <str> END
%token <str> IF
%token <str> THEN
%token <str> ELSE
%token <str> ENDIF
%token <str> WHILE
%token <str> DO
%token <str> ENDWHILE
%token <str> FOR
%token <str> DOWNTO
%token <str> FROM
%token <str> TO
%token <str> ENDFOR
%token <str> READ
%token <str> WRITE
%token <str> PLUS
%token <str> MINUS
%token <str> DIV
%token <str> MUL
%token <str> MOD
%token <str> EQUAL
%token <str> NEQUAL
%token <str> LEQUAL
%token <str> GEQUAL
%token <str> SMALLER
%token <str> GREATER
%token <str> ASSIGN
%token <str> PIDENTIFIER
%token <num> NUM
%token <str> LBRACKET
%token <str> RBRACKET
%token <str> SEMICOLON


%%
program:
	|VAR
	{
		make_registers_free();
	}
	 vdeclarations MYBEGIN commands END { 
		resultCode.push_back("HALT");
	}	
;

vdeclarations:
	vdeclarations PIDENTIFIER {
		declare_variable($<str>2);
	}
	|vdeclarations PIDENTIFIER LBRACKET NUM RBRACKET {
		// declare_array($<str>2, $<num>4);
		;
		}
	| 
;

commands:
	commands command {;}
	|
;

command:
	identifier ASSIGN expression SEMICOLON {
		assign($<str>1);
	}
	| IF condition THEN commands ENDIF {;}
	| IF condition THEN commands ELSE commands ENDIF {;}
	| WHILE condition DO commands ENDWHILE {;}
	| FOR PIDENTIFIER FROM value TO value DO commands ENDFOR {;}
	| FOR PIDENTIFIER FROM value DOWNTO value commands ENDFOR {;}
	| READ identifier SEMICOLON{;}
	| WRITE value SEMICOLON{
		write($<str>2) ;
		}
;

expression:
	value {
		;
	}
	| value PLUS value {
		add();
		}
	| value MINUS value {
		sub();
		}
	| value MUL value {
		mul();
		}
	| value DIV value {
		div();
		}
	| value MOD value {;}
;
condition:
	value EQUAL value { ;}
	| value NEQUAL value {;}
	| value SMALLER value {;}
	| value GREATER value {;}
	| value LEQUAL value {;}
	| value GEQUAL value {;}
;

value:
	NUM {load($<str>1);}
	|identifier {
		loadIdentifier();
	}
;

identifier:
	PIDENTIFIER {loadVar($<str>1);}
	|PIDENTIFIER LBRACKET PIDENTIFIER RBRACKET {;}
	|PIDENTIFIER LBRACKET NUM RBRACKET {;}
;


%%

/*
	Compile functions
*/

/*
	Reserve memory for variable
*/
void add()
{
	generate_value(0, 0);
	resultCode.push_back("STORE "+convertInt(first_free_register-1));
	resultCode.push_back("ADD "+convertInt(first_free_register-2));
	first_free_register--;
}

void sub()
{
	generate_value(0,0);
	resultCode.push_back("STORE "+convertInt(first_free_register-1));
	resultCode.push_back("SUB "+convertInt(first_free_register-2));
	first_free_register--;
}
void mul()
{
	int r1 = first_free_register-1;
	int r2 = first_free_register-2;
	int r3 = first_free_register-3;
	int r0 = 0;
	generate_value(0,r0);
	resultCode.push_back("STORE "+convertInt(r2));
	generate_value(0, r3);
	int temp = resultCode.size();
	resultCode.push_back("JZERO "+convertInt(r2)+" "+convertInt(temp+11));
	resultCode.push_back("JZERO "+convertInt(r1)+" "+convertInt(temp+11));
	resultCode.push_back("JODD "+convertInt(r1)+" "+convertInt(temp+6));
	resultCode.push_back("SHR "+convertInt(r1));
	resultCode.push_back("SHL "+convertInt(r2));	
	resultCode.push_back("JUMP "+convertInt(temp+1));

	resultCode.push_back("STORE "+convertInt(r2));

	resultCode.push_back("ADD "+convertInt(r3));
	resultCode.push_back("SHR "+convertInt(r1));
	resultCode.push_back("SHL "+convertInt(r2));
	resultCode.push_back("JUMP "+convertInt(temp+1));
	resultCode.push_back("PUT "+convertInt(r3));
	first_free_register--;
}

void div(){
	int r1 = first_free_register-1;
	int r2 = first_free_register-2;
	int r3 = first_free_register-3;
	int r0 = 0;
	generate_value(0,r0);
	resultCode.push_back("STORE "+convertInt(r1));
	int temp = resultCode.size();
	resultCode.push_back("JODD "+convertInt(r1)+" "+convertInt(temp+7));
	resultCode.push_back("JZERO "+convertInt(r1)+" "+convertInt(temp+8));
	generate_value(0,r1);
	resultCode.push_back("JZERO "+convertInt(r2)+" "+convertInt(temp+8));
	resultCode.push_back("SUB "+convertInt(r2));
	resultCode.push_back("INC "+convertInt(r1));
	resultCode.push_back("JUMP "+convertInt(temp+3));
	resultCode.push_back("INC "+convertInt(r1));
	

	resultCode.push_back("PUT "+convertInt(r1));
	first_free_register--;
}

void assign(string symbol_name)
{
	if(check_if_var_was_declared(symbol_name)){
		Symbol sym = getVariable(symbol_name);
		int index = getVariableIndex(symbol_name);
		first_free_register--;
		resultCode.push_back("COPY "+convertInt(first_free_register-1));
		resultCode.push_back("STORE "+convertInt(first_free_register));
		symbolTable.at(index).declared = true;
		first_free_register--;
	}
}

void load(string token)
{
	int t = stoi(token);
	generate_value(t, first_free_register);
	first_free_register++;
}

void loadVar(string symbol_name)
{
	Symbol symbol = getVariable(symbol_name);
	int address = symbol.memoryIndex;
	generate_value(address, first_free_register);
	first_free_register++;
}
void loadIdentifier()
{
	resultCode.push_back("COPY "+convertInt(first_free_register-1))	;
	resultCode.push_back("LOAD "+convertInt(first_free_register-1));
}

void write(string symbol_name)
{
	if(check_if_var_was_declared(symbol_name)){
		Symbol sym = getVariable(symbol_name);
		if(sym.declared){
			resultCode.push_back("PUT "+ convertInt(first_free_register-1));
			first_free_register--;
		}
	}
}

Symbol getVariable(string symbol_name)
{
	for(auto sym: symbolTable){
		if (sym.name == symbol_name){
			return sym;
		}
	}
}

int getVariableIndex(string symbol_name){
	for(int i=0; i<symbolTable.size();i++) {
		if(symbolTable.at(i).name == symbol_name){
			return i;
		}
	}
}

string convertInt(int value){
	return to_string(value);
}


void declare_variable(string symbol_name)
{
	if(!check_if_var_was_declared(symbol_name)){
		Symbol symbol = {
			symbol_name,
			NULL,
			false,
			1,
			used_memory++
		};
		symbolTable.push_back(symbol);
	} else {
		errors++;
		cout<<"redeklaracja zmiennej "+symbol_name<<endl;
		exit(0);
	}
}

/*
	Reserve memory for array variable
*/
void declare_array(string symbol_name, string size)
{
	int size_int = stoi(size);
	if(!check_if_var_was_declared(symbol_name)){
		Symbol symbol = {
			symbol_name,
			NULL,
			false,
			size_int,
			used_memory+=size_int
		};
		symbolTable.push_back(symbol);
	} else {
		errors++;
		cout<<"redeklaracja zmiennej "+symbol_name<<endl;
		exit(0);
	}
}
/*
	Check if symbol was used in declarations
*/
bool check_if_var_was_declared(string symbol_name)
{
	for(auto sym: symbolTable){
		if (sym.name == symbol_name) {
			return true;
		}
	}
	return false;
}
/*
	initialize registers
*/
void make_registers_free(){
	for (int i=0; i<5; i++){
		registers[i] = false;
	}
}
/*
	get free register after 0
*/
int get_first_free_register(){
	for(int i=1; i<5; i++){
		if (!registers[i]){
			registers[i]=true;
			return i;
		}
	}
	return -1;
}

/*
	generate value
*/
void generate_value(int number, int register_number)
{
	char chosen_method[32] = "";
	int i = 0;
	if(number>0)
	{
		while(number>0)
		{
			if(number%2==0)
			{
				number = number/2;
				chosen_method[i]='*';
			}
			else 
			{
				number--;
				chosen_method[i]='+';
			}
			i++;
		}
		i--;

		resultCode.push_back("ZERO "+convertInt(register_number));
		registers[register_number] = false;
		while(i>=0)
		{
			if(chosen_method[i]=='*')
			{
				resultCode.push_back("SHL "+convertInt(register_number));
			}
			else
			{
				resultCode.push_back("INC "+convertInt(register_number));
			}
			i--;
		}
		return;
	}
	resultCode.push_back("ZERO "+convertInt(register_number));
}

/*
	Parser functions
*/
int yyerror( char * str )
{
	printf( "BLAD: %s\n", str );
	exit(0);
}
int main()
{
	yyparse ();
	for (auto str: resultCode){
		cout<<str<<endl;
	}
}
void yyerror (char const *s)
{
	errors++;
	printf ("%s\n", s);
}
