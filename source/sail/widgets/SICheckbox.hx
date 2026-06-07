package sail.widgets;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

class SICheckbox extends SIGeneric {
	public var bgSpr:SIStyle;
	public var toggleValue:Bool;
	public var callback:Bool->Void;

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, startingValue:Bool, ?container:SIContainer = null) {
		super(relativeSide, defaultCorner, reference, SIGeneric.COMPONENT_HEIGHT, null, container);
		toggleValue = startingValue;
	}

	public function renderSquares() {
		bgSpr.drawSquare(0, 0, w, h, true);
		
		if (toggleValue)
			bgSpr.drawSquare(6, 6, w - 12, h - 12, false);
	}
	
	override function redraw() {
		super.redraw();
		bgSpr = Type.createInstance(style, [w, h]);
		renderSquares();

		sprGroup.add(new StaticSprite().loadGraphic(bgSpr.getData()));
	}

	override function onClick(mouseX:Float, mouseY:Float) {
		if (!super.onClick(mouseX, mouseY))
			return false;

		bgSpr.drawSquare(5, 5, w - 10, h - 10, true);
		return true;
	}

	override function onClickRelease() {
		toggleValue = !toggleValue;
		renderSquares();
		super.onClickRelease();

		if (callback != null)
			callback(toggleValue);
	}
	
}
