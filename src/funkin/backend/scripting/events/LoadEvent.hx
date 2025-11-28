package funkin.backend.scripting.events;

class LoadEvent extends CancellableEvent
{
	public var loadedData:Dynamic;
	public function new(data:Dynamic) {
		super();
		loadedData = data;
	}
}