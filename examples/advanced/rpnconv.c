#include <stdlib.h>
#include <stdio.h>


char op_stack[32];              // reserved storage for operator stack
char *op_tosp = &op_stack[0];   // pointer to next-slot-we-will-fill


int ops_is_empty() {
	return op_tosp == &op_stack[0];	// if we are still here, we haven't pushed anything
}

int ops_is_full() {
	// (sizeof op_stack) -> size of op_stack array in bytes
	// (sizeof op_stack[0]) -> size of a single op_stack array in bytes
	// (sizeof op_stack / sizeof op_stack[0]) -> number of elements in op_stack array
	// [this math works for any type of array PROVIDED sizeof is valid at all]
	// [i.e., don't use this on pointers (arrays passed to functions)]
	//
	// if the "next slot" pointer points at 1 past the end of the array, we're full
	return op_tosp == &op_stack[(sizeof op_stack / sizeof op_stack[0])];
}

// precondition: must ensure ops_is_empty() == 0 (false)
char ops_peek() {
	// return the last filled slot's value
	return *(op_tosp - 1);
}

// precondition: must ensure ops_is_full() == 0 (false)
void ops_push(char op) {
	// store `op` into "next slot to use" and advance to next available slot
	*op_tosp = op;
	++op_tosp;
}

// precondition: must ensure ops_is_empty() == 0 (false)
char ops_pop() {
	// capture the current top-of-stack value, pop one slot, return saved value
	char op = ops_peek();
	--op_tosp; //--op_tos;
	return op;
}

// simple data structure defining our operator precedence
const struct prec_entry {
	char op;
	int prec;
} PRECEDENCE_TABLE[] = {
	{ '+', 10 }, { '-', 10 }, 
	{ '*', 20 }, { '/', 20 }, { '%', 20 },
	{ '\0', -1} // terminal element
};

// look up relative precedence (higher == higher) of `op` (returns -1 if no such op)
int get_prec(char op) {
	for (int i = 0; PRECEDENCE_TABLE[i].op != '\0'; ++i) {
		if (PRECEDENCE_TABLE[i].op == op) return PRECEDENCE_TABLE[i].prec;
	}
	return -1;
}

// return 1 (true) if op_a has greater/equal precedence than/as op_b
int greater_equal_prec(char op_a, char op_b) {
	return (get_prec(op_a) >= get_prec(op_b));
}


enum token_kind {
	NUM,  // = 0
	OP,   // = 1
	END   // = 2
};

struct token {
	enum token_kind kind;
	union { // experiment with commenting out the "union {" and corresponding "};"
		int num;	
		char op;
       	};
};

struct token inputs[] = {
	{ NUM, .num = 42 },
	{ OP, .op = '+'},
	{ NUM, .num = 1337 },
	{ OP, .op = '*' },
	{ NUM, .num = 7 },
	{ END },
};


int main() {
	int token_i = 0;

	for (int token_i = 0; inputs[token_i].kind != END; ++token_i) {
		if (inputs[token_i].kind == NUM) {
			printf("%d ", inputs[token_i].num);
		/* } else if (inputs[token_i].op == '(') { */   // Handle LPAREN
		/* } else if (inputs[token_i].op == ')') { */   // Handle RPAREN
		} else { // Handle general math op
			 char op_b = inputs[token_i].op;
			 while (!ops_is_empty() && greater_equal_prec(ops_peek(), op_b)) {
				 printf("%c ", ops_pop());
			 }
			 if (ops_is_full()) {
				 puts("stack overflow");
				 abort();
			 }
			 ops_push(op_b);
		}
		//printf("inputs[%d] = { %d, %d, '%c' };\n", token_i, inputs[token_i].kind, inputs[token_i].num, inputs[token_i].op);
	}

	while (!ops_is_empty()) {
		printf("%c ", ops_pop());
	}
	putchar('\n');

	return 0;
}
