"
Tests of the width of the tree panel of MMCCoveragePresenter. With the default initialExtent (1300@700) the left panel had 0.22 of the width: a label of 39 characters ('Class AVeryLong...', about 278 px) was cut. The window test (skipped without World) opens a model with such a class, sets the window to the initialExtent (the World of the test image may be narrower than 1300, so the window is explicitly given that extent: this is the size the user gets on a large screen) and requires that the width of the longest visible label (font of the widget, widthOfString:) + 20 (icon column) + 20 (scroll bar) fits in the table. Constraint when the window is smaller (for instance 858 px wide): the panel is proportional, so nothing can be guaranteed there; the layout tests then state the ratio of the slider of defaultLayout (left panel between 0.25 and 0.32 of the width) and the non regression of the other ratios (the text zone keeps at least 40 % of the width and is the widest of the three columns).
"
Class {
	#name : 'MMCCoveragePresenterTreeWidthTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterTreeWidthTest >> addClassNamed: aName from: start to: end [
	"A class of the model with an indexed file anchor in a.txt."

	| entity anchor |
	entity := FamixJavaClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeWidthTest >> longName [
	"A class name of exactly 39 characters."

	^ 'AVeryLongClassName' , (String new: 21 withAll: $x)
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeWidthTest >> neededWidthOfLongestLabelIn: aPresenter table: aTable [
	"Pixels needed by the longest visible label: its width with the font of the widget + 20 (icon column) + 20 (scroll bar)."

	| label font |
	label := (aPresenter navigator visibleEntities collect: [ :each |
		          aPresenter treeLabelFor: each ]) detectMax: [ :each |
		         each size ].
	font := (aTable container exposedRows anyOne allMorphs detect: [
		         :each | each isKindOf: StringMorph ]) font.
	^ (font widthOfString: label) + 20 + 20
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeWidthTest >> newPresenter [
	"Not opened presenter on the inventory of the model, registered to be closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'fixture' }
MMCCoveragePresenterTreeWidthTest >> setUp [
	"Temporary folder with a.txt, and a model with a class whose name has 39 characters (anchored in a.txt) and a short class."

	super setUp.
	folder := FileLocator temp / ('mmc-width-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	presenters := OrderedCollection new.
	folder / 'a.txt' binaryWriteStreamDo: [ :s |
		s nextPutAll: (String new: 100 withAll: $x) utf8Encoded ].
	self addClassNamed: self longName from: 1 to: 60.
	self addClassNamed: 'Short' from: 61 to: 90
]

{ #category : 'fixture' }
MMCCoveragePresenterTreeWidthTest >> tearDown [
	"Close every window, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterTreeWidthTest >> testLongestLabelFitsInTheTreeAtInitialExtent [
	"Real window (skipped without World), given the initialExtent (1300@700) even when the World is narrower: the label 'Class ' + the 39 characters name, + 20 (icon) + 20 (scroll bar) must fit in the width of the tree table, in #covered mode then in whole model mode."

	| presenter window windowsBefore table |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isSystemWindow ].
	presenter := self newPresenter.
	self assert: self longName size equals: 39.
	[
		window := presenter open.
		window window extent: presenter initialExtent.
		#( #covered #all ) do: [ :filter |
				| waited |
				presenter treeFilter: filter.
				waited := 0.
				[ waited < 1500 ] whileTrue: [
						(Delay forMilliseconds: 100) wait.
						World doOneCycle.
						waited := waited + 100 ].
				table := presenter treePresenter adapter widget.
				self assert: window window extent equals: presenter initialExtent.
				self
					assert:
						(self neededWidthOfLongestLabelIn: presenter table: table)
						<= table bounds width
					description: 'the longest label ('
						,
						(self neededWidthOfLongestLabelIn: presenter table: table)
							printString
						,
						' px with icon and scroll bar) does not fit in the tree table ('
						, table bounds width printString , ' px) in mode ' , filter ] ]
		ensure: [
				window ifNotNil: [
						[ window close ]
							on: Error
							do: [ :e | e return ] ] ].
	self
		assert: (World submorphs count: [ :each | each isSystemWindow ])
		equals: windowsBefore
]

{ #category : 'tests' }
MMCCoveragePresenterTreeWidthTest >> testOtherRatiosOfTheLayoutKeepTheMainSpaceToTheText [
	"Non regression, without window: whatever the left panel ratio, the text zone (1 - left) * textRatio keeps at least 40 % of the width and stays wider than the left panel and than the right column; the initial extent is unchanged."

	| left remainder text right |
	left := self treePanelRatio.
	remainder := self textRatioInTheRemainder.
	text := 1 - left * remainder.
	right := 1 - left * (1 - remainder).
	self assert: text >= 0.4.
	self assert: text > left.
	self assert: text > right.
	self assert: self newPresenter initialExtent equals: 1300 @ 700
]

{ #category : 'tests' }
MMCCoveragePresenterTreeWidthTest >> testTreePanelRatioIsBetweenAQuarterAndAThirdOfTheWidth [
	"Without window. Needs 0.22 -> at least 0.25 so that 39 characters, an icon and a scroll bar (about 320 px) fit at 1300 px; at most 0.32 to leave the room to the text."

	| ratio |
	ratio := self treePanelRatio.
	self assert: ratio >= 0.25.
	self assert: ratio <= 0.32
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeWidthTest >> textRatioInTheRemainder [
	"Position of the second slider of defaultLayout (text / (text + right column))."

	^ self newPresenter defaultLayout children last children last
		  positionOfSlider
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeWidthTest >> treePanelRatio [
	"Position of the first slider of defaultLayout (left panel / total width)."

	^ self newPresenter defaultLayout children last positionOfSlider
]
