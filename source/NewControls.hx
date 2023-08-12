package;

import flixel.input.keyboard.FlxKey;

class NewControls {
    // to be clear this is just for storing binds.
    // the checks HAVE to be implemented in the state itself.
    public static var NOTE_LEFT :Array<Int> = [FlxKey.A, FlxKey.LEFT ];
    public static var NOTE_DOWN :Array<Int> = [FlxKey.S, FlxKey.DOWN ];
    public static var Note_UP   :Array<Int> = [FlxKey.W, FlxKey.UP   ];
    public static var Note_RIGHT:Array<Int> = [FlxKey.S, FlxKey.RIGHT];

    public static var UI_L:Array<Int> = [FlxKey.LEFT ];
    public static var UI_R:Array<Int> = [FlxKey.RIGHT];
    public static var UI_U:Array<Int> = [FlxKey.UP   ];
    public static var UI_D:Array<Int> = [FlxKey.DOWN ];

    public static var UI_ACCEPT:Array<Int> = [FlxKey.ENTER, FlxKey.G];
    public static var UI_BACK:Array<Int> = [FlxKey.BACKSPACE, FlxKey.ESCAPE];

    // # for checking only 2 binds.
    public static function hardCheck(key:Int, array:Array<Int>):Bool
    {
        if(key == array[0] || key == array[1])
            return true;

        return false;
    }
    public static function deepCheck(key:Int, array:Array<Array<Int>>):Int
    {
        for(i in 0...array.length){
            if(key == array[i][0] || key == array[i][1])
                return i;
        }

        return -1;
    }
}