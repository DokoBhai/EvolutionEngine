package funkin.backend.scripting.events.game;

import funkin.game.system.SongData.ChartEvent;

class EventLoadEvent extends LoadEvent {
	public var event:ChartEvent;
	public var strumTime:Float;
	public var values:Array<Dynamic>;

	public function new(strumTime:Float, event:ChartEvent) {
		super(event);
		this.event = event;
		this.strumTime = strumTime;
		values = event.values;
	}
}