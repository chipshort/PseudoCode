package pseudocode;

import pseudocode.Data;
import pseudocode.runtime.PseudoArray;

class Interpreter
{
    var memory = new Map<String, Dynamic>();

    public function new()
    {
        
    }

    public function execute(code : String, ?file : String) : Dynamic
    {
        var input = byte.ByteData.ofString(code);
        var parser = new pseudocode.PseudoParser(input, file);
        var parsed = parser.parseCode();

        var result = exec(parsed);
        
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

    function exec(expr : Expr) : Dynamic
    {
        var result : Dynamic = switch (expr) {
            case EBlock(exprs):
                for (e in exprs) {
                    var value = exec(e);
                    if (isSpecial(value))
                        return value;
                }
                null; //blocks do not return anything by default
            case EArray(e1, e2):
                switch [e1, e2] {
                    case [EConst(CIdent(name)), EBinop(OpInterval, start, end)]: //A[1..2]
                        if (!memory.exists(name)) {//if name does not exist, this is a declaration
                            memory[name] = new PArray(exec(start), exec(end));
                        }
                        else {
                            trace(expr);
                            throw "Interval access for arrays is not implemented (yet?)";
                        }
                        null;
                    case [_, _]: //Assume this is a normal array access, for example: A[2]
                        var array : PArray = exec(e1);
                        array[exec(e2)];
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
                        exec(e1) + exec(e2);
                    case OpAssign:
                        switch (e1) {
                            case EConst(CIdent(name)): //A <- 2
                                memory[name] = exec(e2);
                            case EArray(EConst(CIdent(name)), index): //A[1] <- 2
                                var array : PArray = memory[name];
                                array[exec(index)] = exec(e2);
                            case _:
                                throw 'Cannot assign to $e1';
                        }
                        null; //assignment is not an expression
                    case OpAnd:
                        exec(e1) & exec(e2);
                    case OpAssignOp(op):
                        throw "OpAssignOp not implemented yet";
                        null; //TODO: implement
                    case OpBoolAnd:
                        exec(e1) && exec(e2);
                    case OpBoolOr:
                        exec(e1) || exec(e2);
                    case OpDiv:
                        exec(e1) / exec(e2);
                    case OpEq:
                        exec(e1) == exec(e2);
                    case OpGte:
                        exec(e1) >= exec(e2);
                    case OpInterval:
                        throw 'Unexpected interval: $e1..$e2';
                    case OpGt:
                        exec(e1) > exec(e2);
                    case OpLt:
                        exec(e1) < exec(e2);
                    case OpMod:
                        exec(e1) % exec(e2);
                    case OpMult:
                        exec(e1) * exec(e2);
                    case OpNotEq:
                        exec(e1) != exec(e2);
                    case OpOr:
                        exec(e1) | exec(e2);
                    case OpLte:
                        exec(e1) <= exec(e2);
                    case OpSub:
                        exec(e1) - exec(e2);
                }
            case EReturn(value):
                if (value == null)
                    null;
                else
                    VReturn(exec(value));
            case EBreak:
                //TODO: implement break
                null;
            case EContinue:
                //TODO: implement continue
                null;
            case EFloor(expr):
                //TODO: implement floor
                Math.floor(exec(expr));
            case EFor(id, start, end, body, up):
                var realId = exec(id);
                var i = memory[realId] = exec(start);
                var realEnd = exec(end);
                while (i <= realEnd) {
                    var val = exec(body);
                    if (isReturn(val)) return val;

                    ++i;
                    ++memory[realId];
                }
                null;
            case EWhile(cond, body, normal):
                if (normal) {
                    while(exec(cond)) {
                        var val = exec(body);
                        if (isReturn(val)) return val;
                    }
                }
                else {
                    do {
                        var val = exec(body);
                        if (isReturn(val)) return val;
                    } while(exec(cond));
                }
                null;
            case EIf(cond, body, elseBody):
                if (exec(cond)) {
                    var val = exec(body);
                    if (isSpecial(val)) return val;
                }
                else if (elseBody != null) {
                    var val = exec(elseBody);
                    if (isSpecial(val)) return val;
                }
                null;
            case EParenthesis(expr):
                exec(expr);
            case EUnop(op, post, expr):
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

enum SpecialValue {
    VReturn(?value : Dynamic);
    // VBreak;
    // VContinue;
}