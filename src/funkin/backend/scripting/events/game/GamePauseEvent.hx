package funkin.backend.scripting.events.game;

class GamePauseEvent extends CancellableEvent {
	public var songPosition:Float;
	public var subState:MusicBeatSubstate;

	public function new(songPos:Float, subState:MusicBeatSubstate) {
		super();

        songPosition = songPos;
		this.subState = subState;
	}
}