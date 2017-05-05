package pseudocode;

import haxe.macro.Expr;
import pseudocode.PseudoLexer;
import pseudocode.Data;

class PseudoParser extends hxparse.Parser<PseudoTokenSource, Token> implements hxparse.ParserBuilder
{
    public function new(input:byte.ByteData, sourceName:String) {
		var lexer = new PseudoLexer(input, sourceName);
		var ts = new PseudoTokenSource(lexer);
		super(ts);
    }

	public function parseCode() : Array<Expr>
	{
		return parseStatementList(isEof);
	}

	function parseExpr() : ExprDef
	{
		return switch stream {
			case [POpen, expr = parseExpr(), PClose]:
				trace(expr);
				parseNext(EParenthesis(e(expr)));
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
					list.push(e(statement));
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

	function parseStatement()
	{
		return switch stream {
			//TODO: make OpAssign and OpAssignOp statements
			case [Kwd(KwdIf), cond = parseExpr(), Kwd(KwdThen)]: //read if statement until then
				switch stream {
					case [body = parseStatementList(isFiOrElse)]: //found a fi or an else
						switch stream {
							case [Kwd(KwdFi)]: //it was a fi
								EIf(e(cond), e(EBlock(body)), null);
							case [Kwd(KwdElse), elseBody = parseStatementList(isFi), Kwd(KwdFi)]: //was an else
								EIf(e(cond), e(EBlock(body)), e(EBlock(elseBody)));
						}
				}
			case [Kwd(KwdFor), decl = parseExpr(), Kwd(KwdTo), end = parseExpr(), Kwd(KwdDo), body = parseStatementList(isOd)]:
				var id = null;
				var begin = null;
				switch (decl) {
					case EBinop(OpEq, identifier, start):
						id = identifier;
						begin = start;
					case _:
						unexpected();
				}

				body.push(e(EUnop(OpIncrement, false, id)));
				EBlock([
					e(EBinop(OpAssign, id, begin)),
					e(EWhile(
						e(EBinop(OpLte, id, e(end))),
						e(EBlock(body)), true)
					)
				]);
			case [Kwd(KwdWhile), cond = parseExpr(), Kwd(KwdDo), body = parseStatementList(isOd), Kwd(KwdOd)]:
				EWhile(e(cond), e(EBlock(body)), true);
			case [Kwd(KwdRepeat), body = parseStatementList(isUntil), Kwd(KwdUntil), until = parseExpr()]:
				var cond = EUnop(OpNot, false, e(until));
				EWhile(e(EBlock(body)), e(cond), false);
			case [CommentLine(_)]:
				parseStatement();
			case [expr = parseExpr(), Semicolon] if (expr != null): //expressions become statements when a semicolon is attached
				expr;
			}
	}

	function parseNext(expr : ExprDef) : ExprDef
	{
		return switch stream {
			case [Binop(op), next = parseExpr()]: //binary operators
				//I'm pretty sure OpAssign and OpAssignOp should not be expressions, but statements.
				makeBinop(op, expr, next);
			case [BkOpen, interval = parseExpr(), BkClose]: //Array access / creation
				parseNext(EArray(e(expr), e(interval)));
			case _:
				expr;
		}
	}

	function makeBinop(op : haxe.macro.Expr.Binop, e1 : ExprDef, e2 : ExprDef) : ExprDef
	{
		return switch (e2) {
			case EBinop(_op, _e, _e2) if (mustSwap(op, _op)):
				var swapped = makeBinop(op, e1, _e.expr);
				EBinop(_op, e(swapped), _e2);
			case _:
				EBinop(op, e(e1), e(e2));
		}
	}

	static function operatorPrecedence(op : haxe.macro.Expr.Binop)
	{
		return switch (op) {
			case OpMult | OpDiv | OpMod: {p: 12, left: true};
			case OpAdd | OpSub : {p: 11, left: true};
			case OpShl | OpShr | OpUShr : {p: 10, left: true};
			case OpGt | OpLt | OpGte | OpLte: {p: 9, left: true};
			case OpEq | OpNotEq: {p: 8, left: true};
			case OpAnd: {p: 7, left: true};
			case OpXor: {p: 6, left: true};
			case OpOr : {p: 5, left: true};
			case OpBoolAnd : {p: 4, left: true};
			case OpBoolOr : {p: 3, left: true};
			case OpInterval : {p: 1, left: true};
			case OpArrow : {p: 1, left: true}; //unnecessary
			case OpAssign | OpAssignOp(_) : {p: 1, left: false};
		}
	}

	public static function statementsToString(statements : Array<Expr>) : String
	{
		return toString(EBlock(statements));
	}

	public static function toString(expr : ExprDef) : String
	{
		if (expr == null) return null;

		return switch (expr) {
			case EBlock(exprs):
				var str = new Array<String>();
				str.push("{");
				for (ex in exprs) {
					str.push('${toString(ex.expr)};');
				}
				str.push("}");
				
				str.join(" ");
			case EParenthesis(e):
				'(${toString(e.expr)})';
			case EWhile(cond, e, false):
				'do ${toString(cond.expr)} while ${toString(e.expr)}';
			case EWhile(cond, e, true):
				'while ${toString(cond.expr)} ${toString(e.expr)}';
			case EUnop(op, false, e):
				'($op ${toString(e.expr)})';
			case EUnop(op, true, e):
				'(${toString(e.expr)} $op)';
			case EBinop(OpInterval, e1, e2):
				toString(e1.expr) + ".." + toString(e2.expr);
			case EBinop(op, e1, e2):
				'(${toString(e1.expr)} $op ${toString(e2.expr)})';
			case EConst(CIdent(name)):
				name;
			case EConst(c):
				cast haxe.macro.ExprTools.getValue(e(expr));
			case EArray(e1, e2):
				'${toString(e1.expr)}[${toString(e2.expr)}]';
			case EIf(cond, eif, eelse):
				'if ${toString(cond.expr)} ${toString(eif.expr)}' + (eelse != null ? ' else ${toString(eelse.expr)}' : '');
			default:
				"";
		}
	}

	function mustSwap(op1 : haxe.macro.Expr.Binop, op2 : haxe.macro.Expr.Binop) : Bool
	{
		var prec1 = operatorPrecedence(op1);
		var prec2 = operatorPrecedence(op2);
		return prec1.left && prec1.p >= prec2.p;
	}

	static function e(e : ExprDef)
	{
		return {expr: e, pos: null};
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