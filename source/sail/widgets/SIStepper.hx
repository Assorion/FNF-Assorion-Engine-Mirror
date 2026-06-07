package sail.widgets;

import sail.SIGeneric;

class SIStepper extends SIContainer {
	private var downButton:SIButton;
	private var upButton:SIButton;
	private var numBox:SIInput;

	public var callback:Float->Void = null;

	public var value:Float = 0;
	public var step:Float  = 1;
	public var min:Float   = 0;
	public var max:Float   = 0;

	public function setValue(newValue:Float, ?noCall:Bool = false) {
		if (Math.isNaN(newValue))
			newValue = 0;

		value = max > min ? Math.max(Math.min(newValue, max), min) : newValue;
		numBox.changeText(Std.string(value), false);

		if (!noCall && callback != null)
			callback(value);
	}

	public function new(?relativeSide:SISide = UNDER, ?defaultCorner:SIDiagonal = TOPLEFT, ?reference:SIGeneric
	, width:Int, startValue:Float, ?container:SIContainer = null) {
		super(relativeSide, defaultCorner, reference, width, null, container);
		
		value      = startValue;
		numBox     = new SIInput(null, TOPLEFT, w - (h * 2), Std.string(startValue), this);
		downButton = new SIButton(RIGHT, numBox,     h, '\\/', this);
		upButton   = new SIButton(RIGHT, downButton, h, '/\\', this);

		downButton.callback = function() { setValue(value - step); };
		upButton.callback   = function() { setValue(value + step); };
		numBox.callback     = function(nStr:String, finish:Bool) {
			if (finish)
				setValue(Std.parseFloat(nStr));
		}
	}
}
