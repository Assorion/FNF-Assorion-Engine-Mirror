package sail.presets;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

class SICheckbox extends SIGeneric {
	private var nData:SIStyleGeneric;

	public var checked:Bool = false;
	public var callback:Bool->Void = null;

	public function new(defaultValue:Bool, anchor:SICardinal, reference:SIGeneric) {
		sprite = new FlxSpriteGroup();
		checked = defaultValue;

		super(SIGeneric.DEFAULT_COMPONENT_HEIGHT, SIGeneric.DEFAULT_COMPONENT_HEIGHT, anchor, reference);
	}

	override public function redraw() {
		var nSpr = new FlxSprite(0, 0);
		nData = Type.createInstance(style, [width, height, true]);
		nSpr.loadGraphic(nData);
		nSpr.antialiasing = false;
		setCheck(checked);

		super.redraw();
		sprite.add(nSpr);
	}

	public function setCheck(toOn:Bool) {
		checked = toOn;
		
		nData.createSquare([], 0, 0, width, height, this, true, false);
		if (checked)
			nData.createSquare([], 6, 6, width - 12, height - 12, this, false, true);
	}

	override public function onClick(mouseX:Float, mouseY:Float) {
		if (!isMouseOver(mouseX, mouseY))
			return false;

		nData.createSquare([], 6, 6, width - 12, height - 12, this, false, false);
		SIMasterContainer.lastComponent = this;
		return true;
	}

	override public function onClickRelease() {
		setCheck(!checked);

		if (callback != null)
			callback(checked);
	}
}
