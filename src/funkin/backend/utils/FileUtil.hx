package funkin.backend.utils;

import haxe.io.Bytes;
import openfl.utils.ByteArray;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets as OpenFLAssets;
import openfl.filesystem.File as OpenFLFile;
#end

/*
 * Just a filesystem class to manage both sys targets and html targets.
 */
class FileUtil {
	public static inline function getContent(filePath:String):String {
		#if sys
		return File.getContent(filePath);
		#else
		return OpenFLAssets.getText(filePath);
		#end
	}

	public static inline function saveContent(filePath:String, content:String) {
		try {
			#if sys
			return File.saveContent(filePath, content);
			#else
			throw 'saveContent is not supported in non-sys platform!'
			#end
		} catch(e:Dynamic) trace('error: ${e.toString()}');
	}

	public static inline function exists(filePath:String):Bool {
		#if sys
		return FileSystem.exists(filePath);
		#else
		return OpenFLAssets.exists(filePath);
		#end
	}

	public static inline function getBytes(filePath:String):Bytes {
		#if sys
		return File.getBytes(filePath);
		#else
		return Bytes.ofData(OpenFLAssets.getBytes(filePath));
		#end
	}

	public static inline function getByteArray(filePath:String):ByteArray {
		#if sys
		return ByteArray.fromBytes(File.getBytes(filePath));
		#else
		return OpenFLAssets.getBytes(filePath);
		#end
	}

	public static inline function saveBytes(filePath:String, bytes:Bytes) {
		try {
			#if sys
			return File.saveBytes(filePath, bytes);
			#else
			throw 'saveBytes is not supported in non-sys platform!'
			#end
		} catch(e:Dynamic) trace('error: ${e.toString()}');
	}
}