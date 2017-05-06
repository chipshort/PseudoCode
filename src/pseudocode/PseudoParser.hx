package pseudocode;

import hxparse.Unexpected;
import pseudocode.PseudoLexer;
import pseudocode.Data;

class PseudoParser extends hxparse.Parser<PseudoTokenSource, Token> implements hxparse.ParserBuilder
{
	var canBreak = new Array<Bool>();

    public function new(input:byte.ByteData, sourceName:String) {
		var lexer = new PseudoLexer(input, sourceName);
		var ts = new PseudoTokenSource(lexer);
		super(ts);
    }

	public function parseCode() : Expr
	{
		return EBlock(parseStatementList(isEof));
	}

	function parseExpr() : Expr
	{
		return switch stream {
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
					list.push(statement);
				case _:
					return list;
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

	function parseStatement() : Expr
	{
		//TODO: implement break and continue and make sure they can only exist in while or for blocks
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
			case [Kwd(KwdFor), decl = parseExpr(), Kwd(to = KwdTo | KwdDownto), end = parseExpr(), Kwd(KwdDo), a = canBreak.push(true), body = parseStatementList(isOd)]:
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
			case [Kwd(KwdWhile), cond = parseExpr(), Kwd(KwdDo), a = canBreak.push(true), body = parseStatementList(isOd), b = canBreak.pop(), Kwd(KwdOd)]:
				EWhile(cond, EBlock(body), true);
			case [Kwd(KwdRepeat), a = canBreak.push(true), body = parseStatementList(isUntil), b = canBreak.pop(), Kwd(KwdUntil), until = parseExpr()]:
				var cond = EUnop(OpNot, false, until);
				EWhile(EBlock(body), cond, false);
			case [CommentLine(_)]:
				parseStatement();
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
			case [Binop(op), next = parseExpr()]: //binary operators
				//I'm pretty sure OpAssign and OpAssignOp should not be expressions, but statements.
				makeBinop(op, expr, next);
			case [BkOpen, interval = parseExpr(), BkClose]: //Array access / creation
				parseNext(EArray(expr, interval));
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
				for (ex in exprs) {
					str.push('${toString(ex)};');
				}
				str.push("}");
				
				str.join(" ");
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
			default:
				"";
		}
	}

	function mustSwap(op1 : Binop, op2 : Binop) : Bool
	{
		var prec1 = operatorPrecedence(op1);
		var prec2 = operatorPrecedence(op2);
		return prec1.left && prec1.p >= prec2.p;
	}
}


class PseudoTokenSource {
	var lexer:PseudoLexer;
	var rawSource:hxparse.LexerTokenSource<Token>;

	public function new(lexer : PseudoLexer) {
		this.lexer = lexer;
		this.rawSource = new hxparse.LexerTokenSource(lexer,PseudoLexer.tok);
	}

	public function token() : Token {
		return lexer.token(PseudoLexer.tok);
	}

	public function curPos() : hxparse.Position {
		return lexer.curPos();
	}
}