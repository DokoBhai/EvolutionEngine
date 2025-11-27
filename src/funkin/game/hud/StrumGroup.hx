package funkin.game.hud;

class StrumGroup extends FlxTypedSpriteGroup<Strum> {
    public var cpu(default, set):Bool;
	public var isPixel(default, set):Bool;
	public var texture(default, set):String;

	public var notes:Array<Note> = [];

	function set_cpu(value:Bool) {
		forEach(s -> s.cpu = value);
		return cpu = value;
	}

	function set_isPixel(value:Bool) {
		forEach(s -> s.isPixel = value);
		return isPixel = value;
	}

	function set_texture(path:String) {
		forEach(s -> s.texture = path);
		return texture = members[0]?.texture ?? path;
	}
    
    public function new(x:Float = 0, y:Float = 0, ?isPlayer:Bool = false)
        super(x, y);

	public function playStatic()
		forEach(s -> s.playStatic());
}