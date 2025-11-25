package scripts;

//import funkin.backend.utils.FileUtil;

var exampleTxt:FlxText;
function create() {
	exampleTxt = new FlxText(0, 0, 500, "Hello I am an example text", 45);
	exampleTxt.screenCenter();
	add(exampleTxt);
}