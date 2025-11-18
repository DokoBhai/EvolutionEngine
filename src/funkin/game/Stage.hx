package funkin.game;

import flixel.math.FlxPoint;
import funkin.game.objects.Character;
import funkin.game.objects.HUD;

typedef StageSprite =
{
	?image:String,
	?x:Float,
	?y:Float,
	?alpha:Float,
	?visible:Bool
}

typedef StageCharacter =
{
	?x:Float,
	?y:Float,
	?cameraOffsets:Array<Float>
}

typedef StageData =
{
	characters:Array<StageCharacter>,
	sprites:Array<StageSprite>,
}

class Stage extends FlxSpriteGroup implements IBeatListener
{
	public var state:MusicBeatState;

	public var data:StageData;

	public var characters(get, never):Array<Character>;
	public var hud(get, never):HUD;

	public var songName(get, never):String;
	public var songPath(get, never):String;

	function get_characters()
		return getFromGame(s -> return s.characters);

	function get_hud()
		return getFromGame(s -> return s.hud);

	function get_songName()
		return getFromGame(s -> return s.songName);

	function get_songPath()
		return getFromGame(s -> return s.songPath);

	function getFromGame(?f:PlayState->Dynamic):Dynamic
	{
		if (state is PlayState)
			return f(cast(state, PlayState));
		else
			return null;
	}

	public var characterPositions:Array<FlxPoint> = [];
	public var cameraOffsets:Array<FlxPoint> = [];

	public function new(?stage:StageData)
	{
		super();
		state = MusicBeatState.getState();

		stage ??= {
			characters: [
				{ x: -100, y: 0,  cameraOffsets: [0, 0] },
				{ x: 600, y: 200, cameraOffsets: [0, 0] },
				{ x: 250, y: 150, cameraOffsets: [0, 0] }
			],
			sprites: []
		};
		data = stage;

		for (char in stage.characters) {
			final camOffsets = char.cameraOffsets;
			characterPositions.push(FlxPoint.get(char.x, char.y));
			cameraOffsets.push(FlxPoint.get(camOffsets[0], camOffsets[1]));
		}
	}

	public function beatHit(curBeat:Int):Void {}
	public function stepHit(curStep:Int):Void {}
	public function measureHit(curMeasure:Int):Void {}
}
