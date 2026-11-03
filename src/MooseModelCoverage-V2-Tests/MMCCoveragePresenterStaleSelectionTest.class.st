"
Tests of the tree selection of MMCCoveragePresenter after a click on an entity that lives in another file. The tree is rebuilt by the automatic file switch (roots recomputed), and FastTable used to keep its OLD selected row index, so the selected row became another entity (and Inspect received it). The tests with a real window (skipped without World) click the row with a synthetic mouse event (left or right button), as a user does; the tests without window state the invariant at the Spec level (selectedItem and selectedPath lead to the entity after treeSelectionChangedTo: with switch). Fixture: a.txt (ClassA), b.txt (ClassB1 at 61-80, ClassB2 at 11-30, ClassB3 at 31-50, then the roots of b.txt are B2 B3 B1 in text order), c.txt (ClassC, and ClassH whose method hm is in b.txt: in #covered mode ClassH is visible from b.txt without region there). In #all mode the roots are the entities of the current file in text order, then the others by name.
"
Class {
	#name : 'MMCCoveragePresenterStaleSelectionTest',
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

{ #category : 'fixture' }
MMCCoveragePresenterStaleSelectionTest >> add: aFamixClass named: aName on: aFileName from: start to: end [
	"Add to the model an entity (kept under aName in entities) with an indexed file anchor."

	| entity anchor |
	entity := aFamixClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor.
	entities at: aName put: entity.
	^ entity
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> assertSelectionOf: aPresenter isOn: anEntity inFile: aFileName [
	"After a click: file switched, Spec selection, VISIBLE row and FastTable index all on anEntity; no synchronisation left running."

	| table |
	table := self tableOf: aPresenter.
	self assert: aPresenter currentFile equals: (self file: aFileName).
	self
		assert: aPresenter selectedEntityInTree == anEntity
		description: 'Spec selection is not the clicked entity'.
	self
		assert: (self selectedRowEntityIn: aPresenter) == anEntity
		description: 'the selected FastTable row is not the clicked entity'.
	self
		assert: table selectedIndex
		equals: (self rowIndexOf: anEntity in: aPresenter).
	self deny: aPresenter isSynchronizing
]

{ #category : 'tests - no window' }
MMCCoveragePresenterStaleSelectionTest >> assertSpecSelectionAfterSwitchTo: aName from: aFileName filter: aSymbol [
	"Without window: treeSelectionChangedTo: with a file switch leaves the Spec tree selected on the entity (selectedItem) and its selectedPath leads to the entity."

	| presenter target path |
	presenter := self newPresenterOn: aFileName filter: aSymbol.
	target := self entity: aName.
	presenter treeSelectionChangedTo: target.
	self deny: presenter currentFile equals: (self file: aFileName).
	self
		assert: presenter treePresenter selectedItem == target
		description: 'selectedItem is not ' , aName.
	path := presenter treePresenter selection selectedPath.
	self
		assert: (presenter navigator entityAtPath: path) == target
		description: 'selectedPath does not lead to ' , aName.
	self assert: presenter selectedEntityInTree == target.
	self deny: presenter isSynchronizing
]

{ #category : 'fixture' }
MMCCoveragePresenterStaleSelectionTest >> buildFixture [
	"a.txt, b.txt, c.txt of 100 chars. ClassA a.txt 11-40. ClassB1 b.txt 61-80, ClassB2 b.txt 11-30, ClassB3 b.txt 31-50. ClassC c.txt 11-40. ClassH c.txt 51-90 with its method hm in b.txt 5-9 (visible from b.txt in #covered mode, without region of its own there)."

	| hClass |
	#( 'a.txt' 'b.txt' 'c.txt' ) do: [ :each |
		self writeText: (String new: 100 withAll: $x) to: each ].
	self
		add: FamixJavaClass
		named: 'ClassA'
		on: 'a.txt'
		from: 11
		to: 40.
	self
		add: FamixJavaClass
		named: 'ClassB1'
		on: 'b.txt'
		from: 61
		to: 80.
	self
		add: FamixJavaClass
		named: 'ClassB2'
		on: 'b.txt'
		from: 11
		to: 30.
	self
		add: FamixJavaClass
		named: 'ClassB3'
		on: 'b.txt'
		from: 31
		to: 50.
	self
		add: FamixJavaClass
		named: 'ClassC'
		on: 'c.txt'
		from: 11
		to: 40.
	hClass := self
		          add: FamixJavaClass
		          named: 'ClassH'
		          on: 'c.txt'
		          from: 51
		          to: 90.
	hClass addMethod: (self
			 add: FamixJavaMethod
			 named: 'hm'
			 on: 'b.txt'
			 from: 5
			 to: 9)
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> clickOn: aName from: aFileName filter: aSymbol button: aButtonSymbol do: aBlock [
	"In a real window opened on aFileName with the filter aSymbol, click (#left or #right) on the row of the entity aName, then evaluate aBlock with the presenter and the entity. Skipped without World."

	| presenter target |
	presenter := self newPresenterOn: aFileName filter: aSymbol.
	target := self entity: aName.
	self withOpenWindowOf: presenter do: [ :window |
			self clickRowOf: target in: presenter button: aButtonSymbol.
			aBlock value: presenter value: target ]
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> clickRowOf: anEntity in: aPresenter button: aSymbol [
	"Dispatch through the hand a synthetic press and release of the mouse button (#left or #right) on the row of anEntity, as a user does, then let Morphic run. The row must exist."

	| table index row point hand which |
	index := self rowIndexOf: anEntity in: aPresenter.
	self assert: index > 0 description: 'the entity has no row to click'.
	table := self tableOf: aPresenter.
	row := table container exposedRows at: index.
	point := row bounds center.
	which := aSymbol == #right
		         ifTrue: [ 2 ]
		         ifFalse: [ 4 ].
	hand := World activeHand.
	hand handleEvent: (MouseButtonEvent new
			 setType: #mouseDown
			 position: point
			 which: which
			 buttons: which
			 hand: hand
			 stamp: Time millisecondClockValue).
	hand handleEvent: (MouseButtonEvent new
			 setType: #mouseUp
			 position: point
			 which: which
			 buttons: 0
			 hand: hand
			 stamp: Time millisecondClockValue).
	self waitUpTo: 400 until: [ false ]
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> entity: aName [

	^ entities at: aName
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> file: aFileName [
	"The canonical FileReference expected as currentFile."

	^ (folder / aFileName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> newPresenterOn: aFileName filter: aSymbol [
	"Not opened presenter on the inventory of the model, showing aFileName with the filter aSymbol. Registered to be closed in tearDown."

	| presenter |
	presenter := MMCCoveragePresenter
		             forInventoryOn: model
		             file: aFileName.
	presenter treeFilter: aSymbol.
	^ presenters add: presenter
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> recordInspectionsOf: aPresenter [
	"Replace the inspect action by a recorder; answer the collection of the entities received (no inspector is opened)."

	| calls |
	calls := OrderedCollection new.
	aPresenter inspectAction: [ :entity | calls add: entity ].
	^ calls
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> rowIndexOf: anEntity in: aPresenter [
	"Index of the FastTable row showing anEntity, 0 when it has no row."

	| source |
	source := (self tableOf: aPresenter) dataSource.
	^ (1 to: source numberOfRows)
		  detect: [ :each | (source elementAt: each) data == anEntity ]
		  ifNone: [ 0 ]
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> selectedRowEntityIn: aPresenter [
	"The entity of the row VISUALLY selected in the FastTable (not the Spec selection), nil when no row is selected."

	| table index |
	table := self tableOf: aPresenter.
	index := table selectedIndex.
	^ (index between: 1 and: table dataSource numberOfRows)
		  ifTrue: [ (table dataSource elementAt: index) data ]
		  ifFalse: [ nil ]
]

{ #category : 'fixture' }
MMCCoveragePresenterStaleSelectionTest >> setUp [
	"Temporary folder, empty model with this rootFolder, then the fixture."

	super setUp.
	folder := FileLocator temp / ('mmc-stale-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new.
	self buildFixture
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> tableOf: aPresenter [
	"The FastTable widget of the tree of an opened presenter."

	^ aPresenter treePresenter adapter widget
]

{ #category : 'fixture' }
MMCCoveragePresenterStaleSelectionTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testClickDoesNotEchoNorLoop [
	"(f) After a real click with a file switch, nothing is still synchronizing, and once Morphic has run for a while the file stays the one of the clicked entity (no echo, no ping-pong between files). Independent of the stale selection defect: it only looks at the file and at the synchronisation flag."

	self
		clickOn: 'ClassA'
		from: 'b.txt'
		filter: #all
		button: #left
		do: [ :presenter :target |
				self deny: presenter isSynchronizing.
				self assert: presenter currentFile equals: (self file: 'a.txt').
				self waitUpTo: 1000 until: [ false ].
				self deny: presenter isSynchronizing.
				self assert: presenter currentFile equals: (self file: 'a.txt') ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testClickSelectsTheFirstRegionOfTheClickedEntityInTheText [
	"(d) After a real click that switches file, the text selection is the first region of the CLICKED entity: ClassA 11-40 (from b.txt), ClassB1 61-80 (from a.txt), ClassC 11-40 (from b.txt)."

	#( #( 'ClassA' 'b.txt' 11 40 ) #( 'ClassB1' 'a.txt' 61 80 )
	   #( 'ClassC' 'b.txt' 11 40 ) ) do: [ :each |
			self
				clickOn: each first
				from: each second
				filter: #all
				button: #left
				do: [ :presenter :target |
						self
							assert: presenter textPresenter selectionInterval
							equals: ((each at: 3) to: (each at: 4)) ] ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testCoveredModeClickOnClassHFromBSelectsClassH [
	"(e) #covered mode: from b.txt the roots are ClassB2 ClassB3 ClassB1 ClassH; ClassH is visible (ancestor of hm, no region of its own in b.txt) as row 4. Clicking it switches to c.txt where the roots are ClassC ClassH (row 2, the old index 4 is even out of range). The selection, the visible row and the text selection (51-90) are ClassH."

	| presenter target |
	presenter := self newPresenterOn: 'b.txt' filter: #covered.
	target := self entity: 'ClassH'.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: (self rowIndexOf: target in: presenter) equals: 4.
			self clickRowOf: target in: presenter button: #left.
			self assertSelectionOf: presenter isOn: target inFile: 'c.txt'.
			self assert: (self rowIndexOf: target in: presenter) equals: 2.
			self
				assert: presenter textPresenter selectionInterval
				equals: (51 to: 90) ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testCoveredModeRightClickOnClassHFromBInspectsClassH [
	"(e) #covered mode, right click then Inspect on ClassH from b.txt."

	| presenter target calls item |
	presenter := self newPresenterOn: 'b.txt' filter: #covered.
	target := self entity: 'ClassH'.
	calls := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			self clickRowOf: target in: presenter button: #right.
			item := presenter treeContextMenu menuGroups first menuItems first.
			item action cull: item.
			self assert: calls size equals: 1.
			self
				assert: calls first == target
				description: 'Inspect did not receive ClassH' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testLeftClickOnClassAFromBInWholeModelSwitchesAndSelectsClassA [
	"(a) Real left click on ClassA (regions in a.txt) while b.txt is shown, whole model: a.txt is shown, ClassA is the Spec selection AND the selected row of the FastTable (FastTable used to keep the old row index: ClassB)."

	self
		clickOn: 'ClassA'
		from: 'b.txt'
		filter: #all
		button: #left
		do: [ :presenter :target |
			self assertSelectionOf: presenter isOn: target inFile: 'a.txt' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testLeftClickOnClassB1FromATargetMovesAfterTheOriginalIndex [
	"(c) Whole model from a.txt the roots are ClassA ClassB1 ClassB2 ClassB3 ClassC: ClassB1 is row 2; in b.txt (text order ClassB2 ClassB3 ClassB1) it becomes row 3 (the target moves AFTER the old index)."

	| presenter target |
	presenter := self newPresenterOn: 'a.txt' filter: #all.
	target := self entity: 'ClassB1'.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: (self rowIndexOf: target in: presenter) equals: 2.
			self clickRowOf: target in: presenter button: #left.
			self assertSelectionOf: presenter isOn: target inFile: 'b.txt'.
			self assert: (self rowIndexOf: target in: presenter) equals: 3 ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testLeftClickOnClassCFromBTargetMovesBeforeTheOriginalIndex [
	"(c) Whole model from b.txt the roots are ClassB2 ClassB3 ClassB1 ClassA ClassC: ClassC is row 5; in c.txt it becomes row 1 (the target moves BEFORE the old index)."

	| presenter target |
	presenter := self newPresenterOn: 'b.txt' filter: #all.
	target := self entity: 'ClassC'.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: (self rowIndexOf: target in: presenter) equals: 5.
			self clickRowOf: target in: presenter button: #left.
			self assertSelectionOf: presenter isOn: target inFile: 'c.txt'.
			self assert: (self rowIndexOf: target in: presenter) equals: 1 ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testRightClickOnClassAFromBInWholeModelInspectsClassA [
	"(b) Real right click on ClassA from b.txt, whole model: the Inspect item (action run after the click) receives ClassA, not ClassB."

	| presenter target calls item |
	presenter := self newPresenterOn: 'b.txt' filter: #all.
	target := self entity: 'ClassA'.
	calls := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			self clickRowOf: target in: presenter button: #right.
			item := presenter treeContextMenu menuGroups first menuItems first.
			item action cull: item.
			self assert: calls size equals: 1.
			self
				assert: calls first == target
				description: 'Inspect did not receive the clicked entity'.
			self assertSelectionOf: presenter isOn: target inFile: 'a.txt' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterStaleSelectionTest >> testRightClickOnTargetsMovedBeforeAndAfterInspectsTheClickedEntity [
	"(b)+(c) Right click then Inspect for the two directions: ClassC from b.txt (row 5 to 1) and ClassB1 from a.txt (row 2 to 3). Two windows, one after the other."

	#( #( 'ClassC' 'b.txt' ) #( 'ClassB1' 'a.txt' ) ) do: [ :each |
			| presenter target calls item |
			presenter := self newPresenterOn: each second filter: #all.
			target := self entity: each first.
			calls := self recordInspectionsOf: presenter.
			self withOpenWindowOf: presenter do: [ :window |
					self clickRowOf: target in: presenter button: #right.
					item := presenter treeContextMenu menuGroups first menuItems
						        first.
					item action cull: item.
					self assert: calls size equals: 1.
					self
						assert: calls first == target
						description: 'Inspect did not receive ' , each first ] ]
]

{ #category : 'tests - no window' }
MMCCoveragePresenterStaleSelectionTest >> testSpecSelectionAfterSwitchToClassAFromB [

	self
		assertSpecSelectionAfterSwitchTo: 'ClassA'
		from: 'b.txt'
		filter: #all
]

{ #category : 'tests - no window' }
MMCCoveragePresenterStaleSelectionTest >> testSpecSelectionAfterSwitchToClassB1FromATargetMovesAfter [

	self
		assertSpecSelectionAfterSwitchTo: 'ClassB1'
		from: 'a.txt'
		filter: #all
]

{ #category : 'tests - no window' }
MMCCoveragePresenterStaleSelectionTest >> testSpecSelectionAfterSwitchToClassCFromBTargetMovesBefore [

	self
		assertSpecSelectionAfterSwitchTo: 'ClassC'
		from: 'b.txt'
		filter: #all
]

{ #category : 'tests - no window' }
MMCCoveragePresenterStaleSelectionTest >> testSpecSelectionAfterSwitchToClassHInCoveredMode [

	self
		assertSpecSelectionAfterSwitchTo: 'ClassH'
		from: 'b.txt'
		filter: #covered
]

{ #category : 'helpers' }
MMCCoveragePresenterStaleSelectionTest >> waitUpTo: someMilliseconds until: aBlock [
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
MMCCoveragePresenterStaleSelectionTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Skipped without World. Open aPresenter, wait for the rows of the tree and for the layout to settle (1 s), evaluate aBlock, then always close the window, remove the menus popped up by the block and check that the number of windows is the same as before."

	| window windowsBefore menusBefore |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isSystemWindow ].
	menusBefore := World submorphs select: [ :each | each isMenuMorph ].
	[
		window := aPresenter open.
		self
			assert: (self waitUpTo: 3000 until: [
						 aPresenter treePresenter adapter widget container exposedRows
							 notNil and: [
							 aPresenter treePresenter adapter widget container exposedRows
								 notEmpty ] ])
			description: 'the tree rows were not exposed'.
		self waitUpTo: 1000 until: [ false ].
		aBlock value: window ] ensure: [
			(World submorphs select: [ :each |
				 each isMenuMorph and: [ (menusBefore includes: each) not ] ])
				do: [ :each | each delete ].
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ].
	self
		assert: (World submorphs count: [ :each | each isSystemWindow ])
		equals: windowsBefore
]

{ #category : 'fixture' }
MMCCoveragePresenterStaleSelectionTest >> writeText: aString to: aFileName [
	"UTF-8 text file in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ]
]
