package funkin.backend.input;

#if !FLX_NO_GAMEPAD
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
#end

class Gamepad {
    public function new() {}

	#if !FLX_NO_GAMEPAD
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

	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;

	inline function get_ACCEPT()
		return anyJustPressed([FlxGamepadInputID.fromStringMap.get("ACCEPT")]);
	inline function get_BACK()
		return anyJustPressed([FlxGamepadInputID.fromStringMap.get("CANCEL")]);

	inline function get_UP() return anyPressed([DPAD_UP]);
	inline function get_DOWN() return anyPressed([DPAD_DOWN]);
	inline function get_LEFT() return anyPressed([DPAD_LEFT]);
	inline function get_RIGHT() return anyPressed([DPAD_RIGHT]);

	inline function get_UP_P() return anyJustPressed([DPAD_UP]);
	inline function get_DOWN_P() return anyJustPressed([DPAD_DOWN]);
	inline function get_LEFT_P() return anyJustPressed([DPAD_LEFT]);
	inline function get_RIGHT_P() return anyJustPressed([DPAD_RIGHT]);

	inline function get_UP_R() return anyJustReleased([DPAD_UP]);
	inline function get_DOWN_R() return anyJustReleased([DPAD_DOWN]);
	inline function get_LEFT_R() return anyJustReleased([DPAD_LEFT]);
	inline function get_RIGHT_R() return anyJustReleased([DPAD_RIGHT]);

	inline function anyPressed(buttons:Array<FlxGamepadInputID>):Bool {
		return (FlxG.gamepads?.lastActive?.anyPressed(buttons) == true);
    }
	inline function anyJustPressed(buttons:Array<FlxGamepadInputID>):Bool {
		return (FlxG.gamepads?.lastActive?.anyJustPressed(buttons) == true);
	}
	inline function anyJustReleased(buttons:Array<FlxGamepadInputID>):Bool {
		return (FlxG.gamepads?.lastActive?.anyJustReleased(buttons) == true);
	}
	#end
}