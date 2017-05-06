package pseudocode.runtime;

import haxe.ds.Vector;

class PseudoArray
{
    var values : Vector<Dynamic>;

    var first : Int;
    var last : Int;

    public function new(f : Int, l : Int)
    {
        first = f;
        last = l;

        if (last < first)
            throw 'Cannot create array of inverted bounds: [$f, $l]';

        values = new Vector<Dynamic>(last - first + 1);
    }

    public function get(i : Int) : Dynamic
    {
        return values.get(i - first);
    }

    public function set(i : Int, v : Dynamic) : Dynamic
    {
        values.set(i - first, v);
        return v;
    }


}

@:forward
abstract PArray(PseudoArray) {

    public inline function new(first : Int, last : Int)
    {
        this = new PseudoArray(first, last);
    }

    @:op([]) public inline function get(i : Int)
        return this.get(i);
    
    @:op([]) public inline function set(i : Int, v : Dynamic)
        return this.set(i, v);
}