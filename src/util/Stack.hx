package util;

class Stack<T>
{
    var top : StackElem<T>;

    public function new()
    {
    }

    public function push(x : T) : Void
    {
        var elem = new StackElem(x);
        elem.prev = top;
        
        top = elem;
    }

    public function pop() : T
    {
        if (top == null)
            return null;
        
        var val = top.value;
        top = top.prev;
        return val;
    }

    public function peek() : T
    {
        if (top == null)
            return null;
        
        return top.value;
    }

    public function findFirst(func : T->Bool) : T
    {
        var elem = top;
        while (elem != null) {
            if (func(elem.value))
                return elem.value;
            elem = elem.prev;
        }

        return null;
    }

    public function toString() : String
    {
        if (top == null) return "[]";
        return "[" + top.toString() + "]";
    }
}

class StackElem<T>
{
    public var value : T;
    public var prev : StackElem<T>;

    public function new(v : T)
    {
        value = v;
    }

    public function toString() : String
    {
        return (value != null ? valToString() : "null") + (prev != null ? ", " + prev.toString() : "");
    }

    function valToString() : String
    {
        var str = new Array<String>();
        var v = cast(value, Map<String, Dynamic>);
        for (key in v.keys()) {
            str.push(key + " => " + v.get(key));
        }
        return "[" + str.join(", ") + "]";
    }
}