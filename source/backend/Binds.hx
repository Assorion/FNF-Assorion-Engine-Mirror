package backend;

import flixel.input.keyboard.FlxKey;

#if !debug @:noDebug #end
class Binds {
	public static var NOTE_LEFT :Array<Int> = [FlxKey.A, FlxKey.LEFT];
	public static var NOTE_DOWN :Array<Int> = [FlxKey.S, FlxKey.DOWN];
	public static var NOTE_UP	:Array<Int> = [FlxKey.W, FlxKey.UP];
	public static var NOTE_RIGHT:Array<Int> = [FlxKey.D, FlxKey.RIGHT];

	public static var UI_LEFT :Array<Int>	= [FlxKey.A, FlxKey.LEFT];
	public static var UI_RIGHT:Array<Int>	= [FlxKey.D, FlxKey.RIGHT];
	public static var UI_UP   :Array<Int>	= [FlxKey.W, FlxKey.UP];
	public static var UI_DOWN :Array<Int>	= [FlxKey.S, FlxKey.DOWN];

	public static var UI_ACCEPT:Array<Int>	= [FlxKey.ENTER, FlxKey.SPACE];
	public static var UI_BACK:Array<Int>	= [FlxKey.ESCAPE, FlxKey.BACKSPACE];

	public inline static function loadControls(map:Map<String, Dynamic>){
		var bindsItems:Array<String> = Type.getClassFields(Binds);

		for(key in map.keys())
			if(bindsItems.contains(key))
		Reflect.setField(Binds, key, map.get(key));
	}

	// Checks if a key array is currently pressed
	public static function check(key:Int, array:Array<Int>):Bool {
		if(key == array[0] || key == array[1])
			return true;

		return false;
	}

	// Checks an array of an array of binds and returns the index of it. 
	public static function deepCheck(key:Int, array:Array<Array<Int>>):Int {
		for(i in 0...array.length)
			if(key == array[i][0] || key == array[i][1])
				return i;

		return -1;
	}
	
	// Assigns a list of functions to a list of keys
	public static function bindFunctions(key:Int, bindSets:Array<Array<Dynamic>>) {
		for(bSet in bindSets){
			if(bSet.length == 2 && bSet[1] != null && key.check(bSet[0])){
				bSet[1]();
				return;
			}
		}
	}
}
