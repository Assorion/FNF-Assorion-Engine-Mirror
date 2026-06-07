package sail.widgets;

import flixel.text.FlxText;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

class SIButton extends SIGeneric {
	public var bgSpr:SIStyle;
	public var textSpr:FlxText;
	public var callback:Void->Void;

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, width:Int, label:String = '', ?container:SIContainer = null) {
		super(relativeSide, defaultCorner, reference, width, null, container);
		textSpr = new FormattedText(0, 0, 0, label, 13, SIGeneric.TEXT_COLOUR);
	}

	public function changeLabel(str:String) {
		textSpr.text = str;
		textSpr.x = (w - textSpr.width) / 2;
		textSpr.y = (h - textSpr.height) / 2;
	}

	override function redraw() {
		super.redraw();
		changeLabel(textSpr.text);

		bgSpr = Type.createInstance(style, [w, h, true]);
		bgSpr.drawSquare(0, 0, w, h);

		var tmpSpr = new StaticSprite().loadGraphic(bgSpr.getData());
		sprGroup.add(tmpSpr);
		sprGroup.add(textSpr);
	}

	override function onClick(mouseX:Float, mouseY:Float) {
		if (!super.onClick(mouseX, mouseY))
			return false;

		bgSpr.drawSquare(0, 0, w, h, true);
		return true;
	}

	override function onClickRelease() {
		bgSpr.drawSquare(0, 0, w, h, false);
		super.onClickRelease();
		if (callback != null)
			callback();
	}
}
