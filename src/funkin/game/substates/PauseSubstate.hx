package funkin.game.substates;

@:access(funkin.game.PlayState)
class PauseSubstate extends MusicBeatSubstate {
    public var menuOptions:FlxTypedGroup<FunkinText>;

    // Menu stuff
    public var canSelect:Bool = false;
    public var curSelected:Int = 0;
	public var options:Array<String> = ["Resume", "Restart", "Options", "Exit to Menu"];

    // Objects
	var bg:FlxSprite; // Only making this global so it can be used in scripts
    var songNameTxt:FunkinText;
    var deathCounterTxt:FunkinText;

    var music:FlxSound;

	public var game:PlayState;
    override public function new(parentInstance:PlayState) {
		this.game = parentInstance;
        super();
    }

    override public function create() {
		this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		super.create();

        try {
		    music = new FlxSound();
			music.loadEmbedded(Paths.music("pause/breakfast" + (FlxG.random.bool(10) ? "-pico" : "")), true, true);
			music.volume = 0;
			FlxG.sound.list.add(music);
			music.fadeIn(7, 0, 0.6); // fadeIn should automatically play the music
        } catch(e) {
            trace("No pause music found!");
        }

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);

		menuOptions = new FlxTypedGroup<FunkinText>();
		add(menuOptions);

		regenerateMenuItems();

		songNameTxt = new FunkinText(FlxG.width, 10, 0, '${game.songName}'.toUpperCase(), 33);
		songNameTxt.setFormat(Paths.font('vcr'), 33, 0xFFFFFFFF, RIGHT, OUTLINE, 0xFF000000);
		add(songNameTxt);

		deathCounterTxt = new FunkinText(songNameTxt.x, 10, 0, 'BLUE BALLED: 0', 33);
		deathCounterTxt.setFormat(Paths.font('vcr'), 33, 0xFFFFFFFF, RIGHT, OUTLINE, 0xFF000000);
		deathCounterTxt.y = songNameTxt.y + deathCounterTxt.height + 3;
		add(deathCounterTxt);

		changeSelection(0);

		FlxTween.tween(bg, {alpha: 0.6}, 0.5, {ease: FlxEase.sineOut});
		FlxTween.tween(deathCounterTxt, {x: FlxG.width - deathCounterTxt.width, alpha: 1}, 0.7, {startDelay: 0.6, ease: FlxEase.expoOut});
		FlxTween.tween(songNameTxt, {x: FlxG.width - songNameTxt.width, alpha: 1}, 0.6, {startDelay: 0.4, ease: FlxEase.expoOut});
		canSelect = true;
    } 

    override public function update(elapsed:Float) {
        super.update(elapsed);

		if (canSelect) {
            if (FlxG.keys.justPressed.UP) changeSelection(-1);
            else if (FlxG.keys.justPressed.DOWN) changeSelection(1);
            else if (FlxG.keys.justPressed.ENTER) select(curSelected);
        }
    }

    override function destroy() {
		if(music != null) {
			// Failsafe for if you leave the pause menu while it's still fading in
			music.fadeTween.cancel();
            music.fadeTween.destroy();

			music.stop();
			music.destroy();
        }
        super.destroy();
    }

    public function changeSelection(delta:Int) {
		curSelected = FlxMath.wrap(curSelected + delta, 0, options.length-1);

		menuOptions.forEach((txt:FunkinText) -> {
			txt.color = (txt.ID == curSelected ? 0xFFFFFD9C : 0xFF979797);
		});
    }

    public function select(selectID:Int) {
        switch(options[selectID]) {
			case "Resume":
				canSelect = false;
                close();
            case "Restart":
				canSelect = false;
                FlxG.resetState();
            case "Exit to Menu":
				canSelect = false;
				FlxG.switchState(new funkin.states.FreeplayState());
            default:
				trace('Option ${options[selectID]} is not available!');
        }
    }

    public function regenerateMenuItems() {
		if (menuOptions.length > 0) {
            menuOptions.forEach((txt:FunkinText) -> {
				txt.destroy();
				menuOptions.remove(txt, true);
            });
        }
		for (i => item in options) {
            var text:FunkinText = new FunkinText(100 + (i * 20), 250 + (i * 90), 0, item, 35);
			text.setFormat(Paths.font('funkin'), 35, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			text.ID = i;
			menuOptions.add(text);
        }
    }
}