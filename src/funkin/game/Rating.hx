package funkin.game;

class Rating {
    public static var ratings:Array<Rating> = [];

    public var name:String;
    public var timing:Float;
    public var score:Int;

    public function new(name:String, timing:Float, score:Int) {
        this.name = name;
        this.timing = timing;
        this.score = score;
        ratings.push(this);
    }

    public static function add(name:String, timing:Float, score:Int):Rating {
        return new Rating(name, timing, score);
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
}