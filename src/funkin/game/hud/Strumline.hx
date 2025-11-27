package funkin.game.hud;

import funkin.game.Strum;

@:access(funkin.game.Strum)
class Strumline extends StrumGroup {
	public var character(default, null):Character;
	public var characterID(default, null):Int;

	public function new(x:Float = 0, y:Float = 0, ?keys:Int = 4, ?characterID:Int, ?cpu:Bool = false, ?texture:String, ?isPixel:Bool = false) {
		super(x, y);

		@:bypassAccessor {
			this.characterID = int(Math.abs(characterID));
			this.cpu = cpu;
			this.isPixel = isPixel;
			this.texture = texture ?? Strum.FALLBACK_TEXTURE;
		}

		if (MusicBeatState.getState() is PlayState && characterID != null) {
			final game = cast(MusicBeatState.getState(), PlayState);
			if (game?.characters[characterID] != null)
				character = game.characters[characterID];
		}

		for (i in 0...keys) {
			var strum = new Strum(i * 112, 0, i, characterID, cpu, texture, isPixel);
			strum.strumline = this;
			add(strum);
		}
	}
}
