package funkin.states;

class TitleState extends MusicBeatState
{
	introText:FlxText;

	override function create()
	{
		// Main create function
		super.create();

        introText = new FlxText(0, 0, 128, '');
        introText.setFormat(Paths.font('funkin'), 32 , 0xFFFFFFFF, FlxTextAlign.CENTER);
        introText.screenCenter();  
        add(introText);
	}

    private var beat:Int = 0;

    override function onBeatHit(beat:Int)
    {
        super.onBeatHit(beat);
        beat++;

        switch(beats)
        {
            case 1:
                introText.text = "Hai!";
            case 2:
                introText.text = "";
            case 3:
                introText.text = "Uhh...";
            case 4:
                introText.text = "End this demo pls";
            case 5:
                FlxG.switchState(new PlayState());
        }

    }
}
