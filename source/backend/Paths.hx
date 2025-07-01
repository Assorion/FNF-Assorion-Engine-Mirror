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

	public static inline function lImage(path:String):String {
		return 'assets/images/$path.png';
	}
	public static inline function lMusic(path:String):String {
		return 'assets/music/$path.$SOUND_FORMAT';
	}
	public static inline function lSound(path:String):String {
		return 'assets/sounds/$path.$SOUND_FORMAT';
	}
	public static inline function playableSong(path:String, retVoices:Bool = false):String {
		var endingStr:String = retVoices ? 'voices.$SOUND_FORMAT' : 'inst.$SOUND_FORMAT';
		return 'assets/music/songs/${path.toLowerCase()}/$endingStr';
	}
	public static function lSparrow(path:String, ?prePath:String = 'assets/images/'):FlxFramesCollection {
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
	public static function lText(path:String, ?prePath:String = 'assets/data/'):String {
		if (!Settings.cache_assets)
			return Assets.getText(prePath + path).replace('\r', '');

		var tmp:String = cachedText.get(path);

		if (tmp != null) 
			return tmp;

		tmp = Assets.getText(prePath + path).replace('\r', '');
		cachedText.set(path, tmp);

		return tmp;
	}

	//////////////////////////////////////

	public static function clearCache(){
		if (Settings.cache_assets) 
				return;

		Assets.cache.clear();
		openfl.utils.Assets.cache.clear();
		cachedFrames.clear();
		cachedText.clear();
	}
}
