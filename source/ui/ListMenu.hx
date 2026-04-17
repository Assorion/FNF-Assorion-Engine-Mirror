package ui;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

import backend.Song;
import states.MainMenuState;

typedef MenuObject = {
	var spr:FlxSprite;
	var icon:CharacterIcon;
	var targetX:Int;
	var targetY:Int;
	var targetA:Float;
}

class ListMenu extends EventState {
	/*
		Configure menu spacings. This applies to PauseSubstate as well.
	*/
	public static inline var X_OFFSET:Int  = 90;
	public static inline var X_SPACING:Int = 20;
	public static inline var Y_OFFSET:Int  = 345;
	public static inline var Y_SPACING:Int = 156; 
	public static inline var DESELECTED_ALPHA:Float = 0.375;

	public var curSel:Int  = 0;

	private var listItems:Array<MenuObject> = [];
	private var listGroup:FlxSpriteGroup = new FlxSpriteGroup();
	private var background:FlxSprite;
	private var backgroundY:Float = -72;

	private function addBG(red:Int, green:Int, blue:Int, ?sprite:String = "ui/defaultMenuBackground") {
		background = new StaticSprite(0,-72).loadGraphic(Paths.lImage(sprite));
		background.scale.set(1.1, 1.1);
		background.origin.set(0, 0);
		background.screenCenter(X);
		background.color = FlxColor.fromRGB(red, green, blue);

		add(background);
	}

	override function create(){
		super.create();
		add(listGroup);

		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			Song.musicSet(Paths.MENU_TEMPO);
			FlxG.sound.playMusic(Paths.lMusic(Paths.MENU_MUSIC));
		}
	}

	override function keyHit(ev:KeyboardEvent)
		ev.keyCode.bindFunctions([
			[Binds.ui_up,	 function(){ changeSelection(-1); }],
			[Binds.ui_down,  function(){ changeSelection(1);  }],
			[Binds.ui_left,  function(){ altChange(-1);       }],
			[Binds.ui_right, function(){ altChange(1);        }],
			[Binds.ui_back,  function(){ exitFunction();      }]
		]);

	override function update(elapsed:Float){
		var lerpVal = Math.pow(0.5, elapsed * 15);
		var bgLerp  = Math.pow(0.5, elapsed);

		if (background != null)
			background.y = FlxMath.lerp(backgroundY, background.y, bgLerp);

		for(i in 0...listItems.length){
			var curMember = listItems[i];

			curMember.spr.alpha = FlxMath.lerp(curMember.targetA, curMember.spr.alpha, lerpVal);
			curMember.spr.x		= FlxMath.lerp(curMember.targetX, curMember.spr.x	 , lerpVal);
			curMember.spr.y		= FlxMath.lerp(curMember.targetY, curMember.spr.y	 , lerpVal);

			if (curMember.icon == null) 
				continue;

			curMember.icon.x     = curMember.spr.width + curMember.spr.x;
			curMember.icon.y     = curMember.spr.y + ((curMember.spr.height - curMember.icon.height) * 0.5);
			curMember.icon.alpha = curMember.spr.alpha;
		}

		super.update(elapsed);
	}

	private function clearItems() {
		listItems = [];

		while(listGroup.members.length > 0)
			listGroup.remove(listGroup.members[0], true);
	}

	private function pushMenuItem(spr:FlxBasic, ?icon:CharacterIcon):MenuObject {
		var castedSpr:FlxSprite = cast(spr, FlxSprite);
		castedSpr.alpha = DESELECTED_ALPHA;

		var newMenuItem:MenuObject = {
			spr: castedSpr,
			icon: icon,
			targetX: X_OFFSET + ((listItems.length + 1) * X_SPACING),
			targetY: Y_OFFSET + Math.round((listItems.length + 1) * Y_SPACING),
			targetA: DESELECTED_ALPHA
		};

		listItems.push(newMenuItem);
		listGroup.add(newMenuItem.spr);
		if (icon != null)
			listGroup.add(newMenuItem.icon); // <-- Extremely salty that Flixel won't check that the sprite isn't null

		return newMenuItem;
	}

	/* Empty function that can be overridden */
	public function altChange(change:Int = 0) {}

	public function changeSelection(to:Int = 0) {
		curSel = CoolUtil.intCircularMod(curSel + to, listItems.length);
		backgroundY = (curSel / listItems.length) * 72;
		backgroundY -= 72;

		FlxG.sound.play(Paths.lSound('ui/scrollMenu'));

		for(i in 0...listItems.length){
			var item = listItems[i];

			item.targetX = (i - curSel) * X_SPACING;
			item.targetX += X_OFFSET;
			item.targetY = (i - curSel) * Y_SPACING;
			item.targetY += Y_OFFSET;
			item.targetA = i == curSel ? 1 : DESELECTED_ALPHA;
		}
	}

	public function exitFunction() {
		if (NewTransition.skip())
			return;

		EventState.changeState(new MainMenuState());
		FlxG.sound.play(Paths.lSound('ui/cancelMenu'));
	}
}
