package funkin.backend.scripting.events.game;

import flixel.math.FlxPoint;
import funkin.game.PlayState;
import funkin.game.Character;
import funkin.game.hud.Strumline;

class CameraMoveEvent extends CancellableEvent
{
	public var character:Character;
	public var characterID:Int;
	public var position:FlxPoint;
	public var strumLine:Strumline;

	public function new(character:Character, position:FlxPoint)
	{
		super();

		this.character = character;
		this.position = position;
		characterID = character.characterID;

		if (MusicBeatState.getState() is PlayState) {
			final playState = cast(MusicBeatState.getState(), PlayState);
			for (strumLine in playState.hud.strumlines) {
				if (strumLine.character == character) {
					this.strumLine = strumLine;
					break;
				}
			}
		}
	}
}
