package;

class Parser
{
    var tokenStack : Array<Token>;
    var code : String;

    var currentPos : Int;

    public function new(code : String)
    {
        this.code = code;
    }

    public function parse() : Void
    {
        for (i in 0 ... code.length) {
            var nextChar = code.charAt(i);
            switch (nextChar) {
                case "[":
                    parseArray();
                    
            }
            currentPos = i;
        }
    }

    function parseArray() : Token
    {
        var array = "";
        var currentChar = "";
        currentPos++; //ignore "["
        while(currentChar != "]") {
            array += currentChar;
            currentPos++;
            currentChar = code.charAt(currentPos);
        }

        var split = array.split("..");
        //array range
        if (split.length > 1) {
            var start = split[0];
            var end = split[1];
        }
        //array access
        else {
            var index = array;
        }

        return null;
    }

    function parseValue(str : String)
    {
        var currentChar = "";

        for (i in 0 ... str.length) {
            currentChar = str.charAt(i);

            switch (currentChar) {
                case "(":
                    
            }
        }
    }


}

enum Token
{
    If;
    ArrayDecl(start : Int, end : Int);
    Equals;
    Identifier(name : String);
    While()
}