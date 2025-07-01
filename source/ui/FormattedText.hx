package ui;

import flixel.text.FlxText;

class FormattedText extends FlxText {
	public function new(X:Float = 0, Y:Float = 0, Width:Float = 0, ?startText:String = "", 
						?fontFile:String = "assets/fonts/vcr.ttf", size:Int = 20, 
						colour:Int = 0xFFFFFFFF, ?defaultAlign:FlxTextAlign = LEFT, 
						?defaultBorderStyle:FlxTextBorderStyle = NONE, ?borderColour:Int = 0xFF000000){
		super(X, Y, Width, startText, size);

		setFormat(fontFile, size, colour, defaultAlign, defaultBorderStyle, borderColour);	
		antialiasing = false;
	}
}
