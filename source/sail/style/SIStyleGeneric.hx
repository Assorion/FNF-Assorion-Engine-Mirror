package sail.style;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

interface SIStyle {
	public final THICKNESS:Int;
	public final COLOUR_FG:Int;
	public final COLOUR_LIGHT:Int;
	public final COLOUR_DARK:Int;

	public function getData():BitmapData;
	public function drawSquare(sX:Int, sY:Int, sW:Int, sH:Int, ?fillColour:Null<Int>, ?indent:Bool = false):Void;
	public function clear():Void;
}

class SIStyleGeneric implements SIStyle extends BitmapData {
	public final THICKNESS:Int     = 5;
	public final COLOUR_FG:Int     = 0xFF808080;
	public final COLOUR_LIGHT:Int  = 0xFFAFAFB0;
	public final COLOUR_DARK:Int   = 0xFF50505A;

	public function new(width:Int, height:Int)
		super(width, height, true);

	public function getData() 
		return this;

	public function drawSquare(sX:Int, sY:Int, sW:Int, sH:Int, ?fillColour:Null<Int>, ?indent:Bool = false) {
		var localRect = new Rectangle(sX, sY, sW, sH);
		var rightColour = indent ? COLOUR_LIGHT : COLOUR_DARK;
		var leftColour  = indent ? COLOUR_DARK  : COLOUR_LIGHT;

		fillRect(localRect, fillColour ?? COLOUR_FG);

		for(i in 0...THICKNESS) {
			// Left
			localRect.width = 1;
			localRect.y = sY;
			localRect.x = sX + i;
			localRect.height = (sH - i) - 1;
			fillRect(localRect, leftColour);

			// Top
			localRect.height = 1;
			localRect.x = sX;
			localRect.y = sY + i;
			localRect.width = (sW - i) - 1;
			fillRect(localRect, leftColour);

			// Right
			localRect.width = 1;
			localRect.y = sY + 1 + i;
			localRect.x = (sX + sW - 1) - i;
			localRect.height = (sH - i) - 1;
			fillRect(localRect, rightColour);

			// Bottom
			localRect.height = 1;
			localRect.x = sX + 1 + i;
			localRect.y = (sY + sH - 1) - i;
			localRect.width = (sW - i) - 1;
			fillRect(localRect, rightColour);
		}
	}

	public function clear() {
		var localRect = new Rectangle(0, 0, width, height);
		fillRect(localRect, 0x00000000);
	}
}
