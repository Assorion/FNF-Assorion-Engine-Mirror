package misc;

import haxe.Json;
import lime.utils.Assets;
import sys.io.File;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import misc.Highscore;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

typedef Options = {
    var start_fullscreen:Bool;
    var start_volume:Int;
    var skip_logo:Bool;
    var default_persist:Bool;
    var launch_sprites:Bool;

    var downscroll:Bool;
    var offset:Int;
    var botplay:Bool;
    var ghost_tapping:Bool;
    var miss_health:Int;

    var useful_info:Bool;
    var antialiasing:Bool;
    var show_hud:Bool;
    var framerate:Int;
    var light_bot_strums:Bool;

    // controls
    var note_left :Array<Int>;
    var note_right:Array<Int>;
    var note_up   :Array<Int>;
    var note_down :Array<Int>;
    
    var ui_l:Array<Int>;
    var ui_r:Array<Int>;
    var ui_u:Array<Int>;
    var ui_d:Array<Int>;
    var ui_accept:Array<Int>;
    var ui_back  :Array<Int>;
}

class Settings {
    /*
        This won't work in a web browser since a web browser can't save files.
        The best it will do is simply forget your settings each time.

        The scores will be handles by FlxG save so it won't forget those.
        I don't wan't to write terrible, repeating code.
        So this is the best I will do.
    */

    public static var pr:Options;
    public static function openSettings(){
        var text = Assets.getText('assets/songs&data/savedata.json').trim();
        pr = cast Json.parse(text);
    }
    public static function apply(){
        FlxG.save.bind('funkin', 'candicejoe');

        FlxGraphic.defaultPersist = Settings.pr.default_persist;
        FlxG.updateFramerate      = Settings.pr.framerate;
		FlxG.drawFramerate        = Settings.pr.framerate;

        Main.changeUsefulInfo(Settings.pr.useful_info);        

        if(FlxG.save.data.songScores != null)
            Highscore.songScores = FlxG.save.data.songScores;

        NewControls.NOTE_LEFT = pr.note_left;
        NewControls.NOTE_DOWN = pr.note_down;
        NewControls.NOTE_UP   = pr.note_up;
        NewControls.NOTE_RIGHT= pr.note_right;
        NewControls.UI_L = pr.ui_l;
        NewControls.UI_D = pr.ui_d;
        NewControls.UI_U = pr.ui_u;
        NewControls.UI_R = pr.ui_r;
        NewControls.UI_ACCEPT = pr.ui_accept;
        NewControls.UI_BACK   = pr.ui_back;
    }

    public static function flush(){
        var data:String = Json.stringify(pr, '\t');

        // # TODO actually make this run in a web browser.
        File.saveContent('assets/songs&data/savedata.json', data);
    }
}

// dunno why haxe doesn't haxe something like this included.
// but this is terrible. And for some reason I thought it would be a -
// great idea to include shifted characters!!!!!
// WHEN THIS IS ONLY GONNA BE USED IN 2 PLACES!!! :(
class InputString {
    public static function getKeyNameFromString(code:Int, literal:Bool = false, shiftable:Bool = true):String{
        var shifted:Bool = false;
        if(shiftable)
            shifted = FlxG.keys.pressed.SHIFT;

        switch(code){
            case -2:
                return 'ALL';
            case -1:
                return 'NONE';
            case 65:
                return 'A';
            case 66:
                return 'B';
            case 67:
                return 'C';
            case 68:
                return 'D';
            case 69:
                return 'E';
            case 70:
                return 'F';
            case 71:
                return 'G';
            case 72:
                return 'H';
            case 73:
                return 'I';
            case 74:
                return 'J';
            case 75:
                return 'K';
            case 76:
                return 'L';
            case 77:
                return 'M';
            case 78:
                return 'N';
            case 79:
                return 'O';
            case 80:
                return 'P';
            case 81:
                return 'Q';
            case 82:
                return 'R';
            case 83:
                return 'S';
            case 84:
                return 'T';
            case 85:
                return 'U';
            case 86:
                return 'V';
            case 87:
                return 'W';
            case 88:
                return 'X';
            case 89:
                return 'Y';
            case 90:
                return 'Z';

            case 48:
                if(shifted){
                    if(literal) return ')';
                    return 'CLOSED BRACKET';
                }
                    
                return '0';
            case 49:
                if(shifted){
                    if(literal) return '!';
                    return 'EXCLAIMATION';
                }

                return '1';
            case 50:
                if(shifted){
                    if(literal) return '@';
                    return 'AT SIGN';
                }
                return '2';
            case 51:
                if(shifted){
                    if(literal) return '#';
                    return 'HASHTAG';
                }
                return '3';
            case 52:
                if(shifted){
                    if(literal) return '$';
                    return 'DOLLAR SIGN';
                }
                return '4';
            case 53:
                if(shifted){
                    if(literal) return '%';
                    return 'PERCENT';
                }
                return '5';
            case 54:
                if(shifted){
                    if(literal) return '^';
                    return 'CARET';
                }
                return '6';
            case 55:
                if(shifted){
                    if(literal) return '&';
                    return 'AMPERSAND';
                }
                return '7';
            case 56:
                if(shifted){
                    if(literal) return '*';
                    return 'ASTERISK';
                }
                return '8';
            case 57:
                if(shifted){
                    if(literal) return '(';
                    return 'OPEN BRACKET';
                }
                return '9';   
                
            case 13:
                return 'ENTER';
            case 33:
                return 'PAGE UP';
            case 34:
                return 'PAGE DOWN';
            case 35:
                return 'END';
            case 36:
                return 'HOME';
            case 45:
                return 'INSERT';
            case 46:
                return 'DELETE';
            case 27:
                return 'ESCAPE';
            case 189:
                if(shifted){
                    if(literal) return '_';
                    return 'UNDERSCORE';
                }
                if(literal)
                    return '-';
                return 'MINUS';
            case 187:
                if(shifted){
                    if(literal) return '+';
                    return 'EQUALS';
                }
                if(literal)
                    return '=';
                return 'EQUALS'; 
            case 8:
                return 'BACK';
            case 219:
                if(shifted){
                    if(literal) return '{';
                    return 'OPEN CURLY BRACKET';
                }
                if(literal)
                    return '[';
                return 'OPEN SQUARE BRACKET';
            case 221:
                if(shifted){
                    if(literal) return '}';
                    return 'CLOSED CURLY BRACKET';
                }
                if(literal)
                    return ']';
                return 'CLOSED SQUARE BRACKET';
            case 186:
                return ';';
            case 220:
                return '\\';
            case 222:
                if(shifted)
                    return '"';
                return "'";
            case 188:
                if(shifted)
                    return '<';
                return ',';
            case 191:
                if(shifted)
                    return '?';
                return '/';
            case 18:
                return 'ALT';
            case 17:
                return 'CONTROL';
            case 190:
                if(shifted)
                    return '>';
                return '.';
            case 16:
                return 'SHIFT';
            case 32:
                if(literal)
                    return ' ';
                return 'SPACE';
            case 37:
                return 'LEFT';
            case 40:
                return 'DOWN';
            case 38:
                return 'UP';
            case 39:
                return 'RIGHT';
        }

        trace('Couldn\'t find the character');
        return 'FAILED';
    }
}