package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

import backend.Song;
import states.MainMenuState;

typedef MenuObject = {
	var obj:FlxSprite;
	var targetX:Int;
	var targetY:Int;
	var targetA:Float;
}

class MenuTemplate extends EventState {
	/*
		Configure menu spacings. This applies to PauseSubstate as well.
		If you want the menus to have the base game positioning, replace the values with the comment values. 
	*/
	public static inline var X_OFFSET:Int  = 60;  // 90
	public static inline var X_SPACING:Int = 20;
	public static inline var Y_OFFSET:Int  = 110; // 345
	public static inline var Y_SPACING:Int = 110; // 156
	public static inline var DESELECTED_ALPHA:Float = 0.35;

	public var curSel:Int  = 0;
	public var curAlt:Int  = 0;
	public var columns:Int = 1;

	private var arrGroup:Array<MenuObject> = [];
	private var arrIcons:FlxTypedGroup<CharacterIcon>;
	private var camFollow:FlxObject;

	private function addBG(red:Int, green:Int, blue:Int, ?sprite:String = "ui/defaultMenuBackground") {
		var background = new StaticSprite(0,0).loadGraphic(Paths.lImage(sprite));
		background.scale.set(1.1, 1.1);
		background.screenCenter();
		background.color = FlxColor.fromRGB(red, green, blue);

		add(background);
		background.scrollFactor.set(0, 0.5);
	}

	override function add(Sprite:FlxBasic):FlxBasic {
		super.add(Sprite);

		var castedSprite:FlxObject = cast Sprite;
		if (castedSprite != null)
			castedSprite.scrollFactor.set();
		
		return Sprite;
	}

	override function clear(){
		for(i in 0...arrGroup.length){
			remove(arrGroup[i].obj);

			arrGroup[i].obj.destroy();
			arrGroup[i].obj = null;
		}

		arrGroup = [];
		arrIcons.clear();
		super.clear();
	}

	override function create(){
		arrIcons = new FlxTypedGroup<CharacterIcon>();
		camFollow = new FlxObject(0,0,1,1);
		FlxG.camera.follow(camFollow, null, 0.023);

		add(arrIcons);
		super.create();

		if(FlxG.sound.music == null || !FlxG.sound.music.playing) {
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
		#if (flixel < "5.4.0")
		FlxG.camera.followLerp = (1 - Math.pow(0.5, elapsed * 2)) * (60 / Settings.framerate);
		#end

		var lerpVal = Math.pow(0.5, elapsed * 15);

		for(i in 0...Math.floor(arrGroup.length / columns)){
			for(x in 0...columns){
				var curMember = arrGroup[(i * columns) + x];

				curMember.obj.alpha = FlxMath.lerp(curMember.targetA, curMember.obj.alpha, lerpVal);
				curMember.obj.x		= FlxMath.lerp(curMember.targetX, curMember.obj.x	 , lerpVal);
				curMember.obj.y		= FlxMath.lerp(curMember.targetY, curMember.obj.y	 , lerpVal);
			}

			var icn:CharacterIcon = arrIcons.members[i * columns];

			if(icn == null) 
				continue;

			var grpMem = arrGroup[i * columns];

			icn.x	  = grpMem.obj.width + grpMem.obj.x;
			icn.y	  = grpMem.obj.y + ((grpMem.obj.height - icn.height) * 0.5);
			icn.alpha = grpMem.obj.alpha;
		}

		super.update(elapsed);
	}

	public function pushObject(spr:FlxBasic){
		var cr:MenuObject = {
			obj: cast spr,
			targetX: X_OFFSET + ((arrGroup.length + 1) * X_SPACING),
			targetY: Y_OFFSET + Math.round((arrGroup.length + 1) * Y_SPACING / columns),
			targetA: DESELECTED_ALPHA
		};

		cr.obj.alpha = DESELECTED_ALPHA;
		cr.obj.scrollFactor.set();

		arrGroup.push(cr);
		add(cr.obj);
	}

	public function pushIcon(icn:CharacterIcon){
		arrIcons.add(icn);
		icn.scale.set(0.85, 0.85);
	}

	public function altChange(change:Int = 0)
	if(columns > 2){
		curAlt += change;
		curAlt += columns - 1;
		curAlt %= columns - 1;
		changeSelection(0);
	} 

	public function changeSelection(to:Int = 0) {
		FlxG.sound.play(Paths.lSound('ui/scrollMenu'));

		var loopNum = Math.floor(arrGroup.length / columns);
		curSel += to + loopNum;
		curSel %= loopNum;

		for(i in 0...loopNum){
			var item = arrGroup[i * columns];

			item.targetX = (i - curSel) * X_SPACING;
			item.targetX += X_OFFSET;
			item.targetY = (i - curSel) * Y_SPACING;
			item.targetY += Y_OFFSET;
			item.targetA = i == curSel ? 1 : DESELECTED_ALPHA;

			if(columns <= 1) 
				continue;

			for(x in 1...columns){
				var sn = columns - 1;
				var offItem = arrGroup[(i * columns) + x];

				offItem.obj.screenCenter(X);
				offItem.obj.x += (x - Math.floor(sn * 0.5) + (sn & 0x01 == 0 ? 0.5 : 0)) * 323;

				offItem.targetX = Math.round(offItem.obj.x);
				offItem.targetY = item.targetY;
				offItem.targetA = x-1 == curAlt ? item.targetA : DESELECTED_ALPHA;
			}
		}

		camFollow.y = (curSel / loopNum) * 80;
		camFollow.y += 320;
	}

	public function exitFunction(){
		if(NewTransition.skip()) 
			return;

		EventState.changeState(new MainMenuState());
		FlxG.sound.play(Paths.lSound('ui/cancelMenu'));
	}
}
