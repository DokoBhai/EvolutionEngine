package funkin.game.modchart;

import flixel.math.FlxPoint;

class ModchartHandler {
    public var shakeMod:FlxPoint = FlxPoint.get(0, 0);
	public var wiggleMod:FlxPoint = FlxPoint.get(0, 0);

    var __enabled(get, never):Bool;
    public var enabled:Bool = false;
    public var obj:FlxSprite;

    function get___enabled()
        return obj.alive && obj.exists && enabled;

    public function new(obj:FlxSprite) {
        this.obj = obj;
    }

    var elapsed:Float = 0;
    function update(deltaTime:Float) {
        elapsed += deltaTime;

        
    }
}