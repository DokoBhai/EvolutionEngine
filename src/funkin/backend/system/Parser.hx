package funkin.backend.system;

import funkin.game.Character.AnimationData;
import funkin.game.Character.CharacterData;
import funkin.game.Character.CodenameAnimationData;
import funkin.game.Character.CodenameCharacter;
import funkin.game.Character.PsychAnimationData;
import funkin.game.Character.PsychCharacter;
import funkin.game.system.SongData.ChartNote;
import funkin.game.system.SongData.ChartEvent;
import funkin.game.system.SongData.ChartEventGroup;
import funkin.game.system.SongData.Player;
import funkin.game.system.SongData.PsychSection;
import funkin.game.system.SongData.PsychSong;
import funkin.game.system.SongData.Song;
import funkin.game.system.SongData;
import funkin.game.Stage.StageData;
import tjson.TJSON;
#if sys
import sys.io.File;
#end

enum EngineType
{
	EVOLUTION;
	CODENAME;
	PSYCH;
	UNKNOWN;
}

enum ChartEngineType
{
	EVOLUTION;
	CODENAME;
	PSYCH;
	PSYCH_LEGACY;
	VSLICE;
	UNKNOWN;
}

// ts so ahh 🥀

@:access(funkin.game.objects.Character)
@:access(funkin.states.debug.ChartEditor)
@:access(funkin.game.system.SongData)
@:access(funkin.game.Stage)
@:publicFields class Parser {
	static function chart(content:String, ?from:ChartEngineType = EVOLUTION, ?to:ChartEngineType = EVOLUTION):Dynamic {
		switch (to) {
			case EVOLUTION:
				switch (from) {
					case EVOLUTION:
						var data:Song = TJSON.parse(content);
						return data;
					case CODENAME:
						// wip
						return {};
					case PSYCH:
						var unsafeJson:Dynamic = TJSON.parse(content);
						var chartJson:PsychSong;
						if (unsafeJson.song != null && !(unsafeJson.song is String)) { // check for legacy
							return chart(content, PSYCH_LEGACY);
						} else
							chartJson = cast unsafeJson;

						var data:PsychSong = chartJson;
						var characters:Array<Player> = [
							{ name: data.player2,   isPlayer: false, isBopper: false, hideStrumline: false }, // dad
							{ name: data.player1,   isPlayer: true,  isBopper: false, hideStrumline: false }, // bf
							{ name: data.gfVersion, isPlayer: false, isBopper: true,  hideStrumline: true  }  // gf
						];

						var events:Array<ChartEventGroup> = [];
						for (eventGrp in data.events)
						{
							if (eventGrp.strumTime != null)
								continue; // weird bug, fix later

							final strumTime:Float = eventGrp[0];
							final groupEvents:Array<Array<String>> = eventGrp[1];

							var eventGroup:ChartEventGroup = {
								strumTime: strumTime,
								events: []
							};

							if (groupEvents.length > 0) {
								function resolveCharacterID(charName:Dynamic):Dynamic {
									if (charName is Int) return charName;
									return switch(charName) {
										case 'bf'  | 'boyfriend'  | 'player': 1;
										case 'gf'  | 'girlfriend' | 'bopper' | 'speaker': 2;
										default: 0;
									}
								}

								for (event in groupEvents)
								{
									var chartEvent:ChartEvent = {
										event: event[0],
										values: [ event[1], event[2] ]
									};

									switch(event[0]) { // changed values
										case 'Change Character':
											chartEvent.values[0] = resolveCharacterID(event[1]);
										case 'Play Animation':
											chartEvent.values[1] = resolveCharacterID(event[0]);
										case 'Add Camera Zoom':
											for (i => value in chartEvent.values)
												chartEvent.values[i] = Std.parseFloat(value);
									}
									eventGroup.events.push(chartEvent);
								}
								events.push(eventGroup);
							}
						}

						function pushEvent(strumTime:Float, event:String, values:Array<Dynamic>):ChartEventGroup {
							for (eventGroup in events) {
								if (eventGroup.strumTime == strumTime) {
									eventGroup.events.push({ event: event, values: values });
									return eventGroup;
								}
							}

							var eventGroup:ChartEventGroup = {
								strumTime: strumTime,
								events: [{ event: event, values: values }]
							};
							events.push(eventGroup);

							return eventGroup;
						}

						var notes:Array<ChartNote> = [];
						var lastSection:PsychSection = null;
						var beatsElapsed:Int = 0;
						var curBPM:Float = data.bpm;
						for (section in data.notes)
						{
							final gfSec = section.gfSection;
							final mustHit = section.mustHitSection;

							if (lastSection != null) {
								final crochet = 60000 / curBPM;
								final sectionTime = beatsElapsed * crochet;
								if (lastSection.mustHitSection != mustHit)
									pushEvent(sectionTime, 'Move Camera', [ mustHit ? 1 : 0 ]);

								if (section.changeBPM) {
									curBPM = section.bpm;
									pushEvent(sectionTime, 'Change BPM', [ section.bpm ]);
								}
							}
							lastSection = section;
							beatsElapsed += section?.sectionBeats ?? int((section?.lengthInSteps ?? 0) / 4);
							
							if (section.sectionNotes != null) {
								for (secNote in section.sectionNotes)
								{
									final strumTime = secNote[0];
									final noteData = secNote[1];
									final susLen = secNote[2];
									var characterID:Int = (gfSec && mustHit && noteData <= 3) ? 2 : -1;
									if (characterID < 0)
										characterID = noteData <= 3 ? 0 : 1;

									var note:ChartNote = {
										strumTime: strumTime,
										noteData: noteData % 4,
										sustainLength: susLen,
										character: characterID
									}

									if (secNote.length > 3) // has noteType
										note.noteType = secNote[3];

									notes.push(note);
								}
							}
						}

						var returnData:Song = {
							characters: characters,
							song: data.song,
							hasVoices: data.needsVoices,
							stage: data.stage,
							bpm: data.bpm,
							scrollSpeed: data.speed,
							notes: notes,
							events: events,
							keys: 4,
							postfix: '',
							evoChart: true
						};
						return returnData;
					case PSYCH_LEGACY:
						var data:PsychSong = TJSON.parse(content).song;
						if (Reflect.hasField(data, 'notes')) {
							for (section in data.notes) {
								if (section.sectionNotes != null && section.sectionNotes?.length ?? 0 > 0 && section.mustHitSection) {
									for (note in section.sectionNotes) {
										if (note[1] > 3) // noteData
											note[1] = note[1] % 4;
										else
											note[1] += 4;
									}
								}
							}
						}

						return chart(haxe.Json.stringify(data), PSYCH);
					case VSLICE:
						// wip
						return {};
					case UNKNOWN: return {};
				}
			case CODENAME:
				// wip
				return null;
			case PSYCH:
				// wip
				return null;
			case PSYCH_LEGACY:
				return chart(content, from, PSYCH);
			case VSLICE:
				// wip
				return null;
			case UNKNOWN:
				return null;
		}
	}

	static function character(path:String, ?from:EngineType = EVOLUTION, ?to:EngineType = EVOLUTION, ?reload:Bool = false):Dynamic
	{
		var unsafeJson:Dynamic = PrecacheUtil.data(path, reload);
		switch (to) {
			case EVOLUTION:
				switch (from)
				{
					case EVOLUTION:
						var data = unsafeJson;
						return data;
					case CODENAME:
						// wip
						return {};
					case PSYCH:
						var data:PsychCharacter = unsafeJson;
						var animations:Array<AnimationData> = [];
						for (animData in data.animations)
						{
							var animation:AnimationData = {
								animName: animData.anim,
								prefix: animData.name,
								offset: animData.offsets,
								frameRate: animData.fps,
								indices: animData.indices,
								looped: animData.loop
							};
							animations.push(animation);
						}

						var returnData:CharacterData = {
							name: '',
							icon: data.healthicon,
							antialiasing: !data.no_antialiasing,
							source: data.image.replace('characters/', ''),
							healthColors: fromRGBArray(data.healthbar_colors),
							cameraOffsets: data.camera_position,
							holdTime: data.sing_duration,
							scale: data.scale,
							flipped: data.flip_x,
							animations: animations
						};

						return returnData;
					case UNKNOWN: return {};
				}
			case CODENAME:
				// wip
				return null;
			case PSYCH:
				// wip
				return null;
			case UNKNOWN:
				return null;
		}
		return null;
	}

	static function stage(content:String, ?from:EngineType = EVOLUTION, ?to:EngineType = EVOLUTION):Dynamic {
		switch(from) {
			case EVOLUTION:
				switch(to) {
					case EVOLUTION:
						var data:StageData = TJSON.parse(content);
						return data;
					case CODENAME:
						// wip
						return null;
					case PSYCH:
						// wip
						return null;
					case UNKNOWN:
						return null;
				}
			case CODENAME:
				// wip
				return null;
			case PSYCH:
				// wip
				return null;
			case UNKNOWN:
				return null;
		}
	}

	static function saveJson(path:String, content:Dynamic, ?absolute:Bool = false):String
	{
		final jsonContent = haxe.Json.stringify(content, '\t');
		try
		{
			if (Paths.exists('$path.json', absolute)) {
				FileUtil.saveContent(Paths.getPath('$path.json'), jsonContent);
				PrecacheUtil.data(Paths.getPath('$path.json'), true);
		 	} else
				throw 'saveJson: Path "$path.json" doesn\'t exist!';
		}
		catch (e)
			trace('error: ${Std.string(e)}');
		return jsonContent;
	}

	static function buildXML(data:Dynamic) {}
}
