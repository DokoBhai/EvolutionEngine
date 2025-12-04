package funkin.states;

import flixel.util.FlxTimer;

import lime.app.Future;
import lime.app.Promise;
import haxe.Timer;

import sys.FileSystem;

class PreloadState extends MusicBeatState {
    var progressTxt:FlxText;
    var bpsTxt:FlxText;
	var loadedBytesTxt:FlxText;
    var loadedTxt:FlxText;
    var etaTxt:FlxText;
    var bar:FlxSprite;

    var eta:Float = 0;
    var bytesLoaded:Int = 0;
    var bytesPerSec:Float = 0;
    
    override function create() {
        super.create();

		loadedTxt = new FlxText(3, 3, 0, '');
		loadedTxt.setFormat(Paths.font('vcr'), 12);
		add(loadedTxt);

        add(new FlxSprite(0, FlxG.height - 72.5).makeGraphic(FlxG.width, 73, 0xFF000000));
    
        progressTxt = new FlxText(5, 5, FlxG.width, 'Progress: 0%');
        progressTxt.setFormat(Paths.font('funkin'), 24);
        progressTxt.y = FlxG.height - progressTxt.height - 37.5;
        add(progressTxt);

        etaTxt = new FlxText(5, 5, FlxG.width, 'ETA: Unknown');
		etaTxt.setFormat(Paths.font('funkin'), 12);
		etaTxt.y = FlxG.height - etaTxt.height - 22;
        add(etaTxt);

		bpsTxt = new FlxText(-5, -5, FlxG.width, '0B/s');
		bpsTxt.setFormat(Paths.font('funkin'), 24, -1, RIGHT);
		bpsTxt.y = FlxG.height - bpsTxt.height - 37.5;
		//add(bpsTxt);

		loadedBytesTxt = new FlxText(-5, -5, FlxG.width, '0B / 0B');
		loadedBytesTxt.setFormat(Paths.font('funkin'), 12, -1, RIGHT);
		loadedBytesTxt.y = FlxG.height - loadedBytesTxt.height - 22;
		add(loadedBytesTxt);

        bar = new FlxSprite(0, FlxG.height - 20);
        bar.makeGraphic(1, 20, 0xFFFFFFFF);
        add(bar);

		final filter:String->Bool = path -> return path.endsWith('.png') || path.endsWith('.json') || path.endsWith('.xml');
        final fileSize:Int = getDirectorySize('assets', filter);
		final files = getFiles('assets', filter);
		var future = preload(files);

        future.onComplete((message) -> {
            progressTxt.text = 'Progress: 100%';
			bpsTxt.text = '0B/s';
            bar.scale.x = FlxG.width;
            bar.updateHitbox();

            etaTxt.text = 'ETA: Loaded';

            new FlxTimer().start(0.5, tmr -> FlxG.camera.fade(0xFF000000, 3, false, () -> FlxG.switchState(new funkin.game.PlayState())));
        });

        future.onProgress((loaded, total) -> {
            final percent = loaded / total;

            progressTxt.text = 'Progress: ${FlxMath.roundDecimal(percent, 2) * 100}%';
			bpsTxt.text = '${bytesPerSec.formatBytes()}/s';
            bar.scale.x = FlxG.width * percent;
            bar.updateHitbox();

            if (loaded >= total / 6) // when results are more accurate
                etaTxt.text = 'ETA: ${int(eta)}s left';

            loadedBytesTxt.text = '${bytesLoaded.formatBytes()} / ${fileSize.formatBytes()}';
            loadedTxt.text = files[loaded] + '\n' + loadedTxt.text;
        });
    }

	function preload(files:Array<String>):Future<Array<String>> {
	    var promise = new Promise<Array<String>>();

        if (files.length > 0) {
	        var progress = 0, total = files.length-1;
	        var timer = new Timer(1); // 1ms delay per run

            // ETA
            var startTime = Timer.stamp();
            var lastTime = startTime;

	        timer.run = () -> {
				final now = Timer.stamp();
				final elapsed = now - lastTime;
				lastTime = now;

                PrecacheUtil.precache(files[progress]);

				final fileSize = FileSystem.stat(files[progress]).size;
                bytesLoaded += fileSize;

				final avgTime = (now - startTime) / progress;
				final remaining = total - progress;
				eta = remaining * avgTime;

	            promise.progress(progress, total);
	            progress++;

	            if (progress == total) {
	            	promise.complete(files);
	            	timer.stop();
	            }
	        };
        }
	    return promise.future;
    }

    function getFiles(folder:String, ?filter:String->Bool):Array<String> {
		if (!FileUtil.exists(folder)) {
            trace('ERROR: File "$folder" does not exist.');
            return [];
        }
        
        filter ??= _ -> true;

		var files:Array<String> = [];
		if (FileSystem.isDirectory(folder))
		{
			for (content in FileSystem.readDirectory(folder))
			{
				final path = '$folder/$content';
				if (FileSystem.isDirectory(path))
				{
					var subFiles:Array<String> = getFiles(path, filter);
					files = files.concat(subFiles);

					continue;
				}

				if (filter(path))
                    files.push(path);
			}
			return files;
		}
		trace('ERROR: File $folder is not a directory.');
		return [];
    }

    function getDirectorySize(folder:String, ?filter:String->Bool):Int {
        if (!FileUtil.exists(folder)) {
            trace('ERROR: File "$folder" does not exist.');
            return 0;
        }

		var size:Int = 0;
        if (FileSystem.isDirectory(folder)) {
            final content = getFiles(folder, filter);
            for (file in content)
                size += FileSystem.stat(file).size;

            return size;
        }
        trace('ERROR: File "$folder" is not a directory.');
        return 0;
    }
}