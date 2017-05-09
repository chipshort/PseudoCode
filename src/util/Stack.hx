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
        if (top == null) {
            top = elem;
        }
        else {
            elem.prev = top;
            top = elem; 
        }
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
        }

        return null;
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
}