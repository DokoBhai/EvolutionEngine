package utils;

class MapUtil {
	public static function join<T1, T2>(a:Map<T1, T2>, b:Map<T1, T2>, ?overrideExisting:Bool = false) {
		for (k => v in b) {
			if (a.exists(k) && !overrideExisting) continue;
			a.set(k, v);
		}
		return a;
	}

	public static inline function getLength<T1, T2>(map:Map<T1, T2>):Int
		return Lambda.count({ iterator: map.keys });

	public static inline function getKeys<T1, T2>(map:Map<T1, T2>)
		return Lambda.array({ iterator: map.keys });

	public static inline function getValues<T1, T2>(map:Map<T1, T2>)
		return Lambda.array({ iterator: map.iterator });
}