package pseudocode;

import hxparse.Parser.parse as parse;
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

	public function parseCode() : ExprDef
	{
		return parseExpr();
	}

	function parseExpr() : ExprDef
	{
		return switch stream {
			//, body = parseUntilOr(Kwd(KwdFi), Kwd(KwdElse)) // TODO parse body
			case [Kwd(KwdIf), cond = parseExprList(), Kwd(KwdThen), body = parseExprList(), Kwd(KwdFi)]:
				trace(cond);
				EIf(cond[0], e(EBlock(body)), {expr: null, pos: null});
			case [Const(c)]:
				parseNextExpr(EConst(c));
		}
	}

	function parseExprList()
	{
		var list = new Array<Expr>();
		try {
			while (true) {
				list.push(e(parseExpr()));
			}
		}
		catch (a : Dynamic) {
		}

		return list;
	}

	function parseNextExpr(e : ExprDef) : ExprDef
	{
		return switch stream {
			case [Binop(op), next = parseExpr()]:
				trace(e);
				trace(op);
				trace(next);
				makeBinop(op, e, next);
		}
	}

	function makeBinop(op : haxe.macro.Expr.Binop, e1 : ExprDef, e2 : ExprDef) : ExprDef
	{
		return EBinop(op, e(e1), e(e2));
	}

	function e(e : ExprDef)
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