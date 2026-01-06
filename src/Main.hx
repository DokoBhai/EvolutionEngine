package;

import flixel.FlxGame;
import funkin.backend.debug.Framerate;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

class Main extends Sprite {
	public var framerate:Framerate;
	public function new() {
		super();
		addChild(new FlxGame(0, 0, funkin.states.TitleState, 60, 60, true));
		addChild(framerate = new Framerate());

		FlxG.signals.postUpdate.add(() -> {
			if (FlxG.keys.justPressed.F3)
				framerate.toggleVisibility();
		});

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
	}
}
