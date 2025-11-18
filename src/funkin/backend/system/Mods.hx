package funkin.backend.system;

class Mods {
	#if MODS_ALLOWED
	public static var currentMod:String = '';
	public static var currentModDirectory(get, never):String;
	public static var modList:Array<String> = [];

	static function get_currentModDirectory()
		return currentMod != '' ? '$currentMod/' : '';

	public static function getCurrentDirectory() {
		var directory = Flags.MODS_FOLDER;
		if (currentModDirectory.length > 0)
			directory += '/${currentModDirectory.replace('/', '')}';
		return directory;
	}

	public static function getModList() {

	}

	public static function loadMod() {}
	#end
}
