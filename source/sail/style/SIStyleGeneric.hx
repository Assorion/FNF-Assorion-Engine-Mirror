package sail.style;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import sail.SIGeneric;

class SIStyleGeneric extends BitmapData {
	public function new(width:Int, height:Int, transparent:Bool = true) {
		super(width, height, transparent, 0x00000000);
	}

	public function createSquare(edges:Array<SIDiagonal>, squareX:Int, squareY:Int, squareW:Int, squareH:Int, component:SIGeneric
		, filled:Bool, ?protruding:Bool = true) {}

	public function clear() {
		var localRect = new Rectangle(0, 0, width, height);	
		fillRect(localRect, 0x00000000);
	}
}

class SIStyleDefault extends SIStyleGeneric {
	private final DEFAULT_THICKNESS:Int    = 4;
	private final DEFAULT_BG_COLOUR:Int    = 0xFFDC7A37;
	private final DEFAULT_LIGHT_COLOUR:Int = 0xFFF08E4B;
	private final DEFAULT_DARK_COLOUR:Int  = 0xFFC86623;

	public function new(width:Int, height:Int, transparent:Bool = true) {
		super(width, height, transparent);
	}

	/*
		Here, there's a lot of arguments that essential go unused. 
		However they're here to provide slightly more comprehensive styling if you want more detailed styles.
		For the default however, it doesn't need to do a whole lot.
	*/
	// TODO add edges
	override public function createSquare(edges:Array<SIDiagonal>, squareX:Int, squareY:Int, squareW:Int, squareH:Int, component:SIGeneric
		, filled:Bool, ?protruding:Bool = true) {
		var localRect = new Rectangle(squareX, squareY, squareW, squareH);
		var leftColour  = protruding ? DEFAULT_LIGHT_COLOUR : DEFAULT_DARK_COLOUR;
		var rightColour = protruding ? DEFAULT_DARK_COLOUR  : DEFAULT_LIGHT_COLOUR;

		if (filled)
			fillRect(localRect, DEFAULT_BG_COLOUR);

		for(i in 0...DEFAULT_THICKNESS) {
			// Left
			localRect.width = 1;
			localRect.y = squareY;
			localRect.x = squareX + i;
			localRect.height = (squareH - i) - 1;
			fillRect(localRect, leftColour);

			// Top
			localRect.height = 1;
			localRect.x = squareX;
			localRect.y = squareY + i;
			localRect.width = (squareW - i) - 1;
			fillRect(localRect, leftColour);

			// Right
			localRect.width = 1;
			localRect.y = squareY + 1 + i;
			localRect.x = (squareX + squareW - 1) - i;
			localRect.height = (squareH - i) - 1;
			fillRect(localRect, rightColour);

			// Bottom
			localRect.height = 1;
			localRect.x = squareX + 1 + i;
			localRect.y = (squareY + squareH - 1) - i;
			localRect.width = (squareW - i) - 1;
			fillRect(localRect, rightColour);
		}
	}
}
