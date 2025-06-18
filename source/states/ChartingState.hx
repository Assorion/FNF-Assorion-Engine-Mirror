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
    public final GRID_COLOURS:Array<Array<Array<Int>>> = [
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
				var grCol = GRID_COLOURS[j % division][(i + colOffset) % 2];

				emptySprite.fillRect(new Rectangle(i * cWidth, j * cHeight, cWidth, cHeight), FlxColor.fromRGB(grCol[0], grCol[1], grCol[2]));
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
	public var curNoteType:Int = 0;
	public var songData:SongData;
	public var gridSize:Int = 40;

	public var vocals:FlxSound;

	private var gridGroup:FlxSpriteGroup;
	private var noteLine:StaticSprite;
	private var grid:StaticSprite;
	private var highlightBox:StaticSprite;
	private var selectBox:StaticSprite;

	var stepTime:Float = 0;
	var curSection:Int = -1;
	var selCelX:Int = 0;
	var selCelY:Float = 0;

	public function generateNote(strumTime:Float, noteData:Int, sustainNote:Bool, player:Int, section:Int):Note {
		var newNote = new Note(strumTime, noteData, curNoteType, sustainNote, false);
		newNote.player = player;
		newNote.setGraphicSize(sustainNote ? 15 : gridSize, gridSize);
		newNote.updateHitbox();
		newNote.x = (noteData + (player * PlayState.KEY_COUNT)) * gridSize;
		newNote.x += sustainNote ? (gridSize - 15) * 0.5 : 0;
		newNote.y = (strumTime - (section * 16)) * gridSize;

		return newNote;
	}

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
		FlxG.stage.addEventListener(MouseEvent.MOUSE_UP,   mouseUp);
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

				curNoteType = ntype;
				noteChain.push(generateNote(fNote[0], noteData, false, player, section));

				if (susLength > 1)
					for(i in 1...susLength+1)
						noteChain.push(generateNote(fNote[0] + i, noteData, true, player, section));

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
		gridGroup.y = 70;
		add(gridGroup);

		grid = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.playLength, 16, 4);
		noteLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);
		highlightBox = new StaticSprite(0, 0).makeGraphic(gridSize, gridSize, 0xFFFFFFFF);
		highlightBox.alpha = 0.75;

		selectBox = new StaticSprite(0, 0).makeGraphic(1, 1, NOTE_SELECT_COLOUR);
		selectBox.alpha = 0;
		selectBox.origin.set(0, 0);
		add(selectBox);

		gridGroup.add(grid);
		gridGroup.add(noteLine);
		gridGroup.add(highlightBox);
	}

	override function destroy(){
		super.destroy();

		FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP,    mouseUp);
		FlxG.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.removeEventListener(MouseEvent.RIGHT_CLICK, mouseRightClick);
	}

	override function update(elapsed:Float){
		Song.update(FlxG.sound.music.time);
		super.update(elapsed);

		if (FlxG.sound.music.playing)
			stepTime += elapsed * 1000 * Song.division;

		var oldCurSec:Int = curSection;

		noteLine.y = ((stepTime % 16) * 0.0625 * grid.height) + gridGroup.y;
		curSection = Math.floor(stepTime * 0.0625);

		if (curSection != oldCurSec)
			sectionChange(Math.floor(Math.max(0, oldCurSec)));
	}

	public function sectionChange(oldSection:Int){
		if (noteList[curSection] == null)
			noteList[curSection] = [];

		for(i in 0...noteList[oldSection].length)
			if (noteList[oldSection][i] != null)
				for(j in 0...noteList[oldSection][i].length)
					gridGroup.remove(noteList[oldSection][i][j]);

		for(i in 0...noteList[curSection].length)
			for(j in 0...noteList[curSection][i].length)
				gridGroup.add(noteList[curSection][i][j]);
	}

	// You have to be EXTREMELY careful and make sure that you call this function with a reference within noteList.
	public function selectNote(newNoteChain:Array<Note>){
		for(oldSel in selectedNotes)
			for(n in oldSel)
				n.color = 0xFFFFFFFF;

		selectedNotes = [newNoteChain];

		for(newSel in selectedNotes)
			for(n in newSel)
				n.color = NOTE_SELECT_COLOUR;
	}

	public function regenerateSelection(){
		for(n in selectedNotes){
			var newNoteChain:Array<Note> = [generateNote(n[0].strumTime, n[0].noteData, false, n[0].player, Math.floor(n[0].strumTime / 16))];

			for(i in 1...n.length)
				newNoteChain.push(generateNote(n[0].strumTime + i, n[0].noteData, true, n[0].player, Math.floor(n[0].strumTime / 16)));
			
			for(i in 0...n.length){
				if (Math.floor(newNoteChain[0].strumTime / 16) == curSection)
					gridGroup.add(newNoteChain[i]);

				gridGroup.remove(n[i]);
				n[i] = newNoteChain[i];
				n[i].color = NOTE_SELECT_COLOUR;
			}
		}
	}

	public function stepHit() 
	if (FlxG.sound.music.playing)
		stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);

	public function mouseScroll(ev:MouseEvent) {
		FlxG.sound.music.pause();
		FlxG.sound.music.time = Math.max((Song.currentStep - (ev.delta - 1)) * Song.stepCrochet, 0);
		Song.update(FlxG.sound.music.time);
		stepTime = Math.max(Song.millisecond * Song.division, 0);
	}
	
	public function mouseUp(ev:MouseEvent) {
		selectBox.alpha = 0;
		selectBox.scale.set(0,0);
	}

	public function mouseMove(ev:MouseEvent) {
		selCelX = CoolUtil.intBoundTo(Math.floor((FlxG.mouse.x - gridGroup.x) / gridSize), 0, (songData.playLength * PlayState.KEY_COUNT) - 1);
		selCelY = CoolUtil.boundTo(Math.floor((FlxG.mouse.y - gridGroup.y) / gridSize), 0, 15);
		highlightBox.x = (selCelX * gridSize) + gridGroup.x;
		highlightBox.y = (selCelY * gridSize) + gridGroup.y;

		if (!FlxG.mouse.pressed || !FlxG.keys.pressed.CONTROL)
			return;
			
		selectBox.scale.x = FlxG.mouse.x - selectBox.x;
		selectBox.scale.y = FlxG.mouse.y - selectBox.y;
		var fakeX = selectBox.x + (selectBox.scale.x < 0 ? selectBox.scale.x : 0);
		var fakeY = selectBox.y + (selectBox.scale.y < 0 ? selectBox.scale.y : 0);
		
		selectNote([]);
		selectedNotes = [];

		for(i in 0...noteList[curSection].length){
			var n = noteList[curSection][i][0];
			if (n.x < fakeX || n.x + gridSize > fakeX + Math.abs(selectBox.scale.x) ||
				n.y < fakeY || n.y + gridSize > fakeY + Math.abs(selectBox.scale.y))
				continue;

			selectedNotes.push(noteList[curSection][i]);

			for(selNote in noteList[curSection][i])
				selNote.color = NOTE_SELECT_COLOUR;
		}
	}

	public function mouseDown(ev:MouseEvent) {
		if (FlxG.keys.pressed.CONTROL){
			selectBox.alpha = 0.5;
			selectBox.x = FlxG.mouse.x;
			selectBox.y = FlxG.mouse.y;
			selectBox.scale.set(0,0);
			return;
		}

		for(i in 0...noteList[curSection].length){
			var note = noteList[curSection][i];

			// Will need to be reworked when adding different zoom levels
			if (selCelX % PlayState.KEY_COUNT != note[0].noteData || Math.abs(selCelY - (note[0].strumTime % 16)) >= 0.025 ||
				Math.floor(selCelX / PlayState.KEY_COUNT) != note[0].player)
				continue;

			for(n in note)
				gridGroup.remove(n);

			noteList[curSection].splice(i, 1);
			return;
		}

		var newNote = generateNote(selCelY + (curSection * 16), selCelX % PlayState.KEY_COUNT, false, Math.floor(selCelX / PlayState.KEY_COUNT), curSection);

		var newNoteIndex = noteList[curSection].push([newNote]) - 1;
		selectNote(noteList[curSection][newNoteIndex]);
		gridGroup.add(newNote);
	}

	public function mouseRightClick(ev:MouseEvent){}

	override function keyHit(ev:KeyboardEvent){
		if (FlxG.keys.pressed.SHIFT){
			ev.keyCode.bindFunctions([
				[Binds.ui_down, function(){
					for(n in selectedNotes){
						var newSusNote = generateNote(n[0].strumTime + n.length, n[0].noteData, true, n[0].player, Math.floor(n[0].strumTime / 16));
						newSusNote.color = NOTE_SELECT_COLOUR;

						if (Math.floor(n[0].strumTime / 16) == curSection)
							gridGroup.add(newSusNote);
						
						n.push(newSusNote);
					}
				}],
				[Binds.ui_up, function(){
					for(n in selectedNotes)
						if (n.length > 1)
							gridGroup.remove(n.pop());
				}],
				[Binds.ui_back, function(){
					stepTime = 0;
					FlxG.sound.music.time = 0;
				}],
				[Binds.ui_left, function(){
					curNoteType = CoolUtil.intBoundTo(curNoteType + 1, 0, Note.NOTE_TYPES.length - 1);
					regenerateSelection();
				}],
				[Binds.ui_right, function(){
					curNoteType = CoolUtil.intBoundTo(curNoteType - 1, 0, Note.NOTE_TYPES.length - 1);
					regenerateSelection();
				}],
			]);

			return;
		}

		if (FlxG.keys.pressed.CONTROL){
			ev.keyCode.bindFunctions([
				[Binds.ui_left, function(){
					for(n in selectedNotes){
						n[0].noteData = (n[0].noteData - 1) + (n[0].player * PlayState.KEY_COUNT);
						n[0].player = CoolUtil.intCircularModulo(Math.floor(n[0].noteData / PlayState.KEY_COUNT), songData.playLength);
						n[0].noteData = CoolUtil.intCircularModulo(n[0].noteData, PlayState.KEY_COUNT);
					}
					
					regenerateSelection();
				}],
				[Binds.ui_right, function(){
					for(n in selectedNotes){
						n[0].noteData = (n[0].noteData + 1) + (n[0].player * PlayState.KEY_COUNT);
						n[0].player = CoolUtil.intCircularModulo(Math.floor(n[0].noteData / PlayState.KEY_COUNT), songData.playLength);
						n[0].noteData = CoolUtil.intCircularModulo(n[0].noteData, PlayState.KEY_COUNT);
					}
					
					regenerateSelection();
				}],
				[Binds.ui_up, function(){
					for(n in selectedNotes){
						var sectionOrigin:Int = Math.floor(n[0].strumTime / 16) << 4;
						n[0].strumTime = CoolUtil.circularModulo(n[0].strumTime - 1, 16) + sectionOrigin;
					}

					regenerateSelection();
				}],
				[Binds.ui_down, function(){
					for(n in selectedNotes){
						var sectionOrigin:Int = Math.floor(n[0].strumTime / 16) << 4;
						n[0].strumTime = CoolUtil.circularModulo(n[0].strumTime + 1, 16) + sectionOrigin;
					}

					regenerateSelection();
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
				
				if (songData.needsVoices){
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
