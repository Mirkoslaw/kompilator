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
	bool initialized;
	bool loop_var;
	long long used_memory;
	int memoryIndex;
	bool is_array;
} Symbol;

bool check_if_var_was_declared(string symbol_name);
void declare_variable(string symbol_name);
void declare_array(string symbol_name, string size);
void assign(string symbol_name);
void load(string token);
void loadVar(string symbol_name);
void write(string symbol_name);
void read(string symbol_name);
void make_registers_free();
void generate_value(int number, int register_number);
int get_first_free_register();
Symbol getVariable(string symbol_name);
int getVariableIndex(string symbol_name);
string convertInt(int value);
void loadIdentifier(string symbol_name);
void loadArrayVar(string symbol_name, string index);
void add();
void sub();
void mul();
void div();

void equal();
void not_equal();


int errors = 0;
int jump = 0;
int k=0;
long long used_memory=10;
int first_free_register=1;

vector<Symbol> symbolTable;
vector<string> resultCode;
stack<int> jumpStack;
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
		declare_array($<str>2, $<str>4);
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
	| IF condition THEN commands ENDIF {
		resultCode.at(jumpStack.top())+=convertInt(resultCode.size());
		jumpStack.pop();
		jumpStack.pop();
		}
	| IF condition THEN commands{} ELSE{
		resultCode.at(jumpStack.top())+=convertInt(resultCode.size()+1);
		jumpStack.pop();
		jumpStack.push(resultCode.size());
		resultCode.push_back("JUMP ");
	} commands ENDIF {
		resultCode.at(jumpStack.top())+=convertInt(resultCode.size());
		jumpStack.pop();
		jumpStack.pop();
		}
	| WHILE condition DO commands ENDWHILE {
		resultCode.at(jumpStack.top())+=convertInt(resultCode.size()+1);
		jumpStack.pop();
		resultCode.push_back("JUMP "+convertInt(jumpStack.top()));
		jumpStack.pop();
		;}
	| FOR PIDENTIFIER FROM value TO value DO commands ENDFOR {;}
	| FOR PIDENTIFIER FROM value DOWNTO value commands ENDFOR {;}
	| READ identifier SEMICOLON{
		read($<str>2);
		}
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
	value EQUAL value { 
		equal();
		first_free_register--;
		}
	| value NEQUAL value {
		not_equal();
		first_free_register--;
		}
	| value SMALLER value {;}
	| value GREATER value {;}
	| value LEQUAL value {;}
	| value GEQUAL value {;}
;

value:
	NUM {load($<str>1);}
	|identifier {
		loadIdentifier($<str>1);
	}
;

identifier:
	PIDENTIFIER {loadVar($<str>1);}
	|PIDENTIFIER LBRACKET PIDENTIFIER RBRACKET {
		loadArrayVar($<str>1, $<str>2);
		}
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
	int r3 = first_free_register;
	int r0 = 0;
	generate_value(0,r0);
	resultCode.push_back("STORE "+convertInt(r2));
	resultCode.push_back("LOAD "+convertInt(r3));
	generate_value(0, r2);
	int temp = resultCode.size();
	resultCode.push_back("JZERO "+convertInt(r3)+" "+convertInt(temp+11));
	resultCode.push_back("JZERO "+convertInt(r1)+" "+convertInt(temp+11));
	resultCode.push_back("JODD "+convertInt(r1)+" "+convertInt(temp+6));
	resultCode.push_back("SHR "+convertInt(r1));
	resultCode.push_back("SHL "+convertInt(r3));	
	resultCode.push_back("JUMP "+convertInt(temp+1));

	resultCode.push_back("STORE "+convertInt(r3));

	resultCode.push_back("ADD "+convertInt(r2));
	resultCode.push_back("SHR "+convertInt(r1));
	resultCode.push_back("SHL "+convertInt(r3));
	resultCode.push_back("JUMP "+convertInt(temp+1));
	first_free_register--;
}

void div(){
	int r1 = first_free_register-1;
	int r2 = first_free_register-2;
	int r3 = first_free_register;
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
	
	generate_value(0,r0);
	resultCode.push_back("STORE "+convertInt(r1));
	resultCode.push_back("LOAD "+convertInt(r2));
	first_free_register--;
}

void equal(){
	int r1 = first_free_register-1;
	int r2 = first_free_register-2;
	int r0 = 0;
	jumpStack.push(resultCode.size());
	generate_value(0,r0);//r0=0
	resultCode.push_back("STORE "+convertInt(r2));//copy r2 to P(r0=0)

	resultCode.push_back("INC "+convertInt(r0));//r0=1
	resultCode.push_back("STORE "+convertInt(r1));//copy r1 to P(r0=1)
	resultCode.push_back("SUB "+convertInt(r2));//sub r2 - r1 
	
	resultCode.push_back("DEC "+convertInt(r0));//r0=0
	resultCode.push_back("SUB "+convertInt(r1)); //sub r1 - r2
	resultCode.push_back("STORE "+convertInt(r2));
	resultCode.push_back("ADD "+convertInt(r1)); //add new r1 to new r2
	int temp = resultCode.size();
	resultCode.push_back("JZERO "+convertInt(r1)+ " "+convertInt(temp+3));
	resultCode.push_back("ZERO "+convertInt(r1));
	resultCode.push_back("JUMP "+convertInt(temp+4));
	resultCode.push_back("INC "+convertInt(r1));
	jumpStack.push(resultCode.size());
	resultCode.push_back("JZERO "+convertInt(r1)+" ");
}

void not_equal(){
	int r1 = first_free_register-1;
	int r2 = first_free_register-2;
	int r0 = 0;
	jumpStack.push(resultCode.size());
	generate_value(0,r0);//r0=0
	resultCode.push_back("STORE "+convertInt(r2));//copy r2 to P(r0=0)

	resultCode.push_back("INC "+convertInt(r0));//r0=1
	resultCode.push_back("STORE "+convertInt(r1));//copy r1 to P(r0=1)
	resultCode.push_back("SUB "+convertInt(r2));//sub r2 - r1 
	
	resultCode.push_back("DEC "+convertInt(r0));//r0=0
	resultCode.push_back("SUB "+convertInt(r1)); //sub r1 - r2
	resultCode.push_back("STORE "+convertInt(r2));
	resultCode.push_back("ADD "+convertInt(r1)); //add new r1 to new r2
	jumpStack.push(resultCode.size());
	resultCode.push_back("JZERO "+convertInt(r1)+" ");
}

void div2(){
	int r1 = first_free_register-1;
	int r2 = first_free_register-2;
	int r3 = first_free_register;
	int r0 = 0;
	generate_value(0, r0);
	resultCode.push_back("STORE "+convertInt(r2));
	int temp = resultCode.size();
	resultCode.push_back("JZERO "+convertInt(r2)+" "+convertInt(temp+8));
	resultCode.push_back("JZERO "+convertInt(r1)+" "+convertInt(temp+8));
	resultCode.push_back("SHL "+convertInt(r1));
	resultCode.push_back("SUB "+convertInt(r1));
	resultCode.push_back("JZERO "+convertInt(r1)+" "+convertInt(temp+2));
}

void assign(string symbol_name)
{
	if(check_if_var_was_declared(symbol_name)){
		Symbol sym = getVariable(symbol_name);
		int index = getVariableIndex(symbol_name);
		first_free_register--;
		resultCode.push_back("COPY "+convertInt(first_free_register-1));
		resultCode.push_back("STORE "+convertInt(first_free_register));
		symbolTable.at(index).initialized = true;
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
	if(!check_if_var_was_declared(symbol_name)){
		errors++;
		cout<<"BLAD: Uzycie niezadeklarowanej zmiennej "+symbol_name<<endl;
		exit(1);
	}
	Symbol symbol = getVariable(symbol_name);
	int address = symbol.memoryIndex;
	generate_value(address, first_free_register);
	first_free_register++;
}
void loadIdentifier(string symbol_name)
{
	resultCode.push_back("COPY "+convertInt(first_free_register-1))	;
	resultCode.push_back("LOAD "+convertInt(first_free_register-1));
}

void loadArrayVar(string symbol_name, string index){

	Symbol symbol = getVariable(symbol_name);
	if(!symbol.is_array){
		cout<<"Blad: Nieprawidlowe uzycie zmiennej "+symbol_name+ " "<<endl;
		exit(1);
	}
}

void write(string symbol_name)
{
	if(!check_if_var_was_declared(symbol_name)){
		exit(1);
	}
	Symbol sym = getVariable(symbol_name);
		// if(sym.loop_var){
	resultCode.push_back("PUT "+ convertInt(first_free_register-1));
	first_free_register--;
		// }
}

void read(string symbol_name){

	if(!check_if_var_was_declared(symbol_name)){
		errors++;
		cout<<"Błąd: Użycie niezadeklarowanej zmiennej "+symbol_name<<endl;
		exit(1);
	}
	int loop_var = 0;
	if(loop_var==0){
		resultCode.push_back("GET "+convertInt(first_free_register));
		resultCode.push_back("COPY "+convertInt(first_free_register-1));
		resultCode.push_back("STORE "+convertInt(first_free_register));
		first_free_register--;
		
	} else {

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
			false,
			1,
			used_memory++,
			false
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
	int size_int = stol(size);
	if(!check_if_var_was_declared(symbol_name)){
		Symbol symbol = {
			symbol_name,
			NULL,
			false,
			false,
			size_int,
			used_memory+=size_int,
			true,
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
	printf ("%s %d\n", s, yylineno);
}
