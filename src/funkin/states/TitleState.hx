package funkin.states;

class TitleState extends MusicBeatState
{
	var introText:FlxText;

	override function create()
	{
		// Main create function
		super.create();

        introText = new FlxText(0, 0, 500, '');
        introText.setFormat(Paths.font('funkin'), 32 , 0xFFFFFFFF, FlxTextAlign.CENTER);
        introText.screenCenter();
        add(introText);
		FlxG.sound.playMusic(loadSound(Paths.music('freakyMenu')));
		Conductor.trackedMusic = FlxG.sound.music;
		Conductor.bpm = 102;
	}

    private var beats:Int = 0;

    override function beatHit(curBeat:Int)
    {
        super.beatHit(curBeat);
        beats++;

        switch(beats)
        {
            case 1:
                introText.text = "Hai!";
            case 2:
                introText.text = "";
            case 3:
                introText.text = "Uhh...";
            case 4:
                introText.text = "";
            case 5:
                introText.text = "We love friday night funkin!";
            case 6:
                introText.text = "Engine by: \n Ghostglowdev \n T-bar \n SwagaRuney";
            case 7:
                introText.text = "Engine by: \n Ghostglowdev \n T-bar \n SwagaRuney";
            case 8:
                introText.text = "Engine by: \n Ghostglowdev \n T-bar \n SwagaRuney";
            case 8:
                introText.text = "";
            case 9:
                introText.text = "End this demo pls";
            case 10:
                FlxG.switchState(new FreeplayState());
        }

    }
}
