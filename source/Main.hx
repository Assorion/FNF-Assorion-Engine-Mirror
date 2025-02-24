package;

import openfl.Lib;
import openfl.display.Sprite;
import flixel.FlxState;
import flixel.FlxGame;
import flixel.FlxG;

import ui.FPSCounter;
import ui.MemCounter;
import ui.NewTransition;
import states.TitleState;
import states.LoadingState;

#if !debug
@:noDebug
#end
class Main extends Sprite
{
	private static var fpsC:FPSCounter;
	private static var memC:MemCounter;

	public static inline var initState:Class<FlxState> = TitleState;
	public static inline var gameWidth:Int	= 1280;
	public static inline var gameHeight:Int = 720;

	public static function changeUsefulInfo(on:Bool)
		fpsC.visible = memC.visible = on;

	public function new() {
		super();
		
		SettingsManager.openSettings();

		fpsC = new FPSCounter(10, 3, 0xFFFFFF);
		memC = new MemCounter(10, 18, 0xFFFFFF);

		var ldState:Class<FlxState> = #if (desktop) Settings.cache_assets ? LoadingState : #end initState;

		addChild(new FlxGame(
			gameWidth, 
			gameHeight, 
			ldState, 
			#if (flixel < "5.0.0") 1, #end 
			Settings.framerate, 
			Settings.framerate, 
			Settings.skip_intro, 
			Settings.start_fullscreen
		));
		addChild(fpsC);
		addChild(memC);

		NewTransition.initialise();

		#if (!desktop)
		FlxG.keys.preventDefaultKeys = []; // Required to fix keys such as space-bar not working on web-builds.
		Settings.framerate = 60;
		#end
		
		// I have to give credit to Psych Engine here.
		// Wouldn't have cared enough to fix this on my own.
		#if linux
		Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile("assets/images/icon.png"));
		#end
		
		SettingsManager.apply();
		FlxG.mouse.visible = false;
	}
}
