package funkin.states;

import flixel.text.FlxText;
import funkin.game.system.SongData;
import funkin.game.PlayState;

import sys.FileSystem;

// this is temporary until we add more features to freeplay
class FreeplayState extends MusicBeatState {
    var songs:Array<SongData> = [];
    var songList:Array<FunkinText> = [];

    var curSelected:Int = 0;

    override function create() {
        super.create();

        for (i => songPath in FileSystem.readDirectory('assets/songs')) {
			final songData = addSong(songPath);

            var text = new FunkinText(0, i * 50, 0, songData.songName);
            text.setFormat(Paths.font('funkin'), 44);
            add(text);
            songList.push(text);
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP)
            changeItem(-1);
        else if (FlxG.keys.justPressed.DOWN)
            changeItem(1);

        for (i => songTxt in songList) {
            songTxt.color = (i == curSelected ? 0xFFFFFF00 : 0xFFFFFFFF);
        }

        if (FlxG.keys.justPressed.ENTER) {
            var selectedSong = songs[curSelected];
            PlayState.loadSong(selectedSong.songPath);
            FlxG.switchState(new PlayState());
        }
    }

    function addSong(songPath:String) {
        var song = new SongData(songPath, PlayState.getMedianDifficulty(songPath));
        songs.push(song);

        trace('added song: "$songPath"');

        return song;
    }

    function changeItem(delta:Int) {
        curSelected = FlxMath.wrap(curSelected += delta, 0, songList.length-1);
    }
}