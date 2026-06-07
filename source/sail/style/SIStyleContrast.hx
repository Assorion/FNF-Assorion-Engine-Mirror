package sail.style;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import sail.style.SIStyleGeneric;

class SIStyleContrast extends BitmapData implements SIStyle {
	public final THICKNESS:Int     = 3;
	public final COLOUR_FG:Int     = 0xFF000000;
	public final COLOUR_LIGHT:Int  = 0xFFFFFFFF;
	public final COLOUR_DARK:Int   = 0xFFFFFF00;

	public function new(width:Int, height:Int, transparent:Bool = true) {
		super(width, height, transparent);
	}

	public function getData():BitmapData {
		return this;
	}

	public function drawSquare(sX:Int, sY:Int, sW:Int, sH:Int, ?fillColour:Null<Int>, ?indent:Bool = false) {
		var localRect = new Rectangle(sX, sY, sW, sH);
		fillRect(localRect, indent ? COLOUR_DARK : COLOUR_LIGHT);

		localRect.x = sX + THICKNESS;
		localRect.y = sY + THICKNESS;
		localRect.width  = sW - (THICKNESS * 2);
		localRect.height = sH - (THICKNESS * 2);
		fillRect(localRect, fillColour ?? COLOUR_FG);
	}

	public function clear() {
		var localRect = new Rectangle(0, 0, width, height);
		fillRect(localRect, 0x00000000);
	}
}
