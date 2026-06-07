package sail.widgets;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

class SITabbedContainer extends SIContainer {
	private var tabs:Array<SIContainer>;
	private var tabBar:SIContainer;
	private var tabCon:SIVisibleContainer;

	public var curTab:Int = 0;

	public function changeTab(newIndex:Int) {
		tabCon.removeChild(tabs[curTab]);
		tabCon.addChild(tabs[newIndex]);
		redraw();

		curTab = newIndex;
		lastComponent = null;
		activeComponent = null;
		hover(FlxG.mouse.x, FlxG.mouse.y);
	}

	public function new(width:Int, height:Int, x:Float, y:Float, tabNames:Array<String>, tabs:Array<SIContainer>) {
		super(null, null, null, width, height, null);
		this.tabs = tabs;
		this.x = x;
		this.y = y;

		if (tabNames.length != tabs.length) {
			trace('Tab names differ from tab amount!');
			return;
		}

		tabBar = new SIContainer(null, TOPLEFT, width, null, this);
		tabCon = new SIVisibleContainer(UNDER, tabBar, width, height - SIGeneric.COMPONENT_HEIGHT, this);
		tabCon.spacing = 5;

		var lastButton:SIButton = null;
		var buttonWidth = Math.floor(width / tabNames.length);
		for(i in 0...tabNames.length) {
			lastButton = new SIButton(RIGHT, TOPLEFT, lastButton, buttonWidth, tabNames[i], tabBar);
			lastButton.callback = function() {
				changeTab(i);
			};
		}
	}
}
