package pseudocode;

import pseudocode.Data;
import pseudocode.runtime.PseudoArray;

class Interpreter
{
    /** Contains all variables and their values **/
    public var stack = new util.Stack<Map<String, Dynamic>>();

    public var classes = new Map<String, Map<String, Dynamic>>();

    public function new()
    {
        stack.push(new Map<String, Dynamic>());
        set("true", true);
        set("false", false);
        set("NULL", null);
        set("trace", function (args) { Sys.println(args[1]); });
    }

    /**
        Execute `code`
    **/
    public function execute(code : String) : Dynamic
    {
        var input = byte.ByteData.ofString(code);
        var parser = new pseudocode.PseudoParser(input, null);
        var parsed = parser.parseCode();
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
        Gets the value of `field`.
        This looks for the "nearest" stack that contains `field`.
    **/
    function get(field : String) : Dynamic
    {
        var map = stack.findFirst(function (map) {
            return map.exists(field);
        });

        if (map == null)
            return null;

        return map[field];
    }

    /**
        Sets the value of `field` to `value`.
        This looks for the "nearest" stack that contains `field`.
        If `field` already exists, it is overwritten,
        otherwise field is declared in the current stack.
    **/
    function set(field : String, value : Dynamic) : Void
    {
        var map = stack.findFirst(function (map) {
            return map.exists(field);
        });

        if (map == null)
            map = stack.peek();

        if (map == null) {
            map = new Map<String, Dynamic>();
            stack.push(map);
        }

        map[field] = value;
    }

    /**
        Sets the value of `field` in the current top stack to `value`
    **/
    function define(field : String, value : Dynamic) : Void
    {
        stack.peek()[field] = value;
    }

    /**
        Internal function that takes an `expr`, evaluates it and returns the result.
        Some special return values are used. See SpecialValue for more information.
    **/
    function eval(expr : Expr) : Dynamic
    {
        var result : Dynamic = switch (expr) {
            case EFunc(name, args, body):
                define(name, createPseudoFunction(name, args, body));
                null;
            case EClass(name, body):
                var cls = new Map<String, Dynamic>();
                for (decl in body) {
                    switch (decl) {
                        case EConst(CIdent(variable)):
                            cls.set(variable, null);
                        case EFunc(n, args, body):
                            cls.set(n, createPseudoFunction(name + "." + n, args, body));
                        case _:
                            throw "You cannot declare " + decl + " in a class.";
                    }
                }
                classes.set(name, cls);
                null;
            case ENew(cls):
                var obj = {};

                var clazz = classes.get(cls);
                if (clazz == null)
                    throw "Cannot create an instance of " + cls + " - class not found";
                
                for (field in clazz.keys())
                    Reflect.setField(obj, field, clazz.get(field)); //TODO: find out if classes can have functions in them, if yes, scoping is needed
                
                obj;
            case ECall(e, args):
                var evalArgs = new Array<Dynamic>();

                var func = switch (e) {
                    case EField(e1, field):
                        var obj = eval(e1);
                        evalArgs.push(obj); //object as first argument
                        Reflect.getProperty(obj, field);
                    default:
                        evalArgs.push(null);
                        eval(e);
                }
                
                for (arg in args)
                    evalArgs.push(eval(arg));
                
                func(evalArgs); //.(eval(e), args);
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
                        // if (!memory.exists(name)) {//if name does not exist, this is a declaration
                            define(name, new PArray(eval(start), eval(end)));
                        // }
                        // else {
                        //     throw "Interval access for arrays is not implemented (yet?)";
                        // }
                        null;
                    case [_, _]: //Assume this is a normal array access, for example: A[2]
                        var array : PArray = eval(e1);
                        array[eval(e2)];
                }
            case EConst(const):
                switch (const) {
                    case CIdent(name):
                        get(name);
                    case CFloat(f):
                        Std.parseFloat(f);
                    case CInt(i):
                        Std.parseInt(i);
                }
            case EField(e1, field):
                Reflect.getProperty(eval(e1), field);
            case EBinop(op, e1, e2):
                switch (op) {
                    case OpAdd:
                        eval(e1) + eval(e2);
                    case OpAssign:
                        switch (e1) {
                            case EConst(CIdent(name)): //A <- 2
                                set(name, eval(e2));
                            case EArray(EConst(CIdent(name)), index): //A[1] <- 2
                                var array : PArray = get(name);
                                array[eval(index)] = eval(e2);
                            case EField(e, field):
                                Reflect.setProperty(eval(e),field, eval(e2));
                            case _:
                                throw 'Cannot assign to $e1';
                        }
                        null; //assignment is not an expression
                    case OpAnd:
                        eval(e1) & eval(e2);
                    case OpAssignOp(op):
                        eval(EBinop(OpAssign, e1, EBinop(op, e1, e2)));
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
                stack.push(new Map<String, Dynamic>());
                
                var realId = switch (id) {
                    case EConst(CIdent(realId)):
                        realId;
                    case _:
                        throw "For statement not parsed correctly";
                }
                var i = eval(start);
                define(realId, i);
                //var i = memory[realId] = eval(start);
                var realEnd = eval(end);

                if (up) {
                    while (i <= realEnd) {
                        var val = eval(body);
                        if (isSpecial(val)) {
                            switch (val) {
                                case VReturn(_):
                                    stack.pop();
                                    return val;
                                case VBreak:
                                    break;
                                case VContinue:
                                    //don't do anything here, as we will continue anyway
                            }
                        }

                        i = get(realId) + 1;
                        set(realId, i);
                    }
                }
                else {
                    while (i >= realEnd) {
                        var val = eval(body);
                        if (isSpecial(val)) {
                            switch (val) {
                                case VReturn(_):
                                    stack.pop();
                                    return val;
                                case VBreak:
                                    break;
                                case VContinue:
                                    //don't do anything here, as we will continue anyway
                            }
                        }

                        i = Std.int(get(realId) - 1);
                        set(realId, i);
                    }
                }
                
                stack.pop();
                null;
            case EWhile(cond, body, normal):
                stack.push(new Map<String, Dynamic>());
                if (normal) {
                    while(eval(cond)) {
                        var val = eval(body);
                        if (isSpecial(val)) {
                            switch (val) {
                                case VReturn(_):
                                    stack.pop();
                                    return val;
                                case VBreak:
                                    break;
                                case VContinue:
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
                                    stack.pop();
                                    return val;
                                case VBreak:
                                    break;
                                case VContinue:
                                    //don't do anything here, as we will continue anyway
                            }
                        }
                    } while(eval(cond));
                }
                stack.pop();
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
                switch (op) {
                    case OpDecrement:
                        var current = 0;
                        switch (expr) {
                            case EConst(CIdent(name)):
                                var v = get(name);
                                set(name, v - 1);

                                if (post)
                                    v;
                                else
                                    v - 1;
                            case EField(e1, field):
                                var obj = eval(e1);
                                current = Reflect.getProperty(obj, field);
                                if (post) {
                                    Reflect.setProperty(obj, field, current - 1);
                                    current;
                                }
                                else {
                                    Reflect.setProperty(obj, field, current - 1);
                                    current - 1;
                                }
                            case _:
                                throw "Cannot decrement " + expr;
                        }
                    case OpIncrement:
                        var current = 0;
                        switch (expr) {
                            case EConst(CIdent(name)):
                                var v = get(name);
                                set(name, v + 1);

                                if (post)
                                    v;
                                else
                                    v + 1;
                            case EField(e1, field):
                                var obj = eval(e1);
                                current = Reflect.getProperty(obj, field);
                                if (post) {
                                    Reflect.setProperty(obj, field, current + 1);
                                    current;
                                }
                                else {
                                    Reflect.setProperty(obj, field, current + 1);
                                    current + 1;
                                }
                            case _:
                                throw "Cannot increment " + expr;
                        }
                    case OpNeg:
                        -eval(expr);
                    case OpNot:
                        !eval(expr);
                    case OpNegBits:
                        ~eval(expr);
                }
        }

        return result;
    }

    function createPseudoFunction(name : String, args : Array<Dynamic>, body : Expr)
    {
        return function (arguments : Array<Dynamic>) {
             if (arguments.length != args.length + 1) //`this` as first argument
                throw 'Cannot call $name with ${args.length} arguments';

            var thizMap = new Map<String, Dynamic>();
            var thiz = arguments[0];
            for (field in Reflect.fields(thiz))
                thizMap[field] = Reflect.field(thiz, field);

            stack.push(thizMap);
            
            var s = new Map<String, Dynamic>();
            for (i in 0...args.length)
                s[args[i]] = arguments[i + 1];

            stack.push(s);

            var ret = eval(body);

            for (field in thizMap.keys())
                Reflect.setField(thiz, field, thizMap[field]);

            stack.pop();
            stack.pop();

            if (isSpecial(ret)) {
                switch (ret) {
                    case VReturn(v):
                        return v;
                    case _:
                        throw '$ret is not valid in this context';
                }
            }

            return null;
        }
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