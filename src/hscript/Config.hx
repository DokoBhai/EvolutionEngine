package hscript;

class Config {
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"funkin"
	];
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"funkin",
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack"
	];
	public static final DISALLOW_CUSTOM_CLASSES = [
		"flixel.FlxGame",
		"flixel.addons.ui.FlxUI9SliceSprite",
		"flixel.addons.ui.FlxUIList",
		"flixel.addons.ui.FlxUINumericStepper"
	];
	public static final DISALLOW_ABSTRACT_AND_ENUM = [];
}