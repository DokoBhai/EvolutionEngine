package funkin.backend.utils;

import flixel.graphics.FlxGraphic;

import openfl.media.Sound;
import openfl.display.BitmapData;

#if sys
import sys.FileSystem;
#end

import tjson.TJSON;

enum PrecacheType
{
	BITMAP;
	SOUND;
	DATA;
	CONTENT;
	UNKNOWN;
}

class PrecacheUtil
{
	/**
	 * a Map of precached `BitmapData`s. 
	 * The keys has the `String` path to the corresponding BitmapData file.
	 */
	public static var precachedBitmaps:Map<String, BitmapData> = [];

	/*
	 * a Map of precached sounds. This is precached from a sound file like `.ogg`.
	 * The keys has the `String` path to the corresponding sound file.
	 */
	public static var precachedSounds:Map<String, Sound> = [];

	/*
	 * a Map of precached datas. This is precached from a JSON or an XML.
	 * The keys has the `String` path to the corresponding data file.
	 */
	public static var precachedData:Map<String, Dynamic> = [];

	/*
	 * a Map of precached contents. This is precached from a text file.
	 * The keys has the `String` path to the corresponding BitmapData's file.
	 */
	public static var precachedContents:Map<String, String> = [];

	/*
	 * a Map of the current cache.
	 * Basically all the precached assets are in here.
	 */
	static var __cache:Map<String, Dynamic> = [];

	public static function precache(path:String, ?reload:Bool = false, ?precacheType:PrecacheType):Dynamic
	{
		if (__cache.exists(path) && !reload) {
			return __cache.get(path);
		}

		if (!FileUtil.exists(path))
			return null;

		precacheType ??= getPrecacheType(path);

		var cached:Dynamic;
		switch (precacheType) {
			case BITMAP:
				final graphic = FlxGraphic.fromAssetKey(path);
				if (graphic != null) {
					final bitmap = graphic.bitmap.clone();
					precachedBitmaps.set(path, bitmap);
					cached = bitmap;
				} else cached = null;
			case SOUND:
				#if web
				cached = OpenFLAssets.getSound(path);
				#else
				cached = Sound.fromFile(path);
				#end
				precachedSounds.set(path, cached);
			case DATA:
				if (path.endsWith('.json')) cached = TJSON.parse(FileUtil.getContent(path)); 
				else if (path.endsWith('.xml')) cached = Xml.parse(FileUtil.getContent(path)); 
				else cached = null;

				if (cached != null) precachedData.set(path, cached);
			case CONTENT:
				cached = FileUtil.getContent(path);
				precachedContents.set(path, cached);
			default:
				cached = null;
		}

		if (cached != null) 
			__cache.set(path, cached);
		
		trace('attempted to cache asset: $path (${cached != null ? 'success' : 'failed'} | $precacheType)');

		return cached;
	}

	@:dox(hide)
	static function getPrecacheType(path:String)
	{
		if (FileUtil.exists(path))
		{
			if (path.endsWith('.png'))
				return BITMAP;
			else if (path.endsWith('.ogg'))
				return SOUND;
			else if (path.endsWith('.json') || path.endsWith('.xml'))
				return DATA;
			else
				return CONTENT;
		}
		trace('ERROR: File with path "$path" does not exist.');
		return UNKNOWN;
	}

	/*
	 * Precaches the contents of the provided directory.
	 * Contents which can't be precached is ignored. 
	 *
	 * @param  dir       Path to the directory.
	 * @param  recurse   Precache recursively? This means it will precache the subfolders of said directory. `false` by default.
	 * @param  reload    If `false`, it'll avoid precaching existing cached files.
	 * @param  filter    Used for filtering contents determined by the returned boolean. 
						 If `false` was returned, the file associated with said path won't be precached. 
						 The `String` passed in the function is the file path.
	 * @return Returns a map of data that was cached from the directory. If argument `dir` isn't directory then it'll return `null` instead.
	 */
	public static function directory(dir:String, ?recurse:Bool = false, ?reload:Bool = false, ?filter:String->Bool):Map<String, Dynamic>
	{
		if (dir.endsWith('/') || dir.endsWith('\\'))
			dir.substr(0, dir.length - 1);

		filter ??= _ -> true;

		var cachedData:Map<String, Dynamic> = [];
		if (FileSystem.isDirectory(dir))
		{
			for (content in FileSystem.readDirectory(dir))
			{
				final path = '$dir/$content';
				if (FileSystem.isDirectory(path) && recurse)
				{
					var subCached:Map<String, Dynamic> = directory(path, true, reload, filter);
					cachedData.join(subCached);

					continue;
				}

				if (filter(path))
				{
					var data:Dynamic = precache(path, reload);
					if (data != null)
						cachedData.set(path, data);
				}
			}
			return cachedData;
		}
		trace('ERROR: File $dir is not a directory.');
		return null;
	}

	/*
		######################
		#     SHORTCUTS      #
		######################
	*/

	public static inline function bitmap(path:String, ?reload:Bool = false)
		return precache(path, reload, BITMAP)?.clone() ?? null;

	public static inline function image(path:String, ?reload:Bool = false) {
		return precache(Paths.image(path), reload, BITMAP)?.clone() ?? null;
	}

	public static inline function sound(path:String, ?reload:Bool = false)
		return precache(path, reload, SOUND);

	public static inline function data(path:String, ?reload:Bool = false)
		return precache(path, reload, DATA);

	public static inline function content(path:String, ?reload:Bool = false)
		return precache(path, reload, CONTENT);
}