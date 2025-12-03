package utils;

class MapUtil {
    public static function join<T1, T2>(a:Map<T1, T2>, b:Map<T1, T2>, ?overrideExisting:Bool = false) {
      for (k => v in b) {
        if (a.exists(k) && !overrideExisting) continue;
				a.set(k, v);
      }
      return a;
    }
}