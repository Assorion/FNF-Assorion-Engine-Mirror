package states;

import flixel.FlxG;
import flixel.util.FlxColor;

import backend.Settings;
import ui.NewTransition;
import ui.CharacterIcon;
import ui.ListMenu;
import ui.Alphabet;

class OptionsState extends ListMenu {
	private var OPTS_DESCRIPTIONS:Array<Array<Array<String>>> = [
		[
			['basic',	         'Settings that apply when the game launches'],
			['gameplay',         'Options that only apply in game'],
			['visuals',          'Options that change the presentation of the game'],
			['controls',         'Change the default key bindings']
		],
		[
			#if desktop
			['start_fullscreen', 'Start the game in fullscreen mode'],
			#end
			['start_volume',	 'Change the volume of the game on launch'],
			['skip_intro',       'Allows skipping the HaxeFlixel logo on launch'],
			['cache_assets',	 'Loads all assets into memory and keeps them there. DISABLE WHEN MODDING!']
		],
		[
			['audio_offset',     'Audio offset in milliseconds. Press \'${Utility.keyCodeToString(Binds.ui_accept[0], false)}\' to enter the offset wizard'],
			['downscroll',	     'Makes the notes scroll downwards instead of upwards'],
			['ghost_tapping',    'Disables penalty for pressing a key when no note is hit'], 
			['botplay',		     'Makes the game play itself']
		],
		[
			['antialiasing',     'Makes the game look smoother and less "jagged"'],
			['show_hud',	     'Allow seeing health, score, misses, etc in gameplay'],
			['useful_info',      'Show the FPS and memory counter at the top left of the screen'],
			#if desktop
			['framerate',	     'Changes how fast the game can run'],
			#end
			['high_contrast',    'Enables high contrast UI for the in-built chart editor']
		]
	];

	private var secondaryColumn:Array<Alphabet> = [];
	private var currentOption:String = '';
	private var currentCategory:Int = 0;
	private var bottomBlack:StaticSprite;
	private var descText:FormattedText;

	override function create() {
		bottomBlack = new StaticSprite(0, FlxG.height - 30).makeGraphic(1280, 30, FlxColor.BLACK);
		descText = new FormattedText(5, FlxG.height - 25, 0, "", null, 20);
		bottomBlack.alpha = 0.6;

		addBG(234, 113, 253);
		super.create();
		add(bottomBlack);
		add(descText);

		openCategory(0);
	}

	function openCategory(category:Int = 0) {
		currentCategory = category;
		curSel = 0;

		clearItems();
		secondaryColumn = [];

		for(i in 0...OPTS_DESCRIPTIONS[category].length) {
			var item = pushMenuItem(new Alphabet(0, (60 * i), OPTS_DESCRIPTIONS[category][i][0], true), null);

			if (category <= 0) {
				var categoryIcon:CharacterIcon = new CharacterIcon('settings' + (Math.floor(i / 2) + 1), false);
				item.icon = categoryIcon;
				categoryIcon.animation.play(['neutral', 'losing'][i % 2]);
				listGroup.add(categoryIcon);
				continue;
			}

			var value:Dynamic = Reflect.field(Settings, OPTS_DESCRIPTIONS[category][i][0]);
			var optionStr:String = Std.string(value);

			if (Std.is(value, Bool))
				optionStr = value ? 'on' : 'off';

			secondaryColumn[i] = new Alphabet(0, (60 * i), optionStr, true);
			listGroup.add(secondaryColumn[i]);
		}

		changeSelection(0);
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		for(i in 0...secondaryColumn.length) {
			var item = secondaryColumn[i];
			item.x = 960 - (item.width * 0.5);
			item.y = listItems[i].spr.y;
			item.alpha = listItems[i].spr.alpha;
		}
	}

	override function exitFunction(){
		if (currentCategory > 0) {
			openCategory(0);
			return;
		}

		SettingsManager.flush();
		super.exitFunction();
	}

	override function changeSelection(change:Int = 0){
		super.changeSelection(change);

		currentOption = OPTS_DESCRIPTIONS[currentCategory][curSel][0];
		descText.text = OPTS_DESCRIPTIONS[currentCategory][curSel][1];
	}

	/* Add integer options here. */
	override function altChange(ch:Int = 0) {
		switch(currentOption){
		// Basic
		case 'start_volume':
			Settings.start_volume = Utility.intClamp(Settings.start_volume + (ch * 10), 0, 100);

		// Gameplay.
		case 'audio_offset':
			Settings.audio_offset = Utility.intClamp(Settings.audio_offset + ch, 0, 300);

		// Visuals
		case 'framerate':
			Settings.framerate = SettingsManager.framerateClamp(Settings.framerate + (ch * 10));
			SettingsManager.apply();
		default:
			return;
		}

		secondaryColumn[curSel].setText(Std.string(Reflect.field(Settings, currentOption)));
		changeSelection(0);
	}

	/* Add togglable options here. */
	override function keyHit(ev:KeyboardEvent){
		super.keyHit(ev);

		if (!ev.keyCode.check(Binds.ui_accept)) 
			return;

		switch(currentOption){
		case 'basic':
			openCategory(1);
			return;
		case 'gameplay':
			openCategory(2);
			return;
		case 'visuals':
			openCategory(3);
			return;
		case 'controls':
			if (!NewTransition.skip()) 
				EventState.changeState(new ControlsState());

			return;

		// Basic
		case 'start_fullscreen':
			Settings.start_fullscreen = !Settings.start_fullscreen;
		case 'skip_intro':
			Settings.skip_intro = !Settings.skip_intro;
		case 'cache_assets':
			Settings.cache_assets = !Settings.cache_assets;
			SettingsManager.apply();

		// Gameplay
		case 'audio_offset':
			if (!NewTransition.skip()) 
				EventState.changeState(new OffsetWizard());

			return;
		case 'downscroll':
			Settings.downscroll = !Settings.downscroll;
		case 'botplay':
			Settings.botplay = !Settings.botplay;
		case 'ghost_tapping':
			Settings.ghost_tapping = !Settings.ghost_tapping;

		// Visuals
		case 'useful_info':
			Settings.useful_info = !Settings.useful_info;
			SettingsManager.apply();
		case 'antialiasing':
			Settings.antialiasing = !Settings.antialiasing;
			SettingsManager.apply();
		case 'show_hud':
			Settings.show_hud = !Settings.show_hud;
		case 'high_contrast':
			Settings.high_contrast = !Settings.high_contrast;

		default:
			return;
		}

		var value:Bool = cast(Reflect.field(Settings, currentOption), Bool);
		secondaryColumn[curSel].setText(value ? 'on' : 'off');
		changeSelection(0);
	}
}
