package funkin.game.substates;

class PauseSubstate extends MusicBeatSubstate {
    public var menuOptions:FlxTypedGroup<FunkinText>;

    // Menu stuff
    public var canSelect:Bool = false;
    public var curSelected:Int = 0;
	public var options:Array<String> = ["Resume", "Restart", "Options", "Exit to Menu"];

    // Objects
	var bg:FlxSprite; // Only making this global so it can be used in scripts

    public var parentInstance:MusicBeatState;
    override public function new(parentInstance:MusicBeatState) {
		this.parentInstance = parentInstance;
        super();
    }

    override public function create() {
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);

		menuOptions = new FlxTypedGroup<FunkinText>();
		add(menuOptions);

		regenerateMenuItems();
		changeSelection(0);

		FlxTween.tween(bg, {alpha: 0.6}, 0.5, {ease: FlxEase.sineOut});
		canSelect = true;

        super.create();
    } 

    override public function update(elapsed:Float) {
        super.update(elapsed);

		if (canSelect) {
            if (FlxG.keys.justPressed.UP) changeSelection(-1);
            else if (FlxG.keys.justPressed.DOWN) changeSelection(1);
            else if (FlxG.keys.justPressed.ENTER) select(curSelected);
        }
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
            var text:FunkinText = new FunkinText(20 + (i * 20), 250 + (i * 90), 0, item, 35);
			text.setFormat(Paths.font('funkin'), 35, 0xFFFFFFFF, LEFT, OUTLINE, 0xFF000000);
			text.ID = i;
			menuOptions.add(text);
        }
    }
}