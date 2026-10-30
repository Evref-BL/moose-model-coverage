"
I show a file with the text covered by the FileAnchors of a Moose model highlighted (one color per entity type and nesting depth, a specific color for the uncovered text). The window has three columns. On the left, the tree of the Moose model (a MMCModelNavigator): by default only the entities covered by the file and their ancestors are shown; the ""Whole model"" check box (or #treeFilter: #all) shows the entire model; entities without a region of their own are drawn in grey. In the middle, the highlighted text. On the right, the list of the uncovered zones (selecting one selects it in the text) and the details of the entities at the cursor position. On top, a summary of the coverage. The coverage is an MMCFileCoverage; the Moose model may be nil (empty tree). Build me with #on:, #on:theme:, #on:model:, #on:model:theme:, #forModel:file: or #openOn:file:; #updateFileCoverage: keeps the model and the tree filter, #updateFileCoverage:model: replaces the model too.

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
		'inspectAction'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

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
MMCCoveragePresenter class >> openOn: aModel file: aFileReferenceOrString [
	"Open and answer a presenter on the coverage of the file aFileReferenceOrString in aModel."

	^ (self forModel: aModel file: aFileReferenceOrString)
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

{ #category : 'initialization' }
MMCCoveragePresenter >> connectPresenters [
	"Wire the events: the decorations when the text widget is built, the cursor when the window is displayed, the tree selection (once), the table selection, the whole model check box."

	textPresenter whenBuiltDo: [ self textWidgetBuilt ].
	self whenDisplayDo: [ self subscribeToCursor ].
	treePresenter whenSelectionChangedDo: [ :selection |
		self treeSelectionChangedTo: selection selectedItem ].
	uncoveredListPresenter whenSelectionChangedDo: [ :selection |
		self selectUncoveredRegion: selection selectedItem ].
	wholeModelTogglePresenter whenChangedDo: [ :state |
		self toggleChanged: state ]
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

{ #category : 'layout' }
MMCCoveragePresenter >> defaultLayout [
	"Summary on top; below, three columns separated by two movable dividers (nested paned layouts): the tree of the model (check box and status above), the highlighted text, and the uncovered zones above the details. The sliders give about 0.22 / 0.50 / 0.28 of the width."

	^ SpBoxLayout newTopToBottom
		  add: summaryPresenter expand: false;
		  add: (SpPanedLayout newLeftToRight
				   positionOfSlider: 0.22;
				   first: (SpBoxLayout newTopToBottom
						    add: wholeModelTogglePresenter expand: false;
						    add: treeStatusPresenter expand: false;
						    add: treePresenter;
						    yourself);
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
	self fillWidgets
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

{ #category : 'accessing' }
MMCCoveragePresenter >> palette [

	^ palette
]

{ #category : 'accessing' }
MMCCoveragePresenter >> plan [

	^ plan
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

{ #category : 'tree' }
MMCCoveragePresenter >> selectEntityInTree: anEntity [
	"Select anEntity in the tree (and unfold its ancestors when the tree is displayed). Clear the selection when anEntity is nil or not visible with the current filter."

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

{ #category : 'tree' }
MMCCoveragePresenter >> syncToggleWithFilter [
	"Put the check box in the state of the filter, without reacting to its own event."

	isUpdatingToggle == true ifTrue: [ ^ self ].
	isUpdatingToggle := true.
	[ wholeModelTogglePresenter state: treeFilter = #all ] ensure: [
		isUpdatingToggle := false ]
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
	"The tree selection changed: select the first region of the entity in the text (unchanged when it has none) and show its details."

	self isSynchronizing ifTrue: [ ^ self ].
	isSynchronizing := true.
	[
		anEntityOrNil ifNotNil: [
				(navigator firstRegionOf: anEntityOrNil) ifNotNil: [ :region |
					textPresenter selectionInterval: region interval ] ].
		detailsPresenter text: (self detailsTextFor: anEntityOrNil) ]
		ensure: [ isSynchronizing := false ]
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

{ #category : 'accessing' }
MMCCoveragePresenter >> windowTitle [
	"Answer 'Coverage - <file name>', or 'Coverage - unreadable file' when there is no file."

	^ 'Coverage - ' , (fileCoverage fileReference
		   ifNil: [ 'unreadable file' ]
		   ifNotNil: [ :file | file basename ])
]
