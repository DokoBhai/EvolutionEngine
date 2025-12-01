package funkin.backend.scripting.events.game;

import funkin.game.system.SongData.ChartEvent;

class EventTriggeredEvent extends CancellableEvent {
    public var name:String;
    public var values:Array<Dynamic>;
    public var strumTime:Float;
    public var event:ChartEvent;
    
    public function new(event:ChartEvent, strumTime:Float) {
        super();

        this.event = event;
        this.strumTime = strumTime;
        name = event.event;
        values = event.values;
    }
}