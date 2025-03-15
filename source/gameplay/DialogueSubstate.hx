package gameplay;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import haxe.Json;

import states.PlayState;

// If you need more advanced functionality, then I suggest adding stuff to the typedefs.
typedef DialogueCharacter = {
	var portrait:String;
	var alpha:Float;
	var centerOffsetX:Float;
}

typedef Slide = {
	var text:String;
	var characters:Array<DialogueCharacter>;
	var speed:Float;
} 

#if !debug @:noDebug #end
class DialogueSubstate extends EventSubstate {
	public var playState:PlayState;

	private var characterSprites:Array<StaticSprite> = [];
	private var currentSlide:Int = -1;
	private var totalSlides:Array<Slide> = [];

	public var graySprite:StaticSprite; 
	public var dialogueBGSprite:StaticSprite;
	public var characterSpriteGroup:FlxTypedGroup<StaticSprite>;
	public var dialogueText:FormattedText;

	public function new(pState:PlayState, camera:FlxCamera, dialogueJson:String){
		super();

		playState = pState;
		
		graySprite = new StaticSprite(0,0).makeGraphic(camera.width, camera.height, FlxColor.GRAY);
		graySprite.alpha = 0;
		add(graySprite);

		cameras = [camera];

		characterSpriteGroup = new FlxTypedGroup<StaticSprite>();
		add(characterSpriteGroup);

		dialogueBGSprite = new StaticSprite(0,0).loadGraphic(Paths.lImage('gameplay/dialogueBox'));
		dialogueBGSprite.screenCenter();
		dialogueBGSprite.y += 200;
		dialogueBGSprite.alpha = 0;
		add(dialogueBGSprite);
		
		dialogueText = new FormattedText(dialogueBGSprite.x + 10, dialogueBGSprite.y + 10, 900, '', null, 35, 0xFF000000);
		add(dialogueText);

		FlxTween.tween( graySprite, {alpha: 0.7}, 2);
		postEvent(2, function(){		
			beginDialogue(dialogueJson);	
		});				
	}

	public function beginDialogue(dialogueJson:String){
		FlxTween.tween( dialogueBGSprite, {alpha: 1}, 0.3, {onComplete: function(t:FlxTween){
			totalSlides = cast Json.parse(dialogueJson).slides;
			changeSlide(0, false);	
		}});
	}

	public function changeSlide(slideNumber:Int, playSound:Bool){
		currentSlide = slideNumber;
		if(playSound)
			FlxG.sound.play(Paths.lSound('ui/clickText'));
		
		while(events.length > 0)
			events.pop();

		dialogueText.text = '';

		// Character stuff.
		var charAmount = totalSlides[currentSlide].characters.length;

		while(characterSprites.length > charAmount){
			var char = characterSprites.pop();
			
			char.destroy();
			characterSpriteGroup.remove(char);
		}

		for(i in 0...charAmount){
			if(characterSprites[i] == null){
				characterSprites[i] = new StaticSprite(0,0);
				characterSprites[i].scale.set(0.8, 0.8);
				characterSpriteGroup.add(characterSprites[i]);
			}

			characterSprites[i].loadGraphic(Paths.lImage('gameplay/characters/${totalSlides[currentSlide].characters[i].portrait}'));
			characterSprites[i].screenCenter();
			characterSprites[i].y -= 20;
			characterSprites[i].x += totalSlides[currentSlide].characters[i].centerOffsetX;
			characterSprites[i].alpha = totalSlides[currentSlide].characters[i].alpha;
		}

		// We use Assorion delayed event system to generate the text
		var splitCharacters:Array<String> = totalSlides[currentSlide].text.split('');
		for(i in 0...splitCharacters.length)			
			postEvent(totalSlides[currentSlide].speed * (i + 1), function(){
				dialogueText.text += splitCharacters[i];
				FlxG.sound.play(Paths.lSound('ui/pixelText'));
			}); 
		
	}

	var leaving:Bool = false;
	override public function keyHit(ev:KeyboardEvent){
		super.keyHit(ev);

		if(!ev.keyCode.check(Binds.ui_accept) || leaving || currentSlide < 0)
			return;

		if(++currentSlide == totalSlides.length){
			leaving = true;
			
			for(i in 0...characterSprites.length)
				FlxTween.tween(characterSprites[i], {alpha: 0}, 0.45);
	
			FlxTween.tween( dialogueBGSprite, {alpha: 0}, 0.45);
			FlxTween.tween( dialogueText, {alpha: 0}, 0.45);
			FlxTween.tween( graySprite, {alpha: 0}, 0.46, {onComplete: function(t:FlxTween){
				close();

				playState.paused = false;
				playState.startCountdown();
			}});	
		
			return;
		}
		
		// The ++currentSlide in the prior if statement will increase the value by 1
		changeSlide(currentSlide, true);
	}	
}
