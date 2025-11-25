package;

import funkin.backend.scripting.HScript;

var testStr:String = "
var b:Int = equationTest[0];
var c:Float = equationTest[1];
var a:String = 'Here is the sum of $b and $c times 2: ';
trace(a + b + (c * 2));
";
var haxecode:HScript;
function create() {
	haxecode = new HScript("runHaxeCode", {isString: true});
	haxecode.set("equationTest", [30, 5.5]);
	haxecode.execute(testStr);
}

function destroy() { haxecode.destroy(); }