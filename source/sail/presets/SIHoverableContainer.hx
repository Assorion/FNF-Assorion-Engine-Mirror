package sail.presets;

import sail.SIGeneric;
import sail.SIContainer;

class SIHoverableContainer extends SIContainer {
	public function new(width:Int, height:Int, anchor:SICardinal, reference:SIGeneric) {
		super(width, height, anchor, reference);
	}

	override public function hover(mouseX:Float, mouseY:Float):Bool {
		var ret:Bool = false;

		for(i in 0...children.length)
			ret = children[i].hover(mouseX - x, mouseY - y) || ret;

		return ret;
	}
}
