package states;

import flixel.FlxG;
import flixel.util.FlxColor;

import backend.Settings;
import ui.NewTransition;
import ui.MenuTemplate;
import ui.Alphabet;
import gameplay.HealthIcon;

#if !debug @:noDebug #end
class OptionsState extends MenuTemplate
{
	private var optsAndDescriptions:Array<Array<Array<String>>> = [
		[
			['basic',	 'Settings that apply when the game launches'],
			['gameplay', 'Options that only apply in game'],
			['visuals',  'Options that change the presentation of the game'],
			['controls', 'Change the default key bindings']
		],
		[
			['start_fullscreen',  'Start the game in fullscreen mode'],
			['start_volume',	  'Change the volume of the game on launch'],
			['skip_intro',        'Allows skipping the HaxeFlixel logo on launch'],
			#if desktop
			['cache_assets',	  'Loads all assets into memory and keeps them there. DISABLE WHEN MODDING!']
			#end
		],
		[
			['audio_offset',  'Audio offset in milliseconds. Press \'${CoolUtil.getKeyNameFromString(Binds.UI_ACCEPT[0], true, false)}\' to enter hte offset wizard'],
			['downscroll',	  'Makes the notes scroll downwards instead of upwards'],
			['ghost_tapping', 'Disables penalty for pressing a key when no note is hit'], 
			['botplay',		  'Makes the game play itself']
		],
		[
			['antialiasing', 'Makes the game look smoother and less "jagged"'],
			['show_hud',	 'Allow seeing health, score, misses, etc in gameplay'],
			['useful_info',  'Show the FPS and memory counter at the top left of the screen'],
			#if desktop
			['framerate',	 'Changes how fast the game can run']
			#end
		]
	];

	public var currentCategory:Int;
	public var descText:FormattedText;

	override function create() {
		columns = 1;
		addBG(0xFFea71fd);
		super.create();

		var bottomBlack:StaticSprite = new StaticSprite(0, FlxG.height - 30).makeGraphic(1280, 30, FlxColor.BLACK);
		bottomBlack.alpha = 0.6;

		descText = new FormattedText(5, FlxG.height - 25, 0, "", null, 20);
		
		add(bottomBlack);
		add(descText);

		createNewList();
	}
	
	public function createNewList() {
		for(object in arrGroup)
			remove(object.obj);
		
		var showOptionValues:Bool = currentCategory > 0;
		arrGroup = [];
		arrIcons.clear();
		columns = showOptionValues ? 2 : 1;

		for(i in 0...optsAndDescriptions[currentCategory].length) {
			pushObject(new Alphabet(0, (60 * i), optsAndDescriptions[currentCategory][i][0], true));

			if(!showOptionValues) {
				var categoryIcon:HealthIcon = new HealthIcon('settings' + (Math.floor(i / 2) + 1), false);
				categoryIcon.changeState((i+1) & 1);
				pushIcon(categoryIcon);
				continue;
			}

			var optionStr:String = '';
			var val:Dynamic = Reflect.field(Settings, optsAndDescriptions[currentCategory][i][0]);

			optionStr = Std.string(val);
			if(Std.is(val, Bool))
				optionStr = val ? 'yes' : 'no';

			pushObject(new Alphabet(0, (60 * i), optionStr, true));
		}

		changeSelection();
	}

	override public function exitFunction(){
		if(currentCategory > 0){
			currentCategory = 0;
			curSel = 0;
			createNewList();
			return;
		}

		SettingsManager.flush();
		super.exitFunction();
	}

	override function changeSelection(change:Int = 0){
		super.changeSelection(change);
		descText.text = optsAndDescriptions[currentCategory][curSel][1];
	}

	// Add integer options here.
	override function altChange(ch:Int = 0){
		var atg:Alphabet = cast arrGroup[(curSel * 2) + 1].obj;

		switch(optsAndDescriptions[currentCategory][curSel][0]){
			case 'start_volume':
				Settings.start_volume = CoolUtil.intBoundTo(Settings.start_volume + (ch * 10), 0, 100);
				atg.text = Std.string(Settings.start_volume);

			// gameplay.
			case 'audio_offset':
				Settings.audio_offset = CoolUtil.intBoundTo(Settings.audio_offset + ch, 0, 300);
				atg.text = Std.string(Settings.audio_offset);

			// visuals
			case 'framerate':
				Settings.framerate = SettingsManager.framerateClamp(Settings.framerate + (ch * 10));
				atg.text = Std.string(Settings.framerate);
				SettingsManager.apply();
		}
		changeSelection(0);
	}

	// Add togglable options here.
	override public function keyHit(ev:KeyboardEvent){
		super.keyHit(ev);

		if(!ev.keyCode.check(Binds.UI_ACCEPT)) 
			return;

		switch(optsAndDescriptions[currentCategory][curSel][0]){
			case 'basic':
				curSel = 0;
				currentCategory = 1;
			case 'gameplay':
				curSel = 0;
				currentCategory = 2;
			case 'visuals':
				curSel = 0;
				currentCategory = 3;
			case 'controls':
				if(NewTransition.skip()) 
					return;

				EventState.changeState(new ControlsState());
				return;

			// basic
			case 'start_fullscreen':
				Settings.start_fullscreen = !Settings.start_fullscreen;
			case 'skip_intro':
				Settings.skip_intro = !Settings.skip_intro;
			case 'cache_assets':
				Settings.cache_assets = !Settings.cache_assets;
				SettingsManager.apply();

			// gameplay
			case 'audio_offset':
				if(NewTransition.skip()) 
					return;

				EventState.changeState(new OffsetWizard());
				return;
			case 'downscroll':
				Settings.downscroll = !Settings.downscroll;
			case 'botplay':
				Settings.botplay = !Settings.botplay;
			case 'ghost_tapping':
				Settings.ghost_tapping = !Settings.ghost_tapping;

			// visuals
			case 'useful_info':
				Settings.useful_info = !Settings.useful_info;
				SettingsManager.apply();
			case 'antialiasing':
				Settings.antialiasing = !Settings.antialiasing;
				SettingsManager.apply();
			case 'show_hud':
				Settings.show_hud = !Settings.show_hud;
		}

		createNewList();
	}
}
