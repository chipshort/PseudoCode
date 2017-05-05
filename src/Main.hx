class Main
{
    static function main() : Void
    {
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
