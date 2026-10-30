"
Tests of the option 'Open source file in file manager' of the context menu of the tree of MMCCoveragePresenter: sourceFileOf: (canonical FileReference of the source file of an entity, preferring the current file; nil without file), openFileAction / openFileAction: (one argument block receiving the FileReference; the tests always inject a recorder and NEVER run the native opening), openSourceFileOfTreeEntity, and treeContextMenu (items 'Inspect' then 'Open source file in file manager', the second disabled without file). Real window tests use a synthetic right click as MMCCoveragePresenterStaleSelectionTest does. Fixture: a temporary folder (removed in tearDown) with a.txt and b.txt, classes ClassA (a.txt) and ClassB (b.txt) in the package pkg, ClassG anchored in the missing gone.txt, Orphan without anchor.
"
Class {
	#name : 'MMCCoveragePresenterOpenFileTest',
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
MMCCoveragePresenterOpenFileTest >> addClass: aName on: aFileName from: start to: end [
	"Add to the model a class (kept under aName in entities) with an indexed file anchor."

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
	entities at: aName put: entity.
	^ entity
]

{ #category : 'fixture' }
MMCCoveragePresenterOpenFileTest >> buildFixture [
	"a.txt and b.txt of 100 chars. pkg (no anchor) contains ClassA (a.txt 11-40), ClassB (b.txt 11-40) and ClassG (gone.txt, missing on disk). Orphan has no anchor and no package."

	| pkg orphan |
	self writeText: (String new: 100 withAll: $x) to: 'a.txt'.
	self writeText: (String new: 100 withAll: $x) to: 'b.txt'.
	pkg := FamixJavaPackage new
		       name: 'pkg';
		       yourself.
	model add: pkg.
	entities at: 'pkg' put: pkg.
	pkg addType: (self
			 addClass: 'ClassA'
			 on: 'a.txt'
			 from: 11
			 to: 40).
	pkg addType: (self
			 addClass: 'ClassB'
			 on: 'b.txt'
			 from: 11
			 to: 40).
	pkg addType: (self
			 addClass: 'ClassG'
			 on: 'gone.txt'
			 from: 1
			 to: 5).
	orphan := FamixJavaClass new
		          name: 'Orphan';
		          yourself.
	model add: orphan.
	entities at: 'Orphan' put: orphan
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> dismiss: aMenuMorph [
	"Remove a popped up menu and give back the mouse and keyboard focus the menu took (otherwise the next right click is swallowed)."

	aMenuMorph delete.
	World activeHand releaseAllFocus.
	self waitUpTo: 200 until: [ false ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> entity: aName [

	^ entities at: aName
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> file: aFileName [
	"The canonical FileReference expected from sourceFileOf:."

	^ (folder / aFileName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> isEnabledItem: anItem [
	"isEnabled answers a boolean or a block answering a boolean (Spec2 accepts both)."

	| enabled |
	enabled := anItem isEnabled.
	^ enabled isBlock
		  ifTrue: [ enabled value ]
		  ifFalse: [ enabled ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> itemMorphsOf: aMenuMorph [
	"The menu item morphs of a popped up menu, in display order."

	^ aMenuMorph allMorphs select: [ :each |
		  each isKindOf: MenuItemMorph ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> menuItemsOf: aMenu [
	"All the items of all the groups of an SpMenuPresenter."

	^ aMenu menuGroups
		  inject: OrderedCollection new
		  into: [ :all :group |
				  all
					  addAll: group menuItems;
					  yourself ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> menusInWorld [

	^ World submorphs select: [ :each | each isMenuMorph ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> newPresenter [
	"Not opened presenter on the inventory of the model (current file: a.txt). Registered to be closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> newPresenterWithoutInventory [
	"Not opened presenter on the coverage of a.txt and the model, without inventory (modelFiles is nil)."

	| coverage |
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	^ presenters add: (MMCCoveragePresenter on: coverage model: model)
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> newSplitPresenter [
	"Presenter with inventory on a FamixTest1 model (FamixJava has no multiple file anchor) in the fixture folder: Split spread over a.txt (1-10) then b.txt (11-30), Solo in c.txt (1-10). Entities are registered under Split and Solo (replacing nothing of the Java fixture names)."

	| other split solo multi |
	self writeText: (String new: 100 withAll: $x) to: 'c.txt'.
	other := FamixTest1Model new.
	other rootFolder: folder asFileReference.
	multi := FamixTest1MultipleFileAnchor new.
	other add: multi.
	split := FamixTest1Class new
		         name: 'Split';
		         yourself.
	other add: split.
	split sourceAnchor: multi.
	{
		{ 'a.txt'. 1. 10 }.
		{ 'b.txt'. 11. 30 } } do: [ :each |
			| leaf |
			leaf := FamixTest1IndexedFileAnchor new.
			leaf fileName: each first.
			leaf startPos: (each at: 2).
			leaf endPos: (each at: 3).
			other add: leaf.
			multi addSourceAnchor: leaf ].
	solo := FamixTest1Class new
		        name: 'Solo';
		        yourself.
	other add: solo.
	solo sourceAnchor: (FamixTest1IndexedFileAnchor new
			 fileName: 'c.txt';
			 startPos: 1;
			 endPos: 10;
			 yourself).
	other add: solo sourceAnchor.
	entities at: 'Split' put: split.
	entities at: 'Solo' put: solo.
	^ presenters add: (MMCCoveragePresenter forModel: other)
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> openFileActionOf: aPresenter [

	^ aPresenter perform: #openFileAction
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> openItemOf: aPresenter [
	"The second item of a new context menu of aPresenter, checked to be 'Open source file in file manager'."

	| items |
	items := self menuItemsOf: aPresenter treeContextMenu.
	self assert: items size equals: 2.
	self
		assert: items last name
		equals: 'Open source file in file manager'.
	^ items last
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> openSourceFileOfTreeEntityIn: aPresenter [

	^ aPresenter perform: #openSourceFileOfTreeEntity
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> popUpMenuAfterRightClickOn: anEntity in: aPresenter [
	"Right click on the row of anEntity and answer the single MenuMorph popped up by it (checked). Spike result: in this image a synthetic right click that follows a previous popped up menu (closed in between) is swallowed by the hand (click state of FTTableMorph>>mouseDown: / waitForClicksOrDrag:) and the menu block is not even evaluated; the next identical click works. So the click is repeated up to 3 times until a menu is popped up."

	| before popped attempts |
	before := self menusInWorld.
	attempts := 0.
	[
		attempts := attempts + 1.
		self rightClickRowOf: anEntity in: aPresenter.
		self waitUpTo: 1000 until: [
				(self menusInWorld reject: [ :each | before includes: each ])
					isNotEmpty ].
		(self menusInWorld reject: [ :each | before includes: each ])
			isEmpty and: [ attempts < 3 ] ] whileTrue.
	self waitUpTo: 200 until: [ false ].
	popped := self menusInWorld reject: [ :each | before includes: each ].
	self assert: popped size = 1 description: 'one menu is popped up'.
	^ popped first
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> recordInspectionsOf: aPresenter [
	"Replace the inspect action of aPresenter by a recorder (no inspector is opened); answer the collection of the entities received."

	| calls |
	calls := OrderedCollection new.
	aPresenter inspectAction: [ :entity | calls add: entity ].
	^ calls
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> recordOpensOf: aPresenter [
	"Replace the open file action of aPresenter by a recorder (the native opening is NEVER run); answer the collection of the files received. Sent by perform: because the API does not exist yet."

	| calls |
	calls := OrderedCollection new.
	aPresenter
		perform: #openFileAction:
		with: [ :aFile | calls add: aFile ].
	^ calls
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> rightClickRowOf: anEntity in: aPresenter [
	"Dispatch through the hand a synthetic press and release of the right button on the row of anEntity (the row exists: the ancestors are unfolded by selectEntityInTree:), then let Morphic run."

	| table index row point hand |
	aPresenter selectEntityInTree: anEntity.
	index := self rowIndexOf: anEntity in: aPresenter.
	self assert: index > 0 description: 'the entity has no row to click'.
	self waitUpTo: 1000 until: [
			table := aPresenter treePresenter adapter widget.
			table container exposedRows notNil and: [
				table container exposedRows includesKey: index ] ].
	row := table container exposedRows at: index.
	point := row bounds center.
	hand := World activeHand.
	hand handleEvent: (MouseButtonEvent new
			 setType: #mouseDown
			 position: point
			 which: 2
			 buttons: 2
			 hand: hand
			 stamp: Time millisecondClockValue).
	hand handleEvent: (MouseButtonEvent new
			 setType: #mouseUp
			 position: point
			 which: 2
			 buttons: 0
			 hand: hand
			 stamp: Time millisecondClockValue).
	self waitUpTo: 400 until: [ false ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> rowIndexOf: anEntity in: aPresenter [
	"Index of the FastTable row showing anEntity, 0 when it has no row."

	| source |
	source := aPresenter treePresenter adapter widget dataSource.
	^ (1 to: source numberOfRows)
		  detect: [ :each | (source elementAt: each) data == anEntity ]
		  ifNone: [ 0 ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> selectInTree: anEntityName of: aPresenter [
	"Select in the tree the entity registered under that name (nil clears)."

	aPresenter selectEntityInTree:
		(anEntityName ifNotNil: [ self entity: anEntityName ])
]

{ #category : 'fixture' }
MMCCoveragePresenterOpenFileTest >> setUp [
	"Temporary folder, model with this rootFolder, then the fixture."

	super setUp.
	folder := FileLocator temp / ('mmc-openfile-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new.
	self buildFixture
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> sourceFileOf: anEntity in: aPresenter [

	^ aPresenter perform: #sourceFileOf: with: anEntity
]

{ #category : 'fixture' }
MMCCoveragePresenterOpenFileTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testInspectItemStillReceivesTheSelectedEntity [
	"Non regression of Inspect with the two item menu."

	| presenter items inspections opens |
	presenter := self newPresenter.
	inspections := self recordInspectionsOf: presenter.
	opens := self recordOpensOf: presenter.
	self selectInTree: 'ClassA' of: presenter.
	items := self menuItemsOf: presenter treeContextMenu.
	items first action cull: items first.
	self assert: inspections size equals: 1.
	self assert: inspections first == (self entity: 'ClassA').
	self assert: opens isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenFileActionDefaultIsANonNilOneArgumentBlockDistinctFromTheRecorder [
	"The default action is a block of one argument (the real native opening); it is only checked, never evaluated. A recorder replaces it, and the default is back on a new presenter."

	| presenter default calls |
	presenter := self newPresenter.
	default := self openFileActionOf: presenter.
	self assert: default isBlock.
	self assert: default numArgs equals: 1.
	calls := self recordOpensOf: presenter.
	self deny: (self openFileActionOf: presenter) == default.
	self assert: (self openFileActionOf: self newPresenter) isBlock
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenFileActionSetterStoresTheBlock [

	| presenter block |
	presenter := self newPresenter.
	block := [ :aFile | aFile ].
	presenter perform: #openFileAction: with: block.
	self assert: (self openFileActionOf: presenter) == block
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenItemActionCallsTheActionOnceWithTheFileAndNeverInspects [

	| presenter item opens inspections |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	inspections := self recordInspectionsOf: presenter.
	self selectInTree: 'ClassA' of: presenter.
	item := self openItemOf: presenter.
	item action cull: item.
	self assert: opens size equals: 1.
	self assert: opens first equals: (self file: 'a.txt').
	self assert: inspections isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenItemActionOnAnEntityWithoutFileCallsNothing [

	| presenter item opens |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	self selectInTree: 'pkg' of: presenter.
	item := self openItemOf: presenter.
	item action cull: item.
	self assert: opens isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenItemIsDisabledForAnEntityWithoutFile [
	"The package has no anchor; Inspect stays enabled."

	| presenter items |
	presenter := self newPresenter.
	self selectInTree: 'pkg' of: presenter.
	items := self menuItemsOf: presenter treeContextMenu.
	self assert: items size equals: 2.
	self assert: (self isEnabledItem: items first).
	self deny: (self isEnabledItem: items last)
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenItemIsDisabledWhenTheFileIsMissingFromTheDisk [
	"ClassA is selected, then a.txt disappears: the menu built afterwards has the item disabled."

	| presenter |
	presenter := self newPresenter.
	self selectInTree: 'ClassA' of: presenter.
	(folder / 'a.txt') ensureDelete.
	self deny: (self isEnabledItem: (self openItemOf: presenter))
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenItemIsDisabledWithoutSelection [

	| presenter |
	presenter := self newPresenter.
	self selectInTree: nil of: presenter.
	self deny: (self isEnabledItem: (self openItemOf: presenter))
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenItemIsEnabledForAnEntityWithAFile [

	| presenter |
	presenter := self newPresenter.
	self selectInTree: 'ClassA' of: presenter.
	self assert: (self isEnabledItem: (self openItemOf: presenter))
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenSourceFileOfTreeEntityCallsTheActionOnceWithTheFileOfTheSelectedEntity [

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordOpensOf: presenter.
	self selectInTree: 'ClassA' of: presenter.
	self assert:
		presenter selectedEntityInTree == (self entity: 'ClassA').
	self openSourceFileOfTreeEntityIn: presenter.
	self assert: calls size equals: 1.
	self assert: calls first equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenSourceFileOfTreeEntityDoesNotInspectNorChangeTheSelection [

	| presenter opens inspections |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	inspections := self recordInspectionsOf: presenter.
	self selectInTree: 'ClassA' of: presenter.
	self openSourceFileOfTreeEntityIn: presenter.
	self assert: opens size equals: 1.
	self assert: inspections isEmpty.
	self assert:
		presenter selectedEntityInTree == (self entity: 'ClassA').
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenSourceFileOfTreeEntityOfAnEntityWithoutFileCallsNothing [
	"The package pkg has no anchor: nothing is opened and no error is raised."

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordOpensOf: presenter.
	self selectInTree: 'pkg' of: presenter.
	self assert: presenter selectedEntityInTree == (self entity: 'pkg').
	self openSourceFileOfTreeEntityIn: presenter.
	self assert: calls isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenSourceFileOfTreeEntityWithoutInventoryUsesTheRootFolder [

	| presenter calls |
	presenter := self newPresenterWithoutInventory.
	calls := self recordOpensOf: presenter.
	self selectInTree: 'ClassA' of: presenter.
	self openSourceFileOfTreeEntityIn: presenter.
	self assert: calls size equals: 1.
	self assert: calls first equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testOpenSourceFileOfTreeEntityWithoutSelectionCallsNothing [

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordOpensOf: presenter.
	self selectInTree: nil of: presenter.
	self assert: presenter selectedEntityInTree isNil.
	self openSourceFileOfTreeEntityIn: presenter.
	self assert: calls isEmpty
]

{ #category : 'tests - real window' }
MMCCoveragePresenterOpenFileTest >> testRightClickOnAnEntityWithAFilePopsUpTheTwoEnabledItems [
	"Real window: right click on the row of ClassA: the MenuMorph holds Inspect then Open source file in file manager, both enabled, and the click selected the row. Nothing is triggered."

	| presenter |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			| menu items |
			menu := self
				        popUpMenuAfterRightClickOn: (self entity: 'ClassA')
				        in: presenter.
			items := self itemMorphsOf: menu.
			self
				assert:
				(items collect: [ :each | each contents asString ]) asArray
				equals: #( 'Inspect' 'Open source file in file manager' ).
			items do: [ :each | self assert: each isEnabled ].
			self assert:
				presenter selectedEntityInTree == (self entity: 'ClassA').
			self dismiss: menu ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterOpenFileTest >> testRightClickOnAnEntityWithoutFileDisablesTheOpenItem [
	"Real window: right click on the package pkg (no anchor): Inspect is enabled, the open item is disabled and triggering it calls nothing (the menu stays until dismissed)."

	| presenter opens inspections |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	inspections := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			| menu items |
			menu := self
				        popUpMenuAfterRightClickOn: (self entity: 'pkg')
				        in: presenter.
			self assert: presenter selectedEntityInTree == (self entity: 'pkg').
			items := self itemMorphsOf: menu.
			self assert: items size equals: 2.
			self assert: items first isEnabled.
			self deny: items last isEnabled.
			self trigger: items last.
			self assert: opens isEmpty.
			self assert: inspections isEmpty.
			self dismiss: menu.
			self
				deny: (World submorphs includes: menu)
				description: 'the menu is closed' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterOpenFileTest >> testRightClickOnTwoRowsBuildsTwoIndependentMenus [
	"Real window: right click on ClassA then on pkg (first menu closed in between): the open item of the first menu is enabled, the one of the second menu (built again) is disabled and nothing is opened."

	| presenter opens |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			| first second |
			first := self
				         popUpMenuAfterRightClickOn: (self entity: 'ClassA')
				         in: presenter.
			self assert: (self itemMorphsOf: first) last isEnabled.
			self dismiss: first.
			second := self
				          popUpMenuAfterRightClickOn: (self entity: 'pkg')
				          in: presenter.
			self deny: (self itemMorphsOf: second) last isEnabled.
			self dismiss: second.
			self assert: opens isEmpty ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterOpenFileTest >> testRightClickThenInspectItemStillInspectsTheClickedEntity [
	"Real window, non regression: Inspect receives ClassA, the open action is not called, the menu is closed."

	| presenter opens inspections |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	inspections := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			| menu |
			menu := self
				        popUpMenuAfterRightClickOn: (self entity: 'ClassA')
				        in: presenter.
			self trigger: (self itemMorphsOf: menu) first.
			self assert: inspections size equals: 1.
			self assert: inspections first == (self entity: 'ClassA').
			self assert: opens isEmpty.
			self
				deny: (World submorphs includes: menu)
				description: 'the menu is closed' ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterOpenFileTest >> testRightClickThenOpenItemCallsTheActionWithTheFileAndClosesTheMenu [
	"Real window: triggering the second item calls the recorder once with the canonical file of ClassA; Inspect is not called; the menu is closed afterwards."

	| presenter opens inspections |
	presenter := self newPresenter.
	opens := self recordOpensOf: presenter.
	inspections := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			| menu |
			menu := self
				        popUpMenuAfterRightClickOn: (self entity: 'ClassA')
				        in: presenter.
			self trigger: (self itemMorphsOf: menu) last.
			self assert: opens size equals: 1.
			self assert: opens first equals: (self file: 'a.txt').
			self assert: inspections isEmpty.
			self
				deny: (World submorphs includes: menu)
				description: 'the menu is closed' ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfAFileDeletedAfterTheInventoryIsNil [
	"The inventory knows b.txt but it disappears from the disk: nil, and a.txt is still answered."

	| presenter |
	presenter := self newPresenter.
	(folder / 'b.txt') ensureDelete.
	self assert:
		(self sourceFileOf: (self entity: 'ClassB') in: presenter) isNil.
	self
		assert: (self sourceFileOf: (self entity: 'ClassA') in: presenter)
		equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfASplitEntityIsTheFirstFileWhenTheCurrentFileHoldsNoRegionOfIt [
	"The current file is c.txt, which holds no region of Split: the first file of Split (a.txt)."

	| presenter |
	presenter := self newSplitPresenter.
	presenter showFile: (self file: 'c.txt').
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self
		assert: (self sourceFileOf: (self entity: 'Split') in: presenter)
		equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfASplitEntityPrefersTheCurrentFileWhenItHoldsARegionOfTheEntity [
	"Split has regions in a.txt then b.txt: the first file when a.txt is shown, b.txt (not the first) once b.txt is the current file."

	| presenter split |
	presenter := self newSplitPresenter.
	split := self entity: 'Split'.
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self
		assert: (self sourceFileOf: split in: presenter)
		equals: (self file: 'a.txt').
	presenter showFile: (self file: 'b.txt').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self
		assert: (self sourceFileOf: split in: presenter)
		equals: (self file: 'b.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfAnEntityOfAnotherFileIsItsOwnFileNotTheCurrentOne [
	"Solo lives in c.txt only: whatever the current file, c.txt."

	| presenter |
	presenter := self newSplitPresenter.
	self
		assert: (self sourceFileOf: (self entity: 'Solo') in: presenter)
		equals: (self file: 'c.txt').
	presenter showFile: (self file: 'b.txt').
	self
		assert: (self sourceFileOf: (self entity: 'Solo') in: presenter)
		equals: (self file: 'c.txt')
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfAnEntityWhoseFileIsMissingIsNil [
	"ClassG is anchored in gone.txt, which does not exist: nil with and without inventory."

	{
		self newPresenter.
		self newPresenterWithoutInventory } do: [ :presenter |
			self assert:
				(self sourceFileOf: (self entity: 'ClassG') in: presenter) isNil ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfAnEntityWithReadableAnchorIsTheCanonicalFile [
	"With inventory: the canonical file of the anchor of the entity."

	| presenter |
	presenter := self newPresenter.
	self
		assert: (self sourceFileOf: (self entity: 'ClassA') in: presenter)
		equals: (self file: 'a.txt').
	self
		assert: (self sourceFileOf: (self entity: 'ClassB') in: presenter)
		equals: (self file: 'b.txt')
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfAnEntityWithoutAnchorIsNil [
	"Package and orphan class have no anchor, with and without inventory."

	{
		self newPresenter.
		self newPresenterWithoutInventory } do: [ :presenter |
			#( 'pkg' 'Orphan' ) do: [ :name |
					self
						assert:
						(self sourceFileOf: (self entity: name) in: presenter) isNil
						description: name , ' has no file' ] ]
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfAnswersAFileReference [
	"The answer is a FileReference that exists."

	| file |
	file := self
		        sourceFileOf: (self entity: 'ClassA')
		        in: self newPresenter.
	self assert: (file isKindOf: FileReference).
	self assert: file exists
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfOddArgumentsAnswersNilWithoutError [
	"nil, a number, a string, a plain object and a Famix entity of no model (never printed): nil, with and without inventory."

	{
		self newPresenter.
		self newPresenterWithoutInventory } do: [ :presenter |
			{
				nil.
				42.
				'text'.
				Object new.
				FamixJavaClass new } do: [ :each |
				self assert: (self sourceFileOf: each in: presenter) isNil ] ]
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfWithoutInventoryAcceptsAnAbsolutePath [
	"The anchor holds the absolute path of b.txt: same canonical file."

	| presenter |
	self
		addClass: 'Absolute'
		on: (folder / 'b.txt') asFileReference pathString
		from: 1
		to: 5.
	presenter := self newPresenterWithoutInventory.
	self
		assert: (self sourceFileOf: (self entity: 'Absolute') in: presenter)
		equals: (self file: 'b.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfWithoutInventoryResolvesARelativePathAgainstTheRootFolder [
	"No modelFiles: the anchor 'a.txt' is resolved against the rootFolder of the model, for the shown file and for another one."

	| presenter |
	presenter := self newPresenterWithoutInventory.
	self assert: presenter modelFiles isNil.
	self
		assert: (self sourceFileOf: (self entity: 'ClassA') in: presenter)
		equals: (self file: 'a.txt').
	self
		assert: (self sourceFileOf: (self entity: 'ClassB') in: presenter)
		equals: (self file: 'b.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testSourceFileOfWithoutModelAnswersNil [
	"Presenter on a coverage with a nil Moose model: nothing to resolve."

	| coverage presenter |
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: nil).
	self assert:
		(self sourceFileOf: (self entity: 'ClassA') in: presenter) isNil.
	self assert: (self sourceFileOf: nil in: presenter) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testTreeContextMenuHasTheTwoItemsInOrder [

	| presenter items |
	presenter := self newPresenter.
	self selectInTree: 'ClassA' of: presenter.
	items := self menuItemsOf: presenter treeContextMenu.
	self
		assert: (items collect: [ :each | each name ]) asArray
		equals: #( 'Inspect' 'Open source file in file manager' )
]

{ #category : 'tests' }
MMCCoveragePresenterOpenFileTest >> testTreeContextMenuIsReevaluatedAtEveryPopup [
	"treePresenter contextMenu is a block: the state of the items follows the selection at each evaluation."

	| presenter menu1 menu2 |
	presenter := self newPresenter.
	self assert: presenter treePresenter contextMenu isBlock.
	self selectInTree: 'ClassA' of: presenter.
	menu1 := presenter treePresenter contextMenu value.
	self selectInTree: 'pkg' of: presenter.
	menu2 := presenter treePresenter contextMenu value.
	self deny: menu1 == menu2.
	self assert: (self isEnabledItem: (self menuItemsOf: menu1) last).
	self deny: (self isEnabledItem: (self menuItemsOf: menu2) last)
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> trigger: anItemMorph [
	"Run the action of a menu item morph as a click does (nothing when it is disabled; a popped up menu closes itself), then give back the focus taken by the menu."

	anItemMorph doButtonAction.
	World activeHand releaseAllFocus.
	self waitUpTo: 200 until: [ false ]
]

{ #category : 'helpers' }
MMCCoveragePresenterOpenFileTest >> waitUpTo: someMilliseconds until: aBlock [
	"Let Morphic run (100 ms steps) until aBlock is true or someMilliseconds elapsed. Answer the final value of aBlock."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 100) wait.
			World doOneCycle.
			waited := waited + 100 ].
	^ aBlock value
]

{ #category : 'helpers - window' }
MMCCoveragePresenterOpenFileTest >> withOpenWindowOf: aPresenter do: aBlock [
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
MMCCoveragePresenterOpenFileTest >> writeText: aString to: aFileName [
	"UTF-8 text file in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ]
]
