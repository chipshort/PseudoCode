package pseudocode;

import pseudocode.Data;
import pseudocode.runtime.PseudoArray;

class Interpreter
{
    /** Contains all variables and their values **/
    public var memory = new Map<String, Dynamic>();

    public function new()
    {
    }

    /** Execute `code` **/
    public function execute(code : String) : Dynamic
    {
        var input = byte.ByteData.ofString(code);
        var parser = new pseudocode.PseudoParser(input, null);
        var parsed = parser.parseCode();
        trace(pseudocode.PseudoParser.toString(parsed));
        var result = eval(parsed);
        
        if (isSpecial(result)) {
            switch (result) {
                case VReturn(value):
                    return value;
                default:
                    throw "Invalid keyword: " + result;
            }
        }
        return result;
    }

    /**
        Internal function that takes an `expr`, evaluates it and returns the result.
        Some special return values are used. See SpecialValue for more information.
    **/
    function eval(expr : Expr) : Dynamic
    {
        var result : Dynamic = switch (expr) {
            case EBlock(exprs):
                for (e in exprs) {
                    var value = eval(e);
                    if (isSpecial(value))
                        return value;
                }
                null; //blocks do not return anything by default
            case EArray(e1, e2):
                switch [e1, e2] {
                    case [EConst(CIdent(name)), EBinop(OpInterval, start, end)]: //A[1..2]
                        if (!memory.exists(name)) {//if name does not exist, this is a declaration
                            memory[name] = new PArray(eval(start), eval(end));
                        }
                        else {
                            trace(expr);
                            throw "Interval access for arrays is not implemented (yet?)";
                        }
                        null;
                    case [_, _]: //Assume this is a normal array access, for example: A[2]
                        var array : PArray = eval(e1);
                        array[eval(e2)];
                }
            case EConst(const):
                switch (const) {
                    case CIdent(name):
                        memory[name];
                    case CFloat(f):
                        Std.parseFloat(f);
                    case CInt(i):
                        Std.parseInt(i);
                }
            case EBinop(op, e1, e2):
                switch (op) {
                    case OpAdd:
                        eval(e1) + eval(e2);
                    case OpAssign:
                        switch (e1) {
                            case EConst(CIdent(name)): //A <- 2
                                memory[name] = eval(e2);
                            case EArray(EConst(CIdent(name)), index): //A[1] <- 2
                                var array : PArray = memory[name];
                                array[eval(index)] = eval(e2);
                            case _:
                                throw 'Cannot assign to $e1';
                        }
                        null; //assignment is not an expression
                    case OpAnd:
                        eval(e1) & eval(e2);
                    case OpAssignOp(op):
                        throw "OpAssignOp not implemented yet";
                        null; //TODO: implement
                    case OpBoolAnd:
                        eval(e1) && eval(e2);
                    case OpBoolOr:
                        eval(e1) || eval(e2);
                    case OpDiv:
                        eval(e1) / eval(e2);
                    case OpEq:
                        eval(e1) == eval(e2);
                    case OpGte:
                        eval(e1) >= eval(e2);
                    case OpInterval:
                        throw 'Unexpected interval: $e1..$e2';
                    case OpGt:
                        eval(e1) > eval(e2);
                    case OpLt:
                        eval(e1) < eval(e2);
                    case OpMod:
                        eval(e1) % eval(e2);
                    case OpMult:
                        eval(e1) * eval(e2);
                    case OpNotEq:
                        eval(e1) != eval(e2);
                    case OpOr:
                        eval(e1) | eval(e2);
                    case OpLte:
                        eval(e1) <= eval(e2);
                    case OpSub:
                        eval(e1) - eval(e2);
                }
            case EReturn(value):
                if (value == null)
                    VReturn(null);
                else
                    VReturn(eval(value));
            case EBreak:
                VBreak;
            case EContinue:
                VContinue;
            case EFloor(expr):
                Math.floor(eval(expr));
            case EFor(id, start, end, body, up):
                var realId = eval(id);
                var i = memory[realId] = eval(start);
                var realEnd = eval(end);
                while (i <= realEnd) {
                    var val = eval(body);
                    if (isSpecial(val)) {
                        switch (val) {
                            case VReturn(_):
                                return val;
                            case VBreak:
                                break;
                            case VContinue:
                                continue;
                                //don't do anything here, as we will continue anyway
                        }
                    }

                    ++i;
                    ++memory[realId];
                }
                null;
            case EWhile(cond, body, normal):
                if (normal) {
                    while(eval(cond)) {
                        var val = eval(body);
                        if (isSpecial(val)) {
                            switch (val) {
                                case VReturn(_):
                                    return val;
                                case VBreak:
                                    break;
                                case VContinue:
                                    trace("test");
                                    continue;
                                    //don't do anything here, as we will continue anyway
                            }
                        }
                    }
                }
                else {
                    do {
                        var val = eval(body);
                        if (isSpecial(val)) {
                            switch (val) {
                                case VReturn(_):
                                    return val;
                                case VBreak:
                                    break;
                                case VContinue:
                                    continue;
                                    //don't do anything here, as we will continue anyway
                            }
                        }
                    } while(eval(cond));
                }
                null;
            case EIf(cond, body, elseBody):
                if (eval(cond)) {
                    var val = eval(body);
                    if (isSpecial(val)) return val;
                }
                else if (elseBody != null) {
                    var val = eval(elseBody);
                    if (isSpecial(val)) return val;
                }
                null;
            case EParenthesis(expr):
                eval(expr);
            case EUnop(op, post, expr):
                // switch (op) {
                //     case OpDecrement:
                //         if (post)
                //             (eval(expr) : DynamicBox).value--;
                //         else
                //             ++eval(expr);
                //     case _:
                //         null;
                // }
                null; //TODO: implement unop
        }

        return result;
    }

    static inline function isReturn(v : Dynamic) : Bool
    {
        return isSpecial(v) && (v : SpecialValue).match(VReturn(_));
    }

    static inline function isSpecial(v : Dynamic) : Bool
    {
        return v != null && Std.is(v, SpecialValue);
    }
}

class DynamicBox
{
    //TODO: this concept is flawed, because a variable could be decremented / incremented multiple times
    public var value : Dynamic;

    public function new(v : Dynamic)
        value = v;
    
    public function postDecrement() {
        var v = value;
        --value;
        return new DynamicBox(v);
    }

    public function postIncrement() {
        var v = value;
        ++value;
        return new DynamicBox(v);
    }

    public function preIncrement() {
        ++value;
        return this;
    }

    public function preDecrement() {
        ++value;
        return this;
    }
}

/**
    Special return values.
    These are used to pass information up the recursion tree of the eval function.
    For example: If a EReturn is encountered, it is immediately evaluated and returned.
**/
enum SpecialValue {
    VReturn(?value : Dynamic);
    VBreak;
    VContinue;
}