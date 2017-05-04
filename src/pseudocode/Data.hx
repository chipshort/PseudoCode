package pseudocode;

import haxe.macro.Expr;

enum Keyword {
	KwdFunc;
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
	KwdDownTo;
	KwdBreak;
	KwdContinue;

	KwdReturn;

	KwdTrue;
	KwdFalse;
}

enum Token {
	Kwd(k:Keyword);
	Const(c:Constant);
	Sharp(s:String);
	Dollar(s:String);
	Unop(op:haxe.macro.Expr.Unop);
	Binop(op:haxe.macro.Expr.Binop);
	Comment(s:String);
	CommentLine(s:String);
	IntInterval;
	Semicolon;
	Dot;
	Arrow; //<-
	Comma;
	BkOpen;
	BkClose;
	BrOpen;
	BrClose;
	POpen;
	PClose;
	Question;
	At;
	Eof;
}