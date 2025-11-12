package funkin.game.objects;

import funkin.backend.system.Parser;

import flixel.math.FlxPoint;
import tjson.TJSON;
import sys.io.File;

typedef AnimationData = {
	animName:String,
    prefix:String,
    offset:Array<Int>,
    frameRate:Int,
    indices:Array<Int>,
    looped:Bool
}

@:structInit class CharacterData {
    public var name:String;
    public var icon:String;
    public var antialiasing:Bool;
    public var source:String;
    public var healthColors:Int;
    public var cameraOffsets:Array<Int>;
    public var holdTime:Float;
    public var scale:Float;
    public var flipped:Bool;
    public var animations:Array<AnimationData>;
}

typedef PsychAnimationData = {
    anim:String,
    name:String,
    offsets:Array<Int>,
    fps:Int,
    indices:Array<Int>,
    loop:Bool
}

@:structInit class PsychCharacter {
    public var animations:Array<PsychAnimationData>;
    public var no_antialiasing:Bool;
    public var image:String;
    public var position:Array<Int>;
    public var healthicon:String;
    public var flip_x:Bool;
    public var healthbar_colors:Array<Int>;
    public var camera_position:Array<Int>;
    public var sing_duration:Float;
    public var scale:Float;
}

typedef CodenameAnimationData = {
	name:String, 
    anim:String, 
    x:String, 
    y:String, 
    fps:String, 
    loop:String, 
    indices:String
}

@:structInit class CodenameCharacter {
    public var x:String;
    public var y:String;
    public var camx:String;
    public var camy:String;
    public var sprite:String;
    public var gameOverChar:String;
    public var holdTime:String;
    public var antialiasing:String;
    public var flipX:String;
    public var interval:String;
    public var isPlayer:String;
    public var icon:String;
    public var color:String;
    public var scale:String;
}

class Character extends FlxSprite {
    public static var fallbackCharacter = 'bf';

    public var charData:CharacterData;

    public var name(default, null):String;
    public var icon(default, null):String;

    public var animationList:Array<String> = [];
	public var animationData:Map<String, AnimationData> = [];
    public var animationOffsets:Map<String, FlxPoint> = [];

    public function new(x, y, name) {
        super(x, y);

        if (!loadCharacter(name)) {
            loadCharacter(fallbackCharacter);
        }
    }

    public function loadCharacter(charName:String):Bool {
        var sourceData = Paths.character(charName);
        var charJson = Parser.parseCharacter(File.getContent(sourceData), justifyEngine(sourceData));
        buildCharacter(charJson);

        if (charJson != null)
            return true;

        return false;
    }

    public function buildCharacter(data:CharacterData) {
        frames = FunkinUtil.loadSparrowAtlas(Paths.sparrow('characters/${data.source}'));
        name = data.name;
        icon = data.icon;

        for (anim in data.animations) {
            animationData.set(anim.animName, anim);
            animationOffsets.set(anim.animName, FlxPoint.get(anim.offset[0], anim.offset[1]));
            animationList.push(anim.animName);
        }
        
        charData = data; 
    }

    public static function justifyEngine(path:String) {
        if (path.endsWith('.xml'))
            return CODENAME
        else if (Reflect.hasField(TJSON.parse(File.getContent(path)), 'image'))
            return PSYCH;
        else 
            return EVOLUTION;
    }
}