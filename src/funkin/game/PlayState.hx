package funkin.game;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.game.*;
import funkin.game.*;
import funkin.game.hud.StrumGroup;
import funkin.game.system.*;
import funkin.game.system.SongData.ChartEvent;
import funkin.game.system.SongData.ChartEventGroup;
import funkin.game.system.SongData.Player;
import funkin.game.hud.StrumGroup;

#if sys
import sys.FileSystem;
#end

import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.game.*;

enum BeatType {
    STEP;
    BEAT;
    MEASURE;
}

typedef CharacterChangeData = {
    character:Character,
    nextCharacter:String,
    previousCharacter:String
}

typedef CampaignData = {
	score:Int,
	misses:Int,
	accuracy:Float,

	sicks:Int,
	goods:Int,
	bads:Int,
	shits:Int
}

class PlayState extends ScriptableState {
    // basic game objects
    public var stage:ScriptableStage;
    public var characters:Array<Character> = [];
	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

    public var camGame:FunkinCamera;
    public var camHUD:FunkinCamera;
    public var camFollow:FlxObject;
    public var hud:HUD;

	// basic song elements
	public var inst:FlxSound;
	public var voices:VoicesHandler;

    // aliases
	public var boyfriend(get, never):Character;
	public var girlfriend(get, never):Character;

    function get_boyfriend():Character return bf;
	function get_girlfriend():Character return gf;

    // camera attributes
    var __camZoomInterval(get, never):Int;
    public var camZoomInterval:Int = 1;
    public var camBeatEvery:BeatType = MEASURE;
    public var gameBeatZoom:Float = 0.028;
    public var hudBeatZoom:Float = 0.015;

    function get___camZoomInterval() {
		final mult = switch (camBeatEvery)
		{
			case MEASURE: 16;
			case BEAT: 4;
			case STEP: 1;
		}
		return camZoomInterval * mult;
	}

    // gameplay attributes
    public var noteKillWindow:Float = 376;
    public var spawnTime:Float = 2000;
    public var playerStrums:StrumGroup;
    public var opponentStrums:StrumGroup;
    public var scrollSpeed:Float = 1;

	// scoring-related
	public var songScore:Int = 0;
	public var songMisses:Int = 0;
	public var songAccuracy:Float = 0;
	public var ratingName:String = 'N/A';
	
	public static var ratingList:Map<String, Float> = [
		'X'  => 1,
		'S+' => 0.99,
		'S'  => 0.95,
		'A'  => 0.9,
		'B'  => 0.8,
		'C'  => 0.65,
		'D'  => 0.5,
		'E'  => 0.55,
		'F'  => 0.4
	];

	public static var weekPlaylist:Array<String> = [];
	public static var weekDifficulty:String = '';
	public static var defaultCampaignData:CampaignData = {
		score: 0, misses: 0, accuracy: 0,
		sicks: 0, goods: 0, bads: 0, shits: 0
	}
	public static var campaignData:CampaignData = copyStruct(defaultCampaignData);

    // song attributes
	public var songName(get, never):String;
	public var songPath(get, never):String;
    public var songStarted:Bool = false;
    public var songEnded:Bool = false;
    public var syncThreshold:Float = 25; // in ms
	public var health(default, set):Float = 1;
	public function set_health(val:Float):Float {
		health = FlxMath.bound(val, 0, 2);
		if(hud != null) hud.updateHealthIcons();
		return health;
	}

	function get_songName() return song?.songName ?? '';
	function get_songPath() return song?.songPath ?? '';

    // misc
    public var singAnims:Array<String> = [
        'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'
    ];
    public var keyNames:Array<String> = [
        'note_left', 'note_down', 'note_up', 'note_right'
    ];

    // static vars 
    public static var song(default, set):SongData;
    public static var isPixelStage(default, set):Bool = false;

	static function set_song(data:SongData)
	{
		if (data.chart == null)
			return song = null;

		return song = data;
	}

	// wip
	static function set_isPixelStage(value:Bool)
		return isPixelStage = value;

	// TEMPORARY UNTIL COUNTDOWN IS A THING!!
	public var pressLeEnter:FlxText;
    public var pressedEnter:Bool = false;

    override function create() {
        if (song == null) {
            final songToLoad = 'unknown-suffering';
            loadSong(songToLoad, getMedianDifficulty(songToLoad));
        }

        // loading scripts
		if (songPath != null && Paths.exists('songs/$songPath/scripts'))
			addScriptsFromDirectory('songs/$songPath/scripts');
        
		set('game', this);

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        // ratings initialization
		Rating.add('sick', 45, 350);
		Rating.add('good', 90, 250);
		Rating.add('bad', 135, 100);
		Rating.add('shit', 188, 100);

        // cameras
		camGame = new FunkinCamera();
		FlxG.cameras.add(camGame);
		FlxG.camera = camGame;

		camFollow = new FlxObject();
		camGame.follow(camFollow, LOCKON, 0.083);

		camHUD = new FunkinCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

        // hud elements
		hud = new HUD(this);
		hud.camera = camHUD;
		add(hud);

		playerStrums = new StrumGroup();
		opponentStrums = new StrumGroup();
		playerStrums.camera = hud.camera;
		opponentStrums.camera = hud.camera;

        // loading stage
        stage = new ScriptableStage(song.stage);
        add(stage);
        camGame.defaultCamZoom = stage?.defaultCamZoom ?? 0.9;

        scrollSpeed = (song?.scrollSpeed ?? 1) * GameplayModifiers.scrollMult;
        
		call('create');

        var characterInfos:Array<Player> = (song?.characters ?? []);
		characterInfos.reverse();
        for (j => charInfo in characterInfos) {
            final i = characterInfos.length - 1 - j;
            var character = new Character(stage.characterPositions[i]?.x ?? 0, stage.characterPositions[i]?.y ?? 0, charInfo.name, charInfo.isPlayer);
            character.hideStrumline = charInfo.hideStrumline ?? false;
            character.characterID = i;
            add(character);
            characters.push(character);
        }

		dad = first(characters.filter(c -> return !c.isPlayer && !c.isBopper));
		bf = first(characters.filter(c -> return c.isPlayer && !c.isBopper));
		gf = first(characters.filter(c -> return c.isBopper));
		focusCharacter();

        inst = new FlxSound();
        inst.loadEmbedded(loadSound(Paths.inst(songPath)), false, false, endSong);
        inst.volume = 0.8;
        FlxG.sound.list.add(inst);

        voices = new VoicesHandler(inst, songPath);

        inst.pause();
        voices.pause();
        initVoices();

        hud.loadStrums();
        hud.loadNotes();
		initEvents();

		hud.loadHealthBar("bf", "bf");
		health = 1;

		hud.loadScoreText();

		if (GameplayModifiers.opponentMode)
		{
			for (strumline in hud.strumlines)
				strumline.cpu = !strumline.cpu;
		}

        super.create();

        call('createPost');

        // TEMPORARY
		pressLeEnter = new FlxText(0, 0, 0);
		pressLeEnter.camera = camHUD;
		pressLeEnter.setFormat(Paths.font('funkin'), 26, -1, CENTER, OUTLINE, 0xFF000000);
		pressLeEnter.applyMarkup('Press <y>ENTER<y> to Start the Song', [new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00), '<y>')]);
		pressLeEnter.borderSize = 2;
		pressLeEnter.screenCenter();
		add(pressLeEnter);
    }

    /**
     * Loads additional voice files for characters if they exists.
     */
    function initVoices() {
        for (character in characters) {
			if (Paths.exists(Paths.voices(songPath, '-${character.name}', false), false))
				voices.addVoices('-${character.name}');

			for (postfix in ['-Player', '-Opponent', '-player', '-opponent'])
				if (Paths.exists(Paths.voices(songPath, postfix, false), false))
					voices.addVoices(postfix);
        }
    }
    
    public var events:Array<ChartEventGroup> = [];
    /**
     * Initializes the events defined in the song's difficulty chart.
     */
    function initEvents() {
        final songEvents = song?.chart?.events ?? null;
        if (songEvents == null)
            return;

        var hasCharacterChanges:Bool = false;
        final collectedChanges:Array<CharacterChangeData> = [];
        for (eventGrp in songEvents) {
            for (event in eventGrp.events) {
                var scriptEvent = new EventLoadEvent(eventGrp.strumTime, event);
                call('onLoadEvent', [scriptEvent]);

                if (scriptEvent.cancelled)
                    eventGrp.events.remove(event);
                else {
                    switch(event.event) {
                        case 'Change Character': // character preloading
                            hasCharacterChanges = true;

							final char = characterFromID(event.values[0]);
                            collectedChanges.push({
                                character: char,
                                nextCharacter: event.values[1],
								previousCharacter: char.name
                            });
                    }
                }
				events.push(eventGrp);
            }
        }

        if (hasCharacterChanges) {
            initCharacterChanges(collectedChanges);
        }

        events.sort(HUD.sortByTime);
        call('onEventsLoaded', []); 
    }

    /**
     * Precaches characters that will present later in the song based on the given changes.
     * @param changes an Array of CharacterChangeData.
     */
    function initCharacterChanges(changes:Array<CharacterChangeData>) {
		function changesExists(character:Character) {
			for (change in changes)
			{
				if (change.character == character)
				{
					trace('character "${character.name}" has changes, lol!');
					return true;
				}
			}
			return false;
		}

        for (change in changes) {
            final character = change.character;
            character.loadCharacter(change.nextCharacter);

            var precachedChar = character.clone();
			precachedChar.alpha = 0.001;
			insert(members.indexOf(character), precachedChar);

            @:privateAccess
			PrecacheUtil.__cache.set('character_obj_${change.nextCharacter}', [precachedChar]);
        
            changes.remove(change);

            if (!changesExists(character)) {
				character.loadCharacter(change.previousCharacter);
            }
        }
    }

    var allowStart:Bool = true;
    override function update(elapsed:Float) {
		call('update', [elapsed]);

        if (inst != null) {
			if (!songEnded && Math.abs((voices.container[0] != null ? voices.time : inst.time) - (Conductor.songPosition - Conductor.offset)) > syncThreshold) {
				sync();
				trace('synced!');
			}
        }

        checkForKeys();
        checkForPause();

        checkForEvent(Conductor.songPosition);

		if (FlxG.keys.justPressed.BACKSPACE) {
			FlxG.switchState(new funkin.states.FreeplayState());
		}

		super.update(elapsed);

		call('updatePost', [elapsed]);

		if (!pressedEnter && FlxG.keys.justPressed.ENTER)
		{
			pressedEnter = true;

			startSong();
			pressLeEnter.kill();
		}
    }

    /*
     * ######################
     * ##   INPUT CHECKS   ##
     * ######################
     */

    /**
     * Checks for key presses for each keybinds, calls keyPressed, keyJustPressed or keyJustReleased
       corresponding to the current user action.
     */
    function checkForKeys() {
        for (keyName => keybinds in Preferences.keyBinds) {
            final index = keyNames.indexOf(keyName);
			if (FlxG.keys.anyPressed(keybinds)) keyPressed(index);
			if (FlxG.keys.anyJustPressed(keybinds)) keyJustPressed(index);
			if (FlxG.keys.anyJustReleased(keybinds)) keyJustReleased(index);
        }
    }

	/**
	 * Checks if the pause key was pressed, pause the game if so.
	 * Can be cancelled with scripts.
	 */
	var isPaused:Bool = false;

	var canPause:Bool = true;

	function checkForPause()
	{
		if (FlxG.keys.justPressed.ENTER && canPause && pressedEnter && !songEnded)
		{
			var subState = new funkin.game.substates.PauseSubstate(this);
			var event:GamePauseEvent = new GamePauseEvent(Conductor.songPosition, subState);

			call('onPause', [event]);
			if (!event.cancelled)
			{
				persistentDraw = true;
				persistentUpdate = false;
				isPaused = true;

				openSubState(subState);
			}
			else
				subState.close();
		}
	}

	// Just some managing for substates, so the song pauses when a substate is opened
	override function openSubState(SubState:FlxSubState)
	{
		if (isPaused) {
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);

			inst?.pause();
			voices?.pause();
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		super.closeSubState();

		if (isPaused) {
			sync();
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);

			isPaused = false;
			persistentDraw = true;
			persistentUpdate = true;
			inst?.resume();
			voices?.resume();
		}
	}

    function keyPressed(key:Int) {
		call('keyPressed', [key]);

		for (strumline in hud.strumlines) {
			if (!strumline.cpu) {
				final strum = strumline.members[key];
				if (!strum.animation.name.contains('confirm')) {
					strum.allowStatic = false;
					strum.playAnim('press');
				}
			}
		}
	}

	function keyJustPressed(key:Int) {
		call('keyJustPressed', [key]);

		for (note in hud.notes) {
			if (note.noteData == key && !note.strum.cpu) {
				if (note.canBeHit) {
					hitNote(note);
					break;
				}
			}
		}
	}

	function keyJustReleased(key:Int) {
		call('keyJustReleased', [key]);

		for (strumline in hud.strumlines) {
			if (!strumline.cpu) {
				final strum = strumline.members[key];
				strum.playStatic();
			}
		}
	}

	/*
	 * ############################
	 * ##   SONG EVENT-RELATED   ##
	 * ############################
	 */

    function checkForEvent(strumTime:Float) {
		for (eventGrp in events) {
			if (strumTime >= eventGrp.strumTime) {
				for (event in eventGrp.events)
					triggerEvent(event, eventGrp.strumTime);
				events.remove(eventGrp);
			}
			else
				break; // no point in iterating on future events
		}
    }

    function triggerEvent(event:ChartEvent, ?strumTime:Float) {
        strumTime ??= Conductor.songPosition;

        var scriptEvent = new EventTriggeredEvent(event, strumTime);
        call('onEvent', [scriptEvent]);

        if (!scriptEvent.cancelled) {
			switch (event.event) { // hardcoded events
				case 'Move Camera':
					focusCharacter(int(event.values[0]));
				case 'Change Character':
					for (i => char in characters)
					{
						if (char.characterID == event.values[0])
						{
							final __lastChar = char;
							final __precachedTag = '__character_data_${event.values[1]}';
							char.kill();

							@:privateAccess {
								characters[i] = PrecacheUtil.__cache.get(__precachedTag);
								PrecacheUtil.__cache.remove(__precachedTag);
							}

							char = characters[i];
							remove(__lastChar);
							char.setPosition(__lastChar.x, __lastChar.y);
							char.alpha = __lastChar.alpha;
							char.visible = __lastChar.visible;
							char.playAnim(__lastChar.animation.curAnim.name);

							for (note in hud.notes)
							{
								if (note.character == __lastChar)
									note.character = char;
							}

							for (strumline in hud.strumlines)
							{
								if (strumline.character == __lastChar)
									Reflect.setProperty(strumline, 'character', char);
							}

							break;
						}
					}
				case 'Play Animation':
					final character = characterFromID(event.values[1]);
					character.playAnim(event.values[0], true);
					character.specialAnim = true;
				case 'Add Camera Zoom':
					camGame.zoom += event.values[0];
					camHUD.zoom += event.values[1];
            }
        }
    }

	/*
	 * ########################
	 * ##   CAMERA-RELATED   ##
	 * ########################
	 */

    function focusCharacter(characterID:Int = 0) {
		characterID = int(FlxMath.bound(characterID, 0, characters.length - 1));
		final character = characters[characterID];
		final pos = character.getCameraPosition();

		var event:CameraMoveEvent = new CameraMoveEvent(character, pos);
		call('onCameraMove', [event]);
		if (!event.cancelled)
			camFollow.setPosition(event.position.x, event.position.y);
    }

	/*
	 * ################################
	 * ##   NOTE HIT/MISS HANDLERS   ##
	 * ################################
	 */

    /**
     * Hits the specified note.
     * Meant to be called internally.
     * @param note The note to be hit.
     */
    public function hitNote(note:Note) {
		final rating = Rating.judge(note.strumTime, Conductor.songPosition);
		if (rating == null) return;
		
		final ratingName = rating?.name ?? '';
		note.rating = ratingName;

		if (ratingName != 'miss') {
			var event = new NoteEvent(note);
			callHScript('noteHit', [event]);
			if (note.strum.cpu) callHScript('cpuNoteHit', [event]);
			else callHScript('playerNoteHit', [event]);

			if (!event.cancelled) {
				if (!note.missed && !note.hit && note.spawned) {
					if (note.canBeHit) {						
						note.hit = true;
						note.strum.playAnim('confirm', true);

						if (note.character != null)
							note.character.playAnim(singAnims[note.noteData] + note.animSuffix, true);

						hud.onNoteDestroyed.dispatch(note);
						hud.disposeNote(note);

						if (!note.cpu) {
							health += note.hitHealth ?? 0.023;
							if (!note.isSustainNote) {
								songScore += rating.score;
								rating.hits++;
							}

							var ratingPop = Popup.recycle(300, 0, PrecacheUtil.image('gameplay/${ratingName}'));
							ratingPop.scale.set(0.6, 0.6);
							ratingPop.updateHitbox();
							ratingPop.pop();
							add(ratingPop);
						}

						return;
					}
				}
			}
			note.rating = '';
		} else noteMiss(note);
	}

	/**
     * Misses the specified note.
	 * Meant to be called internally.
	 * @param note The note to miss.
	 */
	public function noteMiss(note:Note) {
		var event = new NoteEvent(note);
		callHScript('noteMiss', [event]);
		if (note.strum.cpu) callHScript('cpuNoteMiss', [event]); // amusia is that you?
		else callHScript('playerNoteMiss', [event]);

		if (!event.cancelled) {
			if (!note.missed && !note.hit && note.spawned) {
				note.missed = true;
				if (note.character != null)
					note.character.playAnim('${singAnims[note.noteData]}miss' + note.animSuffix, true);

				FlxTween.tween(note, { 
					multAlpha: 0,
					multSpeed: 0.75,
					'colorTransform.redOffset': 255,
					'colorTransform.blueOffset': 255,
					'colorTransform.greenOffset': 255
				}, 0.2, { ease: FlxEase.cubeIn });

				if (!note.cpu) {
					health -= note.missHealth ?? 0.043;
				
					if (!note.isSustainNote) {
						songScore -= 10;
						songMisses++;
					}
				}
			}
		}
	}

	/*
	 * #########################
	 * ##   BACKEND HELPERS   ##
	 * #########################
	 */

    /**
     * Syncs the music time for both instrumental and voices to the Conductor's song position.
     */
    public function sync() {
		inst.time = Conductor.songPosition - Conductor.offset;
		voices.sync();
	}

	/**
	 * Starts the song.
	 */
	public function startSong() {
		inst.play();
		voices.play();

		Conductor.trackedMusic = inst;

		songStarted = true;
	}

	/**
	 * Ends the song.
	 */
    public function endSong() {
		songEnded = true;
		PrecacheUtil.clear();
	}

    /**
     * Loads the song data, meant to be called before PlayState's creation.
     * @param songName The song to load.
     * @param difficulty The target difficulty of the song, defaults to the song's first difficulty.
     */
    public static function loadSong(songName:String, ?difficulty:String) {
		difficulty ??= getDifficulties(songName)[0];
		if (Paths.chart(songName, difficulty) != null)
		{
			song = new SongData(songName, difficulty);
			Conductor.bpm = song.bpm;
		}
	}

	/**
	 * Fetches the list of a song's difficulties
	 * @param songName The song to fetch the difficulty list of. Defaults to the current song.
	 * @return an Array of difficulty names.
	 */
	public static function getDifficulties(?songName:String):Array<String> {
		var diffs:Array<String> = [];
		songName ??= song?.songName ?? '';
		if (Paths.exists(Paths.song('$songName/charts', true), true))
		{
			for (diff in FileSystem.readDirectory(Paths.song('$songName/charts', true)))
			{
				if (diff.endsWith('.json'))
				{
					diff = diff.replace('.json', '');
					diffs.push(diff);
				}
			}
		}
		return diffs;
	}

	/**
	 * Fetches the middle difficulty of a song.
	 * @param songName The song to fetch the median difficulty of. Defaults to the current song.
	 * @return The difficulty name.
	 */
	public static function getMedianDifficulty(?songName:String):String {
		songName ??= song?.songName ?? '';
		var difficulties = getDifficulties(songName);
		if (difficulties.length > 0)
			return difficulties[int(difficulties.length / 2)];

		return null;
	}

	/**
	 * Fetches the Character object from the specified ID.
	 * @param id The ID number of the target Character.
	 * @return The Character object, can be null.
	 */
	public function characterFromID(id:Int):Null<Character> {
		for (char in characters) {
			if (char.characterID == id)
				return char;
		}
		return null;
	}

	/**
	 * Fetches the ID of the first Character found associated with the specified name.
	 * @param name The name of the target Character.
	 * @return The character's ID. `-1` is returned instead if the character isn't found.
	 */
	public function characterIDFromName(name:String):Int {
		for (char in characters) {
			if (char.name == name)
				return char.characterID;
		}
		return -1;
	}

	/**
	 * Fetches the first Character object found associated with the specified name.
	 * @param name The name of the target Character.
	 * @return The Character object, can be null.
	 */
	public function characterFromName(name:String):Null<Character> {
		for (char in characters) {
			if (char.name == name)
				return char;
		}
		return null;
	}

	/*
	 * #####################
	 * ##   BEAT EVENTS   ##
	 * #####################
	 */

	override function stepHit(curStep:Int) {
		super.stepHit(curStep);

		call('stepHit', [curStep]);
		set('curStep', curStep);
		callBeatListeners(l -> l.stepHit(curStep));

		if (curStep == 0)
			voices.sync(); // apparently syncs up the vocals on song start?

		if (curStep % __camZoomInterval == 0)
		{
			camGame.zoom += gameBeatZoom;
			camHUD.zoom += hudBeatZoom;
		}
	}

	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);

		call('beatHit', [curBeat]);
		set('curBeat', curBeat);
		callBeatListeners(l -> l.beatHit(curBeat));
	}

	override function measureHit(curMeasure:Int)
	{
		super.measureHit(curMeasure);

		call('measureHit', [curMeasure]);
		set('curMeasure', curMeasure);
		callBeatListeners(l -> l.measureHit(curMeasure));
	}

    /**
     * Calls the corresponding beat function on the game's beat listeners.
     * Meant to be called internally.
     * @param f 
     */
    function callBeatListeners(f:Dynamic->Void) {
		for (character in characters)
			try
			{
				f(character);
			}
			catch (e:Dynamic)
				trace(e.toString());

		f(stage);
		f(hud);
	}

	/*
	 * ###################
	 * ##   SCRIPTING   ##
	 * ###################
	 */

    override function call(f:String, ?args:Array<Dynamic>) {
		super.call(f, args);
		stage.call(f, args);
	}
}