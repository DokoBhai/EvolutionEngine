package funkin.game.substates;

import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.FlxObject;

/*
 * TODO: Add support for death dialogue (Like in Week 7)
 */

@:access(funkin.game.PlayState)
@:access(funkin.backend.utils.PrecacheUtil)
class GameOverSubstate extends MusicBeatSubstate {
    public static var settings:GameOverSettings;

	public var camFollow:FlxObject;
	public var player:Character;

    public var deathMusic:FlxSound;
    var _saved_bpm:Float = -1;

    var game:PlayState;
    override public function new(parentInstance:PlayState) {
        super();
		this.game = parentInstance;
		resetSettings();

        // Saving the bpm here so it can be set when the substate is destroyed
		_saved_bpm = Conductor.bpm;
    }

    override public function create() {
        super.create();

		deathMusic = new FlxSound();
		deathMusic.loadEmbedded(Paths.music(settings.deathMusic), true, true);
		FlxG.sound.list.add(deathMusic);
		Conductor.trackedMusic = deathMusic;
		Conductor.bpm = settings.deathBPM;

		player = new Character(game.bf.x + (settings.characterOffsets.x ?? 0), game.bf.y + (settings.characterOffsets.y ?? 0),
            settings.character, true);
		add(player);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		camFollow.setPosition(player.x + player.width / 2, player.y + player.height / 2);

        startDeath();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // Goofy ahh lookin
		if (player?.animation?.curAnim?.name == "firstDeath") {
			// We don't need to use null conditionals since the check above does it for us
			if (canCameraFocus()) {
				FlxG.camera.follow(camFollow, LOCKON, 0.02);
            }

			if (player.animation.curAnim.finished && !inDeathLoop) {
				canSelect = inDeathLoop = true;
                startDeathLoop();
            }
        }

		if (inDeathLoop && canSelect) {
			if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
                select(true);
            else if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE)
				select(false);
        }
    }

    override public function beatHit(curBeat:Int) {
        super.beatHit(curBeat);

		if (inDeathLoop && curBeat % 2 == 0 && canSelect) {
		    player?.playAnim("deathLoop", true);
        }
    }

    override public function destroy() {
        /* 
         * Just for future reference, make sure to set this to null here, or else the next
         * song reload will start the notes at the song position left off here.
         */
        Conductor.trackedMusic = null;
		Conductor.bpm = _saved_bpm;
		resetSettings();

        super.destroy();
    }

    var inDeathLoop:Bool = false;
    function startDeathLoop() {
		if (deathMusic != null) {
            deathMusic.play();
			player?.playAnim("deathLoop", true);
        }
    }

    function startDeath() {
		player.playAnim("firstDeath");
		FlxG.sound.play(Paths.sound(settings.deathSFX));
    }

    var canSelect:Bool = false;
    function select(retrySong:Bool = true) {
		canSelect = false;
        if(retrySong) {
			deathMusic.loadEmbedded(Paths.music(settings.deathEndSFX), false, true);

			deathMusic.play();
            player?.playAnim("deathConfirm", true);
			new FlxTimer().start(0.7, (_) -> {
				FlxG.camera.fade(FlxColor.BLACK, 2.8, false, () -> {
					FlxG.resetState();
				});
			});
        } else {
			FlxG.switchState(new funkin.states.FreeplayState());
        }
    }

    dynamic function canCameraFocus():Bool {
		return (player.animation.curAnim.curFrame > player.animation.curAnim.numFrames/4);
    }

    inline function resetSettings() {
		settings = {
			deathMusic: "death/gameOver",
			deathEndSFX: "death/gameOverEnd",
			deathSFX: "death/fnf_loss_sfx",
            character: "bf-dead",
			deathBPM: 100,
            characterOffsets: FlxPoint.get(0, 0)
        };
    }
}

typedef GameOverSettings = {
	deathMusic:String,
    deathEndSFX:String,
    deathSFX:String,
    character:String,
    characterOffsets:FlxPoint,
    deathBPM:Float
}