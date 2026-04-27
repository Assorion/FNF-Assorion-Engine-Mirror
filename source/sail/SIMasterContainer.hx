package sail;

import flixel.FlxSprite;

import sail.SIGeneric;
import sail.style.SIStyleGeneric;

// Just a container that doesn't rely on a parent being present.
class SIMasterContainer extends SIContainer {
	public static var lastComponent:SIGeneric = null;
	public static var inputGrabbed:Bool = false;

	public function new(width:Int, height:Int, x:Float, y:Float, style:Class<SIStyleGeneric>) {
		super(width, height, TOP, null);

		this.style = style;
		corner = TOPLEFT;
		setXY(x, y);
	}

	override public function findReferenceX():Float 
		return 0;

	override public function findReferenceY():Float
		return 0;

	override public function redraw() {
		var BGData:SIStyleGeneric = Type.createInstance(style, [width, height, false]);
		var BGSpr:FlxSprite = new FlxSprite(0, 0).loadGraphic(BGData);
		BGSpr.antialiasing = false;
		BGData.createSquare([], 0, 0, width, height, this, true, true);
		sprite.x = x;
		sprite.y = y;

		sprite.clear();
		sprite.add(BGSpr);
		for(child in children)
			child.redraw();
	}

	override public function onClick(mouseX:Float, mouseY:Float):Bool {
		var previousLastComponent:SIGeneric = lastComponent;
		var foundComponent:Bool = super.onClick(mouseX, mouseY);

		if ((previousLastComponent != lastComponent || !foundComponent)
		 && previousLastComponent != null)
			previousLastComponent.offClick();

		return foundComponent;
	}

	override public function onClickRelease()
		if (lastComponent != null)
			lastComponent.onClickRelease();

	public function setXY(x:Float, y:Float) {
		this.x = x;
		this.y = y;
		sprite.x = x;
		sprite.y = y;
	}
}
