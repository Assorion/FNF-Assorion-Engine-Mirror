package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import flixel.graphics.FlxGraphic;

class Settings {
    public static var start_fullscreen:Bool = false;
    public static var start_volume:Int      = 100;
    public static var skip_intro:Bool       = false;
    public static var cache_assets:Bool     = false;

    public static var downscroll:Bool       = true;
    public static var audio_offset:Int      = 75;
    public static var botplay:Bool          = false;
    public static var ghost_tapping:Bool    = true;

    public static var useful_info:Bool      = true;
    public static var antialiasing:Bool     = true;
    public static var show_hud:Bool         = true;
    public static var framerate:Int         = 120;
}

#if !debug @:noDebug #end
class SettingsManager {
    public static var gSave:FlxSave;

    public static inline function framerateClamp(ch:Int):Int
        return CoolUtil.intBoundTo(ch, 10, 340);

    public static function openSettings() {
        gSave = new FlxSave();
        gSave.bind('funkin', 'candicejoe');

        var settingsMap:Map<String, Dynamic> = gSave.data.settingsMap == null ? new Map<String, Dynamic>() : gSave.data.settingsMap;
        var settingsItems:Array<String> = Type.getClassFields(Settings);

        for(key in settingsMap.keys())
            if(settingsItems.contains(key))
                Reflect.setField(Settings, key, settingsMap.get(key));

        Binds.loadControls(settingsMap);
        HighScore.loadScores();
    }
    
    public static function apply(){
        FlxGraphic.defaultPersist = Settings.cache_assets;
		FlxSprite.defaultAntialiasing = Settings.antialiasing;
        FlxG.updateFramerate = FlxG.drawFramerate = framerateClamp(Settings.framerate);
        Main.changeUsefulInfo(Settings.useful_info);
    }

    public static function flush(){
        var settingsMap = new Map<String, Dynamic>();
        var settingsItems:Array<String> = Type.getClassFields(Settings);
        var bindsItems:Array<String>    = Type.getClassFields(Binds);

        for(settingItem in settingsItems)
            settingsMap.set(settingItem, Reflect.field(Settings, settingItem));

        for(bindItem in bindsItems){
            var item = Reflect.field(Binds, bindItem);

            if(Std.is(item, Array))
                settingsMap.set(bindItem, item);
        }

        /////////////////////////////////////

        gSave.data.settingsMap = settingsMap;
        gSave.flush();
    }
}
