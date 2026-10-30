"
I show a file with the text covered by the FileAnchors of a Moose model highlighted (one color per entity type and nesting depth, a specific color for the uncovered text). The window has three columns. On the left, the file selector (with an inventory, see below) above the tree of the Moose model (a MMCModelNavigator): by default only the entities covered by the file and their ancestors are shown; the ""Whole model"" check box (or #treeFilter: #all) shows the entire model; entities without a region of their own are drawn in grey. In the middle, the highlighted text. On the right, the list of the uncovered zones (selecting one selects it in the text) and the details of the entities at the cursor position. On top, a summary of the coverage. The coverage is an MMCFileCoverage; the Moose model may be nil (empty tree). Build me with #on:, #on:theme:, #on:model:, #on:model:theme:, #forModel:file: or #openOn:file:; #updateFileCoverage: keeps the model and the tree filter, #updateFileCoverage:model: replaces the model too.

Synchronisation tree <-> text: selecting an entity in the tree selects its first region in the text and shows its details; moving the selection or the cursor in the text selects the deepest entity at its start in the tree (unfolding its ancestors), or clears the tree selection when there is none. isSynchronizing prevents loops. Drift trap: selecting an entity in the tree selects its region in the text, and the text announces that selection back; an interval that is exactly a region of the entity selected in the tree is ignored, otherwise Engine (1-50) would be replaced by its attribute starting at the same character.

Layout: nested SpPanedLayouts, two movable dividers (about 0.22 / 0.50 / 0.28 of the width): tree column, text, uncovered zones and details.

Empty states: treeStatusPresenter (between the check box and the tree) shows treeStatusText: no Moose model, or no entity of the model anchored in the file (with the rootFolder). The Whole model check box is disabled without model. A relative path given to #forModel:file: is resolved against the rootFolder of the model.

Example: MMCCoveragePresenter example opens a fictive bank model; newExample answers it not opened.

Known limits
- Performance in a real window: about 1.4 s to open and 0.3 s to change the file for 60 000 characters / 600 regions; about 4 s and 1.3 s for 200 000 / 2 000; about 11 s and 7 s for 500 000 / 7 000 (removing the Rubric segments with removeAllTextSegmentDecorations is quadratic).
- The highlight colors are chosen when the window opens, from the background of the text widget. A change of Pharo theme while the window is open is not followed: use applyTheme:.
- A real mouse click was not automated: the cursor tracking and the synchronisation are verified by programmatic Rubric selection.
- Selecting in the tree an entity without region in this file does not move the text (the details say so).
Tree context menu ""Inspect"" (right click): opens the Pharo inspector on the selected entity (entity inspect); the action is injectable with inspectAction:.

File by file navigation (with inventory): #forModel: and #openOn: (and #openOn:file:, opened on that file, when the inventory holds it) build the presenter on a MMCModelFiles (modelFiles): files sorted by relative path, unreadable ones listed with the label ""<relative>  (warning sign) unreadable"". The coverage is computed on demand: opening computes only the current file (currentFile); the label of the other files is ""<relative>  ?"" until computed, then ""<relative>  P%"". API: showFile:, previousFile, nextFile (complete sorted order, filter ignored), nextUncoveredFile (skips unreadable files, computes on demand, loops, does nothing if the only candidate is the current file), computeAllFiles, visibleFiles (text filter on the relative name, ignoring case), fileLabelFor:, globalSummaryText (Files: N, computed K/N, covered P%), windowTitleText (Coverage - <relative> (i/N)), kept by the open window. Widgets: fileFilterPresenter, fileListPresenter, previousFileButton, nextFileButton, nextUncoveredFileButton, computeAllButton, filesSummaryPresenter.
Automatic switch: selecting in the tree an entity without region in the current file switches to the first file of filesOf: where it has a region and selects the region (nothing moves when it has no region anywhere). The tree selection is kept after a file change when its entity is still visible.
#on:, #on:model: and #forModel:file: build a presenter WITHOUT inventory: modelFiles and currentFile are nil, the file widgets are disabled, windowTitleText is Coverage and the file navigation messages do nothing.
Limits: the file list is rebuilt at each file change (labels are recomputed); an unreadable file counts as computed with 0 character in the global summary; the model is not observed (use modelFiles invalidate and rebuild after changing it).
"
Class {
	#name : 'MMCCoveragePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'fileCoverage',
		'plan',
		'palette',
		'theme',
		'uncoveredRegions',
		'decorators',
		'textPresenter',
		'uncoveredListPresenter',
		'detailsPresenter',
		'summaryPresenter',
		'themeIsForced',
		'model',
		'navigator',
		'treePresenter',
		'wholeModelTogglePresenter',
		'treeFilter',
		'isUpdatingToggle',
		'isSynchronizing',
		'treeStatusPresenter',
		'treeStatusText',
		'inspectAction',
		'modelFiles',
		'currentFile',
		'fileListPresenter',
		'fileFilterPresenter',
		'previousFileButton',
		'nextFileButton',
		'nextUncoveredFileButton',
		'computeAllButton',
		'filesSummaryPresenter',
		'isUpdatingFileList'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCCoveragePresenter class >> emptyCoverage [
	"Answer the coverage shown when there is no file to show (unreadable)."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: nil
			   text: ''
			   regions: #(  )
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'examples' }
MMCCoveragePresenter class >> example [
	"Open the fictive example (see #newExample) and answer the presenter."

	^ self newExample
		  open;
		  yourself
]

{ #category : 'examples' }
MMCCoveragePresenter class >> exampleEntitiesFor: aText [
	"Answer an association list entity -> interval for the Account example (package bank, class Account, three methods, two attributes); the entities are linked together but not added to a model."

	| package span entity entities |
	span := [ :startToken :endToken |
		        | start |
		        start := aText findString: startToken.
		        start to:
		        (aText findString: endToken startingAt: start)
		        + endToken size - 1 ].
	package := FamixJavaPackage new
		           name: 'bank';
		           yourself.
	entity := FamixJavaClass new
		          name: 'Account';
		          parentPackage: package;
		          yourself.
	entities := OrderedCollection new.
	entities add: entity -> ('// Demo file, not covered' size + 2 to:
		 (aText findString: 'run(Account)') - 2).
	#( #( 'balance' 'int balance;' 'balance;' )
	   #( 'owner' 'String owner;' 'owner;' ) ) do: [ :each |
			entities add: (FamixJavaAttribute new
					 name: each first;
					 parentType: entity;
					 yourself) -> (span value: (each at: 2) value: (each at: 3)) ].
	#( #( 'deposit' 'void deposit' '  }' )
	   #( 'withdraw' 'void withdraw' '  }' )
	   #( 'getBalance' 'int getBalance' '}' ) ) do: [ :each |
			entities add: (FamixJavaMethod new
					 name: each first;
					 parentType: entity;
					 yourself) -> (span value: (each at: 2) value: (each at: 3)) ].
	^ entities
]

{ #category : 'examples' }
MMCCoveragePresenter class >> exampleText [
	"Answer the pseudo-Java text of the example: an uncovered first line, a class Account and an uncovered last line."

	^ String streamContents: [ :stream |
			  #( '// Demo file, not covered' 'class Account {'
			     '  int balance;' '  String owner;' '' '  void deposit(int n) {'
			     '    balance = balance + n;' '  }' '' '  void withdraw(int n) {'
			     '    balance = balance - n;' '  }' '' '  int getBalance() { return balance; }'
			     '}' 'run(Account); // not covered' )
				  do: [ :line | stream nextPutAll: line ]
				  separatedBy: [ stream nextPut: Character lf ] ]
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> forInventoryOn: aModel file: aFileReferenceOrString [
	"Answer a not opened presenter with the file selector of aModel, on aFileReferenceOrString. When aModel is nil or its inventory does not hold the file, answer the single file presenter of forModel:file:."

	| file files |
	aModel ifNil: [ ^ self forModel: aModel file: aFileReferenceOrString ].
	files := MMCModelFiles on: aModel.
	file := [
		        (self resolveFile: aFileReferenceOrString in: aModel)
			        asFileReference canonicalize ]
		        on: Error
		        do: [ :error | error return: nil ].
	^ (file notNil and: [ files files includes: file ])
		  ifTrue: [ self newOnInventory: files of: aModel startingAt: file ]
		  ifFalse: [ self forModel: aModel file: aFileReferenceOrString ]
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> forModel: aModel [
	"Answer a not opened presenter with the file selector on the inventory of the source files of aModel (MMCModelFiles). It shows the first file in sorted order; only this file is computed."

	^ self
		  newOnInventory: (MMCModelFiles on: aModel)
		  of: aModel
		  startingAt: nil
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> forModel: aModel file: aFileReferenceOrString [
	"Answer a not opened presenter on the coverage of the file aFileReferenceOrString read through the anchors of aModel. A relative path (String) is first resolved against the rootFolder of aModel. The presenter keeps aModel for the tree."

	| reader |
	reader := MMCAnchorReader
		          model: aModel
		          matcher: (MMCCanonicalPathMatcher forFile:
				           (self resolveFile: aFileReferenceOrString in: aModel)).
	^ self
		  on: (MMCFileCoverage fromReadResult: reader read)
		  model: aModel
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> newApplication: anApplication model: aCoverage [
	"Standard Spec2 construction: the coverage is set before the widgets are initialized."

	^ self newApplication: anApplication model: aCoverage theme: nil
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> newApplication: anApplication model: aCoverage theme: aSymbol [
	"Answer a presenter on aCoverage with the forced theme aSymbol (nil: default behavior)."

	^ self basicNew
		  application: anApplication;
		  setModelBeforeInitialization: aCoverage;
		  setInitialTheme: aSymbol;
		  initialize;
		  yourself
]

{ #category : 'examples' }
MMCCoveragePresenter class >> newExample [
	"Answer a not opened presenter on a fictive Java model (package bank, class Account, three methods, two attributes) and a pseudo-Java text with two uncovered zones. No file is read."

	| text entries aModel regions |
	text := self exampleText.
	entries := self exampleEntitiesFor: text.
	aModel := FamixJavaModel new.
	aModel add: entries first key parentPackage.
	entries do: [ :each | aModel add: each key ].
	regions := entries collect: [ :each |
			           MMCEntityRegion
				           entity: each key
				           anchor: nil
				           interval: each value
				           text:
				           (text copyFrom: each value first to: each value last) ].
	^ self
		  on: (MMCFileCoverage fromReadResult: (MMCAnchorReadResult
					    fileReference: 'Account.java' asFileReference
					    text: text
					    regions: regions
					    ignoredAnchors: #(  )
					    otherFileAnchorCount: 0))
		  model: aModel
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> newOnInventory: files of: aModel startingAt: aFileOrNil [
	"Answer a not opened presenter on the inventory files of aModel, showing aFileOrNil (a file of the inventory) or the first sorted file when nil."

	| file |
	file := aFileOrNil ifNil: [
		        files files
			        ifEmpty: [ nil ]
			        ifNotEmpty: [ :all | all first ] ].
	^ self basicNew
		  application: self currentApplication;
		  setMooseModelBeforeInitialization: aModel;
		  setFilesBeforeInitialization: files current: file;
		  setModelBeforeInitialization: (file
				   ifNil: [ self emptyCoverage ]
				   ifNotNil: [ files coverageFor: file ]);
		  setInitialTheme: nil;
		  initialize;
		  yourself
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> on: aCoverage [
	"Answer a not opened presenter on aCoverage. The theme is #dark until the window is built, then the one of the text background."

	^ self on: aCoverage theme: nil
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> on: aCoverage model: aMooseModelOrNil [
	"Answer a not opened presenter on aCoverage with the tree of aMooseModelOrNil (nil: empty tree)."

	^ self on: aCoverage model: aMooseModelOrNil theme: nil
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> on: aCoverage model: aMooseModelOrNil theme: aSymbol [
	"Answer a not opened presenter on aCoverage and aMooseModelOrNil with the forced theme aSymbol (#dark, #light or nil)."

	^ self basicNew
		  application: self currentApplication;
		  setMooseModelBeforeInitialization: aMooseModelOrNil;
		  setModelBeforeInitialization: aCoverage;
		  setInitialTheme: aSymbol;
		  initialize;
		  yourself
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> on: aCoverage theme: aSymbol [
	"Answer a not opened presenter on aCoverage with the forced theme aSymbol (#dark or #light), or the default behavior when nil."

	^ self
		  newApplication: self currentApplication
		  model: aCoverage
		  theme: aSymbol
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> openOn: aModel [
	"Open and answer a presenter with the file selector on aModel, on its first file in sorted order."

	^ (self forModel: aModel)
		  open;
		  yourself
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> openOn: aModel file: aFileReferenceOrString [
	"Open and answer a presenter on aFileReferenceOrString in aModel. With a model whose inventory holds the file, the presenter has the file selector and opens on this file; otherwise it is a single file presenter (see forModel:file:)."

	^ (self forInventoryOn: aModel file: aFileReferenceOrString)
		  open;
		  yourself
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> resolveFile: aFileReferenceOrString in: aModel [
	"Answer the file under the rootFolder of aModel when aFileReferenceOrString is a relative path of an existing file there, otherwise aFileReferenceOrString unchanged."

	| rootFolder candidate |
	(aFileReferenceOrString isString and: [
		 aFileReferenceOrString asFileReference isRelative ]) ifFalse: [
		^ aFileReferenceOrString ].
	rootFolder := aModel ifNotNil: [ :each | each rootFolder ].
	rootFolder ifNil: [ ^ aFileReferenceOrString ].
	candidate := rootFolder asFileReference resolve:
		             aFileReferenceOrString.
	^ candidate isFile
		  ifTrue: [ candidate ]
		  ifFalse: [ aFileReferenceOrString ]
]

{ #category : 'updating' }
MMCCoveragePresenter >> applyDecorators [
	"Put the decorators on the text widget. Without a widget nothing is done: they are put when the widget is built (a deferred action would pile up on each refresh)."

	textPresenter hasAdapter ifFalse: [ ^ self ].
	decorators do: [ :each |
		textPresenter addTextSegmentDecoration: each ]
]

{ #category : 'updating' }
MMCCoveragePresenter >> applyTheme: aSymbol [
	"Use the theme aSymbol (#dark or #light): rebuild the palette and the decorations. Raise an Error mentioning the theme, and change nothing, when aSymbol is unknown."

	self validateTheme: aSymbol.
	themeIsForced := true.
	aSymbol = theme ifTrue: [ ^ self ].
	theme := aSymbol.
	self buildPalette.
	self refreshHighlights
]

{ #category : 'updating' }
MMCCoveragePresenter >> buildDecorators [
	"One opaque decorator per segment of the plan, with the interval of the segment (inclusive, 1-based)."

	decorators := OrderedCollection new.
	plan segments do: [ :segment |
			decorators add: (SpTextPresenterDecorator forHighlight
					 highlightColor: (palette colorForSegment: segment);
					 interval: (segment interval first to: segment interval last);
					 yourself) ]
]

{ #category : 'updating' }
MMCCoveragePresenter >> buildDerivedState [
	"Compute plan, palette, uncovered zones and decorators of the current coverage."

	plan := MMCHighlightPlan for: fileCoverage.
	uncoveredRegions := fileCoverage uncoveredRegions.
	self buildPalette.
	self buildDecorators
]

{ #category : 'files' }
MMCCoveragePresenter >> buildFileWidgets [
	"Create the file selector widgets (filter, list, buttons, global summary). Without inventory they are disabled."

	isUpdatingFileList := false.
	fileFilterPresenter := self newTextInput.
	fileFilterPresenter placeholder: 'Filter files'.
	fileListPresenter := self instantiate: SpListPresenter.
	fileListPresenter display: [ :file | self fileLabelFor: file ].
	previousFileButton := self newButton.
	previousFileButton
		label: 'Previous';
		help: 'Previous file';
		action: [ self previousFile ].
	nextFileButton := self newButton.
	nextFileButton
		label: 'Next';
		help: 'Next file';
		action: [ self nextFile ].
	nextUncoveredFileButton := self newButton.
	nextUncoveredFileButton
		label: 'Next uncovered';
		help: 'Next file with uncovered zones';
		action: [ self nextUncoveredFile ].
	computeAllButton := self newButton.
	computeAllButton
		label: 'Compute all';
		help: 'Compute the coverage of every file';
		action: [ self computeAllFiles ].
	filesSummaryPresenter := self newLabel.
	self refreshFileWidgets
]

{ #category : 'tree' }
MMCCoveragePresenter >> buildNavigator [
	"Build the navigator on the current model and coverage, with the current filter."

	navigator := MMCModelNavigator on: model coverage: fileCoverage.
	navigator filter: treeFilter
]

{ #category : 'updating' }
MMCCoveragePresenter >> buildPalette [

	palette := MMCColorPalette
		           forTypeNames: fileCoverage typeNames
		           theme: theme
]

{ #category : 'initialization' }
MMCCoveragePresenter >> buildTreePresenter [
	"Create the tree of the Moose model (the roots are set by #refreshTree), its check box and its status label. The context menu is a block: a fresh menu is built at each popup."

	treePresenter := self instantiate: SpTreePresenter.
	treePresenter
		children: [ :each | navigator childrenOf: each ];
		display: [ :each | self treeLabelFor: each ];
		displayColor: [ :each | self treeColorFor: each ];
		contextMenu: [ self treeContextMenu ].
	wholeModelTogglePresenter := self newCheckBox.
	wholeModelTogglePresenter label: 'Whole model'.
	treeStatusPresenter := self newLabel.
	treeStatusText := ''
]

{ #category : 'updating' }
MMCCoveragePresenter >> clearDecorators [
	"Remove the decorations from the text widget and forget the decorators. Must be done before changing the text (quadratic and very slow otherwise)."

	textPresenter hasAdapter ifTrue: [
		textPresenter removeAllTextSegmentDecorations ].
	decorators := OrderedCollection new
]

{ #category : 'files' }
MMCCoveragePresenter >> computeAllButton [

	^ computeAllButton
]

{ #category : 'files' }
MMCCoveragePresenter >> computeAllFiles [
	"Compute the coverage of every file of the inventory (those already computed are kept) and refresh the labels and the global summary. The current file does not change."

	modelFiles ifNil: [ ^ self ].
	modelFiles computeAll.
	self refreshFileWidgets
]

{ #category : 'initialization' }
MMCCoveragePresenter >> connectPresenters [
	"Wire the events: the decorations when the text widget is built, the cursor when the window is displayed, the tree selection (once), the table selection, the whole model check box, the file list and the file filter."

	textPresenter whenBuiltDo: [ self textWidgetBuilt ].
	self whenDisplayDo: [ self subscribeToCursor ].
	treePresenter whenSelectionChangedDo: [ :selection |
		self treeSelectionChangedTo: selection selectedItem ].
	uncoveredListPresenter whenSelectionChangedDo: [ :selection |
		self selectUncoveredRegion: selection selectedItem ].
	wholeModelTogglePresenter whenChangedDo: [ :state |
		self toggleChanged: state ].
	fileListPresenter whenSelectionChangedDo: [ :selection |
		self fileListSelectionChangedTo: selection selectedItem ].
	fileFilterPresenter whenTextChangedDo: [ :text |
		self fileFilterChanged ]
]

{ #category : 'files' }
MMCCoveragePresenter >> coverage: aCoverage hasRegionOf: anEntity [

	^ aCoverage regions anySatisfy: [ :each | each entity == anEntity ]
]

{ #category : 'files' }
MMCCoveragePresenter >> currentFile [
	"Answer the file shown (canonical FileReference of the inventory), nil without inventory."

	^ currentFile
]

{ #category : 'files' }
MMCCoveragePresenter >> currentFileIndex [
	"Answer the rank of the current file among all the files, 0 without inventory."

	^ modelFiles
		  ifNil: [ 0 ]
		  ifNotNil: [ modelFiles files indexOf: currentFile ]
]

{ #category : 'actions' }
MMCCoveragePresenter >> cursorPositionIn: aTextArea [
	"Answer the position of the cursor: the start of the selection (pointIndex is the caret, or the last selected index + 1), at most the size of the text."

	| editor |
	editor := aTextArea editor.
	^ ((editor markIndex min: editor pointIndex) min: fileCoverage size)
		  max: 1
]

{ #category : 'accessing' }
MMCCoveragePresenter >> decorators [
	"Answer a copy of the text decorators of the plan segments (one per segment, in order)."

	^ decorators copy
]

{ #category : 'initialization' }
MMCCoveragePresenter >> defaultLayout [
	"Summary on top; below, three columns separated by two movable dividers (nested paned layouts): the left column (file selector above the tree of the model), the highlighted text, and the uncovered zones above the details. The sliders give about 0.22 / 0.50 / 0.28 of the width."

	^ SpBoxLayout newTopToBottom
		  add: summaryPresenter expand: false;
		  add: (SpPanedLayout newLeftToRight
				   positionOfSlider: 0.22;
				   first: self treeColumnLayout;
				   second: (SpPanedLayout newLeftToRight
						    positionOfSlider: 0.64;
						    first: textPresenter;
						    second: (SpBoxLayout newTopToBottom
								     add: uncoveredListPresenter;
								     add: detailsPresenter;
								     yourself);
						    yourself);
				   yourself);
		  yourself
]

{ #category : 'accessing' }
MMCCoveragePresenter >> detailsPresenter [

	^ detailsPresenter
]

{ #category : 'details' }
MMCCoveragePresenter >> detailsTextAt: aPosition [
	"Answer the details of the character at aPosition (1-based), or '' outside the text or without readable file. Lines: 'Position P (line L)', then one line per region containing the position, outermost first, '<indent><Type> <name>' with 2 spaces of indent per nesting depth (0-based) and the mooseName of the entity ('<unnamed>' when empty or absent). Without region: 'Uncovered zone A-B' in an uncovered zone, otherwise 'Not covered (blank)'."

	| regions |
	(fileCoverage isReadable and: [
			 aPosition isInteger and: [
				 aPosition between: 1 and: fileCoverage size ] ]) ifFalse: [ ^ '' ].
	regions := fileCoverage regionsAt: aPosition.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Position ';
				  print: aPosition;
				  nextPutAll: ' (line ';
				  print: (fileCoverage lineOf: aPosition);
				  nextPut: $).
			  regions
				  ifEmpty: [
						  stream cr.
						  self putUncoveredDetailsAt: aPosition on: stream ]
				  ifNotEmpty: [
						  regions do: [ :region |
								  stream cr.
								  self putLineOf: region on: stream ] ] ]
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> detailsTextFor: anEntityOrNil [
	"Answer the label of anEntityOrNil then one line per region in this file, or '' for nil."

	anEntityOrNil ifNil: [ ^ '' ].
	^ String streamContents: [ :stream |
			  | regions |
			  stream nextPutAll: (self treeLabelFor: anEntityOrNil).
			  regions := navigator regionsOf: anEntityOrNil.
			  regions ifEmpty: [
					  stream
						  cr;
						  nextPutAll: '  (no region in this file)' ].
			  regions do: [ :region |
					  stream cr.
					  self putRegionLineOf: region on: stream ] ]
]

{ #category : 'updating' }
MMCCoveragePresenter >> detectedThemeFor: aBackgroundColor [
	"Answer #dark or #light for aBackgroundColor (see MMCColorPalette class>>themeForBackground:). When it is nil or transparent (alpha = 0), use the background of the current Pharo theme; if that is not usable either, keep the current theme (#dark by default)."

	| color |
	color := aBackgroundColor.
	(color isNil or: [ color alpha = 0 ]) ifTrue: [
			color := [ Smalltalk ui theme backgroundColor ]
				         on: Error
				         do: [ nil ] ].
	(color isNil or: [ color alpha = 0 ]) ifTrue: [
		^ theme ifNil: [ #dark ] ].
	^ MMCColorPalette themeForBackground: color
]

{ #category : 'accessing' }
MMCCoveragePresenter >> fileCoverage [

	^ fileCoverage
]

{ #category : 'files' }
MMCCoveragePresenter >> fileFilterChanged [
	"The filter text changed: refresh the list, the current file does not change."

	isUpdatingFileList == true ifTrue: [ ^ self ].
	self refreshFileList
]

{ #category : 'files' }
MMCCoveragePresenter >> fileFilterPresenter [

	^ fileFilterPresenter
]

{ #category : 'files' }
MMCCoveragePresenter >> fileLabelFor: aFile [
	"Answer the label of aFile in the list: '<relative>  ?' until computed, '<relative>  P%' once computed, '<relative>  (warning sign) unreadable' when it cannot be read."

	| name |
	name := modelFiles relativeNameOf: aFile.
	(modelFiles isReadable: aFile) ifFalse: [
			^ name , '  ' , (String with: (Character value: 16r26A0))
			  , ' unreadable' ].
	^ name , '  '
	  , (self percentageLabelOf: (modelFiles summaryFor: aFile))
]

{ #category : 'files' }
MMCCoveragePresenter >> fileListPresenter [

	^ fileListPresenter
]

{ #category : 'files' }
MMCCoveragePresenter >> fileListSelectionChangedTo: aFileOrNil [
	"The user selected a file in the list: show it. Ignored while the list is refreshed or when nothing is selected."

	(isUpdatingFileList == true or: [ aFileOrNil isNil ]) ifTrue: [
		^ self ].
	self showFile: aFileOrNil
]

{ #category : 'initialization' }
MMCCoveragePresenter >> fileSelectorLayout [
	"Filter, file list (fixed height), two compact rows of buttons and the global summary."

	^ SpBoxLayout newTopToBottom
		  add: fileFilterPresenter expand: false;
		  add: fileListPresenter height: 150;
		  add: (SpBoxLayout newLeftToRight
				   add: previousFileButton;
				   add: nextFileButton;
				   yourself)
		  expand: false;
		  add: (SpBoxLayout newLeftToRight
				   add: nextUncoveredFileButton;
				   add: computeAllButton;
				   yourself)
		  expand: false;
		  add: filesSummaryPresenter expand: false;
		  yourself
]

{ #category : 'files' }
MMCCoveragePresenter >> fileToSwitchFor: anEntityOrNil [
	"Answer the file to switch to when anEntityOrNil is selected in the tree: nil when there is no inventory, no entity, or when the entity has a region in the current file; otherwise the first file of filesOf: (other than the current one) where it has a region, nil if there is none."

	(modelFiles isNil or: [ anEntityOrNil isNil ]) ifTrue: [ ^ nil ].
	(navigator regionsOf: anEntityOrNil) ifNotEmpty: [ ^ nil ].
	^ (modelFiles filesOf: anEntityOrNil)
		  detect: [ :each |
				  each ~= currentFile and: [
						  self
							  coverage: (modelFiles coverageFor: each)
							  hasRegionOf: anEntityOrNil ] ]
		  ifNone: [ nil ]
]

{ #category : 'files' }
MMCCoveragePresenter >> filesSummaryPresenter [

	^ filesSummaryPresenter
]

{ #category : 'updating' }
MMCCoveragePresenter >> fillWidgets [
	"Show the current coverage in the widgets (the decorations are not touched)."

	textPresenter text: fileCoverage text.
	textPresenter selectionInterval: (1 to: 0).
	uncoveredListPresenter items: uncoveredRegions.
	summaryPresenter label: self summaryText.
	detailsPresenter text: ''
]

{ #category : 'details' }
MMCCoveragePresenter >> formatPercentage: aNumber [
	"Answer aNumber with one decimal, for example '74.3'."

	^ aNumber printShowingDecimalPlaces: 1
]

{ #category : 'files' }
MMCCoveragePresenter >> globalSummaryText [
	"Answer 'Files: N (middle dot) computed K/N (middle dot) covered P%' (covered ? when no character is measured), empty without inventory. An unreadable file computed counts for K with no character."

	| summary separator |
	modelFiles ifNil: [ ^ '' ].
	summary := modelFiles globalSummary.
	separator := ' ' , (String with: (Character value: 16rB7)) , ' '.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Files: ';
				  print: modelFiles fileCount;
				  nextPutAll: separator;
				  nextPutAll: 'computed ';
				  print: summary fileCount;
				  nextPut: $/;
				  print: modelFiles fileCount;
				  nextPutAll: separator;
				  nextPutAll: 'covered ';
				  nextPutAll: (summary coveredPercentage
						   ifNil: [ '?' ]
						   ifNotNil: [ :percentage |
							   (self formatPercentage: percentage) , '%' ]) ]
]

{ #category : 'initialization' }
MMCCoveragePresenter >> initialExtent [

	^ 1300 @ 700
]

{ #category : 'initialization' }
MMCCoveragePresenter >> initializePresenters [
	"Build the widgets once and fill them with the coverage."

	theme ifNil: [ theme := #dark ].
	treeFilter := #covered.
	isUpdatingToggle := false.
	textPresenter := self newText.
	textPresenter beNotEditable.
	uncoveredListPresenter := self instantiate: SpListPresenter.
	uncoveredListPresenter display: [ :region |
		self labelForUncoveredRegion: region ].
	detailsPresenter := self newText.
	detailsPresenter beNotEditable.
	summaryPresenter := self newLabel.
	decorators := OrderedCollection new.
	self buildTreePresenter.
	self buildNavigator.
	self refreshTree.
	self buildDerivedState.
	self fillWidgets.
	self buildFileWidgets
]

{ #category : 'initialization' }
MMCCoveragePresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter initialExtent: self initialExtent
]

{ #category : 'tree' }
MMCCoveragePresenter >> inspectAction [
	"Answer the one-argument block evaluated with the entity to inspect (default: open the Pharo inspector)."

	^ inspectAction ifNil: [
		  inspectAction := [ :entity | entity inspect ] ]
]

{ #category : 'tree' }
MMCCoveragePresenter >> inspectAction: aBlock [
	"Set the one-argument block evaluated by the Inspect menu item with the selected entity."

	inspectAction := aBlock
]

{ #category : 'tree' }
MMCCoveragePresenter >> inspectTreeEntity [
	"Inspect the entity selected in the tree with the inspect action; do nothing without selection. Selections and synchronization state are untouched."

	| entity |
	entity := self selectedEntityInTree.
	entity ifNil: [ ^ self ].
	self inspectAction value: entity
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> isEchoOfTreeSelection: anInterval [
	"Answer true when anInterval is the interval of a region of the entity selected in the tree."

	| selected |
	selected := self selectedEntityInTree.
	selected ifNil: [ ^ false ].
	^ (navigator regionsOf: selected) anySatisfy: [ :region |
		  region interval = anInterval ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> isSynchronizing [
	"Answer true while a programmatic synchronisation tree <-> text is running."

	^ isSynchronizing == true
]

{ #category : 'details' }
MMCCoveragePresenter >> labelForUncoveredRegion: aRegion [
	"Answer 'Line L - N chars - preview' or 'Lines A-B - N chars - preview'. The preview is the text of the region with line ends replaced by spaces, cut after 60 characters and ended with an ellipsis."

	| lines preview |
	lines := aRegion startLine = aRegion endLine
		         ifTrue: [ 'Line ' , aRegion startLine printString ]
		         ifFalse: [
				         'Lines ' , aRegion startLine printString , '-'
				         , aRegion endLine printString ].
	preview := (aRegion interval first to:
	            (aRegion interval last min: aRegion interval first + 60))
		           collect: [ :i | fileCoverage text at: i ].
	preview := String withAll: preview.
	preview := preview collect: [ :each |
			           (each = Character cr or: [ each = Character lf ])
				           ifTrue: [ Character space ]
				           ifFalse: [ each ] ].
	preview size > 60 ifTrue: [ preview := (preview first: 60) , '…' ].
	^ lines , ' - ' , aRegion size printString , ' chars - ' , preview
]

{ #category : 'accessing' }
MMCCoveragePresenter >> model [
	"Answer the Moose model shown in the tree, or nil."

	^ model
]

{ #category : 'files' }
MMCCoveragePresenter >> modelFiles [
	"Answer the inventory of the source files of the model (MMCModelFiles), nil for a presenter without file selector."

	^ modelFiles
]

{ #category : 'details' }
MMCCoveragePresenter >> nameOfEntity: anEntity [
	"Answer the mooseName of anEntity as a String, '<unnamed>' when it is empty or when anEntity is not a Moose entity (Object answers a name for any object)."

	| name |
	anEntity isMooseEntity ifFalse: [ ^ '<unnamed>' ].
	name := anEntity mooseName asString.
	^ name ifEmpty: [ '<unnamed>' ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> navigator [
	"Answer the navigator on the model and the coverage (never nil)."

	^ navigator
]

{ #category : 'files' }
MMCCoveragePresenter >> nextFile [
	"Show the next file of the complete sorted list (the filter is ignored, unreadable files included). Do nothing on the last file."

	| index |
	index := self currentFileIndex.
	(index > 0 and: [ index < modelFiles fileCount ]) ifTrue: [
		self showFile: (modelFiles files at: index + 1) ]
]

{ #category : 'files' }
MMCCoveragePresenter >> nextFileButton [

	^ nextFileButton
]

{ #category : 'files' }
MMCCoveragePresenter >> nextUncoveredFile [
	"Show the next file, after the current one and looping, that has an uncovered zone. Unreadable files are skipped, the others are computed on demand. Do nothing when there is none other than the current file."

	| file |
	file := self nextUncoveredFileCandidate.
	file ifNil: [ ^ self refreshFileWidgets ].
	self showFile: file
]

{ #category : 'files' }
MMCCoveragePresenter >> nextUncoveredFileButton [

	^ nextUncoveredFileButton
]

{ #category : 'files' }
MMCCoveragePresenter >> nextUncoveredFileCandidate [
	"Answer the first file other than the current one, in loop order after it, that is readable and has an uncovered zone; nil if none. Stops at the first candidate."

	| index count |
	index := self currentFileIndex.
	index = 0 ifTrue: [ ^ nil ].
	count := modelFiles fileCount.
	1 to: count - 1 do: [ :offset |
			| file |
			file := modelFiles files at: index + offset - 1 \\ count + 1.
			((modelFiles isReadable: file) and: [
				 (modelFiles coverageFor: file) uncoveredRegions isNotEmpty ])
				ifTrue: [ ^ file ] ].
	^ nil
]

{ #category : 'accessing' }
MMCCoveragePresenter >> palette [

	^ palette
]

{ #category : 'files' }
MMCCoveragePresenter >> percentageLabelOf: aCoverageOrNil [
	"Answer '?' for a coverage not computed (nil) or without character, else the percentage with one decimal and %."

	| percentage |
	percentage := aCoverageOrNil ifNotNil: [ :each |
		              each coveredPercentage ].
	^ percentage
		  ifNil: [ '?' ]
		  ifNotNil: [ (self formatPercentage: percentage) , '%' ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> plan [

	^ plan
]

{ #category : 'files' }
MMCCoveragePresenter >> previousFile [
	"Show the previous file of the complete sorted list (the filter is ignored, unreadable files included). Do nothing on the first file."

	| index |
	index := self currentFileIndex.
	index > 1 ifTrue: [ self showFile: (modelFiles files at: index - 1) ]
]

{ #category : 'files' }
MMCCoveragePresenter >> previousFileButton [

	^ previousFileButton
]

{ #category : 'details' }
MMCCoveragePresenter >> putLineOf: aRegion on: aStream [

	aStream
		nextPutAll: (String
				 new: 2 * (fileCoverage depthOf: aRegion)
				 withAll: Character space);
		nextPutAll: aRegion typeName;
		nextPut: Character space;
		nextPutAll: (self nameOfEntity: aRegion entity)
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> putRegionLineOf: aRegion on: aStream [
	"Write '  Region <a>-<b> (line <l1>-<l2>)' (one line number when the region is on one line)."

	| first last firstLine lastLine |
	first := aRegion interval first.
	last := aRegion interval last.
	firstLine := fileCoverage lineOf: first.
	lastLine := fileCoverage lineOf: last.
	aStream
		nextPutAll: '  Region ';
		print: first;
		nextPut: $-;
		print: last;
		nextPutAll: ' (line ';
		print: firstLine.
	lastLine = firstLine ifFalse: [
			aStream
				nextPut: $-;
				print: lastLine ].
	aStream nextPut: $)
]

{ #category : 'details' }
MMCCoveragePresenter >> putUncoveredDetailsAt: aPosition on: aStream [

	| zone |
	zone := uncoveredRegions
		        detect: [ :each | each interval includes: aPosition ]
		        ifNone: [ nil ].
	zone
		ifNil: [ aStream nextPutAll: 'Not covered (blank)' ]
		ifNotNil: [
				aStream
					nextPutAll: 'Uncovered zone ';
					print: zone interval first;
					nextPut: $-;
					print: zone interval last ]
]

{ #category : 'files' }
MMCCoveragePresenter >> refreshFileButtons [
	"Enable the file widgets when there is an inventory, the navigation buttons according to the rank of the current file."

	| index hasFiles |
	hasFiles := modelFiles notNil.
	index := self currentFileIndex.
	fileFilterPresenter enabled: hasFiles.
	fileListPresenter enabled: hasFiles.
	nextUncoveredFileButton enabled: hasFiles.
	computeAllButton enabled: hasFiles.
	previousFileButton enabled: index > 1.
	nextFileButton enabled:
		(hasFiles and: [ index < modelFiles fileCount ])
]

{ #category : 'files' }
MMCCoveragePresenter >> refreshFileList [
	"Show the visible files with their labels and select the current file when it is visible, without reacting to the selection."

	| shown |
	shown := self visibleFiles.
	isUpdatingFileList := true.
	[
		fileListPresenter items: shown.
		(modelFiles notNil and: [ shown includes: currentFile ]) ifTrue: [
			fileListPresenter selectItem: currentFile ] ] ensure: [
		isUpdatingFileList := false ]
]

{ #category : 'files' }
MMCCoveragePresenter >> refreshFileWidgets [
	"Bring the file selector (list, summary, buttons) and the window title up to date."

	self refreshFileList.
	self refreshFilesSummary.
	self refreshFileButtons.
	self refreshWindowTitle
]

{ #category : 'files' }
MMCCoveragePresenter >> refreshFilesSummary [

	filesSummaryPresenter label: self globalSummaryText
]

{ #category : 'updating' }
MMCCoveragePresenter >> refreshHighlights [
	"Rebuild the decorators from the plan and the palette and put them on the text. Idempotent."

	self clearDecorators.
	self buildDecorators.
	self applyDecorators
]

{ #category : 'tree' }
MMCCoveragePresenter >> refreshTree [
	"Recompute the roots of the tree from the navigator, clear its selection and update the status message and the check box."

	treePresenter roots: navigator roots asArray.
	treePresenter unselectAll.
	self updateTreeStatus
]

{ #category : 'files' }
MMCCoveragePresenter >> refreshWindowTitle [
	"Make the open window follow the title of the current file."

	self window ifNotNil: [ :aWindow | aWindow title: self windowTitle ]
]

{ #category : 'tree' }
MMCCoveragePresenter >> rootFolderText [
	"Answer the root folder of the model as a string, whatever its type (FileReference, String or nil)."

	| rootFolder |
	rootFolder := model ifNotNil: [ :aModel | aModel rootFolder ].
	rootFolder ifNil: [ ^ 'not set' ].
	^ rootFolder isString
		  ifTrue: [ rootFolder ]
		  ifFalse: [ rootFolder pathString ]
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> selectEntityInTree: anEntity [
	"Select anEntity in the tree (and unfold its ancestors when the tree is displayed). Clear the selection when anEntity is nil or not visible with the current filter. When the selection triggered a file switch, the tree was rebuilt and the path used is stale: the selection is done again with the new path."

	self selectPathOf: anEntity.
	(anEntity notNil and: [ self selectedEntityInTree ~~ anEntity ])
		ifTrue: [ self selectPathOf: anEntity ]
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> selectPathOf: anEntity [
	"Select the path of anEntity in the current tree, clear the selection when it is nil or not visible."

	| path |
	path := anEntity ifNotNil: [ navigator pathTo: anEntity ].
	path ifNil: [ ^ treePresenter unselectAll ].
	treePresenter hasAdapter ifTrue: [
			1 to: path size - 1 do: [ :each |
			treePresenter expandPath: (path first: each) ] ].
	treePresenter selectPath: path
]

{ #category : 'actions' }
MMCCoveragePresenter >> selectUncoveredRegion: aRegion [
	"Select the interval of aRegion in the text (the text scrolls to it). Do nothing for nil."

	aRegion ifNil: [ ^ self ].
	textPresenter selectionInterval: aRegion interval
]

{ #category : 'tree' }
MMCCoveragePresenter >> selectedEntityInTree [
	"Answer the entity selected in the tree, or nil."

	^ treePresenter selection selectedItem
]

{ #category : 'cursor' }
MMCCoveragePresenter >> selectionIntervalIn: aTextArea [
	"Answer the selected interval of the editor: from the first selected index to the last one (an empty interval n to: n - 1 for a caret)."

	| editor |
	editor := aTextArea editor.
	^ (editor markIndex min: editor pointIndex) to:
	  (editor markIndex max: editor pointIndex) - 1
]

{ #category : 'files' }
MMCCoveragePresenter >> setFilesBeforeInitialization: aModelFiles current: aFile [
	"Set the inventory and the current file before the widgets are initialized."

	modelFiles := aModelFiles.
	currentFile := aFile
]

{ #category : 'initialization' }
MMCCoveragePresenter >> setInitialTheme: aSymbol [
	"Force the theme (nil keeps the default one, detected when the window is built). Raise an Error on an unknown theme."

	aSymbol ifNotNil: [ self validateTheme: aSymbol ].
	theme := aSymbol.
	themeIsForced := aSymbol notNil
]

{ #category : 'initialization' }
MMCCoveragePresenter >> setModelBeforeInitialization: aCoverage [

	fileCoverage := aCoverage
]

{ #category : 'accessing' }
MMCCoveragePresenter >> setMooseModelBeforeInitialization: aMooseModelOrNil [
	"Set the Moose model before the widgets are initialized."

	model := aMooseModelOrNil
]

{ #category : 'details' }
MMCCoveragePresenter >> showDetailsAt: aPosition [
	"Show the details of aPosition in the details widget."

	detailsPresenter text: (self detailsTextAt: aPosition)
]

{ #category : 'files' }
MMCCoveragePresenter >> showFile: aFile [
	"Show the coverage of aFile, a file of the inventory (computed on demand, cached). Do nothing without inventory, for an unknown file or for the current file. The tree selection is kept when its entity is still visible."

	| selected |
	modelFiles ifNil: [ ^ self ].
	(aFile notNil and: [ modelFiles files includes: aFile ]) ifFalse: [
		^ self ].
	aFile = currentFile ifTrue: [ ^ self ].
	selected := self selectedEntityInTree.
	currentFile := aFile.
	self updateFileCoverage: (modelFiles coverageFor: aFile).
	self synchronizingDo: [ self selectEntityInTree: selected ].
	self refreshFileWidgets
]

{ #category : 'cursor' }
MMCCoveragePresenter >> subscribeToCursor [
	"Called when the window is displayed: follow the selection of the text area (Rubric announces RubSelectionChanged; the Spec selection hook does not see a mere cursor move) and synchronise the tree and the details with it."

	| textArea |
	textPresenter hasAdapter ifFalse: [ ^ self ].
	textArea := textPresenter adapter widget textArea.
	textArea announcer unsubscribe: self.
	textArea announcer
		when: RubSelectionChanged
		do: [
		self textSelectionChangedTo: (self selectionIntervalIn: textArea) ]
		for: self
]

{ #category : 'accessing' }
MMCCoveragePresenter >> summaryPresenter [

	^ summaryPresenter
]

{ #category : 'details' }
MMCCoveragePresenter >> summaryText [
	"Answer the one-line summary. Unreadable file: 'Unreadable file: ...'. Otherwise
	'Covered C/N characters (P %) | significant S/T (Q %) | U uncovered zone(s) | I ignored anchor(s) | O anchor(s) in other files'
	with percentages on one decimal, and 'n/a' instead of 'Q %' when there is no significant character."

	| significant |
	fileCoverage isReadable ifFalse: [ ^ self unreadableSummaryText ].
	significant := fileCoverage significantPercentage
		               ifNil: [ 'n/a' ]
		               ifNotNil: [ :percentage |
		               (self formatPercentage: percentage) , ' %' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Covered ';
				  print: fileCoverage coveredSet size;
				  nextPut: $/;
				  print: fileCoverage size;
				  nextPutAll: ' characters (';
				  nextPutAll:
					  (self formatPercentage: fileCoverage coveredPercentage);
				  nextPutAll: ' %) | significant ';
				  print: fileCoverage coveredSignificantSet size;
				  nextPut: $/;
				  print: fileCoverage significantSet size;
				  nextPutAll: ' (';
				  nextPutAll: significant;
				  nextPutAll: ') | ';
				  print: uncoveredRegions size;
				  nextPutAll: ' uncovered zone(s) | ';
				  print: fileCoverage ignoredAnchors size;
				  nextPutAll: ' ignored anchor(s) | ';
				  print: fileCoverage otherFileAnchorCount;
				  nextPutAll: ' anchor(s) in other files' ]
]

{ #category : 'files' }
MMCCoveragePresenter >> switchToFile: aFile selecting: anEntity [
	"Show aFile, then select the first region of anEntity in the text and the entity in the tree, without echo."

	self synchronizingDo: [
			self showFile: aFile.
			self selectEntityInTree: anEntity.
			(navigator firstRegionOf: anEntity) ifNotNil: [ :region |
				textPresenter selectionInterval: region interval ].
			detailsPresenter text: (self detailsTextFor: anEntity) ]
]

{ #category : 'tree' }
MMCCoveragePresenter >> syncToggleWithFilter [
	"Put the check box in the state of the filter, without reacting to its own event."

	isUpdatingToggle == true ifTrue: [ ^ self ].
	isUpdatingToggle := true.
	[ wholeModelTogglePresenter state: treeFilter = #all ] ensure: [
		isUpdatingToggle := false ]
]

{ #category : 'files' }
MMCCoveragePresenter >> synchronizingDo: aBlock [
	"Evaluate aBlock with isSynchronizing true (no echo of the tree or text events), restoring the previous state."

	| previous |
	previous := self isSynchronizing.
	isSynchronizing := true.
	aBlock ensure: [ isSynchronizing := previous ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> textPresenter [

	^ textPresenter
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> textSelectionChangedTo: anInterval [
	"The text selection changed: select in the tree the deepest entity at the start of anInterval and show its details; when there is none, clear the tree selection and show the details of the position. A nil interval is ignored. An interval that is exactly a region of the selected entity is the echo of the tree selection: ignored (Engine and its attribute share the same first character)."

	| position entity |
	anInterval ifNil: [ ^ self ].
	self isSynchronizing ifTrue: [ ^ self ].
	fileCoverage isReadable ifFalse: [ ^ self ].
	(self isEchoOfTreeSelection: anInterval) ifTrue: [ ^ self ].
	position := (anInterval first max: 1) min: fileCoverage size.
	isSynchronizing := true.
	[
		entity := navigator deepestEntityAt: position.
		entity
			ifNil: [
					treePresenter unselectAll.
					detailsPresenter text: (self detailsTextAt: position) ]
			ifNotNil: [
					self selectEntityInTree: entity.
					detailsPresenter text: (self detailsTextFor: entity) ] ] ensure: [
		isSynchronizing := false ]
]

{ #category : 'updating' }
MMCCoveragePresenter >> textWidgetBuilt [
	"The text widget exists (window opening): if the theme is not forced, take the one of the text widget background, then put the decorations."

	themeIsForced == true ifFalse: [
			| detected |
			detected := self detectedThemeFor: self widgetBackgroundColor.
			detected = theme ifFalse: [
					theme := detected.
					self buildPalette.
					self buildDecorators ] ].
	self applyDecorators
]

{ #category : 'accessing' }
MMCCoveragePresenter >> theme [
	"Answer #dark or #light."

	^ theme
]

{ #category : 'tree' }
MMCCoveragePresenter >> toggleChanged: aBoolean [
	"The user (or a click) changed the check box."

	isUpdatingToggle == true ifTrue: [ ^ self ].
	self treeFilter: (aBoolean
			 ifTrue: [ #all ]
			 ifFalse: [ #covered ])
]

{ #category : 'tree' }
MMCCoveragePresenter >> treeColorFor: anEntity [
	"Answer nil (default color) for an entity with a region of its own, a neutral grey otherwise."

	^ (navigator isCovered: anEntity)
		  ifTrue: [ nil ]
		  ifFalse: [ self uncoveredTreeColor ]
]

{ #category : 'initialization' }
MMCCoveragePresenter >> treeColumnLayout [
	"Left column: the file selector (filter, list, buttons, global summary) above the check box, the status and the tree."

	^ SpBoxLayout newTopToBottom
		  add: self fileSelectorLayout expand: false;
		  add: wholeModelTogglePresenter expand: false;
		  add: treeStatusPresenter expand: false;
		  add: treePresenter;
		  yourself
]

{ #category : 'tree' }
MMCCoveragePresenter >> treeContextMenu [
	"Answer a new menu with the only item Inspect, enabled when an entity is selected in the tree (a right click selects the row first)."

	| menu |
	menu := SpMenuPresenter new.
	menu addGroup: [ :group |
			group addItem: [ :item |
					item
						name: 'Inspect';
						enabled: self selectedEntityInTree notNil;
						action: [ self inspectTreeEntity ] ] ].
	^ menu
]

{ #category : 'accessing' }
MMCCoveragePresenter >> treeFilter [
	"Answer #covered (entities of the coverage and their ancestors) or #all (whole model)."

	^ treeFilter
]

{ #category : 'tree' }
MMCCoveragePresenter >> treeFilter: aSymbol [
	"Show only the covered entities (#covered) or the whole model (#all). Updates the navigator, the roots and the check box."

	(#( #covered #all ) includes: aSymbol) ifFalse: [
			^ self error: 'Invalid tree filter (expected #covered or #all): '
				  , aSymbol printString ].
	aSymbol = treeFilter ifTrue: [ ^ self ].
	treeFilter := aSymbol.
	navigator filter: aSymbol.
	self refreshTree.
	self syncToggleWithFilter
]

{ #category : 'tree' }
MMCCoveragePresenter >> treeLabelFor: anEntity [
	"Answer '<type> <label>' for anEntity."

	^ (navigator typeNameOf: anEntity) , ' '
	  , (navigator labelOf: anEntity)
]

{ #category : 'accessing' }
MMCCoveragePresenter >> treePresenter [

	^ treePresenter
]

{ #category : 'synchronisation' }
MMCCoveragePresenter >> treeSelectionChangedTo: anEntityOrNil [
	"The tree selection changed. When the entity has no region in the current file but has some in another file, switch to the first such file and select its first region (see switchToFile:selecting:). Otherwise select the first region of the entity in the text (unchanged when it has none) and show its details."

	| file |
	self isSynchronizing ifTrue: [ ^ self ].
	file := self fileToSwitchFor: anEntityOrNil.
	file ifNotNil: [ ^ self switchToFile: file selecting: anEntityOrNil ].
	self synchronizingDo: [
			anEntityOrNil ifNotNil: [
					(navigator firstRegionOf: anEntityOrNil) ifNotNil: [ :region |
						textPresenter selectionInterval: region interval ] ].
			detailsPresenter text: (self detailsTextFor: anEntityOrNil) ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> treeStatusPresenter [
	"Answer the label shown between the check box and the tree (empty states)."

	^ treeStatusPresenter
]

{ #category : 'accessing' }
MMCCoveragePresenter >> treeStatusText [
	"Answer the message of the empty states of the tree, or an empty string."

	^ treeStatusText ifNil: [ '' ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> uncoveredListPresenter [

	^ uncoveredListPresenter
]

{ #category : 'tree' }
MMCCoveragePresenter >> uncoveredTreeColor [
	"Opaque grey, readable on dark and light backgrounds."

	^ Color gray: 0.55
]

{ #category : 'summary' }
MMCCoveragePresenter >> unreadableSummaryText [
	"Answer the summary of an unreadable file; with a Moose model, remind where the relative anchors are resolved."

	| base |
	base := 'Unreadable file: no anchor of the model designates it, or its text is empty'.
	^ model
		  ifNil: [ base ]
		  ifNotNil: [ base , ' (rootFolder: ' , self rootFolderText , ')' ]
]

{ #category : 'updating' }
MMCCoveragePresenter >> updateFileCoverage: aCoverage [
	"Replace the coverage and everything derived from it (plan, palette, text, uncovered zones, summary, details, decorations, navigator and tree roots). The theme, the Moose model and the tree filter are kept. Order matters: decorations are removed before the text changes, and put back last."

	self clearDecorators.
	fileCoverage := aCoverage.
	plan := MMCHighlightPlan for: fileCoverage.
	uncoveredRegions := fileCoverage uncoveredRegions.
	self buildPalette.
	self fillWidgets.
	self buildNavigator.
	self refreshTree.
	self buildDecorators.
	self applyDecorators
]

{ #category : 'updating' }
MMCCoveragePresenter >> updateFileCoverage: aCoverage model: aMooseModelOrNil [
	"Replace the Moose model and the coverage; the theme and the tree filter are kept."

	model := aMooseModelOrNil.
	self updateFileCoverage: aCoverage
]

{ #category : 'tree' }
MMCCoveragePresenter >> updateTreeStatus [
	"Show the message of the empty states: no Moose model, or no entity of the model anchored in the file."

	treeStatusText := model
		                  ifNil: [
		                  'No Moose model: open with MMCCoveragePresenter openOn:file:' ]
		                  ifNotNil: [
				                  navigator roots isEmpty
					                  ifTrue: [
							                  'No entity of the model is anchored in this file (rootFolder: '
							                  , self rootFolderText , ')' ]
					                  ifFalse: [ '' ] ].
	treeStatusPresenter label: treeStatusText.
	wholeModelTogglePresenter enabled: model notNil
]

{ #category : 'initialization' }
MMCCoveragePresenter >> validateTheme: aSymbol [

	(#( dark light ) includes: aSymbol) ifFalse: [
			self error:
				'Unknown theme ' , aSymbol printString
				, ' (expected #dark or #light)' ]
]

{ #category : 'files' }
MMCCoveragePresenter >> visibleFiles [
	"Answer the files whose relative name contains the filter text (ignoring case); all the files when the filter is empty, none without inventory. The absolute path is not looked at."

	| pattern |
	modelFiles ifNil: [ ^ #(  ) ].
	pattern := fileFilterPresenter text asString asLowercase.
	pattern ifEmpty: [ ^ modelFiles files asArray ].
	^ modelFiles files select: [ :each |
			  (modelFiles relativeNameOf: each) asLowercase includesSubstring:
				  pattern ]
]

{ #category : 'accessing' }
MMCCoveragePresenter >> wholeModelTogglePresenter [

	^ wholeModelTogglePresenter
]

{ #category : 'updating' }
MMCCoveragePresenter >> widgetBackgroundColor [
	"Answer the background color of the text widget itself (opaque, unlike textArea backgroundColor), or nil when the adapter or widget is not available."

	^ [ textPresenter adapter widget color ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'initialization' }
MMCCoveragePresenter >> windowTitle [
	"Answer windowTitleText with an inventory; otherwise 'Coverage - <file name>', or 'Coverage - unreadable file' when there is no file."

	modelFiles ifNotNil: [ ^ self windowTitleText ].
	^ 'Coverage - ' , (fileCoverage fileReference
		   ifNil: [ 'unreadable file' ]
		   ifNotNil: [ :file | file basename ])
]

{ #category : 'files' }
MMCCoveragePresenter >> windowTitleText [
	"Answer 'Coverage - <relative name> (i/N)' (i: rank of the current file among all the files, N: number of files whatever the filter), or 'Coverage' without inventory."

	(modelFiles isNil or: [ currentFile isNil ]) ifTrue: [ ^ 'Coverage' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Coverage - ';
				  nextPutAll: (modelFiles relativeNameOf: currentFile);
				  nextPutAll: ' (';
				  print: (modelFiles files indexOf: currentFile);
				  nextPut: $/;
				  print: modelFiles fileCount;
				  nextPut: $) ]
]
