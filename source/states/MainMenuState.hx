package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import lime.app.Application;

import ui.NewTransition;

using StringTools;

#if !debug @:noDebug #end
class MainMenuState extends EventState {
	private var OPTION_LIST  :Array<String> = ['story mode',        'freeplay',        'github',           'options'];
	private var OPTION_ASSETS:Array<String> = ['mainMenuOptions'  , 'mainMenuOptions', 'mainMenuOptions', 'mainMenuOptions'];

	private static var curSelected:Int = 0;

	private var menuItems:FlxTypedGroup<FlxSprite>;
	private var camFollow:FlxObject;
	private var itemWasSelected:Bool;

	override function create() {
		Paths.clearCache();

		var bg:StaticSprite = new StaticSprite(-80).loadGraphic(Paths.lImage('ui/defaultMenuBackground'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18 * (3 / OPTION_LIST.length);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color  = FlxColor.fromRGB(255, 232, 110);

		var versionNumber = new FormattedText(5, FlxG.height - 18, 0, "Assorion Engine v" + Application.current.meta.get('version'), null, 16, FlxColor.WHITE, LEFT, OUTLINE);
		versionNumber.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		camFollow = new FlxObject(0, 0, 1, 1);

		add(bg);
		add(menuItems);
		add(versionNumber);
		FlxG.camera.follow(camFollow, null, 0.023);

		for (i in 0...OPTION_LIST.length) {
			var menuItem:FlxSprite = new FlxSprite(0, 0);
			menuItem.frames = Paths.lSparrow('ui/${OPTION_ASSETS[i]}');

			menuItem.animation.addByPrefix('idle',	   OPTION_LIST[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', OPTION_LIST[i] + " white", 24);
			menuItem.animation.play('idle');

			menuItem.screenCenter();
			menuItem.scrollFactor.set();
			menuItem.y += (i - Math.floor(OPTION_LIST.length / 2) + (OPTION_LIST.length & 0x01 == 0 ? 0.5 : 0)) * 160;

			menuItems.add(menuItem);
		}

		var oldCurSel:Int = curSelected;
		curSelected = 0;
		changeItem(oldCurSel);

		super.create();
	}

	// Camera fix across framerates (Not needed for newer flixel versions!)

	#if (flixel < "5.4.0")
	override function update(elapsed:Float){
		super.update(elapsed);
		FlxG.camera.followLerp = (1 - Math.pow(0.5, elapsed * 2)) * (60 / Settings.framerate);
	}
	#end

	private var fadingTweens:Array<FlxTween> = [];
	private var leaving:Bool = false;
	override public function keyHit(ev:KeyboardEvent)
		ev.keyCode.bindFunctions([
			[Binds.ui_up,	  function(){ changeItem(-1); }],
			[Binds.ui_down,   function(){ changeItem(1);  }],
			[Binds.ui_accept, function(){ changeState();  }],
			[Binds.ui_back,   function(){
				if(itemWasSelected){
					for(i in 0...OPTION_LIST.length){
						if(fadingTweens[i] != null) 
							fadingTweens[i].cancel();

						menuItems.members[i].alpha = 1;
					}
	
					events = [];
					fadingTweens = [];
					itemWasSelected = false;
					return;
				}

				if(leaving){
					NewTransition.skip();
					return;
				}

				FlxG.sound.play(Paths.lSound('ui/cancelMenu'));
				EventState.changeState(new TitleState(false));
				leaving = true;
			}]
		]);

	private function changeState(){
		if(itemWasSelected){
			executeAllEvents();
			NewTransition.skip();
			return;
		}
		
		FlxG.sound.play(Paths.lSound('ui/confirmMenu'));
		itemWasSelected = true;

		for(i in 0...OPTION_LIST.length)
			if(i != curSelected)
				fadingTweens.push(FlxTween.tween(menuItems.members[i], {alpha:0}, 0.8));

		for(i in 0...8)
			postEvent(i / 8, function(){
				menuItems.members[curSelected].alpha = (i & 0x01 == 0 ? 0 : 1);
			});

			postEvent(1, function() {
				switch (curSelected){
				case 0:
					EventState.changeState(new StoryMenuState());
				case 1:
					EventState.changeState(new FreeplayState());
				case 2:
					var site = 'https://codeberg.org/Assorion/FNF-Assorion-Engine';
					FlxG.resetState();

					#if linux
					Sys.command('xdg-open', [site]);
					#else
					FlxG.openURL(site);
					#end
				case 3:
					EventState.changeState(new OptionsState());
				}
			});
	}

	private function changeItem(to:Int = 0)
	if(!itemWasSelected) {
		FlxG.sound.play(Paths.lSound('ui/scrollMenu'));

		var oldSel = curSelected;
		curSelected = (curSelected + to + menuItems.length) % menuItems.length;

		var newItem = menuItems.members[curSelected];
		var oldItem = menuItems.members[oldSel];

		oldItem.animation.play('idle');
		newItem.animation.play('selected');

		camFollow.y = newItem.getGraphicMidpoint().y;

		oldItem.updateHitbox();
		oldItem.screenCenter(X);
		newItem.updateHitbox();
		newItem.screenCenter(X);
	}
}
