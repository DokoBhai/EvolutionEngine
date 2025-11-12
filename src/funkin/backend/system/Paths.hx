package funkin.backend.system;

import sys.FileSystem;
import sys.io.File;

import funkin.backend.system.Mods;

@:publicFields class Paths {
    inline static function image(key:String):String
        return getPath('images/$key.${Flags.IMAGE_EXT}');

	inline static function xml(key:String):String
		return getPath('$key.xml');

    inline static function sparrow(key:String):String
        return xml('images/$key');

    inline static function sparrowExists(key:String):Bool
        return sparrow(key) != '';

    inline static function sound(key:String):String
        return getPath('sounds/$key.${Flags.SOUND_EXT}');

	inline static function music(key:String):String
		return getPath('music/$key.${Flags.MUSIC_EXT}');

    inline static function character(key:String):String
        return getPath('data/characters/$key', Flags.CHAR_EXT);

    static function getPath(path:String, ?extensions:Array<String>, ?includeDir:Array<String>):String {
        if (extensions != null)
            for (i => ext in extensions) {
                if (!ext.startsWith('.'))
                    extensions[i] = '.$ext';
            }
        
        extensions ??= [''];
        includeDir ??= [ // sort in order of hierarchy
            #if MODS_ALLOWED Mods.currentModDirectory ,#end 
            'assets/shared', 'assets'
        ];

        for (dir in includeDir) {
            for (ext in extensions) {
			    final trackedPath = '$dir/$path$ext';
                if (FileSystem.exists(trackedPath)) {
                    trace('Path found!: $trackedPath');
                    return trackedPath;
                }
            }
        }
        trace('Path not found for: $path.');
        return '';
    }
}