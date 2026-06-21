package sail.style;

/*
	This style is only really intended to be used for drop down menus.
	It can be used for other things, but that's not recommended!!!
*/

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import sail.style.SIStyleGeneric;

class SIStyleDropdown implements SIStyle extends BitmapData {
	public final THICKNESS:Int     = 4;
	public final COLOUR_FG:Int     = 0xEE404040;
	public final COLOUR_LIGHT:Int  = 0xFF606060;
	public final COLOUR_DARK:Int   = 0xFF000000;

	public function new(width:Int, height:Int)
		super(width, height, true);

	public function getData()
		return this;

	public function drawSquare(sX:Int, sY:Int, sW:Int, sH:Int, ?fillColour:Null<Int>, ?indent:Bool = false) {
		var localRect = new Rectangle(sX, sY, sW, sH);
		var colour    = indent ? COLOUR_LIGHT : COLOUR_FG;
		fillRect(localRect, fillColour != null ? fillColour : colour);
	}

	public function clear() {
		var localRect = new Rectangle(0, 0, width, height);
		fillRect(localRect, 0x00000000);
	}
}
