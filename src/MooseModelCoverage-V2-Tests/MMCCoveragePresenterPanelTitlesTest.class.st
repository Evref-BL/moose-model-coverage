"
Tests of the visible titles of the panels of MMCCoveragePresenter: panelTitles answers #('Summary' 'Files' 'Model' 'Source text' 'Uncovered zones' 'Details') in display order; in a real window (skipped without World, always closed) every title is a text or label morph of the window, visible, and placed above its panel (Model above the tree, Files above the file list, Source text above the text, Uncovered zones above the list of zones, Details above the details). Non regression: the layout ratios (text at least 40 % of the width, tree about a quarter) and the minimal heights (file list 100 px, tree 200 px) at initialExtent (1300@700) are kept once the titles are added. The temporary folder is removed in tearDown.
"
Class {
	#name : 'MMCCoveragePresenterPanelTitlesTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'fixture' }
MMCCoveragePresenterPanelTitlesTest >> addClass: aName on: aFileName from: start to: end [
	"Add to the model a class with an indexed file anchor. The names never contain a title of the panels."

	| entity anchor |
	entity := FamixJavaClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor.
	^ entity
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> assertEveryTitleIsShownIn: aPresenter [
	"Real window: each of the six titles is a text or label morph of the window, visible inside it (the tree rows are awaited)."

	self assertEveryTitleIsShownIn: aPresenter expectingRows: true
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> assertEveryTitleIsShownIn: aPresenter expectingRows: rowsExpected [
	"Real window: each of the six titles is a text or label morph of the window, visible inside it."

	self
		withOpenWindowOf: aPresenter
		expectingRows: rowsExpected
		do: [ :windowMorph |
				self expectedTitles do: [ :title |
						| candidates |
						candidates := self titleMorphsFor: title in: windowMorph.
						self
							deny: candidates isEmpty
							description: title , ' is not in the morphs of the window'.
						self
							assert: (candidates anySatisfy: [ :each |
									 self isVisible: each inside: windowMorph ])
							description: title , ' is not visible in the window' ] ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> assertTitle: aTitle isAbovePanelOf: aPresenter [
	"Real window: some visible morph showing aTitle is above (and over) the widget of its panel."

	self withOpenWindowOf: aPresenter do: [ :windowMorph |
			| panel candidates |
			panel := self panelMorphOf: aPresenter titled: aTitle.
			candidates := self titleMorphsFor: aTitle in: windowMorph.
			self deny: candidates isEmpty description: aTitle , ' is not shown'.
			self
				assert: (candidates anySatisfy: [ :each |
							 (self isVisible: each inside: windowMorph) and: [
								 self isTitle: each above: panel ] ])
				description: aTitle , ' is not visible above its panel' ]
]

{ #category : 'fixture' }
MMCCoveragePresenterPanelTitlesTest >> buildFixture [
	"a.txt and b.txt of 100 chars; ClassA in a.txt 11-40, ClassB in b.txt 11-40."

	self writeText: (String new: 100 withAll: $x) to: 'a.txt'.
	self writeText: (String new: 100 withAll: $x) to: 'b.txt'.
	self
		addClass: 'ClassA'
		on: 'a.txt'
		from: 11
		to: 40.
	self
		addClass: 'ClassB'
		on: 'b.txt'
		from: 11
		to: 40
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> expectedTitles [

	^ #( 'Summary' 'Files' 'Model' 'Source text' 'Uncovered zones'
	     'Details' )
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> isTitle: aTitleMorph above: aPanelMorph [
	"True when the title is above the panel (the bottom of its area is not below the top of the panel, 4 px of tolerance), at most 120 px away (the file filter or the tree check box and status may sit between), and overlaps the panel horizontally."

	| title panel |
	title := self titleBoundsOf: aTitleMorph.
	panel := aPanelMorph bounds.
	^ title bottom <= (panel top + 4) and: [
			  panel top - title bottom <= 120 and: [
				  title left < panel right and: [ title right > panel left ] ] ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> isVisible: aMorph inside: aWindowMorph [
	"True when the title of aMorph is shown (morph visible and in the world) with non empty bounds inside the bounds of the window."

	| area |
	area := self titleBoundsOf: aMorph.
	^ aMorph visible and: [
			  aMorph isInWorld and: [
					  area width > 0 and: [
						  area height > 0 and: [ aWindowMorph bounds containsRect: area ] ] ] ]
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> newPresenter [
	"Not opened presenter with the file selector (inventory of the model)."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> newPresenterOnCoverageOnly [
	"Not opened presenter built by on: (no model, no inventory)."

	| coverage |
	coverage := (MMCModelFiles on: model) coverageFor:
		            (folder / 'a.txt') asFileReference canonicalize.
	^ presenters add: (MMCCoveragePresenter on: coverage)
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> newPresenterWithoutInventory [
	"Not opened presenter on the file a.txt through forModel:file: (no inventory: the file panel stays present, disabled)."

	^ presenters add:
		  (MMCCoveragePresenter forModel: model file: 'a.txt')
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> panelMorphOf: aPresenter titled: aTitle [
	"The widget morph of the panel titled aTitle (Summary has no widget of its own here)."

	| panel |
	panel := Dictionary new.
	panel at: 'Model' put: aPresenter treePresenter.
	panel at: 'Files' put: aPresenter fileListPresenter.
	panel at: 'Source text' put: aPresenter textPresenter.
	panel at: 'Uncovered zones' put: aPresenter uncoveredListPresenter.
	panel at: 'Details' put: aPresenter detailsPresenter.
	^ (panel at: aTitle) adapter widget
]

{ #category : 'fixture' }
MMCCoveragePresenterPanelTitlesTest >> setUp [
	"Temporary folder with a.txt and b.txt, and a model with a class in each file (rootFolder set)."

	super setUp.
	folder := FileLocator temp / ('mmc-titles-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	presenters := OrderedCollection new.
	self buildFixture
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> stringOfMorph: aMorph [
	"The text shown by a text or label morph (contents, text or label answering a String or a Text), nil for the other morphs."

	#( #contents #text #label ) do: [ :selector |
			(aMorph respondsTo: selector) ifTrue: [
					| value |
					value := [ aMorph perform: selector ]
						         on: Error
						         do: [ :e | e return: nil ].
					((value isKindOf: String) or: [ value isKindOf: Text ]) ifTrue: [
						^ value asString ] ] ].
	^ nil
]

{ #category : 'fixture' }
MMCCoveragePresenterPanelTitlesTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testDetailsTitleIsAboveTheDetails [

	self assertTitle: 'Details' isAbovePanelOf: self newPresenter
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testEveryTitleIsShownAndVisibleInTheWindow [
	"Real window with the file selector."

	self assertEveryTitleIsShownIn: self newPresenter
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testEveryTitleIsShownAndVisibleInTheWindowWithoutInventory [
	"Real window without inventory: the same six titles, Files included although its panel is disabled. The presenter without Moose model has an empty tree: no exposed rows awaited for it."

	self assertEveryTitleIsShownIn: self newPresenterWithoutInventory.
	self
		assertEveryTitleIsShownIn: self newPresenterOnCoverageOnly
		expectingRows: false
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testFilesTitleIsAboveTheFileList [

	self assertTitle: 'Files' isAbovePanelOf: self newPresenter
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testModelAndFilesTitlesAreAboveTheirPanelWithoutInventory [
	"Real window without inventory: Model above the tree, Files above the (disabled) file list."

	self
		assertTitle: 'Model'
		isAbovePanelOf: self newPresenterWithoutInventory.
	self
		assertTitle: 'Files'
		isAbovePanelOf: self newPresenterWithoutInventory
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testModelTitleIsAboveTheTree [

	self assertTitle: 'Model' isAbovePanelOf: self newPresenter
]

{ #category : 'tests' }
MMCCoveragePresenterPanelTitlesTest >> testPanelTitlesAreTheSixNamesInDisplayOrder [
	"Left to right, top to bottom: summary, files, model tree, text, uncovered zones, details."

	self
		assert: (self titlesOf: self newPresenter)
		equals:
			#( 'Summary' 'Files' 'Model' 'Source text' 'Uncovered zones'
			   'Details' )
]

{ #category : 'tests' }
MMCCoveragePresenterPanelTitlesTest >> testPanelTitlesDoNotDependOnTheFileShown [
	"Switching to the other file does not change the titles."

	| presenter |
	presenter := self newPresenter.
	presenter showFile: (folder / 'b.txt') asFileReference canonicalize.
	self assert: (self titlesOf: presenter) equals: self expectedTitles
]

{ #category : 'tests' }
MMCCoveragePresenterPanelTitlesTest >> testPanelTitlesIsAnArrayOfStrings [

	| titles |
	titles := self titlesOf: self newPresenter.
	self assert: titles class equals: Array.
	titles do: [ :each | self assert: each isString ].
	self assert: titles asSet size equals: titles size
]

{ #category : 'tests' }
MMCCoveragePresenterPanelTitlesTest >> testPanelTitlesWithoutInventoryAreTheSameSixNames [
	"forModel:file: and on: keep the Files panel (disabled), hence the same titles."

	self
		assert: (self titlesOf: self newPresenterWithoutInventory)
		equals: self expectedTitles.
	self
		assert: (self titlesOf: self newPresenterOnCoverageOnly)
		equals: self expectedTitles
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testSourceTextTitleIsAboveTheText [

	self assertTitle: 'Source text' isAbovePanelOf: self newPresenter
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testTextAndTreeKeepTheirUsefulWidthAtInitialExtent [
	"Non regression of the layout ratios once the titles are added (real window given the initialExtent 1300@700): the text keeps at least 40 % of the width and is the widest panel; the tree table keeps between 22 % and 32 % of the width (slider 0.26 minus the borders, 39 characters label fit, see MMCCoveragePresenterTreeWidthTest); the right column is not squeezed under 15 %."

	| presenter |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :windowMorph |
			| width text tree right |
			width := windowMorph bounds width.
			self assert: width equals: presenter initialExtent x.
			text := presenter textPresenter adapter widget bounds width.
			tree := presenter treePresenter adapter widget bounds width.
			right := presenter uncoveredListPresenter adapter widget bounds
				         width.
			self
				assert: text >= (width * 0.4)
				description:
				'text ' , text printString , ' px of ' , width printString.
			self
				assert: tree >= (width * 0.22)
				description:
				'tree ' , tree printString , ' px of ' , width printString.
			self
				assert: tree <= (width * 0.32)
				description:
				'tree ' , tree printString , ' px of ' , width printString.
			self
				assert: right >= (width * 0.15)
				description:
				'right column ' , right printString , ' px of '
				, width printString.
			self assert: text > tree.
			self assert: text > right ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testTitlesDoNotShrinkTheFileListAndTheTreeAtInitialExtent [
	"Real window at initialExtent (1300@700): the titles must not take the height of the file list (at least 100 px, today 150) nor of the tree (at least 200 px)."

	| presenter |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :windowMorph |
			| list tree |
			self
				assert: windowMorph bounds height
				equals: presenter initialExtent y.
			list := presenter fileListPresenter adapter widget bounds height.
			tree := presenter treePresenter adapter widget bounds height.
			self
				assert: list >= 100
				description: 'file list ' , list printString , ' px high'.
			self
				assert: tree >= 200
				description: 'tree ' , tree printString , ' px high' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testTitlesFollowTheDisplayOrderOfThePanels [
	"Real window: Files above Model in the left column, Model to the left of Source text, itself to the left of Uncovered zones, Uncovered zones above Details, Summary at the top."

	self withOpenWindowOf: self newPresenter do: [ :windowMorph |
			| bounds |
			bounds := Dictionary new.
			self expectedTitles do: [ :title |
				bounds
					at: title
					put: ((self titleMorphsFor: title in: windowMorph)
							 ifEmpty: [ self fail: title , ' is not shown' ]
							 ifNotEmpty: [ :found | self titleBoundsOf: found first ]) ].
			self assert: (bounds at: 'Files') top < (bounds at: 'Model') top.
			self assert: (bounds at: 'Model') right <= ((bounds at: 'Source text') left + 4).
			self assert: (bounds at: 'Source text') right <= ((bounds at: 'Uncovered zones') left + 4).
			self assert: (bounds at: 'Uncovered zones') top < (bounds at: 'Details') top.
			self assert: (bounds at: 'Summary') top <= (bounds at: 'Files') top ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testTreeLongestLabelStillFitsAtInitialExtent [
	"The tree table stays wide enough for 39 characters + 20 (icon) + 20 (scroll bar) at the font of the rows, with the titles added."

	| presenter |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :windowMorph |
			| table font needed |
			table := presenter treePresenter adapter widget.
			font := (table container exposedRows anyOne allMorphs detect: [
				         :each | each isKindOf: StringMorph ]) font.
			needed := (font widthOfString:
				           'Class ' , (String new: 39 withAll: $x)) + 40.
			self
				assert: needed <= table bounds width
				description:
					needed printString , ' px needed, '
					, table bounds width printString , ' px available' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterPanelTitlesTest >> testUncoveredZonesTitleIsAboveTheListOfZones [

	self assertTitle: 'Uncovered zones' isAbovePanelOf: self newPresenter
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> titleBoundsOf: aMorph [
	"The area where the title is drawn. A text or label morph draws it in its bounds; a frame morph (SpFrameLayout: SpMorphicFrameLayoutMorph, whose label is drawn by the frame itself in its top strip) draws it in the strip of its headerHeight at the top of its bounds."

	^ (aMorph respondsTo: #headerHeight)
		  ifTrue: [
				  aMorph bounds topLeft corner:
					  aMorph bounds right @ (aMorph bounds top + aMorph headerHeight) ]
		  ifFalse: [ aMorph bounds ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterPanelTitlesTest >> titleMorphsFor: aTitle in: aWindowMorph [
	"The morphs of the window showing aTitle: their text equals or contains it and is short (at most 4 characters more, so that texts, lists and the tree never match)."

	^ aWindowMorph allMorphs select: [ :each |
			  (self stringOfMorph: each)
				  ifNil: [ false ]
				  ifNotNil: [ :string |
						  string size <= (aTitle size + 4) and: [
							  string includesSubstring: aTitle ] ] ]
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> titlesOf: aPresenter [
	"panelTitles sent by perform: (the API does not exist yet)."

	^ aPresenter perform: #panelTitles
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> waitUpTo: someMilliseconds until: aBlock [
	"Let Morphic run (100 ms steps) until aBlock is true or someMilliseconds elapsed. Answer the final value of aBlock."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 100) wait.
			World doOneCycle.
			waited := waited + 100 ].
	^ aBlock value
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Same as withOpenWindowOf:expectingRows:do: with the rows of the tree required (presenter with a model)."

	self withOpenWindowOf: aPresenter expectingRows: true do: aBlock
]

{ #category : 'helpers' }
MMCCoveragePresenterPanelTitlesTest >> withOpenWindowOf: aPresenter expectingRows: rowsExpected do: aBlock [
	"Skipped without World. Open aPresenter, give the window the initialExtent (1300@700, even when the World is narrower), wait for the rows of the tree when rowsExpected (not for a presenter without model, whose tree is empty), then for the layout to be stable (the bounds of the main panels unchanged between two steps, then 1 s more), evaluate aBlock with the window morph, then always close the window and check that the number of windows is the same as before."

	| window windowsBefore previous |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isSystemWindow ].
	[
		window := aPresenter open.
		window adapter widget extent: aPresenter initialExtent.
		rowsExpected ifTrue: [
				self
					assert: (self waitUpTo: 3000 until: [
								 aPresenter treePresenter adapter widget container exposedRows
									 notNil and: [
									 aPresenter treePresenter adapter widget container
										 exposedRows notEmpty ] ])
					description: 'the tree rows were not exposed' ].
		self waitUpTo: 3000 until: [
				| now |
				now := {
					       aPresenter treePresenter adapter widget bounds.
					       aPresenter textPresenter adapter widget bounds.
					       aPresenter uncoveredListPresenter adapter widget bounds.
					       aPresenter detailsPresenter adapter widget bounds }.
				previous = now or: [
						previous := now.
						false ] ].
		self waitUpTo: 1000 until: [ false ].
		aBlock value: window adapter widget ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ].
	self
		assert: (World submorphs count: [ :each | each isSystemWindow ])
		equals: windowsBefore
]

{ #category : 'fixture' }
MMCCoveragePresenterPanelTitlesTest >> writeText: aString to: aFileName [
	"UTF-8 text file in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ]
]
