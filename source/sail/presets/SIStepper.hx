package sail.presets;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;
import sail.presets.SIButton;
import sail.presets.SIHoverableContainer;

class SIStepper extends SIHoverableContainer {
	private var upButton:SIButton;
	private var downButton:SIButton;
	private var numBox:SIInput;

	public var value:Float = 0;
	public var step:Float  = 1;
	public var min:Float   = 0;
	public var max:Float   = 0;

	public var callback:Float->Void = null;

	public function new(defaultValue:Float, width:Int, anchor:SICardinal, reference:SIGeneric, style:Class<SIStyleGeneric>) {
		super(width, SIGeneric.DEFAULT_COMPONENT_HEIGHT, anchor, reference);

		this.style = style;
		corner = TOPRIGHT;
		spacing = 0;
		value = defaultValue;

		downButton = new SIButton('-', height, LEFT, null);
		upButton   = new SIButton('+', height, LEFT, downButton);
		numBox     = new SIInput(Std.string(defaultValue), width - (height * 2), LEFT, upButton);
		downButton.callback = function() { setValue(value - step); };
		upButton.callback   = function() { setValue(value + step); };
		numBox.callback     = function(nStr:String, finish:Bool) {
			if (finish)
				setValue(Std.parseFloat(nStr));
		}

		addChild(downButton);
		addChild(upButton);
		addChild(numBox);
	}

	public function setValue(newValue:Float) {
		if (Math.isNaN(newValue))
			newValue = 0;

		value = max > min ? Math.max(Math.min(newValue, max), min) : newValue;
		numBox.changeText(Std.string(value), false);

		if (callback != null)
			callback(value);
	}
}
