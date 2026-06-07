package sail.widgets;

import flixel.FlxSprite;

import sail.SIGeneric;

class SILabel extends SIGeneric {
	private var textSpr:FormattedText;
	public  var center:Bool = true;

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, ?size:Int = 15, label:String = '', ?container:SIContainer = null) {
		textSpr = new FormattedText(0, 0, 0, label, size, SIGeneric.TEXT_COLOUR);
		super(relativeSide, defaultCorner, reference, Math.floor(textSpr.width), Math.floor(textSpr.height), container);
	}

	public function changeLabel(newLabel:String) {
		textSpr.text = newLabel;
		textSpr.y    = center ? (SIGeneric.COMPONENT_HEIGHT - textSpr.height) / 2 : 0;
		textSpr.y   += y;
		textSpr.x    = x;
		w = Math.floor(textSpr.width);
		h = Math.floor(textSpr.height);
	}

	override public function redraw() {
		super.redraw();
		sprGroup.add(textSpr);
		changeLabel(textSpr.text);
	}

	override public function hover(mouseX:Float, mouseY:Float):Bool 
		return false;
}
