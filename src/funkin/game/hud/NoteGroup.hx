package funkin.game.hud;

@:access(funkin.game.objects.hud.Note)
class NoteGroup extends FlxTypedSpriteGroup<Note>
{
	static var recyclable:Array<Note> = [];

	public inline function getFirstHittable(?noteData:Int)
		return first(members.filter( n -> return !n.canBeHit ));  

	public inline function getPlayerNotes()
		return members.filter(n -> return !n.cpu);

	public inline function getCPUNotes()
		return members.filter(n -> return n.cpu);

	public static function getAvailableNote():Null<Note> {
		for (note in recyclable) {
			if (!note.alive)
				return note;
			else
				recyclable.remove(note);
		}
		return null;
	}

	public static inline function recycleNote(noteData:Int, isSustainNote:Bool = false, ?characterID:Int, ?texture:String, ?isPixel:Bool = false) { // cant override recycle cus it's a dumbass inline   
		var note:Note = getAvailableNote();
		if (note != null) {
			note.color = 0xFFFFFFFF;
			note.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);

			note.strumTime = 0;
			note.noteData = noteData;
			note.characterID = characterID;
			note.noteType = '';
			note.animSuffix = '';
			note.isSustainNote = isSustainNote;
			note.isPixel = isPixel;
			note.loadDefaultPixelMeta();

			note.parent = null;
			note.spawned = false;
			note.get_canBeHit = () -> false;
			note.ignoreNote = false;
			note.rating = '';
			note.hit = false;
			note.missed = false;

			note.strum = null;
			note.followPosition = true;
			note.followAngle = true;
			note.followAlpha = true;
			
			note.multAlpha = 1;
			note.multSpeed = 1;
			note.angleOffset = 0;

			note.forcedTextureReload = true;
			note.texture = texture ?? Note.FALLBACK_TEXTURE;

			if (MusicBeatState.getState() is PlayState) {
				final game:PlayState = cast MusicBeatState.getState();
				if (game.characters != null && game.characters.length > 0)
					note.character = game.characterFromID(characterID);
			}
			
			@:privateAccess
			note.reloadNote();
		} else 
			note = new Note(noteData, isSustainNote, characterID, texture, isPixel);
		
		note.revive();
		recyclable.remove(note);
		return note;
	}
}
