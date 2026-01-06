package funkin.backend.input;

import flixel.input.keyboard.FlxKey;

// Ts so bad
class Controls
{
	public var gamepadControls:Gamepad;
	public function new() {
		#if !FLX_NO_GAMEPAD
		gamepadControls = new Gamepad();
		#end
	}

	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;

	public var UP(get, never):Bool;
	public var DOWN(get, never):Bool;
	public var LEFT(get, never):Bool;
	public var RIGHT(get, never):Bool;

	public var UP_P(get, never):Bool;
	public var DOWN_P(get, never):Bool;
	public var LEFT_P(get, never):Bool;
	public var RIGHT_P(get, never):Bool;

	public var UP_R(get, never):Bool;
	public var DOWN_R(get, never):Bool;
	public var LEFT_R(get, never):Bool;
	public var RIGHT_R(get, never):Bool;

	inline public function keyPressed(key:String):Bool
		return FlxG.keys.anyPressed([FlxKey.fromStringMap.get(key)]);
	inline public function keyJustPressed(key:String):Bool
		return FlxG.keys.anyJustPressed([FlxKey.fromStringMap.get(key)]);
	inline public function keyReleased(key:String):Bool
		return FlxG.keys.anyJustReleased([FlxKey.fromStringMap.get(key)]);

	inline function get_ACCEPT()
		return (FlxG.keys.justPressed.ENTER #if !FLX_NO_GAMEPAD || gamepadControls.ACCEPT #end) && !FlxG.keys.pressed.ALT;

	inline function get_BACK()
		return (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.pressed.ESCAPE) #if !FLX_NO_GAMEPAD || gamepadControls.BACK #end;

	inline function get_UP() return FlxG.keys.anyPressed(Preferences.keyBinds.get('note_up')) #if !FLX_NO_GAMEPAD || gamepadControls.UP #end;
	inline function get_DOWN() return FlxG.keys.anyPressed(Preferences.keyBinds.get('note_down')) #if !FLX_NO_GAMEPAD || gamepadControls.DOWN #end;
	inline function get_LEFT() return FlxG.keys.anyPressed(Preferences.keyBinds.get('note_left')) #if !FLX_NO_GAMEPAD || gamepadControls.LEFT #end;
	inline function get_RIGHT() return FlxG.keys.anyPressed(Preferences.keyBinds.get('note_right')) #if !FLX_NO_GAMEPAD || gamepadControls.RIGHT #end;

	inline function get_UP_P() return FlxG.keys.anyJustPressed(Preferences.keyBinds.get('note_up')) #if !FLX_NO_GAMEPAD || gamepadControls.UP_P #end;
	inline function get_DOWN_P() return FlxG.keys.anyJustPressed(Preferences.keyBinds.get('note_down')) #if !FLX_NO_GAMEPAD || gamepadControls.DOWN_P #end;
	inline function get_LEFT_P() return FlxG.keys.anyJustPressed(Preferences.keyBinds.get('note_left')) #if !FLX_NO_GAMEPAD || gamepadControls.LEFT_P #end;
	inline function get_RIGHT_P() return FlxG.keys.anyJustPressed(Preferences.keyBinds.get('note_right')) #if !FLX_NO_GAMEPAD || gamepadControls.RIGHT_P #end;

	inline function get_UP_R() return FlxG.keys.anyJustReleased(Preferences.keyBinds.get('note_up')) #if !FLX_NO_GAMEPAD || gamepadControls.UP_R #end;
	inline function get_DOWN_R() return FlxG.keys.anyJustReleased(Preferences.keyBinds.get('note_down')) #if !FLX_NO_GAMEPAD || gamepadControls.DOWN_R #end;
	inline function get_LEFT_R() return FlxG.keys.anyJustReleased(Preferences.keyBinds.get('note_left')) #if !FLX_NO_GAMEPAD || gamepadControls.LEFT_R #end;
	inline function get_RIGHT_R() return FlxG.keys.anyJustReleased(Preferences.keyBinds.get('note_right')) #if !FLX_NO_GAMEPAD || gamepadControls.RIGHT_R #end;
}
