package funkin.states;

import haxe.CallStack.StackItem;
import flixel.text.FlxText;
import funkin.game.system.SongData;
import funkin.game.PlayState;

import sys.FileSystem;
import tjson.TJSON;

// this is temporary until we add more features to freeplay
class FreeplayState extends MusicBeatState {
    var songs:Array<SongData> = [];
    var songTextList:Array<FunkinText> = [];

    var curSelected:Int = 0;

    var weekData:Array<WeekData> = [];
    override function create() {
        super.create();

		for (index => weekJson in FileSystem.readDirectory('assets/data/weeks')) {
			var json:WeekData = TJSON.parse(FileUtil.getContent('assets/data/weeks/$weekJson'));

			if (json.visibleInFreeplay != null && !json.visibleInFreeplay) continue;
			//if (json.weekRequired != null) continue; // TODO

			for (i => songPath in json.songs) {
				final songData:SongData = addSong(songPath.name);

				var text = new FunkinText(40, 100 + (i * 50), 0, songData.songName);
				text.setFormat(Paths.font('funkin'), 44);
				add(text);
				songTextList.push(text);
            }
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP)
            changeItem(-1);
        else if (FlxG.keys.justPressed.DOWN)
            changeItem(1);

		for (i => songTxt in songTextList) {
            songTxt.color = (i == curSelected ? 0xFFFFFF00 : 0xFFFFFFFF);
        }

        if (FlxG.keys.justPressed.ENTER) {
            var selectedSong = songs[curSelected];
            PlayState.loadSong(selectedSong.songPath);
            FlxG.switchState(new PlayState());
        }
    }

    function addSong(songName:String) {
		var songPath = SongData.resolveSongPath(songName);
		var song = new SongData(songPath, PlayState.getMedianDifficulty(songPath));
        songs.push(song);

		trace('added song: "$songPath"');

        return song;
    }

    function changeItem(delta:Int) {
		curSelected = FlxMath.wrap(curSelected += delta, 0, songTextList.length-1);
    }
}

typedef WeekData = {
	name:String,
	tag:String,
	?difficulties:Array<String>,
	songs:Array<WeekSong>,
	?weekRequired:Null<String>,
	?visibleInStoryMode:Null<Bool>,
    ?visibleInFreeplay:Null<Bool>
}

typedef WeekSong = {
    name:String,
    icon:String
}