package funkin.backend;

class FunkinText extends FlxText {
    public function new(X:Float, Y:Float, Width:Dynamic, Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
        super(X, Y, Width, Text, Size, EmbeddedFont);
        
        setFormat(Paths.font('vcr'), Size, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
        borderSize = 2;
    }
}