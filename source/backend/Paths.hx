package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import lime.utils.Assets;

using StringTools;

class Paths {
	public static inline final SOUND_FORMAT:String = #if desktop 'ogg' #else 'mp3' #end;
	public static inline final MENU_MUSIC:String = 'ui/freakyMenu';
	public static inline final MENU_TEMPO:Int = 102;

	private static var cachedText:Map<String, String> = new Map<String, String>();
	private static var cachedFrames:Map<String, FlxFramesCollection> = new Map<String, FlxFramesCollection>();

	public static inline function image(path:String):String
		return 'assets/images/$path.png';

	public static inline function sound(path:String):String
		return 'assets/sounds/$path.$SOUND_FORMAT';

	public static inline function music(path:String):String
		return 'assets/music/$path.$SOUND_FORMAT';

	public static inline function playableSong(path:String, voices:Bool = false):String
		return 'assets/music/songs/${path.toLowerCase()}/${voices ? "voices" : "inst"}.$SOUND_FORMAT';

	public static function sparrow(path:String, ?prePath:String = 'assets/images/'):FlxFramesCollection {
		var fStr = '$prePath$path';

		if (!Settings.cache_assets)
			return FlxAtlasFrames.fromSparrow('$fStr.png', '$fStr.xml');

		var tmp:FlxFramesCollection = cachedFrames.get(path);
		if (tmp != null) 
			return tmp;

		tmp = FlxAtlasFrames.fromSparrow('$fStr.png', '$fStr.xml');

		cachedFrames.set(path, tmp);
		return tmp;
	}

	public static function text(path:String, ?prePath:String = 'assets/data/'):String {
		if (!Settings.cache_assets)
			return Assets.getText(prePath + path).replace('\r', '');

		var tmp:String = cachedText.get(path);
		if (tmp != null) 
			return tmp;

		tmp = Assets.getText(prePath + path).replace('\r', '');

		cachedText.set(path, tmp);
		return tmp;
	}
}
