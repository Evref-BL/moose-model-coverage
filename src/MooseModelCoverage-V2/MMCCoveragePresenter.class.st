"
I show a file with the text covered by the FileAnchors of a Moose model highlighted (one color per entity type and nesting depth, a specific color for the uncovered text). On the right, the list of the uncovered zones (selecting one selects it in the text) and the details of the entities at the cursor position. On top, a summary of the coverage. The model is an MMCFileCoverage. Build me with #on:, #on:theme:, #forModel:file: or #openOn:file:.

Known limits
- Performance in a real window: about 1.4 s to open and 0.3 s to change the file for 60 000 characters / 600 regions; about 4 s and 1.3 s for 200 000 / 2 000; about 11 s and 7 s for 500 000 / 7 000 (removing the Rubric segments with removeAllTextSegmentDecorations is quadratic).
- The highlight colors are chosen when the window opens, from the background of the text widget. A change of Pharo theme while the window is open is not followed: use applyTheme:.
- The real mouse click was not automated: the cursor tracking is verified by programmatic selection.
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
		'themeIsForced'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'examples' }
MMCCoveragePresenter class >> example [
	"Open the presenter on a standalone fictive coverage (no file, no model): a class, three methods, two attributes, and two uncovered zones (the first and the last lines). Returns the presenter."

	| text span entries regions |
	text := String streamContents: [ :stream |
			        #( '// Demo file, not covered' 'class Account {'
			           '  int balance;' '  String owner;' '' '  void deposit(int n) {'
			           '    balance = balance + n;'
			           '  }' '' '  void withdraw(int n) {'
			           '    balance = balance - n;'
			           '  }' '' '  int getBalance() { return balance; }'
			           '}' 'run(Account); // not covered' )
				        do: [ :line | stream nextPutAll: line ]
				        separatedBy: [ stream nextPut: Character lf ] ].
	"From the first start token to the end of the first end token found after it."
	span := [ :startToken :endToken |
		        | start |
		        start := text findString: startToken.
		        start to:
		        (text findString: endToken startingAt: start)
		        + endToken size - 1 ].
	entries := {
		           ((FamixJavaClass new
			             name: 'Account';
			             yourself)
		            -> (1 + ('// Demo file, not covered' size + 1) to:
			             (text findString: 'run(Account)') - 2)).
		           ((FamixJavaAttribute new
			             name: 'balance';
			             yourself)
		            -> (span value: 'int balance;' value: 'balance;')).
		           ((FamixJavaAttribute new
			             name: 'owner';
			             yourself)
		            -> (span value: 'String owner;' value: 'owner;')).
		           ((FamixJavaMethod new
			             name: 'deposit';
			             yourself) -> (span value: 'void deposit' value: '  }')).
		           ((FamixJavaMethod new
			             name: 'withdraw';
			             yourself)
		            -> (span value: 'void withdraw' value: '  }')).
		           ((FamixJavaMethod new
			             name: 'getBalance';
			             yourself) -> (span value: 'int getBalance' value: '}')) }.
	regions := entries collect: [ :association |
			           MMCEntityRegion
				           entity: association key
				           anchor: nil
				           interval: association value
				           text:
				           (text
					            copyFrom: association value first
					            to: association value last) ].
	^ (self on: (MMCFileCoverage fromReadResult: (MMCAnchorReadResult
						     fileReference: 'Account.java' asFileReference
						     text: text
						     regions: regions
						     ignoredAnchors: #(  )
						     otherFileAnchorCount: 0)))
		  open;
		  yourself
]

{ #category : 'instance creation' }
MMCCoveragePresenter class >> forModel: aModel file: aFileReferenceOrString [
	"Answer a not opened presenter on the coverage of the file aFileReferenceOrString read through the anchors of aModel."

	| reader |
	reader := MMCAnchorReader
		          model: aModel
		          matcher:
		          (MMCCanonicalPathMatcher forFile: aFileReferenceOrString).
	^ self on: (MMCFileCoverage fromReadResult: reader read)
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

{ #category : 'instance creation' }
MMCCoveragePresenter class >> on: aCoverage [
	"Answer a not opened presenter on aCoverage. The theme is #dark until the window is built, then the one of the text background."

	^ self on: aCoverage theme: nil
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

{ #category : 'updating' }
MMCCoveragePresenter >> buildPalette [

	palette := MMCColorPalette
		           forTypeNames: fileCoverage typeNames
		           theme: theme
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
	"Wire the events: the decorations when the text widget is built, the cursor when the window is displayed, the table selection."

	textPresenter whenBuiltDo: [ self textWidgetBuilt ].
	self whenDisplayDo: [ self subscribeToCursor ].
	uncoveredListPresenter whenSelectionChangedDo: [ :selection |
		self selectUncoveredRegion: selection selectedItem ]
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
	"Summary on top; below, the highlighted text on the left and a column with the uncovered zones above the details on the right."

	^ SpBoxLayout newTopToBottom
		  add: summaryPresenter expand: false;
		  add: (SpBoxLayout newLeftToRight
				   add: textPresenter;
				   add: (SpBoxLayout newTopToBottom
						    add: uncoveredListPresenter;
						    add: detailsPresenter;
						    yourself)
				   width: 340;
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

{ #category : 'accessing' }
MMCCoveragePresenter >> initialExtent [

	^ 1000 @ 650
]

{ #category : 'initialization' }
MMCCoveragePresenter >> initializePresenters [
	"Build the widgets once and fill them with the coverage."

	theme ifNil: [ theme := #dark ].
	textPresenter := self newText.
	textPresenter beNotEditable.
	uncoveredListPresenter := self instantiate: SpListPresenter.
	uncoveredListPresenter display: [ :region |
		self labelForUncoveredRegion: region ].
	detailsPresenter := self newText.
	detailsPresenter beNotEditable.
	summaryPresenter := self newLabel.
	decorators := OrderedCollection new.
	self buildDerivedState.
	self fillWidgets
]

{ #category : 'initialization' }
MMCCoveragePresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter initialExtent: self initialExtent
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

{ #category : 'details' }
MMCCoveragePresenter >> nameOfEntity: anEntity [
	"Answer the mooseName of anEntity as a String, '<unnamed>' when it is empty or when anEntity is not a Moose entity (Object answers a name for any object)."

	| name |
	anEntity isMooseEntity ifFalse: [ ^ '<unnamed>' ].
	name := anEntity mooseName asString.
	^ name ifEmpty: [ '<unnamed>' ]
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

{ #category : 'actions' }
MMCCoveragePresenter >> selectUncoveredRegion: aRegion [
	"Select the interval of aRegion in the text (the text scrolls to it). Do nothing for nil."

	aRegion ifNil: [ ^ self ].
	textPresenter selectionInterval: aRegion interval
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

{ #category : 'details' }
MMCCoveragePresenter >> showDetailsAt: aPosition [
	"Show the details of aPosition in the details widget."

	detailsPresenter text: (self detailsTextAt: aPosition)
]

{ #category : 'actions' }
MMCCoveragePresenter >> subscribeToCursor [
	"Called when the window is displayed: follow the cursor of the text area (Rubric announces RubSelectionChanged; the Spec selection hook does not see a mere cursor move) and show the details of its position."

	| textArea |
	textPresenter hasAdapter ifFalse: [ ^ self ].
	textArea := textPresenter adapter widget textArea.
	textArea announcer unsubscribe: self.
	textArea announcer
		when: RubSelectionChanged
		do: [ self showDetailsAt: (self cursorPositionIn: textArea) ]
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
	fileCoverage isReadable ifFalse: [
		^ 'Unreadable file: no anchor of the model designates it, or its text is empty' ].
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

{ #category : 'accessing' }
MMCCoveragePresenter >> textPresenter [

	^ textPresenter
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

{ #category : 'accessing' }
MMCCoveragePresenter >> uncoveredListPresenter [

	^ uncoveredListPresenter
]

{ #category : 'updating' }
MMCCoveragePresenter >> updateFileCoverage: aCoverage [
	"Replace the coverage and everything derived from it (plan, palette, text, uncovered zones, summary, details, decorations). The theme is kept. Order matters: decorations are removed before the text changes, and put back last."

	self clearDecorators.
	fileCoverage := aCoverage.
	plan := MMCHighlightPlan for: fileCoverage.
	uncoveredRegions := fileCoverage uncoveredRegions.
	self buildPalette.
	self fillWidgets.
	self buildDecorators.
	self applyDecorators
]

{ #category : 'initialization' }
MMCCoveragePresenter >> validateTheme: aSymbol [

	(#( dark light ) includes: aSymbol) ifFalse: [
			self error:
				'Unknown theme ' , aSymbol printString
				, ' (expected #dark or #light)' ]
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
