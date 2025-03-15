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
	private static var fpsDisplay:FPSCounter;
	private static var memDisplay:MemCounter;

	public static inline var INITIAL_STATE:Class<FlxState> = TitleState;
	public static inline var GAME_WIDTH:Int	= 1280;
	public static inline var GAME_HEIGHT:Int = 720;

	public static function changeUsefulInfo(on:Bool)
		fpsDisplay.visible = memDisplay.visible = on;

	public function new() {
		super();
		
		SettingsManager.openSettings();

		fpsDisplay = new FPSCounter(10, 3, 0xFFFFFF);
		memDisplay = new MemCounter(10, 18, 0xFFFFFF);

		var ldState:Class<FlxState> = #if (desktop) Settings.cache_assets ? LoadingState : #end INITIAL_STATE;

		addChild(new FlxGame(
			GAME_WIDTH,
			GAME_HEIGHT, 
			ldState, 
			#if (flixel < "5.0.0") 1, #end 
			Settings.framerate, 
			Settings.framerate, 
			Settings.skip_intro, 
			Settings.start_fullscreen
		));
		addChild(fpsDisplay);
		addChild(memDisplay);

		NewTransition.initialise();

		#if (!desktop)
		FlxG.keys.preventDefaultKeys = []; // Required to fix keys such as space-bar not working on web-builds.
		Settings.framerate = 60;
		#end
		
		// I have to give credit to Psych Engine here.
		// Wouldn't have cared enough to fix this on my own.
		#if linux
		Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile("icon.png"));
		#end
		
		SettingsManager.apply();
		FlxG.mouse.visible = false;
	}
}
