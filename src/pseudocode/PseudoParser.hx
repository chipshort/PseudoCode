package pseudocode;

import hxparse.Unexpected;
import hxparse.LexerTokenSource;
import hxparse.Parser;
import hxparse.ParserBuilder;
import pseudocode.PseudoLexer;
import pseudocode.Data;

class PseudoParser extends Parser<LexerTokenSource<Token>, Token> implements ParserBuilder
{
	var canBreak = new Array<Bool>();

    public function new(input:byte.ByteData, sourceName:String) {
		var lexer = new PseudoLexer(input, sourceName);
		var ts = new LexerTokenSource(lexer, PseudoLexer.tok);
		super(ts);
    }

	public function parseCode() : Expr
	{
		return EBlock(parseTopLevelList());
	}

	function parseExpr() : Expr
	{
		return switch stream {
			case [Unop(op), expr = parseExpr()]:
				if (op == OpIncrement || op == OpDecrement) {
					switch (expr) {
						case EConst(CIdent(_)) | EField(_, _): //increment and decrement only allowed on field or identifier
							EUnop(op, false, expr);
						case _:
							throw "Cannot increment / decrement " + expr;
					}
				}
				else {
					EUnop(op, false, expr);
				}
			case [FloorOpen, expr = parseExpr(), FloorClose]:
				parseNext(EFloor(expr));
			case [POpen, expr = parseExpr(), PClose]:
				parseNext(EParenthesis(expr));
			case [Kwd(KwdTrue)]:
				EConst(CIdent("true"));
			case [Kwd(KwdFalse)]:
				EConst(CIdent("false"));
			case [Const(c)]:
				parseNext(EConst(c));
			case [CommentLine(_)]:
				parseExpr();
		};
	}

	function parseStatementList(stop : Token->Bool)
	{
		var list = new Array<Expr>();

		while (!stop(peek(0))) {
			switch stream {
				case [statement = parseStatement()]:
					if (statement != null)
						list.push(statement);
				case _:
					unexpected();
					// return list;
			}
		}

		return list;
	}

	function parseTopLevelList()
	{
		var list = new Array<Expr>();

		while (!isEof(peek(0))) {
			switch stream {
				case [declaration = parseDeclaration()]:
					list.push(declaration);
				case [statement = parseStatement()]:
					if (statement != null)
						list.push(statement);
				case _:
					unexpected();
					// return list;
			}
		}

		return list;
	}

	static function isFiOrElse(t : Token) : Bool
		return t.match(Kwd(KwdFi) | Kwd(KwdElse));

	static function isFi(t : Token) : Bool
		return t.match(Kwd(KwdFi));

	static function isEof(t : Token) : Bool
		return t.match(Eof);
	
	static function isElse(t : Token) : Bool
		return t.match(Kwd(KwdElse));
	
	static function isOd(t : Token) : Bool
		return t.match(Kwd(KwdOd));

	static function isUntil(t : Token) : Bool
		return t.match(Kwd(KwdUntil));
	
	static function isCnuf(t : Token) : Bool
		return t.match(Kwd(KwdCnuf));

	function parseDeclaration() : Expr
	{
		return switch stream {
			case [Kwd(KwdFunc), Const(CIdent(name)), POpen, args = parseSeparated(argSeperator, parseArgDef), PClose, body = parseStatementList(isCnuf), Kwd(KwdCnuf)]:
				EFunc(name, args, EBlock(body));

		}
	}

	function argSeperator(token : Token) : Bool
	{
		return token == Comma;
	}

	function parseArgDef() : String
	{
		return switch stream {
			case [Const(CIdent(name))]:
				name;
		}
	}

	function parseStatement() : Expr
	{
		return switch stream {
			//TODO: make OpAssign and OpAssignOp statements
			case [Kwd(KwdContinue), Semicolon]:
				if (canBreak.length == 0)
					throw new Unexpected(Kwd(KwdContinue), stream.curPos());
				
				EContinue;
			case [Kwd(KwdBreak), Semicolon]:
				if (canBreak.length == 0)
					throw new Unexpected(Kwd(KwdBreak), stream.curPos());
				
				EBreak;
			case [Kwd(KwdIf), cond = parseExpr(), Kwd(KwdThen)]: //read if statement until then
				switch stream {
					case [body = parseStatementList(isFiOrElse)]: //found a fi or an else
						switch stream {
							case [Kwd(KwdFi)]: //it was a fi
								EIf(cond, EBlock(body), null);
							case [Kwd(KwdElse), elseBody = parseStatementList(isFi), Kwd(KwdFi)]: //was an else
								EIf(cond, EBlock(body), EBlock(elseBody));
						}
					case _:
						unexpected();
				}
			case [Kwd(KwdFor), decl = parseExpr(), Kwd(to = KwdTo | KwdDownto), end = parseExpr(), Kwd(KwdDo), _ = canBreak.push(true), body = parseStatementList(isOd), Kwd(KwdOd)]:
				canBreak.pop();
				var id = null;
				var begin = null;
				switch (decl) {
					case EBinop(OpEq, identifier, start):
						id = identifier;
						begin = start;
					case _:
						unexpected();
				}
				EFor(id, begin, end, EBlock(body), to == KwdTo);
			case [Kwd(KwdWhile), cond = parseExpr(), Kwd(KwdDo), _ = canBreak.push(true), body = parseStatementList(isOd), _ = canBreak.pop(), Kwd(KwdOd)]:
				EWhile(cond, EBlock(body), true);
			case [Kwd(KwdRepeat), _ = canBreak.push(true), body = parseStatementList(isUntil), _ = canBreak.pop(), Kwd(KwdUntil), until = parseStatement()]:
				var cond = EUnop(OpNot, false, until);
				EWhile(EBlock(body), cond, false);
			case [CommentLine(_)]:
				parseOptional(parseStatement);
			case [Kwd(KwdReturn)]:
				switch stream {
					case [Semicolon]:
						EReturn();
					case [value = parseExpr(), Semicolon]:
						EReturn(value);
					case _:
						unexpected();
				}
			case [expr = parseExpr(), Semicolon] if (expr != null): //expressions become statements when a semicolon is attached
				expr;
			}
	}

	function parseNext(expr : Expr) : Expr
	{
		return switch stream {
			case [Dot]:
				switch stream {
					case [Const(CIdent(f))]:
						parseNext(EField(expr, f));
					case _:
						unexpected();
				}
			case [Unop(op)]:
				if (op == OpIncrement || op == OpDecrement) {
					switch (expr) {
						case EConst(CIdent(_)) | EField(_, _): //increment and decrement only allowed on field or identifier
							EUnop(op, true, expr);
						case _:
							throw "Cannot increment / decrement " + expr;
					}
				}
				else {
					EUnop(op, true, expr);
				}
			case [Binop(op), next = parseExpr()]: //binary operators
				//I'm pretty sure OpAssign and OpAssignOp should not be expressions, but statements.
				makeBinop(op, expr, next);
			case [BkOpen, interval = parseExpr(), BkClose]: //Array access / creation
				parseNext(EArray(expr, interval));
			case [POpen, args = parseSeparated(argSeperator, parseExpr), PClose]:
				//function call
				ECall(expr, args);
			case _:
				expr;
		}
	}

	function makeBinop(op : Binop, e1 : Expr, e2 : Expr) : Expr
	{
		return switch (e2) {
			case EBinop(_op, _e, _e2) if (mustSwap(op, _op)):
				var swapped = makeBinop(op, e1, _e);
				EBinop(_op, swapped, _e2);
			case _:
				EBinop(op, e1, e2);
		}
	}

	static function operatorPrecedence(op : Binop)
	{
		return switch (op) {
			case OpMult | OpDiv | OpMod: {p: 12, left: true};
			case OpAdd | OpSub : {p: 11, left: true};
			// case OpShl | OpShr | OpUShr : {p: 10, left: true};
			case OpGt | OpLt | OpGte | OpLte: {p: 9, left: true};
			case OpEq | OpNotEq: {p: 8, left: true};
			case OpAnd: {p: 7, left: true};
			// case OpXor: {p: 6, left: true};
			case OpOr : {p: 5, left: true};
			case OpBoolAnd : {p: 4, left: true};
			case OpBoolOr : {p: 3, left: true};
			case OpInterval : {p: 1, left: true};
			case OpAssign | OpAssignOp(_) : {p: 1, left: false};
		}
	}

	public static function statementsToString(statements : Array<Expr>) : String
	{
		return toString(EBlock(statements));
	}

	public static function toString(expr : Expr) : String
	{
		if (expr == null) return null;

		return switch (expr) {
			case EBlock(exprs):
				var str = new Array<String>();
				str.push("{");
				for (ex in exprs)
					str.push('${toString(ex)};');
				
				str.push("}");
				
				str.join(" ");
			case EField(e, field):
				'${toString(e)}.$field';
			case EFunc(name, args, body):
				'func $name($args) ${toString(body)}';
			case ECall(e, args):
				var str = new Array<String>();
				for (arg in args)
					str.push(toString(arg));

				'${toString(e)}(${str.join(", ")})';
			case EFloor(e):
				'FLOOR($e)';
			case EReturn(e):
				if (e != null)
					'return ${toString(e)}';
				else
					'return';
			case EFor(id, begin, end, body, up):
				'for (${toString(id)} <- ${toString(begin)} ${up ? "to" : "downto"} ${toString(end)}) ${toString(body)}';
			case EParenthesis(e):
				'(${toString(e)})';
			case EWhile(cond, e, false):
				'do ${toString(cond)} while ${toString(e)}';
			case EWhile(cond, e, true):
				'while ${toString(cond)} ${toString(e)}';
			case EUnop(op, false, e):
				'($op ${toString(e)})';
			case EUnop(op, true, e):
				'(${toString(e)} $op)';
			case EBinop(OpInterval, e1, e2):
				toString(e1) + ".." + toString(e2);
			case EBinop(op, e1, e2):
				'(${toString(e1)} $op ${toString(e2)})';
			case EConst(c):
				switch (c) {
					case CFloat(i) | CIdent(i) | CInt(i):
						i;
				}
			case EArray(e1, e2):
				'${toString(e1)}[${toString(e2)}]';
			case EIf(cond, eif, eelse):
				'if ${toString(cond)} ${toString(eif)}' + (eelse != null ? ' else ${toString(eelse)}' : '');
			case EBreak:
				"break";
			case EContinue:
				"continue";
		}
	}

	function mustSwap(op1 : Binop, op2 : Binop) : Bool
	{
		var prec1 = operatorPrecedence(op1);
		var prec2 = operatorPrecedence(op2);
		return prec1.left && prec1.p >= prec2.p;
	}
}