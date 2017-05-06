package pseudocode;

//Parser
enum Expr {
	/**
		A constant.
	**/
	EConst( c : Constant );

	/**
		Array access `e1[e2]`.
	**/
	EArray( e1 : Expr, e2 : Expr );

	/**
		Binary operator `e1 op e2`.
	**/
	EBinop( op : Binop, e1 : Expr, e2 : Expr );

	/**
		Parentheses `(e)`.
	**/
	EParenthesis( e : Expr );

	/**
		the result of this expression should be floored.
	**/
	EFloor(e : Expr);

	/**
		An unary operator `op` on `e`:

		* e++ (op = OpIncrement, postFix = true)
		* e-- (op = OpDecrement, postFix = true)
		* ++e (op = OpIncrement, postFix = false)
		* --e (op = OpDecrement, postFix = false)
		* -e (op = OpNeg, postFix = false)
		* !e (op = OpNot, postFix = false)
		* ~e (op = OpNegBits, postFix = false)
	**/
	EUnop( op : Unop, postFix : Bool, e : Expr );

	/**
		A block of statements.
	**/
	EBlock( exprs : Array<Expr> );

	/**
		A `for` expression.
	**/
	EFor( identifier : Expr, start : Expr, end : Expr, body : Expr, up : Bool );

	/**
		An `if(econd) eif` or `if(econd) eif else eelse` expression.
	**/
	EIf( econd : Expr, eif : Expr, eelse : Null<Expr> );

	/**
		Represents a `while` expression.
		When `normalWhile` is `true` it is `while (...)`.
		When `normalWhile` is `false` it is `do {...} while (...)`.
	**/
	EWhile( econd : Expr, e : Expr, normalWhile : Bool );

	/**
		A `return` or `return e` expression.
	**/
	EReturn( ?e : Null<Expr> );

	/**
		A `break` expression.
	**/
	EBreak; //TODO: implement break;

	/**
		A `continue` expression.
	**/
	EContinue;//TODO: implement continue;
}

/**
	A unary operator.
	@see https://haxe.org/manual/types-numeric-operators.html
**/
enum Unop {
	/**
		`++`
	**/
	OpIncrement;

	/**
		`--`
	**/
	OpDecrement;

	/**
		`!`
	**/
	OpNot;

	/**
		`-`
	**/
	OpNeg;

	/**
		`~`
	**/
	OpNegBits;
}

/**
	Represents a constant.
	@see https://haxe.org/manual/expression-constants.html
**/
enum Constant {
	/**
		Represents an integer literal.
	**/
	CInt( v : String );

	/**
		Represents a float literal.
	**/
	CFloat( f : String );

	/**
		Represents a string literal.
	**/
	// CString( s : String ); //TODO: no strings atm

	/**
		Represents an identifier.
	**/
	CIdent( s : String );
}

/**
	A binary operator.
	@see https://haxe.org/manual/types-numeric-operators.html
**/
enum Binop {
	/**
		`+`
	**/
	OpAdd;

	/**
		`*`
	**/
	OpMult;

	/**
		`/`
	**/
	OpDiv;

	/**
		`-`
	**/
	OpSub;

	/**
		`<-`
	**/
	OpAssign;

	/**
		`=`
	**/
	OpEq;

	/**
		`≠`
	**/
	OpNotEq;

	/**
		`>`
	**/
	OpGt;

	/**
		`≥`
	**/
	OpGte;

	/**
		`<`
	**/
	OpLt;

	/**
		`≤`
	**/
	OpLte;

	/**
		`&`
	**/
	OpAnd;

	/**
		`|`
	**/
	OpOr;

	/**
		`⊕`
	**/
	// OpXor;

	/**
		`∧`
	**/
	OpBoolAnd;

	/**
		`∨`
	**/
	OpBoolOr;

	/**
		`<<`
	**/
	// OpShl;

	/**
		`>>`
	**/
	// OpShr;

	/**
		`>>>`
	**/
	// OpUShr;

	/**
		`%`
	**/
	OpMod;

	/**
		`+=`
		`-=`
		`/=`
		`*=`
		`<<=`
		`>>=`
		`>>>=`
		`|=`
		`&=`
		`^=`
		`%=`
	**/
	OpAssignOp( op : Binop );

	/**
		`..`
	**/
	OpInterval;
}


//Lexer
enum Keyword {
	KwdFunc; //TODO: implement functions
	KwdCnuf;

	
	KwdIf;
	KwdThen;
	KwdElse;
	KwdFi;

	KwdFor;
	KwdWhile;
	KwdDo;
	KwdOd;
	KwdTo;
	KwdDownto;
	KwdBreak; //TODO: break
	KwdContinue; //TODO: continue
	KwdRepeat;
	KwdUntil;

	KwdReturn;

	KwdTrue;
	KwdFalse;
}

enum Token {
	Kwd(k:Keyword);
	Const(c:Constant);
	Unop(op:Unop);
	Binop(op:Binop);
	// Comment(s:String);
	CommentLine(s:String);
	Semicolon;
	Dot; //TODO: implement dot access
	Comma; //TODO: use comma token?
	BkOpen;
	BkClose;
	//TODO: implement gauss brackets
	FloorOpen; //⌊
	FloorClose; //⌋
	//TODO: maybe ceil too?

	POpen;
	PClose;
	Eof;
}