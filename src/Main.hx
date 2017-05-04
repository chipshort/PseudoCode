class Main
{
    static function main() : Void
    {
        // var test = [1, 2, 2, 2, 3, 3, 4, 5, 5, 10, 11];

        // for (i in 0 ... 6) {
        //     trace(i + " gefunden bei " + binarysearch(test, i));
        // }

        var input = byte.ByteData.ofString("if a < b then a fi");
        var lexer = new pseudocode.PseudoLexer(input, "Test.pc");
        var token = lexer.token(pseudocode.PseudoLexer.tok);

        var parser = new pseudocode.PseudoParser(input, "Test.pc");
        var expr = parser.parseCode();

        trace(expr);
        
        // while (token != Eof) {
        //     trace(token);
        //     token = lexer.token(pseudocode.PseudoLexer.tok);
        // }

        //trace("Hello, world!");
    }

    static function binarysearch(array : Array<Int>, x : Int) : Int
    {
        var l = 0;
        var r = array.length - 1;
        var back = -1;

        while (l <= r) {
            var m = Math.floor((l + r) / 2);
            //trace(l + " " + r + " " + m);
            if (array[m] == x)
                back = m;
            if (x > array[m])
                l = m + 1;
            else
                r = m - 1;
        }

        return back;
    }

    static function binaryTest(array : Array<Int>, x : Int) : Int
    {
        var l = 0;
        var r = array.length - 1;

        while (l <= r) {
            var m = Math.floor((l + r) / 2);
            //trace(l + " " + r + " " + m);
            if (array[m] == x) {
                return m;
            }
            if (x > array[m]) {
                l = m + 1;
            }
            else {
                r = m - 1;
            }
        }

        return -1;
    }
}
