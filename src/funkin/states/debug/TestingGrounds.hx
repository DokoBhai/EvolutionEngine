package funkin.states.debug;

import flixel.input.keyboard.FlxKey;
import funkin.game.Character;
import funkin.objects.LogoBumpin;
import funkin.game.system.SongData;

import lime.app.Future;

class TestingGrounds extends DebugState
{
	var canSwitch:Bool = false;
	override function create() {
		var progressTxt = new FlxText(0, 0, 0, 'Progress: 0%');
		progressTxt.setFormat(null, 46);
		add(progressTxt);

		super.create();

		final __preloader = new Future(() -> PrecacheUtil.directory('assets', true, false,
		path -> return path.endsWith('.png') || path.endsWith('.json') || path.endsWith('.xml')));

		__preloader.onProgress((progress, total) -> progressTxt.text = 'Progress: ${(progress/total)*100}%');
		__preloader.onComplete(_ -> {
			canSwitch = true;
			
			var test = new FlxSprite(0, 500);
			test.frames = loadSparrowAtlas('characters/BOYFRIEND');
			add(test);

			var char = new Character(0, 0, 'suicide');
			add(char);
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (canSwitch && FlxG.keys.justPressed.A)
			FlxG.switchState(new funkin.game.PlayState());

		if (canSwitch && FlxG.keys.justPressed.S)
			FlxG.switchState(new funkin.states.MainMenuState());
	}
}