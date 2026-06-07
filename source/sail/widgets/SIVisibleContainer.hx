package sail.widgets;

import sail.style.SIStyleGeneric;

class SIVisibleContainer extends SIContainer {
	public var indented:Bool = false;

	function renderPanel() {
		var bgSpr = Type.createInstance(style, [w, h]);
		bgSpr.drawSquare(0, 0, w, h, indented);
		sprGroup.add(new StaticSprite().loadGraphic(bgSpr.getData()));
	}

	override function redraw() {
		redrawCallback = renderPanel;
		super.redraw();
	}
}
