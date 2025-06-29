package states;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.addons.ui.*;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.display.BitmapData;
import haxe.Json;
import sys.io.File;

import backend.Song;
import gameplay.Note;
import gameplay.StageLogic;

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

#if !debug @:noDebug #end
class ChartingState extends EventState {
	private static inline final NOTE_SELECT_COLOUR:Int = 0xFF9999CC; // RGB: 153 153 204
	private static inline final GRID_SIZE:Int = 40;
	private final UI_TABS:Array<{name:String, label:String}> = [{
			name: '1properties', // The number is required, otherwise Flixel will sort tabs alphabetically.
			label: 'Properties'
		}, {
			name: '2section',
			label: 'Section'
		}, {
			name: '3players',
			label: 'Players'
		}, {
			name: '4help',
			label: 'Help'
		}
	];

	public var vocals:FlxSound;
	public var songData:SongData;
	public var curNoteType:Int;
	public var selectedNotes:Map<Int, Array<NoteData>> = new Map<Int, Array<NoteData>>();
	
	private var grid:StaticSprite;
	private var gridGroup:FlxSpriteGroup;
	private var noteGroup:FlxSpriteGroup;
	private var highlightBox:StaticSprite;
	private var selectionBox:StaticSprite;

	private var oldMuteKeys:Array<FlxKey> = [];
	private var mainUIBox:FlxUITabMenu;
	private var warningText:FormattedText;
	private var sectionText:FormattedText;
	private var noteTypeText:FormattedText;
	private var snapText:FormattedText;
	private var typing:Bool;

	var stepTime:Float = 0;
	var curSection:Int = 0;
	var timingLine:StaticSprite;
	var gridSelectX:Int;
	var gridSelectY:Float;

	var snaps:Array<Float> = [1/2, 3/4, 1, 3/2, 2, 4]; // 0.5, 0.75, 1, 1.5, 2, 4
	var curZoom:Int = 2;

	override function create(){
		super.create();

		songData = PlayState.songData;
		Song.stepHooks.push(stepHit);

		vocals = new FlxSound();
		if (songData.hasVoices)
			vocals.loadEmbedded(Paths.playableSong(songData.name, true));

		vocals.play();
		vocals.pause();
		oldMuteKeys = FlxG.sound.muteKeys;
		FlxG.mouse.visible = true;
		FlxG.sound.muteKeys = [];
		FlxG.sound.list.add(vocals);
		FlxG.sound.music.play(); // Playing and immidietly pausing is required to handle some timing weirdness.
		FlxG.sound.music.pause();
		FlxG.sound.music.time = vocals.time = 0;

		FlxG.stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
		FlxG.stage.addEventListener(MouseEvent.MOUSE_UP,    mouseUp);
		FlxG.stage.addEventListener(MouseEvent.RIGHT_CLICK, mouseRight);

		var bg:StaticSprite = new StaticSprite().loadGraphic(Paths.lImage('ui/defaultMenuBackground'));
		bg.setGraphicSize(1280, 720);
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = FlxColor.fromRGB(20, 45, 55);
		add(bg);

		gridGroup = new FlxSpriteGroup(15, 70);
		noteGroup = new FlxSpriteGroup(15, 70);
		add(gridGroup);
		add(noteGroup);

		highlightBox = new StaticSprite(0, 0).makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);

		selectionBox = new StaticSprite(0, 0).makeGraphic(1, 1, NOTE_SELECT_COLOUR);
		selectionBox.alpha = 0;
		selectionBox.origin.set(0, 0);
		add(selectionBox);
		
		// UI Stuff
		mainUIBox = new FlxUITabMenu(null, null, UI_TABS, null, true);
		mainUIBox.resize(350, 500);
		mainUIBox.screenCenter(Y);
		
		warningText  = new FormattedText(0, 0, 0, '', null, 16, 0xFFFFFFFF, LEFT);
		sectionText  = new FormattedText(0, 0, 0, '', null, 16, 0xFFFFFFFF, LEFT);
		noteTypeText = new FormattedText(0, 0, 0, 'Note type: 0 (${Note.NOTE_TYPES[0].assets})', null, 16, 0xFFFFFFFF, LEFT);
		snapText     = new FormattedText(0, 0, 0, 'Snap: 1', null, 16, 0xFFFFFFFF, LEFT);
		warningText.y  = mainUIBox.y - 20;
		sectionText.y  = mainUIBox.y + mainUIBox.height + 5;
		noteTypeText.y = mainUIBox.y + mainUIBox.height + 25;
		snapText.y     = mainUIBox.y + mainUIBox.height + 45;
		add(mainUIBox);
		add(warningText);
		add(sectionText);
		add(noteTypeText);
		add(snapText);

		propertiesUI();
		sectionUI();
		/*playersUI();
		helpUI();*/

		reloadGrid();
		reloadNotes();
	}

	override function update(elapsed:Float){
		Song.update(FlxG.sound.music.time);
		super.update(elapsed);

		if (FlxG.sound.music.playing)
			stepTime += elapsed * 1000 * Song.division;

		var oldSection = curSection;
		timingLine.y = ((stepTime % 16) * 0.0625 * grid.height) + gridGroup.y;
		curSection = Math.floor(stepTime * 0.0625);

		if (oldSection != curSection)
			reloadNotes();

		for(i in 0...noteGroup.length)
			noteGroup.members[i].alpha = stepTime % 16 >= cast(noteGroup.members[i], Note).strumTime ? 0.75 : 1;
	}

	public function stepHit()
	if (FlxG.sound.music.playing)
		stepTime = (Song.millisecond * Song.division * 0.25) + (stepTime * 0.75);

	private inline function noteSelected(noteData:NoteData, sec:Int):Bool 
		return selectedNotes.exists(sec) && (selectedNotes.get(sec)).contains(noteData);

	private inline function sectionNullCheck(sec:Int):Bool {
		var wasNull:Bool = songData.sections[sec] == null;

		if (wasNull)
			songData.sections[sec] = {
				cameraFacing: 0,
				notes: []
			};

		return wasNull;
	}

	public function reloadGrid() {
		gridGroup.clear();

		grid = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.characterCharts, 16, 4);
		timingLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);
		mainUIBox.x = gridGroup.x + grid.x + grid.width + 10;
		warningText.x = sectionText.x = noteTypeText.x = snapText.x = mainUIBox.x;

		gridGroup.add(grid);
		gridGroup.add(timingLine);
		gridGroup.add(highlightBox);
	}

	public function reloadNotes() {
		sectionNullCheck(curSection);
		sectionText.text = 'Section: $curSection';
		sectionCameraStepper.value = songData.sections[curSection].cameraFacing;
		noteGroup.clear();

		for(i in 0...songData.sections[curSection].notes.length){
			var noteData = songData.sections[curSection].notes[i];

			var newNote = new Note(noteData.strumTime, noteData.column, noteData.type, false, false);
			newNote.player = noteData.player;
			newNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
			newNote.updateHitbox();
			newNote.x = (noteData.column + (noteData.player * PlayState.KEY_COUNT)) * GRID_SIZE;
			newNote.y = noteData.strumTime * GRID_SIZE;

			if (noteSelected(noteData, curSection))
				newNote.color = NOTE_SELECT_COLOUR;

			for(j in 1...noteData.length + 1){
				var susNote = new Note(noteData.strumTime + j, noteData.column, noteData.type, true, j == noteData.length);
				susNote.player = noteData.player;
				susNote.setGraphicSize(Math.floor(GRID_SIZE * 0.4), GRID_SIZE);
				susNote.updateHitbox();
				susNote.x = newNote.x + (GRID_SIZE * 0.3);
				susNote.y = susNote.strumTime * GRID_SIZE;
				susNote.flipY = false;
				susNote.color = newNote.color;

				noteGroup.add(susNote);
			}

			noteGroup.add(newNote);
		}
	}

	public function correctSection(sec:Int):Bool {
		var dirty:Bool = false;
		var i:Int = -1;

		while(++i < songData.sections[sec].notes.length){
			var tmpNote = songData.sections[sec].notes[i];
			var secOffset = Math.floor(tmpNote.strumTime / 16);

			tmpNote.player = CoolUtil.intCircularModulo(tmpNote.player + Math.floor(tmpNote.column / PlayState.KEY_COUNT), songData.characterCharts);
			tmpNote.column = CoolUtil.intCircularModulo(tmpNote.column, PlayState.KEY_COUNT);
			tmpNote.strumTime = CoolUtil.circularModulo(tmpNote.strumTime, 16);

			if (secOffset == 0 || (secOffset < 0 && sec == 0))
				continue;

			dirty = true;
			sectionNullCheck(sec + secOffset);
			songData.sections[sec].notes.splice(i--, 1);
			songData.sections[sec + secOffset].notes.push(tmpNote);

			if (noteSelected(tmpNote, sec)){
				if (selectedNotes.get(sec + secOffset) == null && songData.sections[sec + secOffset] != null)
					selectedNotes.set(sec + secOffset, []);

				(selectedNotes.get(sec)).remove(tmpNote);
				(selectedNotes.get(sec + secOffset)).push(tmpNote); 
			}
		}

		return dirty;
	}
	
	public function mouseScroll(ev:MouseEvent) {
		vocals.pause();
		FlxG.sound.music.pause();
		FlxG.sound.music.time = Math.max((Song.currentStep - (ev.delta - (Settings.audio_offset > 0 ? 1 : 0))) * Song.stepCrochet, 0);

		Song.update(FlxG.sound.music.time);
		stepTime = Math.max(Song.millisecond * Song.division, 0);
	}

	public function mouseMove(ev:MouseEvent) {
		gridSelectX = CoolUtil.intBoundTo(Math.floor((FlxG.mouse.x - gridGroup.x) / GRID_SIZE), 0, (songData.characterCharts * PlayState.KEY_COUNT) - 1);
		gridSelectY = CoolUtil.boundTo(Math.floor(((FlxG.mouse.y - gridGroup.y) * snaps[curZoom]) / GRID_SIZE) / snaps[curZoom], 0, 15);
		highlightBox.x = (gridSelectX * GRID_SIZE) + gridGroup.x;
		highlightBox.y = (gridSelectY * GRID_SIZE) + gridGroup.y;
		highlightBox.alpha = FlxG.mouse.x > grid.x + grid.width ? 0 : 0.75;

		if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL){
			selectionBox.scale.x = FlxG.mouse.x - selectionBox.x;
			selectionBox.scale.y = FlxG.mouse.y - selectionBox.y;
		}
	}
	
	public function mouseUp(ev:MouseEvent)
	if (FlxG.keys.pressed.CONTROL) {
		var selBoxX = ((selectionBox.x + (selectionBox.scale.x < 0 ? selectionBox.scale.x : 0)) - gridGroup.x) / GRID_SIZE;
		var selBoxY = ((selectionBox.y + (selectionBox.scale.y < 0 ? selectionBox.scale.y : 0)) - gridGroup.y) / GRID_SIZE;
		var selBoxWidth  = Math.abs(selectionBox.scale.x) / GRID_SIZE;
		var selBoxHeight = Math.abs(selectionBox.scale.y) / GRID_SIZE;

		selectionBox.alpha = 0;
		selectionBox.scale.set(0, 0);
		selectedNotes.clear();
		selectedNotes.set(curSection, []);

		for(i in 0...songData.sections[curSection].notes.length){
			var tmpNote = songData.sections[curSection].notes[i];

			if (tmpNote.column + (PlayState.KEY_COUNT * tmpNote.player) >= selBoxX
			 && tmpNote.column + (PlayState.KEY_COUNT * tmpNote.player) + 1 < selBoxX + selBoxWidth
			 && tmpNote.strumTime + 1 < selBoxY + selBoxHeight
			 && tmpNote.strumTime >= selBoxY)
				selectedNotes.get(curSection).push(tmpNote);
		}

		reloadNotes();
	}

	public function mouseDown(ev:MouseEvent) {
		if (highlightBox.alpha == 0)
			return;

		if (FlxG.keys.pressed.CONTROL){
			selectionBox.alpha = 0.75;
			selectionBox.x = FlxG.mouse.x;
			selectionBox.y = FlxG.mouse.y;
			selectionBox.scale.set(0, 0);
			return;
		}

		for(i in 0...songData.sections[curSection].notes.length){
			var tmpNote = songData.sections[curSection].notes[i];
			
			if (Math.floor(tmpNote.strumTime * 10) == Math.floor(gridSelectY * 10)
			 && tmpNote.player == Math.floor(gridSelectX / PlayState.KEY_COUNT)
			 && tmpNote.column == gridSelectX % PlayState.KEY_COUNT){
				songData.sections[curSection].notes.splice(i, 1);
				reloadNotes();
				return;
			}
		}

		var createdNote:NoteData = {
			strumTime: gridSelectY,
			column: gridSelectX % PlayState.KEY_COUNT,
			length: 0,
			player: Math.floor(gridSelectX / PlayState.KEY_COUNT),
			type: curNoteType
		};

		songData.sections[curSection].notes.push(createdNote);
		selectedNotes.clear();
		selectedNotes.set(curSection, [createdNote]);
		reloadNotes();
	}
	
	public function mouseRight(ev:MouseEvent) {
		for(k in selectedNotes.keys())
			while((selectedNotes.get(k)).length > 0)
				songData.sections[k].notes.remove(selectedNotes.get(k).pop());

		reloadNotes();
	}

	inline function shiftNotes(strumAdd:Int, columnAdd:Int){
		for(k in selectedNotes.keys())
			for(i in 0...selectedNotes.get(k).length){
				selectedNotes.get(k)[i].strumTime += strumAdd;
				selectedNotes.get(k)[i].column    += columnAdd;
			}

		for(k in selectedNotes.keys())
			correctSection(k);

		reloadNotes();
	}

	inline function jumpToSection(newStepTime:Float){
		FlxG.sound.music.pause();
		vocals.pause();
		stepTime = Math.max(newStepTime, 0);
		FlxG.sound.music.time = stepTime * Song.stepCrochet;
	}

	override function keyHit(ev:KeyboardEvent) {
		if (typing || ev.keyCode.check([FlxKey.BACKSPACE])) // Ignore backspace because of Flixel UI!
			return;

		if (FlxG.keys.pressed.SHIFT){
			ev.keyCode.bindFunctions([
				[Binds.ui_down, function(){
					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].length++;
					
					reloadNotes();
				}],
				[Binds.ui_up, function(){
					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							if (selectedNotes.get(k)[i].length > 0)
								selectedNotes.get(k)[i].length--;
					
					reloadNotes();
				}],
				[Binds.ui_left, function(){
					curNoteType = CoolUtil.intCircularModulo(--curNoteType, Note.NOTE_TYPES.length);
					noteTypeText.text = 'Note type: $curNoteType (${Note.NOTE_TYPES[curNoteType].assets})';

					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].type = curNoteType;
				
					reloadNotes();
				}],
				[Binds.ui_right, function(){
					curNoteType = CoolUtil.intCircularModulo(++curNoteType, Note.NOTE_TYPES.length);
					noteTypeText.text = 'Note type: $curNoteType (${Note.NOTE_TYPES[curNoteType].assets})';

					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].type = curNoteType;
					
					reloadNotes();
				}],
				[Binds.ui_back, function(){
					jumpToSection(0);
				}]
			]);
			return;
		}

		if (FlxG.keys.pressed.CONTROL){
			ev.keyCode.bindFunctions([
				[[FlxKey.C], function(){
					var newSelection:Map<Int, Array<NoteData>> = new Map<Int, Array<NoteData>>();

					for(k in selectedNotes.keys()){
						newSelection.set(k, []);

						for(i in 0...selectedNotes.get(k).length){
							var tmpNote:NoteData = selectedNotes.get(k)[i];
							var newNoteData:NoteData = {
								strumTime: tmpNote.strumTime,
								column:    tmpNote.column,
								length:    tmpNote.length,
								player:    tmpNote.player,
								type:      tmpNote.type
							}

							songData.sections[k].notes.push(newNoteData);
							newSelection.get(k).push(newNoteData);
						}
					}

					selectedNotes = newSelection;
				}],
				[[FlxKey.V], function(){
					for(k in selectedNotes.keys())
						for(n in selectedNotes.get(k))
							n.column = PlayState.KEY_COUNT - 1 - n.column;

					reloadNotes();
				}],
				[Binds.ui_down, function(){
					shiftNotes(1, 0);
				}],
				[Binds.ui_up, function(){
					shiftNotes(-1, 0);
				}],
				[Binds.ui_right, function(){
					shiftNotes(0, 1);
				}],
				[Binds.ui_left, function(){
					shiftNotes(0, -1);
				}],
				[Binds.ui_accept, function(){
					selectedNotes.clear();
					selectedNotes.set(curSection, []);
					for(n in songData.sections[curSection].notes)
						(selectedNotes.get(curSection)).push(n);

					reloadNotes();
				}]
			]);
			return;
		}

		ev.keyCode.bindFunctions([
			[Binds.ui_back, function(){
				FlxG.mouse.visible = false;
				FlxG.sound.muteKeys = oldMuteKeys;
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseScroll);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
				FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP,    mouseUp);
				FlxG.stage.removeEventListener(MouseEvent.RIGHT_CLICK, mouseRight);

				EventState.changeState(new PlayState());
			}],
			[Binds.ui_accept, function(){
				FlxG.sound.music.playing ? FlxG.sound.music.pause() : FlxG.sound.music.play();

				if (songData.hasVoices){
					vocals.playing ? vocals.pause() : vocals.play();
					vocals.time = FlxG.sound.music.time;
				}
			}],
			[Binds.ui_down, function(){
				jumpToSection((curSection + 1) * 16);
			}],
			[Binds.ui_up, function(){
				jumpToSection((curSection - 1) * 16);
			}],
			[Binds.ui_left, function(){
				curZoom = CoolUtil.intBoundTo(curZoom - 1, 0, snaps.length - 1);
				snapText.text = 'Snap: ${1 / snaps[curZoom]}';
			}],
			[Binds.ui_right, function(){
				curZoom = CoolUtil.intBoundTo(curZoom + 1, 0, snaps.length - 1);
				snapText.text = 'Snap: ${1 / snaps[curZoom]}';
			}]
		]);
	}

	override function keyRel(ev:KeyboardEvent) 
	if (ev.keyCode.check([FlxKey.CONTROL])){
		selectionBox.alpha = 0;
		selectionBox.scale.set(0, 0);
	}

	// UI Stuff
	private inline function generateLabel(widget:flixel.FlxSprite, labelText:String):FormattedText
		return new FormattedText(widget.x + widget.width + 2, widget.y - 2, 0, labelText, null, 14, 0xFFFFFFFF, LEFT);

	private inline function widgetOffset(y:Float, from:flixel.FlxSprite)
		return from.y + from.height + y;

	private var textTween:FlxTween;
	private inline function postWarning(text:String, colour:Int){
		if (textTween != null)
			textTween.cancel();

		warningText.alpha = 1;
		warningText.color = colour;
		warningText.text  = text;
		textTween = FlxTween.tween(warningText, {alpha: 0}, 1.75, {startDelay: 1.25});
	}

	private inline function saveSong(){
		var corrections:String = '';
		var path = 'assets/data/songs/${PlayState.songData.name}';

		// Safety checks
		if (!StageLogic.STAGE_NAMES.contains(songData.stage))
			corrections += 'No stage called "${songData.stage}". (NOT Fixed)\n';

		if (songData.characterCharts > songData.characters.length){
			songData.characterCharts = songData.characters.length;
			corrections += 'More charts than characters. (Fixed)\n';
		}

		if (songData.activePlayer >= songData.characterCharts){
			songData.activePlayer = 0;
			corrections += 'Active player was higher than amount of charts. (Defaulted to 0)\n';
		}

		if (songData.BPM < 0 || songData.speed < 0 || songData.activePlayer < 0 || songData.startDelay < 0)
			corrections += 'Either BPM, speed, active player, or start delay was under 0. (NOT fixed)\n';

		for(i in 0...songData.sections.length){
			if (sectionNullCheck(i))
				corrections += 'Section $i did not exist. (Fixed)\n';

			if (correctSection(i))
				corrections += 'Section $i contained notes outside of range. (Fixed)\n';

			for(n in songData.sections[i].notes){
				var j:Int = -1;
				while(++j < songData.sections[i].notes.length){
					var tmpNote = songData.sections[i].notes[j];

					if (tmpNote == n 
					 || tmpNote.strumTime != n.strumTime 
				 	 || tmpNote.player != n.player 
					 || tmpNote.column != n.column)
						continue;

					corrections += 'Found duplicate note at section $i, position ${tmpNote.strumTime}. (Fixed)\n';
					songData.sections[i].notes.splice(j--, 1);
				}
			}
		}

		reloadNotes();
		/////////////////////////

		var JsonString:String = Json.stringify(songData, '\t'); // '\t' enables pretty printing.
		File.saveContent('$path/edit.json', JsonString);
		postWarning('File saved to "$path/edit.json"', 0xFFFFFFFF);
		
		if (corrections != ''){
			File.saveContent('$path/errors.txt', corrections);
			postWarning('Check errors/warnings at "$path/errors.txt"', 0xFFFFFF00);
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
		switch(id){ // Flixel UI is such a joke.
		case FlxUINumericStepper.CHANGE_EVENT:
			var tmpStepper:FlxUINumericStepper = cast sender;

			switch(tmpStepper.name){
			case 'speed':
				songData.speed = tmpStepper.value;
			case 'startDelay':
				songData.startDelay = tmpStepper.value;
			case 'cameraFacing':
				songData.sections[curSection].cameraFacing = Math.floor(tmpStepper.value);
			}
		case FlxUIInputText.CHANGE_EVENT:
			var tmpBox:FlxUIInputText = cast sender;

			switch(tmpBox.name){
			case 'name':
				songData.name = tmpBox.text;
			case 'BPM':
				FlxG.sound.music.pause();
				vocals.pause();

				songData.BPM = Math.isNaN(Std.parseFloat(tmpBox.text)) ? 120 : Std.parseFloat(tmpBox.text);
				Song.musicSet(songData.BPM);
			}
		case FlxUIDropDownMenu.CLICK_EVENT:
			var tmpDropDown:FlxUIDropDownMenu = cast sender;

			switch(tmpDropDown.name){
			case 'stage':
				songData.stage = cast(data, String);
			}
		case FlxUICheckBox.CLICK_EVENT:
			var tmpCheck:FlxUICheckBox = cast sender;
			
			switch(tmpCheck.name){
			case 'hasVoices':
				FlxG.sound.music.pause();
				vocals.pause();

				songData.hasVoices = tmpCheck.checked;
				songData.hasVoices ? vocals.loadEmbedded(Paths.playableSong(songData.name, true)) : vocals = new FlxSound();
			}
		}

	public function propertiesUI() { var nameBox = new FlxUIInputText(10, 10, 120, songData.name, 8); nameBox.name = 'name';
		var stageDropDown = new FlxUIDropDownMenu(220, 10, FlxUIDropDownMenu.makeStrIdLabelArray(StageLogic.STAGE_NAMES, false));
		stageDropDown.name = 'stage';

		var BPMBox = new FlxUIInputText(10, widgetOffset(10, nameBox), 120, Std.string(songData.BPM), 8); // Using input box instead of stepper because of how buggy they are.
		BPMBox.focusGained = nameBox.focusGained = function(){ typing = true; };
		BPMBox.focusLost   = nameBox.focusLost   = function(){ typing = false; };
		BPMBox.name = 'BPM';

		var speedStepper = new FlxUINumericStepper(10, widgetOffset(10, BPMBox), 0.1, songData.speed, 0.1, 10, 1);
		speedStepper.name = 'speed';
		
		var delayStepper = new FlxUINumericStepper(10, widgetOffset(10, speedStepper), 0.5, songData.startDelay, 0, 100, 1);
		delayStepper.name = 'startDelay';

		var voicesCheck = new FlxUICheckBox(10, widgetOffset(10, delayStepper), null, null, '', 0);
		voicesCheck.checked = songData.hasVoices;
		voicesCheck.name = 'hasVoices';

		var saveButton = new FlxButton(10, 450, 'Save', saveSong);
		var clearButton = new FlxButton(10, 420, 'Clear', function(){
			songData.sections = [];
			sectionNullCheck(0);
			jumpToSection(0);
			reloadNotes();
		});
		var selectButton = new FlxButton(10, 390, 'Select All', function(){
			selectedNotes.clear();

			for(i in 0...songData.sections.length){
				selectedNotes.set(i, []);

				for(n in songData.sections[i].notes)
					selectedNotes.get(i).push(n);
			}

			reloadNotes();
		});
		var updateButton = new FlxButton(10, 360, 'Update Song', function(){
			postWarning('Using "${Paths.playableSong(songData.name, false)}"', 0xFFFFFFFF);
			FlxG.sound.list.remove(vocals);
			FlxG.sound.playMusic(Paths.playableSong(songData.name, false));
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;

			vocals.pause();
			vocals = new FlxSound();
			FlxG.sound.list.add(vocals);

			if (songData.hasVoices)
				vocals.loadEmbedded(Paths.playableSong(songData.name, true));
		});

		var propertiesUIGroup = new FlxUI(null, mainUIBox);
		propertiesUIGroup.add(generateLabel(nameBox, 'Song Name'));
		propertiesUIGroup.add(generateLabel(BPMBox, 'Beats Per Minute'));
		propertiesUIGroup.add(generateLabel(speedStepper, 'Scroll speed'));
		propertiesUIGroup.add(generateLabel(delayStepper, 'Starting delay (seconds)'));
		propertiesUIGroup.add(generateLabel(voicesCheck, 'Use voices'));
		propertiesUIGroup.add(nameBox);
		propertiesUIGroup.add(BPMBox);
		propertiesUIGroup.add(speedStepper);
		propertiesUIGroup.add(delayStepper);
		propertiesUIGroup.add(voicesCheck);
		propertiesUIGroup.add(stageDropDown);
		propertiesUIGroup.add(saveButton);
		propertiesUIGroup.add(clearButton);
		propertiesUIGroup.add(selectButton);
		propertiesUIGroup.add(updateButton);

		propertiesUIGroup.name = '1properties';
		mainUIBox.addGroup(propertiesUIGroup);
	}

	public var sectionCameraStepper = new FlxUINumericStepper(10, 10, 1, 0, 0, 0, 0);
	public function sectionUI() {
		sectionCameraStepper.value = songData.sections[curSection].cameraFacing;
		sectionCameraStepper.max  = songData.characterCharts - 1;
		sectionCameraStepper.name = 'cameraFacing';

		var copySectionStepper = new FlxUINumericStepper(10, widgetOffset(10, sectionCameraStepper), 1, 1, 1);
		copySectionStepper.name = 'copySectionStepper';

		var copyButton = new FlxButton(10, 450, 'Copy section', function(){
			var offSection = CoolUtil.intBoundTo(curSection - copySectionStepper.value, 0, songData.sections.length - 1);
			sectionNullCheck(offSection);
			
			for(n in songData.sections[offSection].notes)
				songData.sections[curSection].notes.push({ // We can't just push 'n', otherwise it will pass by reference.
					strumTime: n.strumTime,
					column: n.column,
					length: n.length,
					player: n.player,
					type: n.type
				});

			reloadNotes();
		});

		var selectButton = new FlxButton(10, 420, 'Select notes', function(){
			selectedNotes.clear();
			selectedNotes.set(curSection, []);

			for(n in songData.sections[curSection].notes)
				selectedNotes.get(curSection).push(n);

			reloadNotes();
		});

		var clearButton = new FlxButton(10, 390, 'Clear', function(){
			songData.sections[curSection] = null;
			sectionNullCheck(curSection);
			reloadNotes();
		});

		var sectionUIGroup = new FlxUI(null, mainUIBox);
		sectionUIGroup.add(generateLabel(sectionCameraStepper, 'Camera facing'));
		sectionUIGroup.add(generateLabel(copySectionStepper, 'Copy offset'));
		sectionUIGroup.add(sectionCameraStepper);
		sectionUIGroup.add(copySectionStepper);
		sectionUIGroup.add(copyButton);
		sectionUIGroup.add(selectButton);
		sectionUIGroup.add(clearButton);

		sectionUIGroup.name = '2section';
		mainUIBox.addGroup(sectionUIGroup);
	}
}
