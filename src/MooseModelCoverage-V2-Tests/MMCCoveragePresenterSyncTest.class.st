"
Tests of the two-way synchronisation tree <-> text of MMCCoveragePresenter, of the tree status and toggle states, of relative paths, of newExample and of the paned layout. Fixture (see #buildFixture): text of 10 lines of 10 characters (9 visible + line feed), entities Engine 1-50 (contains the attribute cylinders 1-10, same first character, and the method start 21-35), Fuel 61-90 (method pump with two regions 71-75 and 81-85), packages pkg (without region, ancestor) and pkgB (Orphan, never covered). Uncovered zones: 51-59 and 91-99.
"
Class {
	#name : 'MMCCoveragePresenterSyncTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'fixture'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> accountText [

	^ 'class Account {}'
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> assertSelectedEntityOf: aPresenter is: anEntityOrNil [
	"Compare the selected entity of the tree by identity, with names in the message."

	self
		assert: aPresenter selectedEntityInTree == anEntityOrNil
		description:
			'expected the tree selection ' , (self nameOf: anEntityOrNil)
			, ' but it is ' , (self nameOf: aPresenter selectedEntityInTree)
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> buildFixture [
	"Entities and regions (positions of #sampleText). Hierarchy: pkg(Engine(cylinders, start), Fuel(pump)), pkgB(Orphan).
	Regions: Engine 1-50, cylinders 1-10 (same first character as Engine), start 21-35, Fuel 61-90, pump 71-75 and 81-85. pkg, pkgB and Orphan have no region.
	Uncovered zones: 51-59 and 91-99. Blanks (line feeds) not covered: 60 and 100."

	| d model |
	d := Dictionary new.
	d at: #pkg put: (self entityOf: FamixJavaPackage named: 'pkg').
	d at: #pkgB put: (self entityOf: FamixJavaPackage named: 'pkgB').
	d at: #engine put: (self entityOf: FamixJavaClass named: 'Engine').
	d at: #fuel put: (self entityOf: FamixJavaClass named: 'Fuel').
	d at: #orphan put: (self entityOf: FamixJavaClass named: 'Orphan').
	d
		at: #cylinders
		put: (self entityOf: FamixJavaAttribute named: 'cylinders').
	d at: #start put: (self entityOf: FamixJavaMethod named: 'start').
	d at: #pump put: (self entityOf: FamixJavaMethod named: 'pump').
	(d at: #pkg)
		addType: (d at: #engine);
		addType: (d at: #fuel).
	(d at: #pkgB) addType: (d at: #orphan).
	(d at: #engine)
		addAttribute: (d at: #cylinders);
		addMethod: (d at: #start).
	(d at: #fuel) addMethod: (d at: #pump).
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	(d values select: [ :each | each isKindOf: FamixJavaEntity ]) do: [
		:each | model add: each ].
	d at: #model put: model.
	d
		at: #coverage
		put: (self newCoverageFor: self sampleText regions: {
					 (self regionOf: (d at: #engine) from: 1 to: 50).
					 (self regionOf: (d at: #cylinders) from: 1 to: 10).
					 (self regionOf: (d at: #start) from: 21 to: 35).
					 (self regionOf: (d at: #fuel) from: 61 to: 90).
					 (self regionOf: (d at: #pump) from: 71 to: 75).
					 (self regionOf: (d at: #pump) from: 81 to: 85) }).
	^ d
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> callsOf: aSelector in: aPresenter [
	"Answer how many times aSelector was logged by the instrumented presenter."

	^ aPresenter callLog count: [ :each | each first = aSelector ]
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> entityNamed: aString in: aPresenter [
	"Answer the entity labelled aString found by walking the tree of aPresenter from its roots (nil when absent). Names only, no printString of Famix entities."

	| pending |
	pending := OrderedCollection withAll: aPresenter navigator roots.
	[ pending isEmpty ] whileFalse: [
			| each |
			each := pending removeFirst.
			(aPresenter navigator labelOf: each) = aString ifTrue: [ ^ each ].
			pending addAll: (aPresenter navigator childrenOf: each) ].
	^ nil
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> entityOf: aFamixClass named: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> fixtureAt: aKey [
	"Answer a named element of the fixture (an entity, #model or #coverage)."

	fixture ifNil: [ fixture := self buildFixture ].
	^ fixture at: aKey
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> instrumentedPresenterClassWith: someSources [
	"Answer an ANONYMOUS subclass of MMCCoveragePresenter that logs in #callLog an Array {selector. isSynchronizing} at each call of #selectEntityInTree:, #treeSelectionChangedTo: and #textSelectionChangedTo: (then calls super), plus the extra method sources someSources."

	| class |
	class := MMCCoveragePresenter newAnonymousSubclass.
	class addInstVarNamed: 'callLog'.
	class compile: 'callLog
	^ callLog ifNil: [ callLog := OrderedCollection new ]'.
	class compile: 'selectEntityInTree: anEntity
	self callLog add: { #selectEntityInTree:. self isSynchronizing }.
	^ super selectEntityInTree: anEntity'.
	class compile: 'treeSelectionChangedTo: anEntity
	self callLog add: { #treeSelectionChangedTo:. self isSynchronizing }.
	^ super treeSelectionChangedTo: anEntity'.
	class compile: 'textSelectionChangedTo: anInterval
	self callLog add: { #textSelectionChangedTo:. self isSynchronizing }.
	^ super textSelectionChangedTo: anInterval'.
	someSources do: [ :source | class compile: source ].
	^ class
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> linesOf: aString [
	"The lines of aString whatever the line end convention (a stream cr is not the same character as a line feed)."

	^ aString lines
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> nameOf: anEntityOrNil [
	"The name of anEntityOrNil, for assertion messages (never print a Famix entity)."

	^ anEntityOrNil
		  ifNil: [ 'nil' ]
		  ifNotNil: [ :each | each name asString ]
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> newAccountModelWithRootFolder: aRootFolder [
	"FamixJava model with the class Account anchored on the RELATIVE file name 'src/Account.java' (characters 1 to 16), and aRootFolder as rootFolder."

	| aModel anchor class |
	aModel := FamixJavaModel new.
	aModel rootFolder: aRootFolder.
	class := self entityOf: FamixJavaClass named: 'Account'.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'src/Account.java'.
	anchor startPos: 1.
	anchor endPos: 16.
	aModel add: class.
	aModel add: anchor.
	class sourceAnchor: anchor.
	^ aModel
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> newCoverageFor: aText regions: aCollection [
	"Readable coverage of aText with the given regions (no ignored, no other file anchor)."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: aText
			   regions: aCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> newInstrumentedPresenterWith: someSources [
	"Not opened presenter of an instrumented anonymous subclass on the fixture."

	^ (self instrumentedPresenterClassWith: someSources)
		  on: (self fixtureAt: #coverage)
		  model: (self fixtureAt: #model)
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> newPresenter [
	"Not opened presenter on the fixture: coverage and Moose model."

	^ MMCCoveragePresenter
		  on: (self fixtureAt: #coverage)
		  model: (self fixtureAt: #model)
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> newPresenterWithoutModel [

	^ MMCCoveragePresenter on: (self fixtureAt: #coverage)
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> panedLayoutsIn: aLayout [
	"Answer every SpPanedLayout found in aLayout, aLayout included (children that are presenters are skipped)."

	| found |
	found := OrderedCollection new.
	(aLayout isKindOf: SpPanedLayout) ifTrue: [ found add: aLayout ].
	aLayout children do: [ :child |
			(child isKindOf: SpExecutableLayout) ifTrue: [
				found addAll: (self panedLayoutsIn: child) ] ].
	^ found
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> presenterWithoutAnchoredEntityAndRootFolder: aRootFolder [
	"Presenter on a readable text without any region, on a model that holds an entity and whose rootFolder is aRootFolder: the covered tree is empty."

	| aModel |
	aModel := FamixJavaModel new.
	aModel rootFolder: aRootFolder.
	aModel add: (self entityOf: FamixJavaClass named: 'Lonely').
	^ MMCCoveragePresenter
		  on: (self newCoverageFor: self sampleText regions: #(  ))
		  model: aModel
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> regionOf: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> sampleText [
	"Answer 100 characters: ten lines of 10 characters (4 letters, 5 digits, then a line feed). Line k holds the positions 10(k-1)+1 to 10k."

	^ String streamContents: [ :stream |
			  1 to: 10 do: [ :index |
					  stream
						  nextPutAll: 'row-';
						  nextPutAll: (index printPaddedWith: $0 to: 5);
						  nextPut: Character lf ] ]
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-v2-' , UUID new asString).
	folder ensureCreateDirectory
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testARealCaretAtTheSameStartAfterTheEchoSelectsTheDeepestEntity [
	"After selecting Engine (echo ignored), a real click at position 1 (empty interval 1 to: 0) is not a region of Engine: the deepest entity at 1, cylinders, is selected."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #engine).
	presenter textSelectionChangedTo: (1 to: 50).
	presenter textSelectionChangedTo: (1 to: 0).
	self
		assertSelectedEntityOf: presenter
		is: (self fixtureAt: #cylinders)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testDefaultLayoutContainsAtLeastTwoPanedLayouts [
	"Three columns separated by two movable dividers: [left | text | right] needs two SpPanedLayout (nested), instead of the fixed widths."

	| paned |
	paned := self panedLayoutsIn: self newPresenter layout.
	self assert: paned size >= 2
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testDetailsTextOfAMultiLineRegion [
	"Engine 1-50: position 1 is on line 1 ((1-1)//10 + 1), position 50 on line 5 ((50-1)//10 + 1)."

	| presenter |
	presenter := self newPresenter.
	self
		assert:
		(self linesOf: (presenter detailsTextFor: (self fixtureAt: #engine)))
		equals: #( 'Class Engine' '  Region 1-50 (line 1-5)' )
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testDetailsTextOfASingleLineRegionHasOneLineNumber [
	"cylinders 1-10: position 10 is the line feed of line 1, so one line."

	| presenter |
	presenter := self newPresenter.
	self
		assert: (self linesOf:
				 (presenter detailsTextFor: (self fixtureAt: #cylinders)))
		equals: #( 'Attribute cylinders' '  Region 1-10 (line 1)' )
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testDetailsTextOfAnEntityWithSeveralRegionsHasOneLinePerRegion [
	"pump: 71-75 is on line 8 (70/10+1), 81-85 is on line 9 (80/10+1)."

	| presenter |
	presenter := self newPresenter.
	self
		assert:
		(self linesOf: (presenter detailsTextFor: (self fixtureAt: #pump)))
		equals:
		#( 'Method pump' '  Region 71-75 (line 8)' '  Region 81-85 (line 9)' )
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testDetailsTextOfAnEntityWithoutRegionSaysSo [

	| presenter |
	presenter := self newPresenter.
	self
		assert:
		(self linesOf: (presenter detailsTextFor: (self fixtureAt: #pkg)))
		equals: #( 'Package pkg' '  (no region in this file)' )
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testDetailsTextOfNilIsEmpty [

	self assert: (self newPresenter detailsTextFor: nil) equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testForModelFileKeepsAnAbsolutePathAbsolute [
	"The absolute path of src/Account.java is not resolved again against the root folder of the model (which would give a wrong path)."

	| presenter |
	self writeAccountFile.
	presenter := MMCCoveragePresenter
		             forModel:
		             (self newAccountModelWithRootFolder:
			              folder asFileReference)
		             file: (folder / 'src' / 'Account.java') pathString.
	self assert: presenter fileCoverage isReadable.
	self assert: presenter fileCoverage size equals: 16
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testForModelFileResolvesARelativePathAgainstTheRootFolder [
	"The model has the root folder, the file is src/Account.java under it, the anchors are relative: 16 characters, one region."

	| presenter |
	self writeAccountFile.
	presenter := MMCCoveragePresenter
		             forModel:
		             (self newAccountModelWithRootFolder:
			              folder asFileReference)
		             file: 'src/Account.java'.
	self assert: presenter fileCoverage isReadable.
	self assert: presenter fileCoverage size equals: 16.
	self assert: presenter fileCoverage regions size equals: 1
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testForModelFileWithAMissingRelativeFileIsUnreadableWithoutError [

	| presenter |
	self writeAccountFile.
	presenter := MMCCoveragePresenter
		             forModel:
		             (self newAccountModelWithRootFolder:
			              folder asFileReference)
		             file: 'src/Missing.java'.
	self deny: presenter fileCoverage isReadable.
	self assert: (presenter summaryText includesSubstring: 'rootFolder')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testHandlersReturnImmediatelyWhileSynchronizing [
	"The tree selection made by the text synchronisation triggers, inside #selectEntityInTree:, a nested #textSelectionChangedTo: (1 to: 0) that would select cylinders if it was not ignored: the selection stays on start."

	| presenter |
	presenter := self newInstrumentedPresenterWith:
		             #( 'selectEntityInTree: anEntity
	super selectEntityInTree: anEntity.
	self textSelectionChangedTo: (1 to: 0)' ).
	presenter textSelectionChangedTo: (25 to: 24).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #start)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testIsSynchronizingIsFalseAfterTheSynchronisationsInBothDirections [

	| presenter |
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self fixtureAt: #start).
	self deny: presenter isSynchronizing.
	presenter textSelectionChangedTo: (71 to: 70).
	self deny: presenter isSynchronizing.
	presenter selectEntityInTree: (self fixtureAt: #engine).
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testIsSynchronizingIsFalseOnANewPresenter [

	self deny: self newPresenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testIsSynchronizingIsReleasedAfterAnErrorInTheTextToTreeSynchronisation [

	| presenter error |
	presenter := self newInstrumentedPresenterWith:
		             #( 'selectEntityInTree: anEntity
	self error: ''boom in the tree''' ).
	error := [
		         presenter textSelectionChangedTo: (25 to: 24).
		         nil ]
		         on: Error
		         do: [ :e | e messageText ].
	self assert: error equals: 'boom in the tree'.
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testIsSynchronizingIsReleasedAfterAnErrorInTheTreeToTextSynchronisation [

	| presenter error |
	presenter := self newInstrumentedPresenterWith:
		             #( 'detailsTextFor: anEntity
	self error: ''boom in the details''' ).
	error := [
		         presenter treeSelectionChangedTo: (self fixtureAt: #start).
		         nil ]
		         on: Error
		         do: [ :e | e messageText ].
	self assert: error equals: 'boom in the details'.
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testIsSynchronizingIsTrueWhenTheTextSynchronisationSelectsTheTree [
	"The instrumented #selectEntityInTree: logs the flag: it must be true when the synchronisation text to tree calls it."

	| presenter |
	presenter := self newInstrumentedPresenterWith: #(  ).
	presenter textSelectionChangedTo: (25 to: 24).
	self
		assert: (presenter callLog select: [ :each |
				 each first = #selectEntityInTree: ])
		equals: { { #selectEntityInTree:. true } } asOrderedCollection
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleAttributeSelectedInTheTreeIsSelectedInTheText [
	"The region of balance starts with 'int balance;' (the declaration, not its later uses)."

	| presenter interval |
	presenter := MMCCoveragePresenter newExample.
	presenter selectEntityInTree:
		(self entityNamed: 'balance' in: presenter).
	interval := presenter textPresenter selectionInterval.
	self assert: interval size > 1.
	self assert: ((presenter textPresenter text asString
			  copyFrom: interval first
			  to: interval last) beginsWith: 'int balance;')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleHasAMooseModelAndTreeRoots [

	| presenter |
	presenter := MMCCoveragePresenter newExample.
	self assert: presenter model notNil.
	self assert: presenter navigator roots size >= 1.
	self assert: presenter treePresenter roots isEmpty not
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleHasAPlanAndTwoUncoveredZones [
	"The example text starts and ends with an uncovered line: two zones."

	| presenter |
	presenter := MMCCoveragePresenter newExample.
	self assert: presenter plan size > 0.
	self assert: presenter uncoveredListPresenter items size equals: 2
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleHasNoTreeStatusMessage [

	self
		assert: MMCCoveragePresenter newExample treeStatusText
		equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleHasTheAccountEntitiesInTheTree [
	"package bank > class Account > 3 methods and 2 attributes (names, not entities, are compared)."

	| presenter |
	presenter := MMCCoveragePresenter newExample.
	#( 'bank' 'Account' 'deposit' 'withdraw' 'getBalance' 'balance'
	   'owner' ) do: [ :each |
			self
				assert: (self entityNamed: each in: presenter) notNil
				description: 'the example tree has no entity ' , each ]
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleMethodSelectedInTheTreeIsSelectedInTheText [
	"The region of deposit starts with 'void deposit' (see the example source)."

	| presenter interval |
	presenter := MMCCoveragePresenter newExample.
	presenter selectEntityInTree:
		(self entityNamed: 'deposit' in: presenter).
	interval := presenter textPresenter selectionInterval.
	self assert: interval size > 1.
	self assert: ((presenter textPresenter text asString
			  copyFrom: interval first
			  to: interval last) beginsWith: 'void deposit')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testNewExampleSummaryMentionsTheTwoUncoveredZones [

	| presenter |
	presenter := MMCCoveragePresenter newExample.
	self assert: presenter summaryText isEmpty not.
	self assert:
		(presenter summaryText includesSubstring: 'uncovered zone').
	self assert:
		(presenter summaryText includesSubstring: '2 uncovered zone')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testRealClickDoesNotRewriteTheTextSelection [
	"The caret (1 to: 0) selects cylinders in the tree programmatically; the tree handler must not then replace the caret by 1-10."

	| presenter |
	presenter := self newPresenter.
	presenter textPresenter selectionInterval: (1 to: 0).
	presenter textSelectionChangedTo: (1 to: 0).
	self
		assertSelectedEntityOf: presenter
		is: (self fixtureAt: #cylinders).
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 0)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSelectingAPathInTheTreePresenterTriggersTheTextSelection [
	"Same as a click on the row: treePresenter selectPath: (no selectEntityInTree:)."

	| presenter |
	presenter := self newPresenter.
	presenter treePresenter selectPath:
		(presenter navigator pathTo: (self fixtureAt: #fuel)).
	self
		assert: presenter textPresenter selectionInterval
		equals: (61 to: 90)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSelectingAnEntityInTheTreeThenEchoKeepsTheContainingEntitySelected [
	"Critical case: Engine (1-50) contains cylinders (1-10), same first character. Selecting Engine selects 1-50 in the text; Rubric answers with that same interval, which must NOT select cylinders (the deepest entity at 1)."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #engine).
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 50).
	presenter textSelectionChangedTo: (1 to: 50).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #engine)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSelectingAnEntityWithSelectEntityInTreeTriggersTheTextSelection [
	"The handler of the tree (whenSelectionChangedDo:, also fired by the Mock/no adapter presenters) calls #treeSelectionChangedTo:."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #start).
	self
		assert: presenter textPresenter selectionInterval
		equals: (21 to: 35).
	self
		assert: presenter detailsPresenter text asString
		equals: (presenter detailsTextFor: (self fixtureAt: #start))
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSelectingAnUncoveredZoneThenTheEchoDeselectsTheTree [
	"The zone 51-59 is selected in the text; the echo of Rubric designates no entity, so the tree selection (start) is cleared without error."

	| presenter zone |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #start).
	zone := presenter uncoveredListPresenter items first.
	presenter selectUncoveredRegion: zone.
	self
		assert: presenter textPresenter selectionInterval
		equals: (51 to: 59).
	presenter textSelectionChangedTo:
		presenter textPresenter selectionInterval.
	self assertSelectedEntityOf: presenter is: nil.
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSelectingTheSecondUncoveredZoneThenTheEchoShowsItsDetails [
	"The zone 91-99: the details are those of position 91 ('Uncovered zone 91-99')."

	| presenter |
	presenter := self newPresenter.
	presenter selectUncoveredRegion:
		presenter uncoveredListPresenter items second.
	presenter textSelectionChangedTo:
		presenter textPresenter selectionInterval.
	self
		assert: presenter textPresenter selectionInterval
		equals: (91 to: 99).
	self assert:
		(presenter detailsPresenter text asString includesSubstring:
			 'Uncovered zone 91-99')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSmokeLayoutGivesTheTextAtLeastFortyPercentOfTheWindow [
	"Real window. (1) the text is at least 40 % of the window width (with the former fixed widths of 280 and 340 it was the remainder only), (2) horizontal order tree < text < uncovered list, (3) the tree is between 120 px and 40 % of the window. Run in the small World of the image, the window is bounded by it."

	| presenter |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			| windowWidth textWidth treeWidth treeLeft textLeft listLeft |
			World doOneCycle.
			windowWidth := window adapter widget bounds width.
			textWidth := presenter textPresenter adapter widget bounds width.
			treeWidth := presenter treePresenter adapter widget bounds width.
			treeLeft := presenter treePresenter adapter widget bounds left.
			textLeft := presenter textPresenter adapter widget bounds left.
			listLeft := presenter uncoveredListPresenter adapter widget bounds
				            left.
			self
				assert: textWidth >= (windowWidth * 0.4)
				description:
					'text width ' , textWidth printString , ' of the window width '
					, windowWidth printString.
			self
				assert: treeLeft < textLeft
				description: 'the tree is not left of the text'.
			self
				assert: textLeft < listLeft
				description: 'the text is not left of the list'.
			self
				assert: treeWidth >= 120
				description: 'tree width ' , treeWidth printString.
			self
				assert: treeWidth <= (windowWidth * 0.4)
				description:
					'tree width ' , treeWidth printString , ' of the window width '
					, windowWidth printString ]
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSmokeTwoWaySynchronisation [
	"Real window on the fixture. Phase 1: selectEntityInTree: start selects 21-35 in the model of the text AND in the Rubric editor (markIndex 21, pointIndex 36), and the echo does not move the tree. Phase 2: a caret put at the start of pump (editor selectFrom: 71 to: 70) selects pump in the tree (Rubric event, possibly deferred: polled up to 3 s) and changes the details. Phase 3: after 500 ms the selection is stable, the details unchanged and the number of #textSelectionChangedTo: calls bounded (no oscillation)."

	| presenter |
	presenter := self newInstrumentedPresenterWith: #(  ).
	self withOpenWindowOf: presenter do: [ :window |
			| editor detailsBefore detailsAfter callsAfterPhase2 |
			editor := presenter textPresenter adapter widget textArea editor.
			presenter selectEntityInTree: (self fixtureAt: #start).
			self
				assert: presenter textPresenter selectionInterval
				equals: (21 to: 35).
			self assert: editor markIndex equals: 21.
			self assert: editor pointIndex equals: 36.
			self waitUpTo: 400 until: [ false ].
			self assertSelectedEntityOf: presenter is: (self fixtureAt: #start).
			detailsBefore := presenter detailsPresenter text asString.
			self
				assert: detailsBefore
				equals: (presenter detailsTextFor: (self fixtureAt: #start)).
			editor selectFrom: 71 to: 70.
			self
				assert: (self
						 waitUpTo: 3000
						 until: [
						 presenter selectedEntityInTree == (self fixtureAt: #pump) ])
				description:
					'the Rubric selection did not select pump in the tree, the tree selection is '
					, (self nameOf: presenter selectedEntityInTree).
			detailsAfter := presenter detailsPresenter text asString.
			self deny: detailsAfter equals: detailsBefore.
			self
				assert: detailsAfter
				equals: (presenter detailsTextFor: (self fixtureAt: #pump)).
			callsAfterPhase2 := self
				                    callsOf: #textSelectionChangedTo:
				                    in: presenter.
			self waitUpTo: 500 until: [ false ].
			self assertSelectedEntityOf: presenter is: (self fixtureAt: #pump).
			self
				assert: presenter detailsPresenter text asString
				equals: detailsAfter.
			self
				assert: (self callsOf: #textSelectionChangedTo: in: presenter)
					- callsAfterPhase2 <= 2
				description:
				'too many #textSelectionChangedTo: calls after the selection settled'.
			self assert:
				(self callsOf: #textSelectionChangedTo: in: presenter) <= 6.
			self deny: presenter isSynchronizing ]
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSummaryOfAnUnreadableFileWithAModelMentionsTheRootFolder [

	| presenter |
	presenter := self presenterWithoutAnchoredEntityAndRootFolder:
		             folder asFileReference.
	presenter updateFileCoverage:
		(MMCFileCoverage fromReadResult: (MMCAnchorReadResult
				  fileReference: nil
				  text: ''
				  regions: #(  )
				  ignoredAnchors: #(  )
				  otherFileAnchorCount: 0)).
	self assert: (presenter summaryText beginsWith: 'Unreadable file').
	self assert: (presenter summaryText includesSubstring: 'rootFolder')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testSummaryOfAnUnreadableFileWithoutModelIsUnchanged [

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (MMCFileCoverage fromReadResult: (MMCAnchorReadResult
				               fileReference: nil
				               text: ''
				               regions: #(  )
				               ignoredAnchors: #(  )
				               otherFileAnchorCount: 0)).
	self
		assert: presenter summaryText
		equals:
		'Unreadable file: no anchor of the model designates it, or its text is empty'
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionAfterTheEndOfTheTextIsClampedToTheLastPosition [
	"Position 500 is clamped to 100, the final line feed: not covered, so the tree is cleared."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #start).
	presenter textSelectionChangedTo: (500 to: 499).
	self assertSelectedEntityOf: presenter is: nil.
	self
		assert: presenter detailsPresenter text asString
		equals: (presenter detailsTextAt: 100)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionBeforeTheStartOfTheTextIsClampedToTheFirstPosition [
	"Position 0 is clamped to 1, where the deepest entity is cylinders."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (0 to: -1).
	self
		assertSelectedEntityOf: presenter
		is: (self fixtureAt: #cylinders)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionBetweenTheRegionsOfAMethodSelectsTheClass [
	"Position 78 is in Fuel (61-90) between the regions of pump (71-75 and 81-85)."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (78 to: 77).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #fuel)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInABlankDeselectsTheTreeAndSaysNotCovered [
	"Position 60 is the line feed between the zone 51-59 and Fuel: not covered, not in a zone."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #start).
	presenter textSelectionChangedTo: (60 to: 59).
	self assertSelectedEntityOf: presenter is: nil.
	self
		assert: presenter detailsPresenter text asString
		equals: (presenter detailsTextAt: 60).
	self
		assert: (presenter detailsTextAt: 60) lines last
		equals: 'Not covered (blank)'
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInAMethodSelectsTheMethod [
	"Position 25 is in start (21-35)."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (25 to: 24).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #start)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInANestedAttributeSelectsTheAttribute [
	"Position 5 is in cylinders (1-10), nested in Engine (1-50): the deepest is cylinders."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (5 to: 4).
	self
		assertSelectedEntityOf: presenter
		is: (self fixtureAt: #cylinders)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInAnEntityFillsTheDetailsOfThatEntity [

	| presenter start |
	presenter := self newPresenter.
	start := self fixtureAt: #start.
	presenter textSelectionChangedTo: (25 to: 24).
	self
		assert: presenter detailsPresenter text asString
		equals: (presenter detailsTextFor: start)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInAnUncoveredZoneDeselectsTheTreeAndSaysUncovered [
	"Position 55 is in the uncovered zone 51-59."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self fixtureAt: #start).
	presenter textSelectionChangedTo: (55 to: 54).
	self assertSelectedEntityOf: presenter is: nil.
	self
		assert: presenter detailsPresenter text asString
		equals: (presenter detailsTextAt: 55).
	self assert:
		(presenter detailsPresenter text asString includesSubstring:
			 'Uncovered zone 51-59')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInTheClassAloneSelectsTheClass [
	"Position 40 is in Engine (1-50) but outside cylinders (1-10) and start (21-35)."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (40 to: 39).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #engine)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionInTheSecondRegionOfAnEntitySelectsThatEntity [
	"Position 83 is in the second region 81-85 of pump."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (83 to: 82).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #pump)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionOfALargeIntervalUsesItsFirstPosition [
	"The interval 21-90 starts in start (21-35): the entity is the one at 21."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (21 to: 90).
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #start)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionOnAnUnreadableFileDoesNothing [
	"Empty text: no position, so no change and no error."

	| presenter unreadable |
	unreadable := MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			               fileReference: nil
			               text: ''
			               regions: #(  )
			               ignoredAnchors: #(  )
			               otherFileAnchorCount: 0).
	presenter := MMCCoveragePresenter
		             on: unreadable
		             model: (self fixtureAt: #model).
	presenter textSelectionChangedTo: (1 to: 0).
	self assertSelectedEntityOf: presenter is: nil.
	self assert: presenter detailsPresenter text asString equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTextSelectionWithoutModelLeavesTheTreeEmptyAndDoesNotFail [
	"Without model the tree is empty: nothing can be selected, whatever the position."

	| presenter |
	presenter := self newPresenterWithoutModel.
	presenter textSelectionChangedTo: (5 to: 4).
	self assertSelectedEntityOf: presenter is: nil
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeFilterAllWithoutModelKeepsTheNoModelMessage [

	| presenter |
	presenter := self newPresenterWithoutModel.
	presenter treeFilter: #all.
	self
		assert: presenter treeStatusText
		equals:
		'No Moose model: open with MMCCoveragePresenter openOn:file:'
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionEqualsTheFirstRegionOfTheNavigator [

	| presenter pump |
	presenter := self newPresenter.
	pump := self fixtureAt: #pump.
	presenter treeSelectionChangedTo: pump.
	self
		assert: presenter textPresenter selectionInterval
		equals: (presenter navigator firstRegionOf: pump) interval
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionFillsTheDetailsWithDetailsTextFor [

	| presenter pump |
	presenter := self newPresenter.
	pump := self fixtureAt: #pump.
	presenter treeSelectionChangedTo: pump.
	self
		assert: presenter detailsPresenter text asString
		equals: (presenter detailsTextFor: pump)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfAContainingEntitySelectsItsWholeRegion [
	"Engine has the region 1-50."

	| presenter |
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self fixtureAt: #engine).
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 50)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfANestedEntitySelectsItsOwnRegion [
	"cylinders (1-10) is nested in Engine (1-50): the text gets 1-10, not 1-50."

	| presenter |
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self fixtureAt: #cylinders).
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 10)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfASimpleEntitySelectsItsRegionInTheText [
	"start has the single region 21-35."

	| presenter |
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self fixtureAt: #start).
	self
		assert: presenter textPresenter selectionInterval
		equals: (21 to: 35)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfAnAncestorWithoutRegionKeepsTheTextSelectionAndSaysSo [
	"pkg has no region of its own: the text selection (5 to: 7) is untouched and the details say there is no region."

	| presenter |
	presenter := self newPresenter.
	presenter textPresenter selectionInterval: (5 to: 7).
	presenter treeSelectionChangedTo: (self fixtureAt: #pkg).
	self
		assert: presenter textPresenter selectionInterval
		equals: (5 to: 7).
	self
		assert: (self linesOf: presenter detailsPresenter text asString)
		equals: #( 'Package pkg' '  (no region in this file)' )
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfAnEntityWithSeveralRegionsSelectsTheFirstOne [
	"pump has the regions 71-75 then 81-85: the first one is selected."

	| presenter |
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self fixtureAt: #pump).
	self
		assert: presenter textPresenter selectionInterval
		equals: (71 to: 75)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfAnEntityWithoutRegionInWholeModelModeKeepsTheText [
	"Orphan is only visible with the whole model and has no region in this file."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter textPresenter selectionInterval: (30 to: 32).
	presenter treeSelectionChangedTo: (self fixtureAt: #orphan).
	self
		assert: presenter textPresenter selectionInterval
		equals: (30 to: 32).
	self
		assert: (self linesOf: presenter detailsPresenter text asString)
		equals: #( 'Class Orphan' '  (no region in this file)' )
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeSelectionOfNilKeepsTheTextSelectionAndClearsTheDetails [

	| presenter |
	presenter := self newPresenter.
	presenter treeSelectionChangedTo: (self fixtureAt: #start).
	self deny: presenter detailsPresenter text asString isEmpty.
	presenter treeSelectionChangedTo: nil.
	self
		assert: presenter textPresenter selectionInterval
		equals: (21 to: 35).
	self assert: presenter detailsPresenter text asString equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusAcceptsARootFolderGivenAsAString [

	| presenter |
	presenter := self presenterWithoutAnchoredEntityAndRootFolder:
		             '/some/root/folder'.
	self assert: (presenter treeStatusText includesSubstring:
			 '(rootFolder: /some/root/folder)')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusDoesNotFailWithoutRootFolder [

	| presenter |
	presenter := self presenterWithoutAnchoredEntityAndRootFolder: nil.
	self assert: (presenter treeStatusText beginsWith:
			 'No entity of the model is anchored in this file')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusIsEmptyWhenTheTreeHasEntities [
	"Choice: no message when everything is fine (no 'N entities' counter)."

	| presenter |
	presenter := self newPresenter.
	self assert: presenter treeStatusText equals: ''.
	self assert: presenter treeStatusPresenter label asString equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusIsUpdatedByTreeFilter [
	"No region: the covered tree is empty (message), the whole model (1 entity) is not (empty status), and back to covered: message again."

	| presenter |
	presenter := self presenterWithoutAnchoredEntityAndRootFolder:
		             folder asFileReference.
	presenter treeFilter: #all.
	self assert: presenter navigator roots size equals: 1.
	self assert: presenter treeStatusText equals: ''.
	presenter treeFilter: #covered.
	self assert: (presenter treeStatusText beginsWith:
			 'No entity of the model is anchored in this file')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusIsUpdatedByUpdateFileCoverage [
	"Normal coverage, then a coverage without region (message), then the normal one again."

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage:
		(self newCoverageFor: self sampleText regions: #(  )).
	self assert: (presenter treeStatusText beginsWith:
			 'No entity of the model is anchored in this file').
	self
		assert: presenter treeStatusPresenter label asString
		equals: presenter treeStatusText.
	presenter updateFileCoverage: (self fixtureAt: #coverage).
	self assert: presenter treeStatusText equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusIsUpdatedByUpdateFileCoverageModel [
	"With the model: normal. With nil: no model message. With the model again: normal."

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self fixtureAt: #coverage) model: nil.
	self
		assert: presenter treeStatusText
		equals:
		'No Moose model: open with MMCCoveragePresenter openOn:file:'.
	presenter
		updateFileCoverage: (self fixtureAt: #coverage)
		model: (self fixtureAt: #model).
	self assert: presenter treeStatusText equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusPresenterIsALabel [

	self assert:
		(self newPresenter treeStatusPresenter isKindOf: SpLabelPresenter)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusWithAModelButNoAnchoredEntityShowsTheRootFolder [
	"rootFolder is a FileReference (the default type)."

	| presenter |
	presenter := self presenterWithoutAnchoredEntityAndRootFolder:
		             folder asFileReference.
	self assert: presenter navigator roots isEmpty.
	self assert: (presenter treeStatusText beginsWith:
			 'No entity of the model is anchored in this file').
	self assert: (presenter treeStatusText includesSubstring:
			 '(rootFolder: ' , folder pathString , ')')
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeStatusWithoutModelSaysHowToOpenWithAModel [

	| presenter |
	presenter := self newPresenterWithoutModel.
	self
		assert: presenter treeStatusText
		equals:
		'No Moose model: open with MMCCoveragePresenter openOn:file:'.
	self
		assert: presenter treeStatusPresenter label
		equals: presenter treeStatusText
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testTreeToTextRoundTripSelectsTheTextOnceAndNeverReselectsTheTree [
	"Click on Engine in the tree (selectPath:), then the echo of Rubric: exactly one #treeSelectionChangedTo:, no #selectEntityInTree:, one tree selection event, Engine stays selected."

	| presenter treeEvents |
	presenter := self newInstrumentedPresenterWith: #(  ).
	treeEvents := 0.
	presenter treePresenter whenSelectionChangedDo: [ :selection |
		treeEvents := treeEvents + 1 ].
	presenter treePresenter selectPath:
		(presenter navigator pathTo: (self fixtureAt: #engine)).
	presenter textSelectionChangedTo:
		presenter textPresenter selectionInterval.
	self
		assert: (self callsOf: #treeSelectionChangedTo: in: presenter)
		equals: 1.
	self
		assert: (self callsOf: #selectEntityInTree: in: presenter)
		equals: 0.
	self assert: treeEvents equals: 1.
	self assertSelectedEntityOf: presenter is: (self fixtureAt: #engine).
	self
		assert: presenter textPresenter selectionInterval
		equals: (1 to: 50)
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testWholeModelToggleFollowsTheModelOfUpdateFileCoverageModel [

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self fixtureAt: #coverage) model: nil.
	self deny: presenter wholeModelTogglePresenter isEnabled.
	presenter
		updateFileCoverage: (self fixtureAt: #coverage)
		model: (self fixtureAt: #model).
	self assert: presenter wholeModelTogglePresenter isEnabled
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testWholeModelToggleIsDisabledWithoutModel [

	self deny:
		self newPresenterWithoutModel wholeModelTogglePresenter isEnabled
]

{ #category : 'tests' }
MMCCoveragePresenterSyncTest >> testWholeModelToggleIsEnabledWithAModel [

	self assert: self newPresenter wholeModelTogglePresenter isEnabled
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> waitUpTo: someMilliseconds until: aBlock [
	"Let Morphic run (200 ms steps) until aBlock is true or someMilliseconds elapsed. Answer the final value of aBlock."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 200) wait.
			World doOneCycle.
			waited := waited + 200 ].
	^ aBlock value
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Open aPresenter in a forked process (15 s limit: #waitTimeoutSeconds: answers TRUE on timeout), evaluate aBlock with the window, and always close it, then check that no SpWindow is left. Skipped without World."

	| window semaphore timedOut openError windowsBefore |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isKindOf: SpWindow ].
	semaphore := Semaphore new.
	openError := nil.
	[
		[
			[ window := aPresenter open ]
				on: Error
				do: [ :e | openError := e ] ] ensure: [ semaphore signal ] ] fork.
	[
		timedOut := semaphore waitTimeoutSeconds: 15.
		self
			deny: timedOut
			description: 'the window did not open within 15 seconds'.
		self
			assert: openError isNil
			description: 'open raised ' , openError class name.
		aBlock value: window ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ].
			self
				assert:
				(World submorphs count: [ :each | each isKindOf: SpWindow ])
				equals: windowsBefore ]
]

{ #category : 'helpers' }
MMCCoveragePresenterSyncTest >> writeAccountFile [
	"Write the 16 characters of #accountText in src/Account.java under the temporary folder (UTF-8) and answer the file."

	| ref |
	ref := folder / 'src' / 'Account.java'.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :stream |
		stream nextPutAll: self accountText utf8Encoded ].
	^ ref
]
