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
		return parseExprList(Eof);
	}

	function parseExpr() : ExprDef
	{
		return switch stream {
			//, body = parseUntilOr(Kwd(KwdFi), Kwd(KwdElse)) // TODO parse body
			case [Kwd(KwdIf), cond = parseExpr(), Kwd(KwdThen), body = tryParseExprList(Eof)]: //using Eof as stub, some weird shit going on here
				switch stream {
					case [Kwd(KwdFi)]:
						EIf(e(cond), e(EBlock(body)), null);
					case [Kwd(KwdElse), elseBody = tryParseExprList(Kwd(KwdFi)), Kwd(KwdFi)]:
						EIf(e(cond), e(EBlock(body)), e(EBlock(elseBody)));
				}
			case [Const(c)]:
				tryParseNext(EConst(c));
			case [Semicolon | CommentLine(_)]:
				null;
		};
	}

	function tryParseExprList(stop : Token)
	{
		var list = new Array<Expr>();
		try {
			while (peek(0) != stop) {
				switch stream {
					case [expr = parseExpr()]:
						if (expr != null)
							list.push(e(expr));
				}
			}
		}
		catch (e : hxparse.NoMatch<Dynamic>) {
			
		}

		return list;
	}

	function parseExprList(stop : Token)
	{
		var list = new Array<Expr>();
		while (peek(0) != stop) {
			switch stream {
				case [Semicolon]:
				case [expr = parseExpr()]:
					if (expr != null)
						list.push(e(expr));
			}
		}

		return list;
	}

	function tryParseNext(e : ExprDef) : ExprDef
	{
		try {
			return parseNext(e);
		}
		catch (e : hxparse.NoMatch<Dynamic>) {}

		return e;
	}

	function parseNext(expr : ExprDef) : ExprDef
	{
		return switch stream {
			case [Binop(op), next = parseExpr()]: //binary operators
				makeBinop(op, expr, next);
			case [BkOpen, interval = parseExpr(), BkClose]: //Array access / creation
				EArray(e(expr), e(interval));
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
			case OpArrow : {p: 1, left: true};
			case OpAssign | OpAssignOp(_) : {p: 1, left: false};
		}
	}

	public static function toString(expr : ExprDef) : String
	{
		return switch (expr) {
			case EBlock(exprs):
				var str = new Array<String>();
				for (ex in exprs)
					str.push(toString(ex.expr) + ";");
				
				str.join(" ");
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
				'if ${toString(cond.expr)} then ${toString(eif.expr)}' + (eelse != null ? ' else ${toString(eelse.expr)}' : '') + ' fi';
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