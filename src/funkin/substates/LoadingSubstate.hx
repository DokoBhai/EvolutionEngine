package funkin.substates;

import lime.app.Promise;
import lime.app.Future;
import haxe.Timer;

typedef TaskInfo = {
    task:Void->Dynamic,
    ?result:Dynamic,
    ?desc:String
}

class LoadingSubstate extends MusicBeatSubstate {
    public var tasks:Map<String, TaskInfo> = [];
    public var currentTask:TaskInfo;
    public var eta:Float; 

	public var onProgress:FlxTypedSignal<(Int, Int, TaskInfo)->Void>;
	public var onComplete:FlxTypedSignal<Map<String, TaskInfo>->Void>;
    
    var background:FlxSprite;
    var loadingBar:FlxSprite;
    var title:FlxText;
    var loadingLabel:FlxText;
    var loadingDesc:FlxText;
    var progressTxt:FlxText;

	var labelTimer:Timer;
	var loader(default, set):Future<Map<String, TaskInfo>>;
    public function new(tasks:Map<String, TaskInfo>) {
        super();

        background = new FlxSprite();
        background.makeGraphic(1, 1, 0xFF000000);
        background.scale.set(FlxG.width, FlxG.height);
        background.updateHitbox();
        add(background);

        var titleBG = new FlxSprite().makeGraphic(FlxG.width, 40, 0xFF000000);
        add(titleBG);

        title = new FlxText(5, 5, FlxG.width, 'Please wait..');
        title.setFormat(Paths.font('funkin'), 36);
        add(title);

        loadingBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(1, 20, 0xFFFFFFFF);
        add(loadingBar);

		loadingLabel = new FlxText(5, 5, FlxG.width, 'Loading');
		loadingLabel.setFormat(Paths.font('funkin'), 24);
		loadingLabel.y = FlxG.height - loadingLabel.height - 37.5;
		add(loadingLabel);

        var labelStage = 0;
		labelTimer = new Timer(500);
        labelTimer.run = () -> {
            loadingLabel.text = ('Loading').rpad('.', 8 + (labelStage % 3));
			labelStage++;
        }

		loadingDesc = new FlxText(5, 5, FlxG.width, '');
		loadingDesc.setFormat(Paths.font('funkin'), 12);
		loadingDesc.y = FlxG.height - loadingDesc.height - 22;
		add(loadingDesc);

		progressTxt = new FlxText(-5, -5, FlxG.width, '0%');
		progressTxt.setFormat(Paths.font('funkin'), 34, -1, RIGHT);
		progressTxt.y = FlxG.height - progressTxt.height - 25;
		add(progressTxt);

        tasks ??= [];
        this.tasks = tasks;

        onProgress = new FlxTypedSignal();
		onComplete = new FlxTypedSignal();
    }

	function set_loader(loader:Future<Map<String, TaskInfo>>) {
        loader.onProgress( (loaded, total) -> {
            progressTxt.text = '${int((loaded / total) * 100)}%';
			loadingBar.scale.x = FlxG.width * (loaded / total);
            loadingBar.updateHitbox();
            
            onProgress.dispatch(loaded, total, currentTask);
        } );

        loader.onComplete( (taskInfos) -> {
            progressTxt.text = '100%';
            loadingLabel.text = 'Loaded.';
            loadingDesc.text = 'Loading Complete!';

            labelTimer.stop();
            onComplete.dispatch(taskInfos);
        } );

        return this.loader = loader;
    }

    public function runTasks() {
		var promise = new Promise<Map<String, TaskInfo>>();

		var progress = 0, total = tasks.getLength() - 1;
		var timer = new Timer(0);

		var startTime = Timer.stamp();
        var taskKeys = tasks.getKeys();

		timer.run = () -> {
			final now = Timer.stamp();
			final avgTime = (now - startTime) / progress;
			final remaining = total - progress;
			eta = remaining * avgTime;

            currentTask = tasks.get(taskKeys[progress]);
			loadingDesc.text = currentTask.desc;
            currentTask.result = currentTask.task();

			promise.progress(progress, total);
			progress++;

			if (progress == total)
			{
				promise.complete(tasks);
				timer.stop();
			}
		};
		return loader = promise.future;
    }
}