package gameplay;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;

import backend.Song;
import states.PlayState;

class ComboDisplay extends FlxSpriteGroup {
	private var comboNumbers:Array<StaticSprite> = [];
	private var ratingSprite:StaticSprite;
	private var offsetX:Int;
	private var offsetY:Int;

	private var previousRating:RatingData;
	private var scoreTweens:Array<FlxTween> = [];

	public function new(possibleScores:Array<RatingData>, oX:Int, oY:Int){
		super();

		offsetX = oX;
		offsetY = oY;

		for(i in 0...possibleScores.length)
			FlxGraphic.fromAssetKey(Paths.lImage('gameplay/${possibleScores[i].asset}'), false, null, true).persist = true;

		for(i in 0...3){
			var sRef = comboNumbers[i] = new StaticSprite(0,0);
			sRef.frames = Paths.lSparrow('gameplay/comboNumbers');
			for(i in 0...10) {
				sRef.animation.addByPrefix('$i', '${i}num', 1, false);
				sRef.animation.play('$i');
			}

			sRef.screenCenter(X);
			sRef.centerOrigin();
			sRef.x += ((i - 1) * 60) + offsetX;
			sRef.scale.set(0.6, 0.6);
			sRef.alpha = 0;
			add(sRef);
		}

		ratingSprite = new StaticSprite(0,0);
		ratingSprite.scale.set(0.7, 0.7);
		ratingSprite.alpha = 0;
		add(ratingSprite);
	}

	private function createTween(spr:StaticSprite):FlxTween {
		spr.alpha = 1;
		return FlxTween.tween(spr, {y: spr.y + 10, alpha: 0}, Song.stepCrochet * 0.003, {ease: FlxEase.cubeInOut, startDelay: Song.stepCrochet * 0.0005});
	}

	public function displayScore(rating:RatingData, combo:Int){
		if (scoreTweens[0] != null)
			for(i in 0...4) scoreTweens[i].cancel();

		if (previousRating != rating){
			ratingSprite.loadGraphic(Paths.lImage('gameplay/' + rating.asset));
			ratingSprite.centerOrigin();
			previousRating = rating;
		}

		ratingSprite.screenCenter();
		ratingSprite.x += offsetX;
		ratingSprite.y += offsetY;

		var scoreCharacters:Array<String> = Std.string(combo).split('');
		for(i in 0...3){
			var sRef = comboNumbers[i];
			sRef.animation.play((3 - scoreCharacters.length <= i) ? scoreCharacters[i + (scoreCharacters.length - 3)] : '0');
			sRef.screenCenter(Y);
			sRef.y += 120 + offsetY;

			scoreTweens[i+1] = createTween(sRef);
		}

		scoreTweens[0] = createTween(ratingSprite);
	}
}
