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
	KwdRepeat;
	KwdUntil;

	KwdReturn; //TODO: implement

	KwdTrue;
	KwdFalse;
}

enum Token {
	Kwd(k:Keyword);
	Const(c:Constant);
	Unop(op:haxe.macro.Expr.Unop);
	Binop(op:haxe.macro.Expr.Binop);
	Comment(s:String);
	CommentLine(s:String);
	Semicolon;
	Dot;
	Comma;
	BkOpen;
	BkClose;
	//TODO: implement gauss brackets
	FloorOpen;
	FloorClose;

	//TODO: implement ()
	POpen;
	PClose;
	Eof;
}