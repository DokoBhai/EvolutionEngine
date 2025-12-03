package funkin.states;

import lime.app.Future;
import funkin.game.Character;
import funkin.objects.LogoBumpin;

class MainMenuState extends SelectableState
{
	var buttons:Array<String> = [];

	var logoBumpin:LogoBumpin;
	var char:Character;
	public function new()
	{
		super(0, 4);

		var bg = new FunkinSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFF9DB69;
		add(bg);

		logoBumpin = new LogoBumpin(0, 0, 'logoBumpin');
		logoBumpin.screenCenter();
		add(logoBumpin);

		FlxG.sound.playMusic(loadSound(Paths.music('freakyMenu')));
		Conductor.trackedMusic = FlxG.sound.music;
		Conductor.bpm = 102;

		var test = new FlxSprite(0, 500);
		test.frames = loadSparrowAtlas('characters/BOYFRIEND');
		add(test);

		char = new Character(0, 0, 'bf');
		add(char);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.ENTER) 
			FlxG.switchState(new funkin.game.PlayState());

		if (FlxG.keys.justPressed.SHIFT) {
			final chars = ['bf', 'mouse-smile', 'smileeeeer', 'suicide', 'night', 'bf-retro'];
			final charName = FlxG.random.getObject(chars);
			trace(charName);
			char.loadCharacter(charName);
		}
	}

	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);

		char.beatHit(curBeat);
		if (curBeat % 2 == 0) {
			logoBumpin.bump();
		}
	}
}

class MenuButton extends FunkinSprite {}
