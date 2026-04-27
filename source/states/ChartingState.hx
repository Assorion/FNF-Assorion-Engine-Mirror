package states;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.utils.Assets;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.display.BitmapData;
import haxe.Json;
#if desktop
import sys.io.File;
import sys.FileSystem;
#else
import haxe.io.Bytes;
import lime.ui.FileDialog;
#end

import backend.Song;
import ui.CharacterIcon;
import gameplay.Note;
import gameplay.StageLogic;

import sail.*;
import sail.presets.*;
import sail.style.SIStyleGeneric;

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
	private static inline final NOTE_SELECT_COLOUR:Int = 0xFF9999CC; // RGB: 153 153 204
	private static inline final GRID_SIZE:Int = 40;

	private final tabNames:Array<String> = ['Properties', 'Section', 'Players', 'Help'];
	private var tabBar:SIHoverableContainer;
	private var mainUIBox:SIMasterContainer;
	var allTabs:Array<SIContainer> = [];

	public var vocals:FlxSound;
	public var curNoteType:Int;
	public var songData:SongData;
	public var selectedNotes:Map<Int, Array<NoteData>> = new Map<Int, Array<NoteData>>();
	
	private var grid:StaticSprite;
	private var gridGroup:FlxSpriteGroup;
	private var noteGroup:FlxSpriteGroup;
	private var highlightBox:StaticSprite;
	private var selectionBox:StaticSprite;

	private var warningText:FormattedText;
	private var sectionText:FormattedText;
	private var noteTypeText:FormattedText;
	private var snapText:FormattedText;

	var stepTime:Float = 0;
	var timingLine:StaticSprite;
	var curSection:Int = 0;
	var gridSelectX:Int;
	var gridSelectY:Float;

	var snaps:Array<Float> = [1/2, 3/4, 1, 3/2, 2, 4]; // 0.5, 0.75, 1, 1.5, 2, 4
	var curZoom:Int = 2;

	private function autoSave(){
		saveSong(true);
		postEvent(120, autoSave);
	}

	override function create(){
		super.create();

		songData = PlayState.songData;
		Song.stepHooks.push(stepHit);

		vocals = new FlxSound();
		if (songData.hasVoices)
			vocals.loadEmbedded(Paths.playableSong(songData.name, true));

		vocals.play();
		vocals.pause();
		FlxG.mouse.visible = true;
		FlxG.sound.muteKeys = [];
		FlxG.sound.list.add(vocals);
		FlxG.sound.music.play(); // Playing and immidietly pausing is required to handle some timing weirdness.
		FlxG.sound.music.pause();
		FlxG.sound.music.volume = 0.75;
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

		gridGroup = new FlxSpriteGroup(380, 70);
		noteGroup = new FlxSpriteGroup(380, 70);
		add(gridGroup);
		add(noteGroup);

		highlightBox = new StaticSprite(0, 0).makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);

		selectionBox = new StaticSprite(0, 0).makeGraphic(1, 1, NOTE_SELECT_COLOUR);
		selectionBox.alpha = 0;
		selectionBox.origin.set(0, 0);
		add(selectionBox);
		
		// UI Stuff
		mainUIBox    = new SIMasterContainer(350, 500, 20, 100, SIStyleDefault);
		tabBar       = new SIHoverableContainer(340, SIGeneric.DEFAULT_COMPONENT_HEIGHT, TOP, null);
		tabBar.style = mainUIBox.style;

		var lastButton:SIButton = null;
		for(i in 0...tabNames.length) {
			lastButton = new SIButton(tabNames[i], Math.floor(tabBar.width / tabNames.length), RIGHT, lastButton);
			lastButton.callback = function() {
				allTabs[i].addChild(tabBar);
				mainUIBox.setChildren([allTabs[i]]);
			};

			tabBar.addChild(lastButton);
		}

		sectionUI();
		propertiesUI();
		mainUIBox.setChildren([allTabs[0]]);

		sectionText  = new FormattedText(0, 0, 0, '', null, 16, 0xFFFFFFFF, LEFT);
		noteTypeText = new FormattedText(0, 0, 0, 'Note type: 0 (${Note.NOTE_TYPES[0].assets})', null, 16, 0xFFFFFFFF, LEFT);
		snapText     = new FormattedText(0, 0, 0, 'Snap: 1', null, 16, 0xFFFFFFFF, LEFT);
		warningText  = new FormattedText(0, 0, 0, '', null, 16, 0xFFFFFFFF, LEFT);
		sectionText.y  = FlxG.height - 15;
		noteTypeText.y = FlxG.height - 30;
		snapText.y     = FlxG.height - 45;
		warningText.y  = 20;
		add(sectionText);
		add(noteTypeText);
		add(snapText);
		add(warningText);
		add(mainUIBox.sprite);

		reloadGrid();
		reloadNotes();

		#if desktop
		postEvent(120, autoSave);
		#end
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
		var section = songData.sections[sec];
		songData.sections[sec] = section ?? {
			cameraFacing: 0,
			notes: []
		};

		return section == null;
	}

	public function reloadGrid() {
		gridGroup.clear();

		for(i in 0...songData.characterCharts){
			var tmpIcon = new CharacterIcon(songData.characters[i].name);
			tmpIcon.x = (GRID_SIZE * i * PlayState.KEY_COUNT) + GRID_SIZE;
			tmpIcon.y = gridGroup.y - 140;
			tmpIcon.alpha = songData.activePlayer == i ? 1 : 0.5;
			tmpIcon.scale.set(0.5, 0.5);

			tmpIcon.updateHitbox();
			gridGroup.add(tmpIcon);
		}

		grid = new ChartGrid(40, 40, PlayState.KEY_COUNT * songData.characterCharts, 16, 4);
		timingLine = new StaticSprite(0, 0).makeGraphic(Math.round(grid.width), 4, 0xFFFFFFFF);

		gridGroup.add(grid);
		gridGroup.add(timingLine);
		gridGroup.add(highlightBox);
	}

	public function reloadNotes() {
		sectionNullCheck(curSection);
		sectionText.text = 'Section: $curSection';
		//sectionCameraStepper.value = songData.sections[curSection].cameraFacing;
		noteGroup.clear();

		for(i in 0...songData.sections[curSection].notes.length){
			var noteData = songData.sections[curSection].notes[i];

			var newNote = new Note(noteData.strumTime, noteData.column, noteData.type, false, false);
			newNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
			newNote.updateHitbox();
			newNote.player = noteData.player;
			newNote.x = (noteData.column + (noteData.player * PlayState.KEY_COUNT)) * GRID_SIZE;
			newNote.y = noteData.strumTime * GRID_SIZE;

			if (noteSelected(noteData, curSection))
				newNote.color = NOTE_SELECT_COLOUR;

			for(j in 1...noteData.length + 1){
				var susNote = new Note(noteData.strumTime + j, noteData.column, noteData.type, true, j == noteData.length);
				susNote.setGraphicSize(Math.floor(GRID_SIZE * 0.4), GRID_SIZE);
				susNote.updateHitbox();
				susNote.player = noteData.player;
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

			tmpNote.player = CoolUtil.intCircularMod(tmpNote.player + Math.floor(tmpNote.column / PlayState.KEY_COUNT), songData.characterCharts);
			tmpNote.column = CoolUtil.intCircularMod(tmpNote.column, PlayState.KEY_COUNT);
			tmpNote.strumTime = CoolUtil.circularMod(tmpNote.strumTime, 16);

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
		mainUIBox.hover(FlxG.mouse.x, FlxG.mouse.y);

		gridSelectX = CoolUtil.intClamp(Math.floor((FlxG.mouse.x - gridGroup.x) / GRID_SIZE), 0, (songData.characterCharts * PlayState.KEY_COUNT) - 1);
		gridSelectY = CoolUtil.clamp(Math.floor(((FlxG.mouse.y - gridGroup.y) * snaps[curZoom]) / GRID_SIZE) / snaps[curZoom], 0, 15);
		highlightBox.x = (gridSelectX * GRID_SIZE) + gridGroup.x;
		highlightBox.y = (gridSelectY * GRID_SIZE) + gridGroup.y;
		highlightBox.alpha = FlxG.mouse.x < gridGroup.x ? 0 : 0.75;

		if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL){
			selectionBox.scale.x = FlxG.mouse.x - selectionBox.x;
			selectionBox.scale.y = FlxG.mouse.y - selectionBox.y;
		}
	}

	public function mouseUp(ev:MouseEvent) {
		mainUIBox.onClickRelease();
		mainUIBox.hover(FlxG.mouse.x, FlxG.mouse.y);

		if (!FlxG.keys.pressed.CONTROL) 
			return;

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
		mainUIBox.onClick(FlxG.mouse.x, FlxG.mouse.y);
		mainUIBox.offClick();

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
		if (SIMasterContainer.inputGrabbed) 
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
					curNoteType = CoolUtil.intCircularMod(--curNoteType, Note.NOTE_TYPES.length);
					noteTypeText.text = 'Note type: $curNoteType (${Note.NOTE_TYPES[curNoteType].assets})';

					for(k in selectedNotes.keys())
						for(i in 0...selectedNotes.get(k).length)
							selectedNotes.get(k)[i].type = curNoteType;
				
					reloadNotes();
				}],
				[Binds.ui_right, function(){
					curNoteType = CoolUtil.intCircularMod(++curNoteType, Note.NOTE_TYPES.length);
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
				FlxG.sound.music.volume = 1;
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
				curZoom = CoolUtil.intClamp(curZoom - 1, 0, snaps.length - 1);
				snapText.text = 'Snap: ${1 / snaps[curZoom]}';
			}],
			[Binds.ui_right, function(){
				curZoom = CoolUtil.intClamp(curZoom + 1, 0, snaps.length - 1);
				snapText.text = 'Snap: ${1 / snaps[curZoom]}';
			}]
		]);
	}

	override function keyRel(ev:KeyboardEvent) {
		if (!ev.keyCode.check([FlxKey.CONTROL]))
			return;

		selectionBox.alpha = 0;
		selectionBox.scale.set(0, 0);
	}

	/*  !!! READ HERE !!!
		Pretty much all the UI code is pure garbage. Which is mostly Flixel-UIs fault.
		Huge apologies to anyone who wants/needs to tinker with the UI.
	*/
	/*private inline function generateLabel(widget:flixel.FlxSprite, labelText:String):FormattedText
		return new FormattedText(widget.x + widget.width + 2, widget.y - 2, 0, labelText, null, 14, 0xFFFFFFFF, LEFT);

	private inline function widgetOffset(y:Float, from:flixel.FlxSprite)
		return from.y + from.height + y;*/

	private var textTween:FlxTween;
	private inline function postWarning(text:String, colour:Int){
		if (textTween != null)
			textTween.cancel();

		warningText.alpha = 1;
		warningText.color = colour;
		warningText.text  = text;
		textTween = FlxTween.tween(warningText, {alpha: 0}, 1.75, {startDelay: 1.25});
	}

	private inline function saveSong(autosave:Bool = false){
		var corrections:String = '';
		var fileName:String = (autosave ? 'autosave.json' : 'edit.json');
		var path = 'assets/data/songs/${PlayState.songData.name}/editor';

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

		var JsonString:String = Json.stringify(songData, '\t'); // '\t' enables pretty printing.

		#if desktop
		FileSystem.createDirectory('$path');
		File.saveContent('$path/$fileName', JsonString);
		postWarning('File saved to "$path/$fileName"', autosave ? 0xFF00AAFF : 0xFFFFFFFF);
		
		if (corrections != '' && !autosave){
			File.saveContent('$path/errors.txt', corrections);
			postWarning('Check errors/warnings at "$path/errors.txt"', 0xFFFFFF00);
		}
		#else
		var fileDialog = new FileDialog();
		fileDialog.save(Bytes.ofString(JsonString), null, fileName);
		postWarning('File saved', 0xFFFFFFFF);
		#end
	}

	public function setHealthBarColour(player:Int, channel:Int, value:Int, colBox:SIColourBox) {
		channel = (2 - channel) << 3;

		var newColour = songData.healthColours[player];
		newColour ^= newColour & (0xFF << channel);
		newColour |= value << channel;
	
		songData.healthColours[player] = newColour;
		colBox.setColour(songData.healthColours[player]);
	}

	public function propertiesUI() {
		var propUI = new SIContainer(350, 500, TOP, null);
		var topCon = new SIContainer(340, 300, BOTTOM, tabBar);
		var botCon = new SIContainer(340, 155, BOTTOM, topCon);
		propUI.spacing = topCon.spacing = botCon.spacing = 5;
		propUI.style = mainUIBox.style;
		botCon.corner = BOTTOMLEFT;
		propUI.addChild(tabBar);
		propUI.addChild(topCon);
		propUI.addChild(botCon);

		var nameBox = new SIInput(songData.name, 150, BOTTOM, null);
		nameBox.callback = function(newStr:String, finish:Bool) {
			songData.name = newStr;
		};

		var BPMStepper = new SIStepper(songData.BPM, 150, BOTTOM, nameBox, propUI.style);
		BPMStepper.min = 1;
		BPMStepper.max = 1000;
		BPMStepper.callback = function(num:Float) {
			FlxG.sound.music.pause();
			vocals.pause();
			songData.BPM = num;
			Song.musicSet(songData.BPM);
		};

		var speedStepper = new SIStepper(songData.speed, 150, BOTTOM, BPMStepper, propUI.style);
		speedStepper.min = 0.1;
		speedStepper.max = 10;
		speedStepper.step = 0.1;
		speedStepper.callback = function(num:Float) {
			songData.speed = num;
		};

		var stageDropDown = new SIDropdown(StageLogic.STAGE_NAMES, songData.stage, 150, BOTTOM, speedStepper, propUI.style);
		stageDropDown.callback = function(str:String, opt:Int) {
			songData.stage = str;
		};

		var voicesCheck = new SICheckbox(songData.hasVoices, BOTTOM, stageDropDown);
		voicesCheck.callback = function(chk:Bool) {
			FlxG.sound.music.pause();
			vocals.pause();
			songData.hasVoices = chk;
			songData.hasVoices ? vocals.loadEmbedded(Paths.playableSong(songData.name, true)) : vocals = new FlxSound();
		};

		/* Just for health bar colours :facepalm: */
		var oppCol = songData.healthColours[0];
		var oppColourbox = new SIColourBox(oppCol, BOTTOM, voicesCheck);
		var oppRS = new SIStepper((oppCol >> 16) & 0xFF, 90, RIGHT, oppColourbox, propUI.style);
		var oppGS = new SIStepper((oppCol >> 8)  & 0xFF, 90, RIGHT, oppRS, propUI.style);
		var oppBS = new SIStepper(oppCol         & 0xFF, 90, RIGHT, oppGS, propUI.style);
		oppRS.callback = function(num:Float) { setHealthBarColour(0, 0, Math.floor(num), oppColourbox); };
		oppGS.callback = function(num:Float) { setHealthBarColour(0, 1, Math.floor(num), oppColourbox); };
		oppBS.callback = function(num:Float) { setHealthBarColour(0, 2, Math.floor(num), oppColourbox); };

		var proCol = songData.healthColours[1];
		var proColourbox = new SIColourBox(proCol, BOTTOM, oppColourbox);
		var proRS = new SIStepper((proCol >> 16) & 0xFF, 90, RIGHT, proColourbox, propUI.style);
		var proGS = new SIStepper((proCol >> 8)  & 0xFF, 90, RIGHT, proRS, propUI.style);
		var proBS = new SIStepper(proCol         & 0xFF, 90, RIGHT, proGS, propUI.style);
		proRS.callback = function(num:Float) { setHealthBarColour(1, 0, Math.floor(num), proColourbox); };
		proGS.callback = function(num:Float) { setHealthBarColour(1, 1, Math.floor(num), proColourbox); };
		proBS.callback = function(num:Float) { setHealthBarColour(1, 2, Math.floor(num), proColourbox); };
		oppRS.min = oppGS.min = oppBS.min = proRS.min = proGS.min = proBS.min = 0;
		oppRS.max = oppGS.max = oppBS.max = proRS.max = proGS.max = proBS.max = 255;
		/******************************************/

		topCon.addChild(nameBox);
		topCon.addChild(new SILabel('Song file name', RIGHT, nameBox));
		topCon.addChild(BPMStepper);
		topCon.addChild(new SILabel('Beats Per Minute', RIGHT, BPMStepper));
		topCon.addChild(speedStepper);
		topCon.addChild(new SILabel('Chart scroll speed', RIGHT, speedStepper));
		topCon.addChild(stageDropDown);
		topCon.addChild(new SILabel('Stage name', RIGHT, stageDropDown));
		topCon.addChild(voicesCheck);
		topCon.addChild(new SILabel('Use vocal track', RIGHT, voicesCheck));

		topCon.addChild(oppColourbox);
		topCon.addChild(oppRS);
		topCon.addChild(oppGS);
		topCon.addChild(oppBS);
		topCon.addChild(proColourbox);
		topCon.addChild(proRS);
		topCon.addChild(proGS);
		topCon.addChild(proBS);

		var saveButton = new SIButton('Save', 100, TOP, null);
		saveButton.callback = function() {
			saveSong(false);
		};

		var clearButton = new SIButton('Clear', 100, TOP, saveButton);
		clearButton.callback = function() {
			songData.sections = [];
			sectionNullCheck(0);
			jumpToSection(0);
			reloadNotes();
		};

		var selectButton = new SIButton('Select All', 100, TOP, clearButton);
		selectButton.callback = function() {
			selectedNotes.clear();

			for(i in 0...songData.sections.length){
				selectedNotes.set(i, []);

				for(n in songData.sections[i].notes)
					selectedNotes.get(i).push(n);
			}

			reloadNotes();
		};

		var reloadButton = new SIButton('Reload Song', 100, TOP, selectButton);
		reloadButton.callback = function() {
			postWarning('Using "${Paths.playableSong(songData.name, false)}"', 0xFF00FFAA);
			FlxG.sound.list.remove(vocals);
			FlxG.sound.playMusic(Paths.playableSong(songData.name, false));
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			FlxG.sound.music.volume = 0.75;

			vocals.pause();
			vocals = new FlxSound();
			FlxG.sound.list.add(vocals);

			if (songData.hasVoices)
				vocals.loadEmbedded(Paths.playableSong(songData.name, true));
		}

		botCon.addChild(saveButton);
		botCon.addChild(clearButton);
		botCon.addChild(selectButton);
		botCon.addChild(reloadButton);
		allTabs[0] = propUI;
	}

	public function sectionUI() {
		var secUI = new SIContainer(350, 500, TOP, null);
		secUI.spacing = 5;
		secUI.style = mainUIBox.style;
		secUI.addChild(tabBar);

		var topContainer = new SIContainer(340, 350, BOTTOM, tabBar);
		topContainer.spacing = 5;
		secUI.addChild(topContainer);

		var coolButton = new SIButton('Not at all', 80, BOTTOM, null);
		topContainer.addChild(coolButton);

		allTabs[1] = secUI;
	}

	/*
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
			case 'activePlayer':
				songData.activePlayer = Math.floor(tmpStepper.value) - 1;
				reloadGrid();
			case 'characterCharts':
				songData.characterCharts = Math.floor(tmpStepper.value);
				songData.activePlayer = CoolUtil.intBoundTo(songData.activePlayer, 0, songData.characterCharts - 1);
				reloadGrid();
				reloadNotes();
				playersUI();
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
			case 'oppbox':
				songData.iconNames[0] = tmpBox.text;
			case 'secbox':
				songData.iconNames[1] = tmpBox.text;
			case 'oppR', 'secR':
				var charNum:Int = tmpBox.name.split('sec').length - 1;
				var curCol = songData.healthColours[charNum] ^ (songData.healthColours[charNum] & 0xFF0000);
				curCol |= CoolUtil.intBoundTo(Std.parseInt(tmpBox.text), 0, 0xFF) << 16;
				songData.healthColours[charNum] = curCol | 0xFF000000;
			case 'oppG', 'secG':
				var charNum:Int = tmpBox.name.split('sec').length - 1;
				var curCol = songData.healthColours[charNum] ^ (songData.healthColours[charNum] & 0x00FF00);
				curCol |= CoolUtil.intBoundTo(Std.parseInt(tmpBox.text), 0, 0xFF) << 8;
				songData.healthColours[charNum] = curCol | 0xFF000000;
			case 'oppB', 'secB':
				var charNum:Int = tmpBox.name.split('sec').length - 1;
				var curCol = songData.healthColours[charNum] ^ (songData.healthColours[charNum] & 0x0000FF);
				curCol |= CoolUtil.intBoundTo(Std.parseInt(tmpBox.text), 0, 0xFF);
				songData.healthColours[charNum] = curCol | 0xFF000000;
			default:
				var safeValue = Math.isNaN(Std.parseFloat(tmpBox.text)) ? 0 : Std.parseFloat(tmpBox.text);
				var character = Std.parseInt(tmpBox.name.split('.')[0]);

				tmpBox.name.split('.')[1] == 'x' ? 
				songData.characters[character].x = safeValue :
				songData.characters[character].y = safeValue;
			}

			oppColourPreview.color = songData.healthColours[0];
			secColourPreview.color = songData.healthColours[1];
		case FlxUIDropDownMenu.CLICK_EVENT:
			var tmpDropDown:FlxUIDropDownMenu = cast sender;

			switch(tmpDropDown.name){
			case 'stage':
				songData.stage = cast(data, String);
			default:
				var charIndex = Std.parseInt(tmpDropDown.name);
				
				songData.characters[Std.parseInt(tmpDropDown.name)].name = cast(data, String);
				reloadGrid();
			}
		case FlxUICheckBox.CLICK_EVENT:
			var tmpCheck:FlxUICheckBox = cast sender;
			
			switch(tmpCheck.name){
			case 'hasVoices':
			case 'renderBackwards':
				songData.renderBackwards = tmpCheck.checked;
			}
		}

	public function propertiesUI() { 

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
		propertiesUIGroup.add(oppBox);
		propertiesUIGroup.add(secBox);
		propertiesUIGroup.add(generateLabel(oppBox, 'Left side icon'));
		propertiesUIGroup.add(generateLabel(secBox, 'Right side icon'));
		propertiesUIGroup.add(oppColourPreview);
		propertiesUIGroup.add(secColourPreview);
		propertiesUIGroup.add(secR);
		propertiesUIGroup.add(secG);
		propertiesUIGroup.add(secB);
		propertiesUIGroup.add(oppR);
		propertiesUIGroup.add(oppG);
		propertiesUIGroup.add(oppB);
		propertiesUIGroup.add(generateLabel(oppB, 'Left side R,G,B'));
		propertiesUIGroup.add(generateLabel(secB, 'Right side R,G,B'));

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

		var swapButton = new FlxButton(10, 360, 'Swap', function(){
			for(n in songData.sections[curSection].notes)
				++n.player;

			correctSection(curSection);
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
		sectionUIGroup.add(swapButton);

		sectionUIGroup.name = '2section';
		mainUIBox.addGroup(sectionUIGroup);
	}

	private var characterNames:Array<String> = [];
	private inline function getCharacterNames()
	if (characterNames.length <= 0) {
		characterNames = Assets.list();

		var i = -1;
		while(++i < characterNames.length)
			if (characterNames[i].substring(0, 22) != 'assets/data/characters')
				characterNames.splice(i--, 1);

		for(i in 0...characterNames.length){
			var nameSplit:Array<String> = characterNames[i].split('/');
			characterNames[i] = nameSplit[nameSplit.length - 1];
			characterNames[i] = characterNames[i].split('.json')[0];
		}
	}

	public var playersUIGroup:FlxUI;
	public function playersUI(){
		if (playersUIGroup == null)
			playersUIGroup = new FlxUI(null, mainUIBox);

		sectionCameraStepper.max = songData.characters.length - 1;
		playersUIGroup.name = '3players';
		playersUIGroup.clear();
		getCharacterNames();

		var playerStepper = new FlxUINumericStepper(10, 450, 1, songData.activePlayer + 1, 1, songData.characterCharts);
		playerStepper.name = 'activePlayer';

		// The limit of 5 charts is only because more would push the UI off the screen. If you need more: lower GRID_SIZE.
		var chartStepper = new FlxUINumericStepper(10, 420, 1, songData.characterCharts, 1, Math.floor(Math.min(songData.characters.length, 5)));
		chartStepper.name = 'characterCharts';

		var renderCheck = new FlxUICheckBox(10, 390, null, null, '', 0);
		renderCheck.checked = songData.renderBackwards;
		renderCheck.name = 'renderBackwards';

		var addButton = new FlxButton(260, 10, 'Add', function(){
			if (songData.characters.length >= 13)
				return;

			songData.characters.push({
				name: characterNames[0],
				x: 0,
				y: 0
			});
			playersUI();
		});

		var removeButton = new FlxButton(260, widgetOffset(10, addButton), 'Remove', function(){
			if (songData.characters.length <= 1)
				return;

			songData.characters.pop();
			songData.characterCharts = CoolUtil.intBoundTo(songData.characterCharts, 1, songData.characters.length);
			songData.activePlayer = CoolUtil.intBoundTo(songData.activePlayer, 0, songData.characterCharts - 1);
			reloadGrid();
			reloadNotes();
			playersUI();
		});

		playersUIGroup.add(generateLabel(playerStepper, 'Active player'));
		playersUIGroup.add(generateLabel(chartStepper, 'Charts'));
		playersUIGroup.add(generateLabel(renderCheck, 'Render characters backwards'));
		playersUIGroup.add(playerStepper);
		playersUIGroup.add(chartStepper);
		playersUIGroup.add(renderCheck);
		playersUIGroup.add(addButton);
		playersUIGroup.add(removeButton);

		var dropDownList:Array<FlxUIDropDownMenu> = [];
		for(i in 0...songData.characters.length){
			var tmpPlayerDropDown = new FlxUIDropDownMenu(9, 10 + (i * 30), FlxUIDropDownMenu.makeStrIdLabelArray(characterNames, false));
			tmpPlayerDropDown.selectedLabel = songData.characters[i].name;
			tmpPlayerDropDown.name = '$i';
			
			var tmpPlayerX = new FlxUIInputText(142, 12 + (i * 30), 40, '${songData.characters[i].x}', 8);
			var tmpPlayerY = new FlxUIInputText(192, 12 + (i * 30), 40, '${songData.characters[i].y}', 8);
			tmpPlayerX.focusGained = tmpPlayerY.focusGained = function(){ typing = true; };
			tmpPlayerX.focusLost   = tmpPlayerY.focusLost   = function(){ typing = false; };
			tmpPlayerX.name = '$i.x';
			tmpPlayerY.name = '$i.y';

			dropDownList.push(tmpPlayerDropDown);
			playersUIGroup.add(generateLabel(tmpPlayerY, '${i + 1}'));
			playersUIGroup.add(tmpPlayerX);
			playersUIGroup.add(tmpPlayerY);
		}

		for(i in 0...songData.characters.length)
			playersUIGroup.add(dropDownList[dropDownList.length - 1 - i]);
	}

	private var oppColourPreview:FlxSprite;
	private var secColourPreview:FlxSprite;

	public function helpUI(){
		var pagesText:Array<String> = [
			'Common controls:

			Down/Up: Jump forward/back a section
			Left/Right: Increase/decrease snapping
			Accept: Toggle pausing and playing
			Back: Test chart changes

			Click: Add note to grid
			Click (on top of note): Delete note
			Right click: Delete selected notes',

			'Controls while holding SHIFT:

			Down/Up: Change selected notes length
			Left/Right: Change selected notes type
			Back: Jump back to the first section

			Controls while holding CONTROL:
			
			Click (and Drag): Select multiple notes
			Down/Up: Move selected notes up/down
			Left/Right: Move select notes left/right
			Accept: Select all notes in section
			C: Copy all selected notes
			V: Mirror selected notes',

			'Players: 
			
			Unlike most other engines, players are -
			stored as a variable sized list of -
			characters. "CharacterCharts" determines -
			the charts respective to the characters.

			Active player controls which of the -
			characters in the character list will -
			have the player controlling them.

			Each player has an X and Y value -
			next to them to determine their location.'
		];

		var helpUIGroup = new FlxUI(null, mainUIBox);
		var txtPoint:FlxSprite = new FlxSprite(5, 10);
		var labelText:FormattedText = generateLabel(txtPoint, pagesText[0]);

		var nextButton = new FlxButton(260, 450, 'Next', function(){
			helpUIGroup.remove(labelText);
			pagesText.push(pagesText.shift());

			labelText = generateLabel(txtPoint, pagesText[0]);
			helpUIGroup.add(labelText);
		});

		var backButton = new FlxButton(10, 450, 'Back', function(){
			helpUIGroup.remove(labelText);
			pagesText.insert(0, pagesText.pop());

			labelText = generateLabel(txtPoint, pagesText[0]);
			helpUIGroup.add(labelText);
		});

		helpUIGroup.add(labelText);
		helpUIGroup.add(nextButton);
		helpUIGroup.add(backButton);

		helpUIGroup.name = '4help';	
		mainUIBox.addGroup(helpUIGroup);
	}*/
}
