package sail.widgets;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

class SIColourbox extends SIGeneric {
	public var bgSpr:SIStyle;
	public var colour:Int;

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, startingColour:Int, ?container:SIContainer = null) {
		super(relativeSide, defaultCorner, reference, SIGeneric.COMPONENT_HEIGHT, null, container);
		colour = startingColour;
	}

	public function setColour(col:Int) {
		colour = col;
		bgSpr.drawSquare(0, 0, w, h, col, true);
	}

	override function redraw() {
		super.redraw();
		bgSpr = Type.createInstance(style, [w, h]);
		setColour(colour);
		sprGroup.add(new StaticSprite().loadGraphic(bgSpr.getData()));
	}

	override function hover(mouseX:Float, mouseY:Float)
		return false;
}
