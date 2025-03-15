package backend;

import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.util.FlxColor;

#if !debug @:noDebug #end
class CoolUtil {
	// Clamps a value to be between to other values.
	public static function boundTo(val:Float, min:Float, max:Float):Float
		return Math.min(Math.max(val, min), max);

	public static function intBoundTo(val:Float, min:Float, max:Float):Int
		return Math.round(boundTo(val, min, max));
	
	public static function randomRange(min:Int, max:Int):Int
		return min + Math.round(Math.random() * (max - min));

	// Used for converting arrays of integers to colours.
	public inline static function cfArray(array:Array<Int>):Int
			return FlxColor.fromRGB(array[0], array[1], array[2]);
	
	// Cross Platform method for returning the exact time in ticks
	public static function getCurrentTime()
		#if desktop 
		return Sys.time();
		#else
		return Date.now().getTime() * 0.001;
		#end

	// Converts the OpenFL/Flixel key code into it's string variant.
	public static function keyCodeToString(keyCode:Int, literal:Bool = false):String {
		switch(keyCode){
		case -2:
			return 'ALL';
		case -1:
			return 'NONE';
		case 81:
			return 'Q';
		case 87:
			return 'W';
		case 69:
			return 'E';
		case 82:
			return 'R';
		case 84:
			return 'T';
		case 89:
			return 'Y';
		case 85:
			return 'U';
		case 73:
			return 'I';
		case 79:
			return 'O';
		case 80:
			return 'P';
		case 65:
			return 'A';
		case 83:
			return 'S';
		case 68:
			return 'D';
		case 70:
			return 'F';
		case 71:
			return 'G';
		case 72:
			return 'H';
		case 74:
			return 'J';
		case 75:
			return 'K';
		case 76:
			return 'L';
		case 90:
			return 'Z';
		case 88:
			return 'X';
		case 67:
			return 'C';
		case 86:
			return 'V';
		case 66:
			return 'B';
		case 78:
			return 'N';
		case 77:
			return 'M';

		case 192:
			return literal ? '`' : 'GRAVE';
		case 49:
			return literal ? '1' : 'ONE';
		case 50:
			return literal ? '2' : 'TWO';
		case 51:
			return literal ? '3' : 'THREE';
		case 52:
			return literal ? '4' : 'FOUR';
		case 53:
			return literal ? '5' : 'FIVE';
		case 54:
			return literal ? '6' : 'SIX';
		case 55:
			return literal ? '7' : 'SEVEN';
		case 56:
			return literal ? '8' : 'EIGHT';
		case 57:
			return literal ? '9' : 'NINE';
		case 48:
			return literal ? '0' : 'ZERO';
		case 189:
			return literal ? '-' : 'MINUS';
		case 187:
			return literal ? '=' : 'EQUAL';
		case 8:
			return 'BACK';

		case 9:
			return 'TAB';
		case 219:
			return literal ? '[' : 'OPEN';
		case 221:
			return literal ? ']' : 'CLOSED';
		case 220:
			return literal ? '\\' : 'BACKSLASH';

		case 20:
			return 'CAPSLOCK';
		case 186:
			return literal ? ';' : 'COLON';
		case 222:
			return literal ? "'" : 'QUOTE';
		case 13:
			return 'ENTER';

		case 16:
			return 'SHIFT';
		case 188:
			return literal ? ',' : 'COMMA';
		case 190:
			return literal ? '.' : 'PERIOD';
		case 191:
			return literal ? '/' : 'SLASH';
		
		case 17:
			return 'CONTROL';
		case 15:
			return 'SUPER';
		case 18:
			return 'ALT';
		case 32:
			return 'SPACE';
		
		case 27:
			return 'ESCAPE';
		case 112:
			return 'F1';
		case 113:
			return 'F2';
		case 114:
			return 'F3';
		case 115:
			return 'F4';
		case 116:
			return 'F5';
		case 117:
			return 'F6';
		case 118:
			return 'F7';
		case 119:
			return 'F8';
		case 120:
			return 'F9';
		case 121:
			return 'F10';
		case 122:
			return 'F11';
		case 123:
			return 'F12';

		case 45:
			return 'INSERT';
		case 36:
			return 'HOME';
		case 33:
			return 'PAGEUP';
		case 46:
			return 'DELETE';
		case 35:
			return 'END';
		case 34:
			return 'PAGEDOWN';
		case 37:
			return 'LEFT';
		case 40:
			return 'DOWN';
		case 38:
			return 'UP';
		case 39:
			return 'RIGHT';

		case 96:
			return literal ? '0' : 'NUM ZERO';
		case 97:
			return literal ? '1' : 'NUM ONE';
		case 98:
			return literal ? '2' : 'NUM TWO';
		case 99:
			return literal ? '3' : 'NUM THREE';
		case 100:
			return literal ? '4' : 'NUM FOUR';
		case 101:
			return literal ? '5' : 'NUM FIVE';
		case 102:
			return literal ? '6' : 'NUM SIX';
		case 103:
			return literal ? '7' : 'NUM SEVEN';
		case 104:
			return literal ? '8' : 'NUM EIGHT';
		case 105:
			return literal ? '9' : 'NUM NINE';
		case 110:
			return literal ? '.' : 'NUM PERIOD';
		case 109:
			return literal ? '-' : 'NUM MINUS';
		case 107:
			return literal ? '+' : 'NUM PLUS';
		case 144:
			return 'NUMLOCK';
		case 111:
			return literal ? '/' : 'NUM SLASH';
		case 106:
			return literal ? '*' : 'ASTERISK';
		case 301:
			return 'PRTSC';
		case 145:
			return 'SCROLL';
		case 19:
			return 'PAUSE';
		}

		return 'UNKNOWN';
	}
}
