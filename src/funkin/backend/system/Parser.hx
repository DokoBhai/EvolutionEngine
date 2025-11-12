package funkin.backend.system;

import funkin.game.objects.Character.CharacterData;
import funkin.game.objects.Character.AnimationData;
import funkin.game.objects.Character.PsychCharacter;
import funkin.game.objects.Character.PsychAnimationData;
import funkin.game.objects.Character.CodenameCharacter;
import funkin.game.objects.Character.CodenameAnimationData;

import tjson.TJSON;

enum EngineType {
	EVOLUTION;
	CODENAME;
    PSYCH;
}

// ts so ahh 🥀
@:access(funkin.game.objects.Character)
@:access(funkin.game.objects.Stage)
@:access(funkin.states.debug.ChartEditor)
@:publicFields class Parser {
    static function parseCharacter(content:String, ?from:EngineType = EVOLUTION, ?to:EngineType = EVOLUTION):Dynamic {
        switch(to) {
            case EVOLUTION:
                switch(from) {
                    case EVOLUTION:
                        var data = TJSON.parse(content);
                        return data;
                    case CODENAME:
                        return {};
                    case PSYCH:
                        var data = TJSON.parse(content);
                        var returnData:CharacterData = {
							name: '',
							icon: data.healthicon,
							antialiasing: !data.no_antialiasing,
							source: data.image,
							healthColors: FunkinUtil.fromRGBArray(data.healthbar_colors),
							cameraOffsets: data.camera_position,
							holdTime: data.sing_duration,
							scale: data.scale,
							flipped: data.flip_x,
							animations: []
                        };
                        
						return returnData;
                }
            case CODENAME:
                // wip
                return {};
            case PSYCH:
                // wip
                return {};
        }
    }

    static function parseCharacterAnimations(anims:Array<Dynamic>, ?from:EngineType = EVOLUTION) {
        switch(from) {
            case EVOLUTION: return anims; // are you kidding me
            case CODENAME:  return anims; // wip
            case PSYCH:
                var returnAnims:Array<AnimationData> = [];
                for (data in anims) {
                    var returnData:AnimationData = {
						animName: data.anim,
                        prefix: data.name,
						offset: data.offsets,
						frameRate: data.fps,
						indices: data.indices,
						looped: data.loop
                    };
                    returnAnims.push(returnData);
                }
                
                return returnAnims;
        }
    }

    static function buildXML(data:Dynamic) {

    }
}