package funkin.game;

class Rating {
    public static var ratings:Array<Rating> = [];

    public var name:String;
    public var timing:Float;
    public var score:Int;
    public var hits:Int;
    public var factor:Float;

    public function new(name:String, timing:Float, score:Int, factor:Float) {
        this.name = name;
        this.timing = timing;
        this.score = score;
        this.factor = factor;
        ratings.push(this);
    }

	public static function add(name:String, timing:Float, score:Int, factor:Float):Rating {
        return new Rating(name, timing, score, factor);
    }

    public static function judge(strumTime:Float, hitTime:Float):Rating {
        var diff = Math.abs(strumTime - hitTime);
        for (rating in ratings) {
            if (diff <= rating.timing) {
                return rating;
            }
        }
        return null; // miss
    }

    public static inline function judgeScore(strumTime:Float, hitTime:Float):Int
        return judge(strumTime, hitTime)?.score ?? 0;

    public static inline function judgeRating(strumTime:Float, hitTime:Float):String
        return judge(strumTime, hitTime)?.name ?? 'miss';

    public static inline function getFromName(ratingName:String):Null<Rating> {
        for (rating in ratings) {
            if (rating.name == ratingName)
                return rating;
        }
        return null;
    }
}