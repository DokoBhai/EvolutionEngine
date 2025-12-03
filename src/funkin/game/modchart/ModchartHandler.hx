package funkin.game.modchart;

import flixel.math.FlxPoint;

class ModchartHandler {
    public var shakeMod:FlxPoint = FlxPoint.get(0, 0);
	public var wiggleMod:FlxPoint = FlxPoint.get(0, 0);

    public function new() {

    }

    var elapsed:Float = 0;
    function update(deltaTime:Float) {
        elapsed += deltaTime;

        
    }
}