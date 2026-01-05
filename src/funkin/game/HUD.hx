package funkin.game;

import funkin.substates.LoadingSubstate;
import flixel.util.FlxSort;
import funkin.game.hud.Strumline;
import funkin.game.hud.NoteGroup;
import funkin.game.system.SongData;
import funkin.game.system.SongData.Song;

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
