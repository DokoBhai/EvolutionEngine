package funkin.states;

import funkin.objects.LogoBumpin;

class TitleState extends MusicBeatState
{
	// basic objects
	var introText:FlxText;
	var logoBumpin:LogoBumpin;

	static var didIntro:Bool = false;
	override function create()
	{
		// Main create function
		super.create();

        introText = new FlxText(0, 0, FlxG.width, '');
        introText.setFormat(Paths.font('funkin'), 52 , 0xFFFFFFFF, CENTER);
        introText.screenCenter();
        add(introText);

		logoBumpin = new LogoBumpin(0, 0, 'logoBumpin');
		logoBumpin.screenCenter();
		logoBumpin.visible = false;
		add(logoBumpin);

		if (!didIntro) {
			FlxG.sound.playMusic(loadSound(Paths.music('freakyMenu')));
			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.trackedMusic = FlxG.sound.music;
			Conductor.bpm = 102;
		} else skipIntro();
	}

    override function beatHit(curBeat:Int) {
        super.beatHit(curBeat);
        
		if (!didIntro)
			beatIntro(curBeat+1);

		logoBumpin.bump();
    }

	function beatIntro(beat) {
		switch(beat) {
            case 2: introText.text = "Evolution Engine by";
            case 4: introText.text += ":\nGhostglowDev\nT-Bar\nSwagaRuney";
            case 5: introText.text = "";
            case 6: introText.text = "Not associated\nwith";
            case 8: introText.text += ":\nNEWGROUNDS";
			case 9: introText.text = "";
            case 10: introText.text = "coolswag";
			case 12: introText.text += "\nmoney money";
            case 13: introText.text = "";
            case 14: introText.text = "Friday";
            case 15: introText.text += "\nNight";
			case 16: introText.text += "\nFunkin";
			case 17: skipIntro();
        }

        introText.updateHitbox();
        introText.screenCenter();
	}

	function skipIntro() {
		didIntro = true;

		FlxG.camera.flash(0xFFFFFFFF, 1);
		introText.visible = false;
		logoBumpin.visible = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.ACCEPT) {
			if (didIntro)
				FlxG.switchState(new FreeplayState());
			else
				skipIntro();
		}
	}

	override function destroy() {
		didIntro = true;
	}
}
