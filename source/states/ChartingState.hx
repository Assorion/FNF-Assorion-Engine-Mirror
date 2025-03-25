package states;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.display.BitmapData;

import backend.Song;
import gameplay.Note;

class ChartGrid extends StaticSprite {
    public final gridColours:Array<Array<Array<Int>>> = [
        [[255, 200, 200], [255, 215, 215]], // Red
        [[200, 200, 255], [215, 215, 255]], // Blue
        [[240, 240, 200], [240, 240, 215]], // Yellow / White
        [[200, 255, 200], [215, 255, 215]], // Green
    ];

	public function new(cWidth:Int, cHeight:Int, columns:Int, rows:Int, division:Int = 4) {
		var emptySprite:BitmapData = new BitmapData(cWidth * columns, cHeight * rows, true);
		var colOffset:Int = 0;

		for(i in 0...columns)
			for(j in 0...rows){
				var grCol = CoolUtil.cfArray(gridColours[j % division][(i + colOffset) % 2]);

				emptySprite.fillRect(new Rectangle(i * cWidth, j * cHeight, cWidth, cHeight), grCol);
				colOffset++;
			}

		for(i in 1...Math.floor(columns / PlayState.KEY_COUNT))
			emptySprite.fillRect(new Rectangle((cWidth * PlayState.KEY_COUNT * i) - 2, 0, 4, cHeight * rows), FlxColor.BLACK);

		super(0,0);
		loadGraphic(emptySprite);
	}
}

class ChartingState extends EventState {
	private static inline final NOTE_SELECT_COLOUR:Int = 0xFFAAAAAA;

	public var noteList:Array<Array<Array<Note>>> = [];
	public var selectedNotes:Array<Array<Note>> = [];
	public var songData:SongData;
	public var gridSize:Int = 40;

	public var vocals:FlxSound;

	private var gridGroup:FlxSpriteGroup;
	private var noteLine:StaticSprite;
	private var grid:StaticSprite;
	private var highlightBox:StaticSprite;

	var stepTime:Float = 0;
	var curSection:Int = -1;
	var selCelX:Int = 0;
	var selCelY:Float = 0;

	override function create(){
		super.create();

		songData = PlayState.songData;
		Song.stepHooks.push(stepHit);

		vocals = new FlxSound();
		if (songData.needsVoices)
			vocals.loadEmbedded(Paths.playableSong(songData.name, true));

		vocals.play();
		vocals.pause();
		FlxG.mouse.visible = true;
		FlxG.sound.list.add(vocals);
		FlxG.sound.music.play(); // Playing and immidietly pausing is required to handle some timing weirdness.
		FlxG.sound.music.pause();
		FlxG.sound.music.time = 0;

		FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.addEventListener(MouseEvent.RIGHT_CLICK, mouseRightClick);

		for(section in 0...songData.notes.length){
			if (noteList[section] == null)
				noteList[section] = [];

			for(fNote in songData.notes[section].sectionNotes){
				var noteChain:Array<Note> = [];
				var noteData :Int = Std.int(fNote[1]);
				var susLength:Int = Std.int(fNote[2]);
				var player	 :Int = CoolUtil.intBoundTo(Std.int(fNote[3]), 0, songData.playLength - 1);
				var ntype	 :Int = Std.int(fNote[4]);

				var newNote = new Note(fNote[0], noteData, ntype, false, false);
				newNote.x = (noteData + (player * PlayState.KEY_COUNT)) * gridSize;
				newNote.y = (fNote[0] % 16) * gridSize;
				newNote.player = player;
				newNote.setGraphicSize(gridSize, gridSize);
				newNote.updateHitbox();
				noteChain.push(newNote);

				if(susLength > 1)
					for(i in 1...susLength+1){
						var susNote = new Note(fNote[0] + i, noteData, ntype, true, false);
						susNote.player = player;
						susNote.setGraphicSize(15, gridSize);
						susNote.updateHitbox();
						susNote.x = (noteData + (player * PlayState.KEY_COUNT)) * gridSize;
						susNote.x += (gridSize - 15) * 0.5;
						susNote.y = ((fNote[0] % 16) + i) * gridSize;
						noteChain.push(susNote);
					}

				noteList[section].push(noteChain);
			}
		}

		///////////////////////////////////////////

		var bg:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('ui/defaultMenuBackground'));
		bg.setGraphicSize(1280, 720);
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = FlxColor.fromRGB(20, 45, 55);
		add(bg);

		gridGroup = new FlxSpriteGroup(10, 100);
		gridGroup.y = 65;
		add(gridGroup);

		grid = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.playLength, 16, 4);
		noteLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);
		highlightBox = new StaticSprite(0, 0).makeGraphic(gridSize, gridSize, 0xFFFFFFFF);
		highlightBox.alpha = 0.75;

		gridGroup.add(grid);
		gridGroup.add(noteLine);
		gridGroup.add(highlightBox);
	}

	override function destroy(){
		super.destroy();

		FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.removeEventListener(MouseEvent.RIGHT_CLICK, mouseRightClick);
	}

	override function update(elapsed:Float){
		Song.update(FlxG.sound.music.time);
		super.update(elapsed);

		if(FlxG.sound.music.playing)
			stepTime += elapsed * 1000 * Song.division;

		var oldCurSec:Int = curSection;

		noteLine.y = ((stepTime % 16) * 0.0625 * grid.height) + gridGroup.y;
		curSection = Math.floor(stepTime * 0.0625);

		if(curSection != oldCurSec)
			sectionChange(Math.floor(Math.max(0, oldCurSec)));
	}

	public function sectionChange(oldSection:Int){
		if (noteList[curSection] == null)
			noteList[curSection] = [];

		for(i in 0...noteList[oldSection].length)
			if(noteList[oldSection][i] != null)
				for(j in 0...noteList[oldSection][i].length)
					gridGroup.remove(noteList[oldSection][i][j]);

		for(i in 0...noteList[curSection].length)
			for(j in 0...noteList[curSection][i].length)
				gridGroup.add(noteList[curSection][i][j]);
	}

	public function selectNote(newNoteChain:Array<Note>){
		for(oldSel in selectedNotes)
			for(n in oldSel)
				n.color = 0xFFFFFFFF;

		// We have to do all this madness to force Haxe into passing a reference to the note list.
		var noteListIndex:Int = 0;

		for(i in 0...noteList[curSection].length)
			if(noteList[curSection][i][0] == newNoteChain[0]){
				noteListIndex = i;
				break;
			}

		selectedNotes = [noteList[curSection][noteListIndex]];

		for(newSel in selectedNotes)
			for(n in newSel)
				n.color = NOTE_SELECT_COLOUR;
	}

	public function stepHit() 
	if(FlxG.sound.music.playing)
		stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);

	public function mouseScroll(ev:MouseEvent){
		FlxG.sound.music.pause();
		FlxG.sound.music.time = Math.max((Song.currentStep - (ev.delta - 1)) * Song.stepCrochet, 0);
		Song.update(FlxG.sound.music.time);
		stepTime = Math.max(Song.millisecond * Song.division, 0);
	}
	
	public function mouseMove(ev:MouseEvent){
		selCelX = CoolUtil.intBoundTo(Math.floor((FlxG.mouse.x - gridGroup.x) / gridSize), 0, (songData.playLength * PlayState.KEY_COUNT) - 1);
		selCelY = CoolUtil.boundTo(Math.floor((FlxG.mouse.y - gridGroup.y) / gridSize), 0, 15);

		highlightBox.x = (selCelX * gridSize) + gridGroup.x;
		highlightBox.y = (selCelY * gridSize) + gridGroup.y;
	}

	public function mouseDown(ev:MouseEvent){
		if(FlxG.keys.pressed.CONTROL){
			for(note in noteList[curSection])
				if (selCelX % PlayState.KEY_COUNT == note[0].noteData && Math.abs(selCelY - (note[0].strumTime % 16)) < 0.025 
					&& Math.floor(selCelX / PlayState.KEY_COUNT) == note[0].player){
					selectNote(note);
					return;
				}

			return;
		}

		var newNote = new Note(selCelY + (curSection * 16), selCelX % PlayState.KEY_COUNT, 0, false, false);
		newNote.player = Math.floor(selCelX / PlayState.KEY_COUNT);
		newNote.x = (newNote.noteData + (newNote.player * PlayState.KEY_COUNT)) * gridSize;
		newNote.y = (newNote.strumTime % 16) * gridSize;
		newNote.setGraphicSize(gridSize, gridSize);
		newNote.updateHitbox();

		noteList[curSection].push([newNote]);
		selectNote([newNote]);
		gridGroup.add(newNote);
	}

	public function mouseRightClick(ev:MouseEvent){}

	override function keyHit(ev:KeyboardEvent){
		if(FlxG.keys.pressed.SHIFT){
			ev.keyCode.bindFunctions([
				[Binds.ui_down, function(){
					for(n in selectedNotes){
						var newSusNote = new Note(n[0].strumTime + n.length, n[0].noteData, 0, true, false);
						newSusNote.setGraphicSize(15, gridSize);
						newSusNote.updateHitbox();
						newSusNote.player = n[0].player;
						newSusNote.x = (newSusNote.noteData + (newSusNote.player * PlayState.KEY_COUNT)) * gridSize;
						newSusNote.x += (gridSize - 15) * 0.5;
						newSusNote.y = (newSusNote.strumTime % 16) * gridSize;
						newSusNote.color = NOTE_SELECT_COLOUR;

						n.push(newSusNote);
						gridGroup.add(newSusNote);
					}
				}],
				[Binds.ui_up, function(){
					for(n in selectedNotes){
						if(n.length <= 1)
							continue;

						gridGroup.remove(n.pop());
					}
				}],
				[Binds.ui_back, function(){
					stepTime = 0;
					FlxG.sound.music.time = 0;
				}]
			]);

			return;
		}

		ev.keyCode.bindFunctions([
			[Binds.ui_back, function(){
				FlxG.mouse.visible = false;
				EventState.changeState(new PlayState());
			}],
			[Binds.ui_accept, function(){
				FlxG.sound.music.playing ? FlxG.sound.music.pause() : FlxG.sound.music.play();
				
				if(songData.needsVoices){
					vocals.playing ? vocals.pause() : vocals.play();
					vocals.time = FlxG.sound.music.time;
				}
			}],
			[Binds.ui_down, function(){
				FlxG.sound.music.pause();
				vocals.pause();

				stepTime = (curSection + 1) * 16;
				FlxG.sound.music.time = stepTime * Song.stepCrochet;
			}],
			[Binds.ui_up, function(){
				FlxG.sound.music.pause();
				vocals.pause();

				stepTime = Math.max((curSection - 1) * 16, 0);
				FlxG.sound.music.time = stepTime * Song.stepCrochet;
			}]
		]);
	}
}
