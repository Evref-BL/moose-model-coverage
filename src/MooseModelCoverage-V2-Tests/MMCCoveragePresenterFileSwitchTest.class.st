"
TDD tests of the automatic file switch of MMCCoveragePresenter: treeSelectionChangedTo: on an entity whose regions are in another file switches the current file (showFile: on the first file of filesOf: holding a region) and selects the first region in the text; no switch when the entity has a region in the current file or none anywhere; whole model and filtered trees; no echo loop; tree filter and selection after a file change; window title (windowTitleText) and global summary (globalSummaryText, filesSummaryPresenter); one smoke test with a real window closed in ensure:. Same fixture as MMCCoveragePresenterFilesTest (a.txt ClassA, b.txt ClassB, c.txt ClassC, gone.txt unreadable ClassG, entity Orphan without anchor), plus a FamixTest1 model for an entity spread over two files.
"
Class {
	#name : 'MMCCoveragePresenterFileSwitchTest',
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

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> addClass: aName on: aFileName from: start to: end [
	"Add to the model the class aName (kept under aName in entities) with an indexed file anchor."

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

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> addSplit: aName parts: aCollection [
	"Add to the FamixTest1 model an entity aName (kept in entities) spread over several files. aCollection holds {file name. start. end}, in the order of the anchors."

	| entity multi |
	multi := FamixTest1MultipleFileAnchor new.
	model add: multi.
	entity := FamixTest1Class new
		          name: aName;
		          yourself.
	model add: entity.
	entity sourceAnchor: multi.
	aCollection do: [ :each |
			| leaf |
			leaf := FamixTest1IndexedFileAnchor new.
			leaf fileName: each first.
			leaf startPos: (each at: 2).
			leaf endPos: (each at: 3).
			model add: leaf.
			multi addSourceAnchor: leaf ].
	entities at: aName put: entity.
	^ entity
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> buildFullyCoveredFixture [
	"p.txt and q.txt, 10 chars each, entirely covered (no uncovered zone)."

	self writeText: (String new: 10 withAll: $x) to: 'p.txt'.
	self writeText: (String new: 10 withAll: $x) to: 'q.txt'.
	self
		addClass: 'ClassP'
		on: 'p.txt'
		from: 1
		to: 10.
	self
		addClass: 'ClassQ'
		on: 'q.txt'
		from: 1
		to: 10
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> buildSplitFixture [
	"FamixTest1 model, a.txt b.txt c.txt of 100 chars. Solo: a.txt 1-10. Split: b.txt 5-50 and c.txt 20-60. Wide: a.txt 60-80 and b.txt 60-90. Sorted files: a.txt b.txt c.txt."

	model := FamixTest1Model new.
	model rootFolder: folder asFileReference.
	#( 'a.txt' 'b.txt' 'c.txt' ) do: [ :each |
		self writeText: (String new: 100 withAll: $x) to: each ].
	self addSplit: 'Solo' parts: { #( 'a.txt' 1 10 ) }.
	self addSplit: 'Split' parts: {
			#( 'b.txt' 5 50 ).
			#( 'c.txt' 20 60 ) }.
	self addSplit: 'Wide' parts: {
			#( 'a.txt' 60 80 ).
			#( 'b.txt' 60 90 ) }
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> buildStandardFixture [
	"a.txt: 100 chars, ClassA 1-50 (50.0 %, one uncovered zone). b.txt: 100 chars, ClassB 1-100 (100.0 %, no uncovered zone). c.txt: 3 chars, ClassC 1-1 (33.3 %, one uncovered zone). gone.txt: missing on disk (unreadable), ClassG. Orphan: class without anchor. Sorted relative names: a.txt b.txt c.txt gone.txt."

	self writeText: (String new: 100 withAll: $x) to: 'a.txt'.
	self writeText: (String new: 100 withAll: $x) to: 'b.txt'.
	self writeText: 'xxx' to: 'c.txt'.
	self
		addClass: 'ClassA'
		on: 'a.txt'
		from: 1
		to: 50.
	self
		addClass: 'ClassB'
		on: 'b.txt'
		from: 1
		to: 100.
	self
		addClass: 'ClassC'
		on: 'c.txt'
		from: 1
		to: 1.
	self
		addClass: 'ClassG'
		on: 'gone.txt'
		from: 1
		to: 2.
	entities at: 'Orphan' put: (FamixJavaClass new
			 name: 'Orphan';
			 yourself).
	model add: (entities at: 'Orphan')
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> entity: aName [

	^ entities at: aName
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> file: aFileName [
	"The canonical FileReference expected in MMCModelFiles>>files."

	^ (folder / aFileName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> globalText: total computed: done covered: aPercentageText [
	"Expected global summary, for example 'Files: 3 (dot) computed 2/3 (dot) covered 70.0%'."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Files: ';
				  print: total;
				  nextPutAll: self separator;
				  nextPutAll: 'computed ';
				  print: done;
				  nextPut: $/;
				  print: total;
				  nextPutAll: self separator;
				  nextPutAll: 'covered ';
				  nextPutAll: aPercentageText ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> namesOf: aCollection [

	^ (aCollection collect: [ :each | each name ]) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> newPresenter [
	"Not opened presenter on the inventory of the model (current file: the first sorted file). Registered to be closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> separator [
	"The middle dot used by the global summary."

	^ ' ' , (String with: (Character value: 16rB7)) , ' '
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-files-ui-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityInAnotherFileSwitchesTheFileAndSelectsItsFirstRegion [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self entity: 'ClassC').
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self assert: presenter textPresenter text equals: 'xxx'.
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 1).
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (self file: 'c.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityInTheCurrentFileDoesNotSwitchAndSelectsItsRegion [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self entity: 'ClassA').
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 50)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityInTheCurrentFileOfTwoFilesDoesNotMoveFromTheSecondOne [
	"Wide has a region in b.txt (current): stays on b.txt although a.txt is its first file."

	| presenter |
	self buildSplitFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'b.txt').
	presenter treeSelectionChangedTo: (self entity: 'Wide').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (60 to: 90)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityInTwoFilesNotHoldingTheCurrentOneUsesTheOrderOfFilesOf [
	"Wide has regions in a.txt (60-80) and b.txt (60-90); current c.txt: a.txt, first of filesOf:."

	| presenter |
	self buildSplitFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	presenter treeSelectionChangedTo: (self entity: 'Wide').
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (60 to: 80)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityInTwoFilesStaysInTheCurrentFileWhenItHasARegionThere [
	"Split has a region in c.txt, the current file: no move, the region of c.txt is selected even though b.txt comes first."

	| presenter |
	self buildSplitFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	presenter treeSelectionChangedTo: (self entity: 'Split').
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (20 to: 60)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityInTwoFilesSwitchesToTheFirstFileHoldingARegion [
	"Split has regions in b.txt (5-50) and c.txt (20-60); current file a.txt: b.txt is chosen."

	| presenter |
	self buildSplitFixture.
	presenter := self newPresenter.
	self assert: presenter currentFile equals: (self file: 'a.txt').
	presenter treeSelectionChangedTo: (self entity: 'Split').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (5 to: 50)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityOnlyAnchoredInAnUnreadableFileDoesNotSwitch [
	"ClassG is listed in gone.txt, which has no region (unreadable): nothing to select, no switch."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self entity: 'ClassG').
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testEntityWithoutRegionAnywhereChangesNeitherFileNorText [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter textPresenter selectionInterval: (3 to: 7).
	presenter treeSelectionChangedTo: (self entity: 'Orphan').
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (3 to: 7)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testGlobalSummaryAfterComputeAllCoversEveryReadableFile [
	"50 + 100 + 1 covered of 100 + 100 + 3 measured characters (gone.txt is unreadable and counts for 0): 151/203 = 74.4 percent."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter computeAllFiles.
	self assert: (presenter globalSummaryText beginsWith: 'Files: 4').
	self assert: (presenter globalSummaryText endsWith: 'covered 74.4%').
	self
		assert: presenter filesSummaryPresenter label
		equals: presenter globalSummaryText
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testGlobalSummaryAfterOpeningCountsOnlyTheFirstFile [
	"a.txt computed: 50 of 100 characters."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self
		assert: presenter globalSummaryText
		equals: (self globalText: 4 computed: 1 covered: '50.0%')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testGlobalSummaryIsUpdatedAfterEachComputation [
	"a.txt 50/100 then b.txt 100/100: 150/200."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'b.txt').
	self
		assert: presenter globalSummaryText
		equals: (self globalText: 4 computed: 2 covered: '75.0%').
	self
		assert: presenter filesSummaryPresenter label
		equals: presenter globalSummaryText
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testGlobalSummaryShowsQuestionMarkWhenNothingIsComputed [
	"Dropping the cache of the inventory leaves no computed file."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter modelFiles invalidate.
	self
		assert: presenter globalSummaryText
		equals: (self globalText: 4 computed: 0 covered: '?')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testGlobalSummaryShowsQuestionMarkWhenOnlyUnreadableFilesAreComputed [
	"The only file is unreadable: no character, no percentage."

	| presenter |
	self
		addClass: 'Gone'
		on: 'gone.txt'
		from: 1
		to: 2.
	presenter := self newPresenter.
	self assert: (presenter globalSummaryText beginsWith: 'Files: 1').
	self assert: (presenter globalSummaryText endsWith: 'covered ?')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testNilSelectionDoesNotSwitchNorFail [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: nil.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testNoEchoLoopWhenTheSwitchHappens [
	"After the switch the synchronization guard is released and the file does not bounce back."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self entity: 'ClassC').
	self deny: presenter isSynchronizing.
	self assert: presenter currentFile equals: (self file: 'c.txt').
	presenter treeSelectionChangedTo: (self entity: 'ClassC').
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 1)
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testOpenOnOpensTheFirstSortedFileOnARealWindowOrIsSkipped [
	"openOn: (first sorted file) shares the smoke conditions: needs a World, closed in ensure:."

	| presenter window |
	World ifNil: [ self skip: 'no world' ].
	self buildFullyCoveredFixture.
	[
		presenter := MMCCoveragePresenter openOn: model.
		presenters add: presenter.
		window := presenter window.
		self assert: presenter currentFile equals: (self file: 'p.txt').
		self assert: window title equals: 'Coverage - p.txt (1/2)' ]
		ensure: [
				window ifNotNil: [
						[ window close ]
							on: Error
							do: [ :e | e return ] ] ]
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testSelectingAFileInTheListDoesNotLoopWithTheTree [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileListPresenter selectItem: (self file: 'b.txt').
	self deny: presenter isSynchronizing.
	self assert: presenter currentFile equals: (self file: 'b.txt').
	presenter fileListPresenter selectItem: (self file: 'a.txt').
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testSmokeOpenWithRealWindowOnTheFilesThenCloseCleanly [
	"Only test with a real Morphic window (skipped without World): openOn:file: on b.txt of the fixture, navigation, title of the window, then the window is closed in ensure: and no window remains."

	| presenter window windowsBefore |
	World ifNil: [ self skip: 'no world' ].
	self buildStandardFixture.
	windowsBefore := World submorphs count: [ :each |
		                 each isSystemWindow ].
	[
		presenter := MMCCoveragePresenter openOn: model file: 'b.txt'.
		presenters add: presenter.
		window := presenter window.
		self assert: window isOpen.
		self assert: presenter currentFile equals: (self file: 'b.txt').
		self assert: window title equals: 'Coverage - b.txt (2/4)'.
		presenter nextFile.
		self assert: presenter currentFile equals: (self file: 'c.txt').
		self assert: window title equals: 'Coverage - c.txt (3/4)'.
		self assert: presenter textPresenter text equals: 'xxx' ] ensure: [
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
MMCCoveragePresenterFileSwitchTest >> testSplitFixtureInventoryIsAsDocumented [
	"Sanity check of the fixture, on the existing MMCModelFiles only."

	| files |
	self buildSplitFixture.
	files := MMCModelFiles on: model.
	self assert: files fileCount equals: 3.
	self
		assert: ((files filesOf: (self entity: 'Split')) collect: [ :each |
				 files relativeNameOf: each ]) asArray
		equals: #( 'b.txt' 'c.txt' ).
	self
		assert: ((files filesOf: (self entity: 'Wide')) collect: [ :each |
				 files relativeNameOf: each ]) asArray
		equals: #( 'a.txt' 'b.txt' )
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testSwitchFromTheWholeModelTreeBySelectingTheEntity [
	"Whole model mode: ClassB is visible in the tree although it is in another file; selecting it in the tree switches the file."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter selectEntityInTree: (self entity: 'ClassB').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 100).
	self assert:
		presenter selectedEntityInTree == (self entity: 'ClassB').
	self assert: presenter treeFilter equals: #all
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testSwitchInFilteredModeSelectsTheEntityInTheTreeOfTheNewFile [
	"Filtered mode: ClassB is not in the tree of a.txt; after the switch the tree shows the covered entities of b.txt, ClassB included and selected."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'ClassA' ).
	presenter treeSelectionChangedTo: (self entity: 'ClassB').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'ClassB' ).
	self assert:
		presenter selectedEntityInTree == (self entity: 'ClassB').
	self assert: presenter treeFilter equals: #covered
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testSwitchedFileIsComputedOnDemand [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self assert:
		(presenter modelFiles summaryFor: (self file: 'b.txt')) isNil.
	presenter treeSelectionChangedTo: (self entity: 'ClassB').
	self assert:
		(presenter modelFiles summaryFor: (self file: 'b.txt')) notNil.
	self
		assert: (presenter fileLabelFor: (self file: 'b.txt'))
		equals: 'b.txt  100.0%'
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testTreeFilterCoveredReflectsTheNewFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'ClassC' ).
	presenter treeFilter: #all.
	presenter showFile: (self file: 'b.txt').
	presenter treeFilter: #covered.
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'ClassB' )
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testTreeSelectionIsClearedAfterAFileChangeWhenTheEntityIsNoMoreVisible [
	"Filtered mode: ClassA is only covered in a.txt."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter selectEntityInTree: (self entity: 'ClassA').
	self assert:
		presenter selectedEntityInTree == (self entity: 'ClassA').
	presenter showFile: (self file: 'b.txt').
	self assert: presenter selectedEntityInTree isNil.
	self assert: presenter currentFile equals: (self file: 'b.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testTreeSelectionIsKeptAfterAFileChangeWhenTheEntityStaysVisible [
	"Whole model mode: Orphan (no region) is visible in every file."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter selectEntityInTree: (self entity: 'Orphan').
	presenter showFile: (self file: 'b.txt').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self assert:
		presenter selectedEntityInTree == (self entity: 'Orphan')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testTreeSelectionIsKeptWhenTheSameEntityIsCoveredInTheNewFile [
	"Split is covered in b.txt and c.txt: kept when moving from b.txt to c.txt in filtered mode."

	| presenter |
	self buildSplitFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'b.txt').
	presenter selectEntityInTree: (self entity: 'Split').
	presenter showFile: (self file: 'c.txt').
	self assert: presenter selectedEntityInTree == (self entity: 'Split').
	self assert: presenter currentFile equals: (self file: 'c.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testWindowTitleCountsAllFilesWhateverTheFilter [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'c.txt'.
	self
		assert: presenter windowTitleText
		equals: 'Coverage - a.txt (1/4)'
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testWindowTitleFollowsTheAutomaticSwitch [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self entity: 'ClassB').
	self
		assert: presenter windowTitleText
		equals: 'Coverage - b.txt (2/4)'
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testWindowTitleShowsRelativeNameAndPosition [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self
		assert: presenter windowTitleText
		equals: 'Coverage - a.txt (1/4)'.
	presenter showFile: (self file: 'c.txt').
	self
		assert: presenter windowTitleText
		equals: 'Coverage - c.txt (3/4)'.
	presenter showFile: (self file: 'gone.txt').
	self
		assert: presenter windowTitleText
		equals: 'Coverage - gone.txt (4/4)'
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testWindowTitleUsesTheRelativePathOfSubfolderFiles [

	| presenter |
	self writeText: 'xxxx' to: 'src/Foo.txt'.
	self
		addClass: 'Foo'
		on: 'src/Foo.txt'
		from: 1
		to: 2.
	presenter := self newPresenter.
	self
		assert: presenter windowTitleText
		equals: 'Coverage - src/Foo.txt (1/1)'
]

{ #category : 'tests' }
MMCCoveragePresenterFileSwitchTest >> testWindowTitleWithoutInventoryIsJustCoverage [

	| presenter coverage |
	self buildStandardFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self assert: presenter windowTitleText equals: 'Coverage'
]

{ #category : 'helpers' }
MMCCoveragePresenterFileSwitchTest >> writeText: aString to: aFileName [
	"UTF-8 text file in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
