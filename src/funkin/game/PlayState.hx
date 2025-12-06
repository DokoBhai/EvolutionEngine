package funkin.game;

import flixel.FlxObject;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

import funkin.game.*;
import funkin.game.system.*;
import funkin.game.system.SongData.ChartEventGroup;
import funkin.game.system.SongData.ChartEvent;
import funkin.game.system.SongData.Player;

import funkin.game.hud.StrumGroup;

import flixel.math.FlxPoint;

#if sys
import sys.FileSystem;
#end

import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.game.*;

enum BeatType
{
	STEP;
	BEAT;
	MEASURE;
}

typedef CharacterChangeData =
{
	character:Character,
	initialCharacter:String
}

@:access(funkin.game.system.SongData)
@:access(funkin.game.Stage)
@:access(funkin.game.objects.HUD)
@:access(funkin.game.objects.Character)
class PlayState extends ScriptableState
{
	public var stage:ScriptableStage;
	public var characters:Array<Character> = [];
	public var boyfriend:Character;
	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

	var __camZoomInterval(get, never):Int;
	public var camZoomInterval:Int = 1;
	public var camBeatEvery:BeatType = MEASURE;
	public var gameBeatZoom:Float = 0.028;
	public var hudBeatZoom:Float = 0.023;

	function get___camZoomInterval() {
		final mult = switch (camBeatEvery)
		{
			case MEASURE: 16;
			case BEAT: 4;
			case STEP: 1;
		}
		return camZoomInterval * mult;
	}

	public var camGame:FunkinCamera;
	public var camHUD:FunkinCamera;
	public var camFollow:FlxObject;
	public var hud:HUD;

	public var noteKillWindow:Float = 376; // in ms 
	public var spawnTime:Float = 2000; // in ms
	public var playerStrums:StrumGroup;
	public var opponentStrums:StrumGroup;

	public var inst:FlxSound;
	public var voices:VoicesHandler;

	public var songName(get, never):String;
	public var songPath(get, never):String;
	public var syncThreshold:Float = 25; // in ms
	
	// TEMPORARY
	public var pressLeEnter:FlxText;
	
	public var scrollSpeed:Float = 1;

	function get_songName()
		return song?.songName ?? '';

	function get_songPath()
		return song?.songPath ?? '';

	public var singAnimations:Array<String> = [ 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT' ];

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

	override function create() {
		final songToLoad = 'unknown-suffering';
		loadSong(songToLoad, getMedianDifficulty(songToLoad));

		if (songPath != null && Paths.exists('songs/$songPath/scripts'))
			addScriptsFromDirectory('songs/$songPath/scripts');

		set('game', this);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		Rating.add('sick', 45, 350);
		Rating.add('good', 90, 250);
		Rating.add('bad', 135, 100);
		Rating.add('shit', 188, 100);

		camGame = new FunkinCamera();
		FlxG.cameras.add(camGame);
		FlxG.camera = camGame;

		camFollow = new FlxObject();
		camGame.follow(camFollow, LOCKON, 0.083);

		camHUD = new FunkinCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		hud = new HUD(this);
		hud.camera = camHUD;
		add(hud);

		playerStrums = new StrumGroup();
		opponentStrums = new StrumGroup();
		playerStrums.camera = hud.camera;
		opponentStrums.camera = hud.camera;

		record('initial', true);

		stage = new ScriptableStage(song.stage);
		add(stage);
		camGame.defaultCamZoom = stage?.defaultCamZoom ?? 0.9;

		record('Stage Creation');

		scrollSpeed = (song?.scrollSpeed ?? 1) * GameplayModifiers.scrollMult;

		call('create');

		var sortedCharacter:Array<Player> = song?.characters ?? [];
		sortedCharacter.reverse(); // so the last added gets to the bottom
		for (j => char in sortedCharacter)
		{
			final i = sortedCharacter.length - 1 - j;
			var character = new Character(stage.characterPositions[i]?.x ?? 0, stage.characterPositions[i]?.y ?? 0, char.name, char.isPlayer);
			characters.push(character);
			character.hideStrumline = char.hideStrumline ?? false;
			character.characterID = i;
			add(character);
		}

		dad = first(characters.filter(c -> return !c.isPlayer && !c.isBopper));
		bf = first(characters.filter(c -> return c.isPlayer && !c.isBopper));
		gf = first(characters.filter(c -> return c.isBopper));
		boyfriend = bf;
		focusCharacter();

		record('Character Creation');

		inst = FlxG.sound.play(loadSound(Paths.inst(songPath)), 0.8, false);
		voices = new VoicesHandler(inst, songPath);

		inst.pause();
		voices.pause();

		for (character in characters)
			if (Paths.exists(Paths.voices(songPath, '-${character.name}', false), false))
				voices.addVoices('-${character.name}');

		for (postfix in ['-Player', '-Opponent', '-player', '-opponent'])
			if (Paths.exists(Paths.voices(songPath, postfix, false), false))
				voices.addVoices(postfix);

		record('Music Setup');

		hud.loadStrums();

		record('Strums Loaded');

		hud.loadNotes();

		record('Notes Loaded');

		loadEvents();

		for (strumline in hud.strumlines) {
			for (strum in strumline) {
				if (strum.cpu)
					opponentStrums.add(strum);
				else
					playerStrums.add(strum);
			}
		}

		if (GameplayModifiers.opponentMode) {
			for (strumline in hud.strumlines)
				strumline.cpu = !strumline.cpu;
		}

		super.create();

		call('createPost');

		// TEMPORARY
		pressLeEnter = new FlxText(0, 0, 0);
		pressLeEnter.camera = camHUD;
		pressLeEnter.setFormat(Paths.font('funkin'), 26, -1, CENTER, OUTLINE, 0xFF000000);
		pressLeEnter.applyMarkup('Press <y>ENTER<y> to Start the Song', [
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00), '<y>')
		]);
		pressLeEnter.borderSize = 2;
		pressLeEnter.screenCenter();
		add(pressLeEnter);
	}

	public var events:Array<ChartEventGroup> = [];
	function loadEvents() {
		final songEvents = song?.chart?.events ?? null;
		var characterChanges:Array<CharacterChangeData> = [];
		
		function changesExists(character:Character) {
			for (change in characterChanges) {
				if (change.character == character) {
					trace('Changes lol!');
					return true;
				}
			}
			return false;
		} 

		if (songEvents != null) {
			for (eventGroup in songEvents) {
				for (ev in eventGroup.events) {
					var scrEvent = new EventLoadEvent(eventGroup.strumTime, ev);
					call('onEventLoad', [scrEvent]);

					if (scrEvent.cancelled)
						eventGroup.events.remove(ev);
					else {
						switch(ev.event) {
							case 'Change Character': // character preloading
								final character = characterFromID(ev.values[0]);
								if (!changesExists(character))
									characterChanges.push({ character: character, initialCharacter: character.name });

								character.loadCharacter(ev.values[1]);
								var precachedCharacter = character.clone();
								precachedCharacter.alpha = 0.001;
								insert(members.indexOf(character), precachedCharacter);
								PrecacheUtil.precachedData.set('__character_data_${ev.values[1]}', precachedCharacter);
						}
					}
				}
				events.push(eventGroup);
			}
		}
		record('Looped through Events');

		for (change in characterChanges) {
			final char = change.character;
			char.loadCharacter(change.initialCharacter);
		}

		events.sort(HUD.sortByTime);
		call('onEventsLoaded', []);
	}

	var allowStart:Bool = true;
	override function update(elapsed:Float) {
		call('update', [elapsed]);

		if (inst != null)
		{
			if (Math.abs((voices.container[0] != null ? voices.time : inst.time) - (Conductor.songPosition - Conductor.offset)) > syncThreshold) {
				sync();
				trace('synced!');
			}
		}

		// this is obv wip, im js lazy rn
		for (key in ['A', 'S', 'UP', 'RIGHT']) {
			final pressed = Reflect.getProperty(FlxG.keys.pressed, key);
			final justPressed = Reflect.getProperty(FlxG.keys.justPressed, key);
			final justReleased = Reflect.getProperty(FlxG.keys.justReleased, key);

			if (pressed) keyPressed(key);
			if (justPressed) keyJustPressed(key);
			if (justReleased) keyJustReleased(key);
		}

		if (FlxG.keys.justPressed.ENTER && allowStart) {
			allowStart = false;
			startSong();

			pressLeEnter.kill();
		}

		checkForEvent(Conductor.songPosition);

		super.update(elapsed);

		call('updatePost', [elapsed]);
	}

	function checkForEvent(strumTime:Float) {
		for (eventGrp in events) {
			if (strumTime >= eventGrp.strumTime) {
				for (event in eventGrp.events)
					onEvent(event, eventGrp.strumTime);
				events.remove(eventGrp);
			} else
				break; // no point in iterating on future events
		}
	}

	function onEvent(event:ChartEvent, ?strumTime:Float = 0) {
		var scriptEvent = new EventTriggeredEvent(event, strumTime);
		call('onEvent', [scriptEvent]);
		
		if (!scriptEvent.cancelled) {
			switch (event.event) { // hardcoded events
				case 'Move Camera':
					focusCharacter(int(event.values[0]));
				case 'Change Character':
					for (i => char in characters) {
						if (char.characterID == event.values[0]) {
							final __lastChar = char;
							final __precachedTag = '__character_data_${event.values[1]}';
							char.kill();
							characters[i] = PrecacheUtil.precachedData.get(__precachedTag);
							PrecacheUtil.precachedData.remove(__precachedTag);
							
							char = characters[i];
							remove(__lastChar);
							char.setPosition(__lastChar.x, __lastChar.y);
							char.alpha = __lastChar.alpha;
							char.visible = __lastChar.visible;
							char.playAnim(__lastChar.animation.curAnim.name);

							for (note in hud.notes) {
								if (note.character == __lastChar)
									note.character = char;
							}

							for (strumline in hud.strumlines) {
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

	function focusCharacter(characterID:Int = 0) {
		characterID = int(FlxMath.bound(characterID, 0, characters.length-1));
		final character = characters[characterID];
		final pos = character.getCameraPosition();

		var event:CameraMoveEvent = new CameraMoveEvent(character, pos);
		call('onCameraMove', [event]);
		if (!event.cancelled)
			camFollow.setPosition(event.position.x, event.position.y);
	}

	function keyPressed(key:String) {
		call('keyPressed', [key]);

		final index = (['A', 'S', 'UP', 'RIGHT']).indexOf(key);
		for (strumline in hud.strumlines) {
			if (!strumline.cpu) {
				final strum = strumline.members[index];
				if (!strum.animation.name.contains('confirm')) {
					strum.allowStatic = false;
					strum.playAnim('press');
				}
			}
		}
	}

	function keyJustPressed(key:String) {
		call('keyJustPressed', [key]);

		final index = (['A', 'S', 'UP', 'RIGHT']).indexOf(key);
		for (note in hud.notes) {
			if (note.noteData == index && !note.strum.cpu) {
				if (note.canBeHit) {
					hitNote(note);
					break;
				}
			}
		}
	}

	function keyJustReleased(key:String) {
		call('keyJustReleased', [key]);

		final index = (['A', 'S', 'UP', 'RIGHT']).indexOf(key);
		for (strumline in hud.strumlines) {
			if (!strumline.cpu) {
				final strum = strumline.members[index];
				strum.playStatic();
			}
		}
	}

	public function sync() {
		inst.time = Conductor.songPosition - Conductor.offset;
		voices.sync();
	}

	public function startSong() {
		inst.play();
		voices.play();

		Conductor.trackedMusic = inst;
	}

	public static function loadSong(songName:String, ?difficulty:String) {
		difficulty ??= getDifficulties(songName)[0];
		if (Paths.chart(songName, difficulty) != null)
		{
			song = new SongData(songName, difficulty);
			Conductor.bpm = song.bpm;
		}
	}

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

	public static function getMedianDifficulty(?songName:String):String {
		songName ??= song?.songName ?? '';
		var difficulties = getDifficulties(songName);
		if (difficulties.length > 0)
			return difficulties[int(difficulties.length / 2)];

		return null;
	}

	public function characterFromID(id:Int):Null<Character> {
		for (i => char in characters) {
			if (char.characterID == id)
				return char;
		}
		return null;
	}

	public function characterIDFromName(name:String):Int {
		for (i => char in characters) {
			if (char.name == name)
				return char.characterID;
		}
		return -1;
	}

	public function characterFromName(name:String) {
		for (char in characters) {
			if (char.name == name)
				return char;
		}
		return null;
	}

	public function hitNote(note:Note) {
		final rating = Rating.judgeRating(note.strumTime, Conductor.songPosition);
		note.rating = rating;

		if (rating != 'miss') {
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
							note.character.playAnim(singAnimations[note.noteData] + note.animSuffix, true);

						hud.onNoteDestroyed.dispatch(note);
						hud.disposeNote(note);

						if (!note.cpu) {
							var ratingPop = Popup.recycle(300, 0, PrecacheUtil.image('gameplay/$rating'));
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

	public function noteMiss(note:Note) {
		var event = new NoteEvent(note);
		callHScript('noteMiss', [event]);
		if (note.strum.cpu) callHScript('cpuNoteMiss', [event]); // amusia is that you?
		else callHScript('playerNoteMiss', [event]);

		if (!event.cancelled) {
			if (!note.missed && !note.hit && note.spawned) {
				note.missed = true;
				if (note.character != null)
					note.character.playAnim('${singAnimations[note.noteData]}miss' + note.animSuffix, true);

				FlxTween.tween(note, { 
					multAlpha: 0,
					multSpeed: 0.75,
					'colorTransform.redOffset': 255,
					'colorTransform.blueOffset': 255,
					'colorTransform.greenOffset': 255
				}, 0.2, { ease: FlxEase.cubeIn });
			}
		}
	}

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

	override function beatHit(curBeat:Int) {
		super.beatHit(curBeat);

		call('beatHit', [curBeat]);
		set('curBeat', curBeat);
		callBeatListeners(l -> l.beatHit(curBeat));
	}

	override function measureHit(curMeasure:Int) {
		super.measureHit(curMeasure);

		call('measureHit', [curMeasure]);
		set('curMeasure', curMeasure);
		callBeatListeners(l -> l.measureHit(curMeasure));
	}

	override function call(f:String, ?args:Array<Dynamic>) {
		super.call(f, args);
		stage.call(f, args);
	}

	function callBeatListeners(f:Dynamic->Void) {
		for (character in characters)
			try {
				f(character);
			} catch(e:Dynamic)
				trace(e.toString());

		f(stage);
		f(hud);
	}
}
