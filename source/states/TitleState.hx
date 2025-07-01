package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

import backend.Song;
import ui.NewTransition;
import ui.Alphabet;

using StringTools;

class TitleState extends EventState {
	private var TEXT_SEQUENCE:Array<Array<String>> = [ // % = Random Text
		['welcome', 'traveller'],
		['Original game by','ninjamuffin'],
		['assorion engine by', 'antivirus', 'and barzil'],
		['runs on', 'windows 2000', 'and netbsd'],
		['%'],
		['%'],
		['get ready', 'here it comes']
	];

	public var allIntroTexts:Array<Array<String>> = [];
	public var funkinLogo:FlxSprite;
	public var gfDance:FlxSprite;
	public var dancedLeft:Bool = false;
	public var enterText:FlxSprite;

	var textGroup:FlxGroup;
	var postFlashGroup:FlxTypedGroup<FlxSprite>;
	var soundTween:FlxTween;

	private var initialized:Bool = false;

	public function new(?firstLoad:Bool = true){
		initialized = !firstLoad;
		super();
	}

	override public function create() {
		allIntroTexts = cast haxe.Json.parse(Paths.lText('introText.json'));

		for(i in 0...TEXT_SEQUENCE.length) 
			if (TEXT_SEQUENCE[i][0] == '%') 
				TEXT_SEQUENCE[i] = allIntroTexts.splice(CoolUtil.randomRange(0, allIntroTexts.length - 1), 1)[0];

		super.create();

		if (!initialized) {
			if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
				Song.musicSet(Paths.MENU_TEMPO);
				FlxG.sound.playMusic(Paths.lMusic(Paths.MENU_MUSIC));
			}

			FlxG.sound.volume = Settings.start_volume / 100;
			FlxG.sound.music.volume = 0;
			soundTween = FlxTween.tween(FlxG.sound.music, {volume: 1}, 3);
		}

		funkinLogo = new FlxSprite(-150, -100);
		funkinLogo.frames = Paths.lSparrow('titleScreen/logoBumpin');
		funkinLogo.animation.addByPrefix('bump', 'logo bumpin', 24);
		funkinLogo.updateHitbox();

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.lSparrow('titleScreen/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

		enterText = new FlxSprite(100, FlxG.height * 0.8);
		enterText.frames = Paths.lSparrow('titleScreen/titleEnter');
		enterText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		enterText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		enterText.updateHitbox();
		enterText.antialiasing = gfDance.antialiasing = funkinLogo.antialiasing = Settings.antialiasing;
		
		Song.beatHooks.push(beatHit);

		// Ending card
		postFlashGroup = new FlxTypedGroup<FlxSprite>();
		postFlashGroup.add(funkinLogo);
		postFlashGroup.add(gfDance);
		postFlashGroup.add(enterText);

		textGroup = new FlxGroup();
		add(textGroup);

		if (initialized)
			skipIntro();

		initialized = true;
	}

	private var leaving:Bool = false;
	override public function keyHit(ev:KeyboardEvent)
		ev.keyCode.bindFunctions([
			[Binds.ui_accept, function(){
				if (leaving) {
					if (soundTween != null){ 
						soundTween.cancel();
						FlxG.sound.music.volume = 1;
					}

					executeAllEvents();
					NewTransition.skip();
					return;
				}

				if (skippedIntro) {
					enterText.animation.play('press');
					leaving = true;
					FlxG.sound.play(Paths.lSound('ui/confirmMenu'));
					postEvent(1, function() { 
						EventState.changeState(new MainMenuState()); 
					});
				}

				skipIntro();
			}]
		]);

	override function update(elapsed:Float){
		FlxG.camera.zoom = CoolUtil.boundTo(FlxG.camera.zoom - (elapsed * 0.5), 1, 2);

		Song.update(FlxG.sound.music.time);
		super.update(elapsed);
	}

	private var textStep:Int = 0;
	private var tsubStep:Int = 0;
	private function createCoolText(pos:Int, amount:Int, text:String) {
		var txt:Alphabet = new Alphabet(0,0, text, true);
		txt.screenCenter();
		txt.y += (pos - Math.floor(amount / 2) + (amount & 1 == 0 ? 0.5 : 0)) * 75;

		textGroup.add(txt);
	}

	public function beatHit() {
		if (Song.currentBeat <= 0 || skippedIntro) {
			dancedLeft = !dancedLeft;

			gfDance.animation.play('dance' + (dancedLeft ? 'Left' : 'Right'));
			funkinLogo.animation.play('bump');
			return;
		}
		
		// Text code
		FlxG.camera.zoom = 1.075;
		
		if (tsubStep < 0){
			tsubStep = 0;

			if (++textStep == TEXT_SEQUENCE.length){
				skipIntro();
				return;
			}
		}

		if (tsubStep == TEXT_SEQUENCE[textStep].length){
			textGroup.clear();
			tsubStep = -1;
			
			return;
		}

		if (Song.currentBeat & 1 == 0)
			createCoolText(tsubStep, TEXT_SEQUENCE[textStep].length, TEXT_SEQUENCE[textStep][tsubStep++]);
	}

	private var skippedIntro:Bool = false;
	private function skipIntro()
	if (!skippedIntro) {
		FlxG.camera.flash(FlxColor.WHITE, 4);

		textGroup.clear();
		remove(textGroup);
		add(postFlashGroup);

		enterText.animation.play('idle');
		skippedIntro = true;
	}
}
