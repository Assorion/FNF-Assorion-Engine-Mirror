package gameplay;

import flixel.FlxG;
import flixel.FlxBasic;

import states.PlayState;
import EventState;

class StageLogic {
	public static final STAGE_NAMES:Array<String> = ['demo-stage'];
	private final STAGE_CLASSES:Array<Dynamic>    = [DemoStage];

	public var playStateRef:PlayState;
	public var currentStage:Dynamic;

	public function new(name:String, playState:PlayState) {
		playStateRef = playState;
		
		for(i in 0...STAGE_NAMES.length)
			if (STAGE_NAMES[i] == name){
				currentStage = Type.createInstance(STAGE_CLASSES[i], [this]);
				return;
			}

		currentStage = Type.createInstance(STAGE_CLASSES[0], [this]);
	}

	public function add(obj:FlxBasic)
		playStateRef.add(obj);

	public function remove(obj:FlxBasic)
		playStateRef.remove(obj);

	public function addCharacters() {
		var songData = PlayState.songData;

		for(i in 0...songData.characters.length)
			playStateRef.allCharacters.push(new Character(songData.characters[i].x, songData.characters[i].y, songData.characters[i].name, i == 1));
		
		for(i in 0...songData.characters.length)
			playStateRef.add(playStateRef.allCharacters[songData.renderBackwards ? i : (songData.characters.length - 1) - i]);
	}
}

/*
	I believe this warrents a comment.

	Why were the stages coded in like this? The answer:
	Because it allows writing completely custom functions for each stage without tainting PlayState.
	E.G: If I wanted to write in the Week 3 background train, I could easily write some custom -
	custom functions, variables, etc to achieve the result, while being able to leave PlayState's code as-is.

	However since the only stage here is the default demonstration stage, it doesn't use any custom functions or
	variables, so I admit it would be very difficult to see the value in doing it this way with the example code given.
	
	I'll also reiterate: If modding this engine, remove the default stage if it isn't needed.
*/
class DemoStage {
	public function new(stage:StageLogic){
		FlxG.camera.zoom = 0.9;

		var bg:StaticSprite = new StaticSprite(-600, -200).loadGraphic(Paths.lImage('gameplay/stages/demo/stageback'));
		bg.setGraphicSize(Std.int(bg.width * 2));
		bg.updateHitbox();
		bg.scrollFactor.set(0.9, 0.9);
		stage.add(bg);

		var stageFront:StaticSprite = new StaticSprite(-650, 600).loadGraphic(Paths.lImage('gameplay/stages/demo/stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 2.2));
		stageFront.updateHitbox();
		stageFront.scrollFactor.set(0.9, 0.9);
		stage.add(stageFront);

		var curtainLeft:StaticSprite = new StaticSprite(-500, -165).loadGraphic(Paths.lImage('gameplay/stages/demo/curtainLeft'));
		curtainLeft.setGraphicSize(Std.int(curtainLeft.width * 1.8));
		curtainLeft.updateHitbox();
		curtainLeft.scrollFactor.set(1.3, 1.3);
		stage.add(curtainLeft);

		var curtainRight:StaticSprite = new StaticSprite(1406, -165).loadGraphic(Paths.lImage('gameplay/stages/demo/curtainRight'));
		curtainRight.setGraphicSize(Std.int(curtainRight.width * 1.8));
		curtainRight.updateHitbox();
		curtainRight.scrollFactor.set(1.3, 1.3);
		stage.add(curtainRight);

		stage.addCharacters();
	}
}
