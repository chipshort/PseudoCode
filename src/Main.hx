class Main
{
    static function main() : Void
    {
        var interp = new pseudocode.Interpreter();
        trace(interp.execute("i <- 3 % 2 + 2; return i;")); // 3

        var interp = new pseudocode.Interpreter();
        trace(interp.execute("A[1..2]; A[1] <- 3; return A[1];")); // 3

        var interp = new pseudocode.Interpreter();
        trace(interp.execute("if w2 then return 1; else return 0; fi")); // 0

        var interp = new pseudocode.Interpreter();
        trace(interp.execute("
        x <- 6;
        n <- 5;
        A[1..n];
        A[1] <- 1;
        A[2] <- 2;
        A[3] <- 3;
        A[4] <- 4;
        A[5] <- 5;

        i <- 1;
        while i ≤ n ∧ A[i] ≠ x do
            i <- i + 1;
        od
        if i > n then i <- 0; fi

        return i;
        ")); //0

        runTests("tests");
    }

    static function runTests(folder : String) : Void
    {
        var testCases = readTests(folder);
        var failCounter = 0;

        for (test in testCases) {
            var input = byte.ByteData.ofString(test.code);
            var parser = new pseudocode.PseudoParser(input, test.file);

            var lexer = new pseudocode.PseudoLexer(input, test.file);
            
            var expr = try {
                parser.parseCode();
            }
            catch (e : Dynamic) {
                failCounter++;
                Sys.println('=== ${test.file} ===');

                Sys.println("--- Code ---");
                Sys.println(test.code);
                Sys.println("--- Tokens ---");
                var token = lexer.token(pseudocode.PseudoLexer.tok);
                while (token != Eof) {
                    Sys.println(token);
                    token = lexer.token(pseudocode.PseudoLexer.tok);
                }
                Sys.println("--- could not be parsed: ---");
                neko.Lib.rethrow(e);
            }
            
            var result = pseudocode.PseudoParser.toString(expr);

            test.expected = '{ ${test.expected} }';

            if (result != test.expected) {
                failCounter++;
                Sys.println('=== ${test.file} ===');

                Sys.println("--- Code ---");
                Sys.println(test.code);
                Sys.println("-- was parsed to --");
                Sys.println(result);
                Sys.println("-- raw expressions --");
                Sys.println(expr);
                Sys.println("-- but should be --");
                Sys.println(test.expected);

                Sys.println("--- Tokens ---");
                var token = lexer.token(pseudocode.PseudoLexer.tok);
                while (token != Eof) {
                    Sys.println(token);
                    token = lexer.token(pseudocode.PseudoLexer.tok);
                }

                Sys.println('=== End of ${test.file} ===');
                Sys.println("");
            }
        }

        if (failCounter != 0)
            Sys.println('$failCounter of ${testCases.length} tests failed ✗');
        else
            Sys.println('All ${testCases.length} tests succeeded ✓');
    }

    static function readTests(folder : String) : Array<Test>
    {
        var tests = new Array<Test>();

        for (file in sys.FileSystem.readDirectory(folder)) {
            var fullFile = haxe.io.Path.join([folder, file]);

            if (sys.FileSystem.isDirectory(fullFile)) {
                tests = tests.concat(readTests(fullFile));
            }
            else {
                var content = haxe.Json.parse(sys.io.File.getContent(fullFile));
                content.file = fullFile;
                tests.push(content);
            }
        }

        return tests;
    }
}

typedef Test = {
    code : String,
    expected : String,
    file : String
}
