package pseudocode;
import pseudocode.Data;
import hxparse.Lexer;

class PseudoLexer extends Lexer implements hxparse.RuleBuilder
{
    public static var tok = @:rule [
        "" => Eof,
        "[\r\n\t ]+" => {
			lexer.token(tok);
        },
        integer => Const(CInt(lexer.current)),
		integer + "\\.[0-9]+" => Const(CFloat(lexer.current)),
        "//[^\n\r]*" => CommentLine(lexer.current.substr(2)),
        "+\\+" => Unop(OpIncrement),
		"--" => Unop(OpDecrement),
		"~" => Unop(OpNegBits),
		"%=" => Binop(OpAssignOp(OpMod)),
		"&=" => Binop(OpAssignOp(OpAnd)),
		"|=" => Binop(OpAssignOp(OpOr)),
		"^=" => Binop(OpAssignOp(OpXor)),
		"+=" => Binop(OpAssignOp(OpAdd)),
		"-=" => Binop(OpAssignOp(OpSub)),
		"*=" => Binop(OpAssignOp(OpMult)),
		"/=" => Binop(OpAssignOp(OpDiv)),
		"<<=" => Binop(OpAssignOp(OpShl)),
		"≠" => Binop(OpNotEq),
		"<=" => Binop(OpLte),
		"∧" => Binop(OpBoolAnd), //unicode
		"∨" => Binop(OpBoolOr), //this is unicode, not a simple "∨"
		"<<" => Binop(OpShl),
        "<-" => Binop(OpAssign),
        "\\.\\." => Binop(OpInterval), //used for arrays
        "!" => Unop(OpNot),
		"<" => Binop(OpLt),
		">" => Binop(OpGt),
        ";" => Semicolon,
        "%" => Binop(OpMod),
		"&" => Binop(OpAnd),
		"|" => Binop(OpOr),
		"⊕" => Binop(OpXor),
		"+" => Binop(OpAdd),
		"*" => Binop(OpMult),
		"/" => Binop(OpDiv),
		"-" => Binop(OpSub),
		"=" => Binop(OpEq),
		"[" => BkOpen,
		"]" => BkClose,
		"\\(" => POpen,
        "\\)" => PClose,
        ident => {
			var kwd = keywords.get(lexer.current);
			if (kwd != null)
				Kwd(kwd);
			else
				Const(CIdent(lexer.current));
        },
    ];

    static var keywords = @:mapping(3) Data.Keyword;
    static var ident = "_*[a-zA-Z][a-zA-Z0-9_]*|_+|_+[0-9][_a-zA-Z0-9]*";
    static var integer = "([1-9][0-9]*)|0";
}