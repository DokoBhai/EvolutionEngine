package funkin.states;

import flixel.util.FlxTimer;

import lime.app.Future;
import lime.app.Promise;
import haxe.Timer;

import sys.FileSystem;

class PreloadState extends MusicBeatState {
    var progressTxt:FlxText;
    var loadedTxt:FlxText;
    var bar:FlxSprite;
    override function create() {
        super.create();

		loadedTxt = new FlxText(3, 3, 0, '');
		loadedTxt.setFormat(Paths.font('vcr'), 12);
		add(loadedTxt);

        add(new FlxSprite(0, FlxG.height - 50).makeGraphic(FlxG.width, 50, 0xFF000000));
    
        progressTxt = new FlxText(5, 5, 0, 'Progress: 0%');
        progressTxt.setFormat(Paths.font('funkin'), 24);
        progressTxt.y = FlxG.height - progressTxt.height - 25;
        add(progressTxt);

        bar = new FlxSprite(0, FlxG.height - 20);
        bar.makeGraphic(1, 20, 0xFFFFFFFF);
        add(bar);

		final files = getFiles('assets', path -> return path.endsWith('.png') || path.endsWith('.json') || path.endsWith('.xml'));
		var future = preload(files);

        future.onComplete((message) -> {
            progressTxt.text = 'Progress: 100% (Loaded)';
            bar.scale.x = FlxG.width;
            bar.updateHitbox();

            FlxTween.tween(FlxG.camera, {alpha: 0}, 2, { 
                startDelay: 1, 
                ease: FlxEase.cubeIn,
                onComplete: _ -> FlxG.switchState(new funkin.game.PlayState())
            });
        });

        future.onProgress((loaded, total) -> {
            final percent = loaded / total;

            progressTxt.text = 'Progress: ${FlxMath.roundDecimal(percent, 2) * 100}%';
            bar.scale.x = FlxG.width * percent;
            bar.updateHitbox();

            loadedTxt.text = files[loaded] + '\n' + loadedTxt.text;
        });
    }

	function preload(files:Array<String>):Future<Array<String>> {
	    var promise = new Promise<Array<String>>();

        if (files.length > 0) {
	        var progress = 0, total = files.length-1;
	        var timer = new Timer(total * 5);
	        timer.run = () -> {
                trace(files[progress]);
                PrecacheUtil.precache(files[progress]);

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
}