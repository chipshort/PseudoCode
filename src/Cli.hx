class Cli
{
    static function main() : Void
    {
        var args = Sys.args();

        if (args.length == 0) {
            var path = #if neko
                "neko pseudocode.n"
            #elseif cpp
                "pseudocode"
            #elseif python
                "python pseudocode.py"
            #elseif lua
                "lua pseudocode.lua"
            #elseif cs
                "pseudocode"
            #elseif java
                "java -jar pseudocode.jar"
            #else
                ""
            #end;
            Sys.println('Usage: $path <FILE>\n       $path --tests to run tests');

            return;
        }

        if (args[0] == "--tests") { 
            runParserTests("tests/parser");
            runInterpTests("tests/interpreter");
        }
        else {
            var interpreter = new pseudocode.Interpreter();
            Sys.println("Output: " + interpreter.execute(sys.io.File.getContent(args[0])));
        }
    }

    static function runParserTests(folder : String) : Void
    {
        Sys.println('==== Running parser tests ====');
        var testCases = readParserTests(folder);
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
                #if neko
                neko.Lib.rethrow(e);
                #else
                throw e;
                #end
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

    static function runInterpTests(folder : String) : Void
    {
        Sys.println('==== Running interpreter tests ====');
        var testCases = readInterpTests(folder);
        var failCounter = 0;

        for (test in testCases) {
            var interp = new pseudocode.Interpreter();

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
                #if neko
                neko.Lib.rethrow(e);
                #else
                throw e;
                #end
            }
            
            var result = interp.execute(test.code);

            if (result != true) {
                failCounter++;
                Sys.println('=== ${test.file} ===');

                Sys.println("--- Code ---");
                Sys.println(test.code);
                Sys.println("-- returned --");
                Sys.println(result);
                Sys.println("-- raw expressions --");
                Sys.println(expr);

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

    inline static function readInterpTests(folder : String) : Array<InterpTest>
    {
        return parseFilesIn(folder, function (file) {
            var test = {
                code: sys.io.File.getContent(file),
                file: file
            }
            return test;
        });
    }

    inline static function readParserTests(folder : String) : Array<ParserTest>
    {
        return parseFilesIn(folder, function (file) {
            var content : ParserTest = haxe.Json.parse(sys.io.File.getContent(file));
            content.file = file;
            return content;
        });
    }

    static function parseFilesIn<T>(folder : String, parse : String->T) : Array<T>
    {
        var files = new Array<T>();

        for (file in sys.FileSystem.readDirectory(folder)) {
            var fullFile = haxe.io.Path.join([folder, file]);

            if (sys.FileSystem.isDirectory(fullFile)) {
                files = files.concat(parseFilesIn(fullFile, parse));
            }
            else {
                files.push(parse(fullFile));
            }
        }

        return files;
    }
}

typedef ParserTest = {
    code : String,
    expected : String,
    file : String
}

typedef InterpTest = {
    code : String,
    file : String
}
