package funkin.backend;

import openfl.system.System;

import funkin.backend.input.Controls;
import funkin.game.Character;
import funkin.states.*;

import funkin.backend.MusicBeatState;

@:access(funkin.backend.system.Conductor)
class MusicBeatSubstate extends FlxSubState implements IBeatListener
{
    public var controls(get, never):Controls;
    function get_controls()
        return MusicBeatState.getState().controls;

	public var onStepHit:BeatHitSignal;
	public var onBeatHit:BeatHitSignal;
	public var onMeasureHit:BeatHitSignal;

    public var subStateCam:FlxCamera;
    public static var defaultCam:FlxCamera;

	// for hscript and lua
	public static var instance:MusicBeatSubstate;

	public function new()
	{
		super();

        subStateCam = new FlxCamera();
        subStateCam.bgColor = 0x0;
        FlxG.cameras.add(subStateCam, false);

        if (defaultCam == null)
            defaultCam = subStateCam;

        subStateCam = defaultCam;

		instance = this;

		if (FlxG.sound.music != null && Conductor.trackedMusic == null)
			Conductor.trackedMusic = FlxG.sound.music;

		onStepHit = new BeatHitSignal();
		onBeatHit = new BeatHitSignal();
		onMeasureHit = new BeatHitSignal();

		onStepHit.add(stepHit);
		onBeatHit.add(beatHit);
		onMeasureHit.add(measureHit);
	}

    override function add(basic:FlxBasic) {
        super.add(basic);
        basic.camera = subStateCam;
        return basic;
    }

	public function lerp(a:Float, b:Float, ratio:Float, ?fpsSensitive:Bool = false)
	{
		final lerpRatio = fpsSensitive ? getLerpRatio(ratio) : ratio;
		return FlxMath.lerp(a, b, lerpRatio);
	}

	public static function getState():MusicBeatState
		return cast(FlxG.state, MusicBeatState);

	var __lastStep:Int = -1;
	var __lastBeat:Int = -1;
	var __lastMeasure:Int = -1;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (__lastStep != Conductor.curStep)
			for (step in (__lastStep + 1)...Conductor.curStep + 1)
				onStepHit.dispatch(step);

		if (__lastBeat != Conductor.curBeat)
			for (beat in (__lastBeat + 1)...Conductor.curBeat + 1)
				onBeatHit.dispatch(beat);

		if (__lastMeasure != Conductor.curMeasure)
			for (measure in (__lastMeasure + 1)...Conductor.curMeasure + 1)
				onMeasureHit.dispatch(measure);

		__lastStep = Conductor.curStep;
		__lastBeat = Conductor.curBeat;
		__lastMeasure = Conductor.curMeasure;
	}

	public function stepHit(curStep:Int) {}
	public function beatHit(curBeat:Int) {}
	public function measureHit(curMeasure:Int) {}
}
