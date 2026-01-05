package funkin.game;

import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import funkin.game.hud.NoteGroup;
import funkin.game.hud.Strumline;
import funkin.game.hud.HealthIcon;
import funkin.game.system.SongData.Song;
import funkin.game.system.SongData;
import funkin.substates.LoadingSubstate;

@:access(funkin.game.hud.NoteGroup)
class HUD extends FlxSpriteGroup implements IBeatListener {
	public var strumlines:Array<Strumline> = [];
	public var strums:Array<Strum> = [];
	public var notes:NoteGroup;
	public var unspawnNotes:Array<ChartNote> = [];
	public var game:PlayState;

	public var onNoteDestroyed:FlxTypedSignal<Note->Void>;

	public function new(game:PlayState) {
		super();

		this.game = game;

		onNoteDestroyed = new FlxTypedSignal();
	}

	/* Health Bar & Icons */

	var healthBar:FlxBar;
	var iconP1:HealthIcon;
	var iconP2:HealthIcon;
	var iconXGap:Float = -20;
	public function loadHealthBar(playerIcon:String, opponentIcon:String) {
		healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, int(FlxG.width / 2), 15, game, "health", 0, 2, true);
		healthBar.screenCenter(X);
		healthBar.y = FlxG.height - healthBar.height - 60;
		healthBar.createFilledBar(FlxColor.RED, FlxColor.LIME, true, FlxColor.BLACK);
		healthBar.numDivisions = 1000;
		add(healthBar);

		iconP1 = new HealthIcon(0, 0, playerIcon, true);
		iconP1.followObject = true;
		iconP1.trackerOffset.x = iconXGap;
		add(iconP1);

		iconP2 = new HealthIcon(0, 0, opponentIcon, false);
		iconP2.followObject = true;
		iconP2.trackerOffset.x = -iconP2.width - iconXGap;
		add(iconP2);
	}

	public dynamic function bopIcons(bopAmount:Float = 0.3, duration:Float = 0.5) {
		iconP1.bop(bopAmount, duration);
		iconP2.bop(bopAmount, duration);
	}

	public dynamic function updateHealthIcons() {
		iconP1.posTracker.set(healthBar.x + (healthBar.width * (1 - (game.health / 2))), healthBar.y - (iconP1.height/2));
		iconP2.posTracker.set(healthBar.x + (healthBar.width * (1 - (game.health / 2))), healthBar.y - (iconP2.height/2));

		iconP1.state = (game.health > 0.2 ? NORMAL : LOSING);
		iconP2.state = (game.health < 1.8 ? NORMAL : LOSING);
	}

	/* Strums & Notes */

	public function loadStrums() {
		var characters = game.characters.copy();
		characters.reverse();

		for (char in characters) {
			var strumline = new Strumline(0, 50, 4, char.characterID, !char.isPlayer, null, PlayState.isPixelStage);
			strumline.visible = !char.hideStrumline;
			add(strumline);
			strumlines.push(strumline);

			for (strum in strumline) 
				strums.push(strum);

			strumline.x = ((FlxG.width / 2) - strumline.width) / 2;
			if (char.isPlayer)
				strumline.x += FlxG.width/2;
		}
		characters.resize(0);
	}

	public function loadNotes() {
		final song = PlayState.song;
		for (i => note in song.chart.notes) {
			unspawnNotes.push(note);
			if (note.strumTime > game.spawnTime * 2) // other notes gets recycled
				continue;

			var leNote = new Note(note.noteData, false, note.character, null, PlayState.isPixelStage);
			leNote.y += FlxG.height * camera.zoom;
			leNote.strumTime = note.strumTime;

			final strumline = strumlines[note.character];
			leNote.strum = strumline.members[note.noteData];
			strumline.notes.push(leNote);

			leNote.get_canBeHit = function()
				return Math.abs(Conductor.songPosition - leNote.strumTime) <= 188;
		}

		record('[loadNotes] Iterated through chart\'s notes');

		unspawnNotes.sort(sortByTime);

		notes = new NoteGroup();
		add(notes);
	}

	public function updateNotes() {
		for (note in notes) {
			if (!note.hit) {
				note.y = FlxMath.lerp(note.strum.y, (59500 + note.strum.y) * game.scrollSpeed * note.multSpeed, (note.strumTime - Conductor.songPosition) / game.inst.length);
		
				if (Conductor.songPosition >= note.strumTime && note.strum.cpu && !note.ignoreNote)
					game.hitNote(note);

				if (Conductor.songPosition - note.strumTime > 188 && !note.ignoreNote)
					game.noteMiss(note);

				if (Conductor.songPosition - note.strumTime > game.noteKillWindow) {
					onNoteDestroyed.dispatch(note);
					disposeNote(note);
				}
			}
		}

		for (note in unspawnNotes) {
			if (Conductor.songPosition + game.spawnTime >= note.strumTime) {
				unspawnNotes.remove(note);

				var leNote = NoteGroup.recycleNote(note.noteData, false, note.character, null, PlayState.isPixelStage);
				leNote.y = FlxG.height * camera.zoom;
				leNote.strumTime = note.strumTime;

				final strumline = strumlines[note.character];
				leNote.strum = strumline.members[note.noteData];
				strumline.notes.push(leNote);

				leNote.get_canBeHit = function() return Math.abs(Conductor.songPosition - leNote.strumTime) <= 188;
				notes.add(leNote);
				leNote.spawned = true;

				notes.members.sort(sortByTime);
			}
		}
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int {
		if (Obj1 == null || Obj2 == null) return 0;
		if (!Reflect.hasField(Obj1, "strumTime") || !Reflect.hasField(Obj2, "strumTime")) return 0;
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function disposeNote(note:Note) {
		FlxTween.cancelTweensOf(note);
		if (notes.members.contains(note))
			notes.remove(note);
		note.kill();
		NoteGroup.recyclable.push(note);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		if (notes != null)
			updateNotes();
	}

	public function beatHit(curBeat:Int):Void {}
	public function stepHit(curStep:Int):Void {}
	public function measureHit(curMeasure:Int):Void {}
}
