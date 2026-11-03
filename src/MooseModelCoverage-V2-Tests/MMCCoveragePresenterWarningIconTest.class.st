"
TDD tests of the warning icon of MMCCoveragePresenter: a small warning icon shown at the RIGHT of the name of every entity of the model tree (treePresenter) that has NO SourceAnchor (entity sourceAnchor isNil), because such an entity cannot be shown in the coverage text. Packages and namespaces are concerned too (on purpose).

Expected API (production, not written here; every call goes through perform: so this class compiles before it exists):
- MMCCoveragePresenter>>warningIconFor: anEntity -> the shared warning Form (same instance at each call) or nil when the entity has a SourceAnchor.
- MMCCoveragePresenter>>warningTextFor: anEntity -> 'No source anchor: this entity cannot be shown in the text' or nil.
- MMCCoveragePresenter>>treeIconColumn -> the SpImageTableColumn (second column of the tree) whose evaluation calls warningIconFor:.
- The tree has exactly 2 columns: text (same label and color as before) then image (icon at the right).
- MMCModelNavigator>>hasSourceAnchor: is covered in MMCModelNavigatorSourceAnchorTest.

Decisions fixed here: the warning depends only on the existence of the anchor, not on the mode (#covered or #all), not on the current file and not on the readability of the target file (anchor to a missing file: no warning).

Icon choice (Pharo 13 image, Smalltalk ui icons): #warning 16x16, #smallWarning 16x16, #error 16x16, #smallError 16x16. The recommended one is #smallWarning (16x16, explicitly small, below the default row height of 17 pixels; iconNamed: returns always the same cached Form). The tests only require a Form of at most 20x20 pixels, not a precise name.

DESIGN WARNING: SpTreePresenter has no columns (only SpTreeTablePresenter has #columns, #addColumn:), and the existing test MMCCoveragePresenterTreeTest>>testTreePresenterIsASpTreePresenterAndToggleACheckBox, testTreeIsEmptyWithoutModel (isKindOf: SpTreePresenter) and testTreeDisplayBlockShowsTheTreeLabel (treePresenter display) conflict with a SpTreeTablePresenter. The tests of this class require #columns on the treePresenter.

Fixture (temporary folder, removed in tearDown): package pkg without anchor containing ClassA (anchor a.txt 1-50, method runA a.txt 5-20), Orphan (NO anchor, method orphanRun a.txt 60-80), ClassB (b.txt 1-100) and ClassG (anchor to gone.txt, file absent).
"
Class {
	#name : 'MMCCoveragePresenterWarningIconTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'entities',
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'running' }
MMCCoveragePresenterWarningIconTest >> anchor: aName file: aFileName from: start to: end [
	"Give the entity kept under aName an indexed file anchor."

	| anchor |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	(entities at: aName) sourceAnchor: anchor
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> assertWarningsMatchAnchorsOfVisibleEntities [
	"For every shown entity the icon is present exactly when there is no anchor, and the text agrees with the icon."

	| visible |
	visible := self visibleEntities.
	self deny: visible isEmpty.
	visible do: [ :each |
			| icon hasIcon |
			icon := self iconFor: each.
			hasIcon := icon isNotNil.
			self
				assert: hasIcon equals: each sourceAnchor isNil;
				assert: (self textFor: each) isNotNil equals: hasIcon ]
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> buildFixture [
	"pkg (no anchor) contains ClassA (a.txt 1-50, method runA a.txt 5-20), Orphan (NO anchor, method orphanRun a.txt 60-80), ClassB (b.txt 1-100) and ClassG (anchor to gone.txt, absent on disk)."

	| pkg |
	self writeText: (String new: 100 withAll: $x) to: 'a.txt'.
	self writeText: (String new: 100 withAll: $x) to: 'b.txt'.
	pkg := self newEntity: FamixJavaPackage named: 'pkg'.
	#( 'ClassA' 'Orphan' 'ClassB' 'ClassG' ) do: [ :each |
		pkg addType: (self newEntity: FamixJavaClass named: each) ].
	(entities at: 'ClassA') addMethod:
		(self newEntity: FamixJavaMethod named: 'runA').
	(entities at: 'Orphan') addMethod:
		(self newEntity: FamixJavaMethod named: 'orphanRun').
	self
		anchor: 'ClassA'
		file: 'a.txt'
		from: 1
		to: 50.
	self
		anchor: 'runA'
		file: 'a.txt'
		from: 5
		to: 20.
	self
		anchor: 'orphanRun'
		file: 'a.txt'
		from: 60
		to: 80.
	self
		anchor: 'ClassB'
		file: 'b.txt'
		from: 1
		to: 100.
	self
		anchor: 'ClassG'
		file: 'gone.txt'
		from: 1
		to: 2
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> entity: aName [

	^ entities at: aName
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> iconColumn [

	^ self subject perform: #treeIconColumn
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> iconFor: anEntity [

	^ self subject perform: #warningIconFor: with: anEntity
]

{ #category : 'running' }
MMCCoveragePresenterWarningIconTest >> newEntity: aClass named: aName [
	"A named entity of the model, kept in entities under aName. No anchor."

	| entity |
	entity := aClass new.
	entity name: aName.
	model add: entity.
	entities at: aName put: entity.
	^ entity
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> newPresenter [
	"Not opened presenter on the inventory of the model (current file: a.txt). Registered to be closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'running' }
MMCCoveragePresenterWarningIconTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-warning-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new.
	self buildFixture
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> subject [
	"The first presenter of the test, created on demand."

	presenters ifEmpty: [ self newPresenter ].
	^ presenters first
]

{ #category : 'running' }
MMCCoveragePresenterWarningIconTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testAnchorOfAnotherFileHasNoWarningIcon [
	"ClassB is anchored in b.txt while the current file is a.txt: no warning."

	self assert: (self iconFor: (self entity: 'ClassB')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testAnchorToAMissingFileHasNoWarningIcon [
	"Decision: the warning means literally 'no SourceAnchor'. ClassG has an anchor to gone.txt, absent on disk: no warning."

	self assert: (self iconFor: (self entity: 'ClassG')) isNil.
	self assert: (self textFor: (self entity: 'ClassG')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testClassWithoutAnchorHasWarningButItsChildrenWithAnchorsDoNot [

	self assert: ((self iconFor: (self entity: 'Orphan')) isKindOf: Form).
	self assert: (self iconFor: (self entity: 'orphanRun')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testCoveredModeShowsWarningsOnAncestorsWithoutAnchor [
	"Default mode (#covered): pkg and Orphan are shown only as ancestors of covered entities; they have no anchor so they carry the warning."

	| visible |
	self assert: self subject treeFilter equals: #covered.
	visible := self visibleEntities.
	self assert: (visible includes: (self entity: 'pkg')).
	self assert: (visible includes: (self entity: 'Orphan')).
	self assert: (visible includes: (self entity: 'orphanRun')).
	self deny: (visible includes: (self entity: 'ClassB')).
	self assertWarningsMatchAnchorsOfVisibleEntities
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testFixtureHasTheExpectedAnchors [
	"Sanity of the fixture (green without production code)."

	self deny: (self entity: 'ClassA') sourceAnchor isNil.
	self deny: (self entity: 'ClassG') sourceAnchor isNil.
	self assert: (self entity: 'Orphan') sourceAnchor isNil.
	self assert: (self entity: 'pkg') sourceAnchor isNil.
	self deny: (self entity: 'orphanRun') sourceAnchor isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testIconColumnEvaluationAnswersTheWarningIconOrNil [

	| column |
	column := self iconColumn.
	self assert: (column evaluation value: (self entity: 'Orphan'))
		== (self iconFor: (self entity: 'Orphan')).
	self assert:
		((column evaluation value: (self entity: 'pkg')) isKindOf: Form).
	self assert: (column evaluation value: (self entity: 'ClassA')) isNil.
	self assert: (column evaluation value: (self entity: 'ClassG')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testNoWarningIconForEntityWithSourceAnchor [

	self assert: (self iconFor: (self entity: 'ClassA')) isNil.
	self assert: (self iconFor: (self entity: 'runA')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testNoWarningTextForEntityWithAnchor [

	self assert: (self textFor: (self entity: 'ClassA')) isNil.
	self assert: (self textFor: (self entity: 'orphanRun')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testPackageWithoutAnchorHasWarningIcon [
	"Packages and namespaces have no anchor: they carry the warning on purpose."

	self assert: ((self iconFor: (self entity: 'pkg')) isKindOf: Form)
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testPresenterWithoutModelHasAnEmptyTreeAndTheIconColumn [

	| presenter |
	presenter := presenters add:
		             (MMCCoveragePresenter on:
			              MMCCoveragePresenter emptyCoverage).
	self assert: presenter treePresenter roots isEmpty.
	self
		assert: (presenter treePresenter perform: #columns) size
		equals: 2.
	self assert:
		((presenter perform: #treeIconColumn) isKindOf: SpImageTableColumn)
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testShowFileKeepsTheWarningIcons [

	| icon file |
	icon := self iconFor: (self entity: 'Orphan').
	file := (folder / 'b.txt') asFileReference canonicalize.
	self subject showFile: file.
	self assert: self subject currentFile equals: file.
	self assert: self treeColumns size equals: 2.
	self assert: (self iconFor: (self entity: 'Orphan')) == icon.
	self assert: (self iconFor: (self entity: 'ClassB')) isNil.
	self assertWarningsMatchAnchorsOfVisibleEntities.
	self subject treeFilter: #all.
	self assertWarningsMatchAnchorsOfVisibleEntities
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testSmokeOpenWithRealWindowShowsTheImageColumn [
	"Only test with a real Morphic window (skipped without World): the tree widget of the opened window has two columns (text, image), the whole model mode keeps them, the window is closed in ensure: and the number of system windows is the same as before."

	| presenter window windowsBefore widget |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isSystemWindow ].
	presenter := self newPresenter.
	[
		window := presenter open.
		self assert: window isOpen.
		self assert: presenter treePresenter adapter isNotNil.
		widget := presenter treePresenter adapter widget.
		self assert: widget columns size equals: 2.
		self assert: widget dataSource numberOfRows > 0.
		presenter treeFilter: #all.
		self
			assert: presenter treePresenter adapter widget columns size
			equals: 2.
		self
			assert: (presenter treePresenter perform: #columns) size
			equals: 2.
		self assert:
			((presenter perform: #treeIconColumn) isKindOf: SpImageTableColumn) ]
		ensure: [
				window ifNotNil: [
						[ window close ]
							on: Error
							do: [ :e | e return ] ] ].
	self deny: window isOpen.
	self
		assert: (World submorphs count: [ :each | each isSystemWindow ])
		equals: windowsBefore
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testTextColumnKeepsTheLabelAndTheColor [

	| column |
	column := self treeColumns first.
	#( 'ClassA' 'Orphan' 'pkg' 'orphanRun' ) do: [ :each |
			self
				assert: (column evaluation value: (self entity: each))
				equals: (self subject treeLabelFor: (self entity: each)).
			self
				assert: (column displayColor value: (self entity: each))
				equals: (self subject treeColorFor: (self entity: each)) ]
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testTreeHasExactlyTwoColumnsTextThenImage [

	| columns |
	columns := self treeColumns.
	self assert: columns size equals: 2.
	self assert: (columns first isKindOf: SpStringTableColumn).
	self assert: (columns second isKindOf: SpImageTableColumn)
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testTreeIconColumnIsTheSecondColumnAndAnImageColumn [
	"The icon column is after the text column: the icon is at the RIGHT of the name."

	self assert: (self iconColumn isKindOf: SpImageTableColumn).
	self assert: self iconColumn == self treeColumns second.
	self assert: self iconColumn == self treeColumns last
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testTreeLabelIsUnchangedAndHasNoWarningText [

	self
		assert: (self subject treeLabelFor: (self entity: 'Orphan'))
		equals: 'Class Orphan'.
	self
		assert: (self subject treeLabelFor: (self entity: 'ClassA'))
		equals: 'Class ClassA'.
	self
		assert: (self subject treeLabelFor: (self entity: 'pkg'))
		equals: 'Package pkg'
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testWarningDoesNotDependOnTheFilterMode [

	| before |
	before := (self entity: 'pkg')
	          -> (self iconFor: (self entity: 'pkg')).
	self subject treeFilter: #all.
	self assert: (self iconFor: (self entity: 'pkg')) == before value.
	self subject treeFilter: #covered.
	self assert: (self iconFor: (self entity: 'pkg')) == before value.
	self assert: (self iconFor: (self entity: 'ClassA')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testWarningIconForEntityWithoutSourceAnchor [

	self assert: ((self iconFor: (self entity: 'Orphan')) isKindOf: Form)
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testWarningIconIsSmall [
	"Small icon consistent with the row height (16x16 expected, see the class comment)."

	| icon |
	icon := self iconFor: (self entity: 'Orphan').
	self assert: (icon width between: 8 and: 20).
	self assert: (icon height between: 8 and: 20)
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testWarningIconIsTheSameInstanceAtEachCall [

	| first |
	first := self iconFor: (self entity: 'Orphan').
	self assert: first isNotNil.
	self assert: (self iconFor: (self entity: 'Orphan')) == first.
	self assert: (self iconFor: (self entity: 'pkg')) == first.
	self assert: (self iconFor: (self entity: 'Orphan')) == first
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testWarningTextForEntityWithoutAnchor [

	self
		assert: (self textFor: (self entity: 'Orphan'))
		equals: 'No source anchor: this entity cannot be shown in the text'.
	self
		assert: (self textFor: (self entity: 'pkg'))
		equals: 'No source anchor: this entity cannot be shown in the text'
]

{ #category : 'tests' }
MMCCoveragePresenterWarningIconTest >> testWholeModelModeShowsWarningsOfEntitiesWithoutAnchor [

	| visible |
	self subject treeFilter: #all.
	visible := self visibleEntities.
	#( 'pkg' 'ClassA' 'Orphan' 'ClassB' 'ClassG' 'runA' 'orphanRun' )
		do: [ :each | self assert: (visible includes: (self entity: each)) ].
	self assertWarningsMatchAnchorsOfVisibleEntities.
	self assert: ((self iconFor: (self entity: 'Orphan')) isKindOf: Form).
	self assert: (self iconFor: (self entity: 'ClassG')) isNil
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> textFor: anEntity [

	^ self subject perform: #warningTextFor: with: anEntity
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> treeColumns [
	"Columns of the tree (SpTreeTablePresenter API, absent on SpTreePresenter)."

	^ self subject treePresenter perform: #columns
]

{ #category : 'helpers' }
MMCCoveragePresenterWarningIconTest >> visibleEntities [
	"All the entities currently shown by the navigator (roots and descendants, depth first). The tree is acyclic."

	| result stack |
	result := OrderedCollection new.
	stack := self subject navigator roots asOrderedCollection.
	[ stack isEmpty ] whileFalse: [
			| next |
			next := stack removeFirst.
			result add: next.
			stack addAll: (self subject navigator childrenOf: next) ].
	^ result
]

{ #category : 'running' }
MMCCoveragePresenterWarningIconTest >> writeText: aString to: aFileName [
	"UTF-8 text file in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
