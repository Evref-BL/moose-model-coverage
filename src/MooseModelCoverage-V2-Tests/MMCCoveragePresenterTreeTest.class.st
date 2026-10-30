"
Tests of the model tree (MMCModelNavigator based) shown on the left of MMCCoveragePresenter: constructors keeping the Moose model, roots, lazy children, labels, colors, filter toggle, selection, updates, performance and one smoke test in a real window.
"
Class {
	#name : 'MMCCoveragePresenterTreeTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'fixture'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> buildLargeEntities [
	"50 packages x 20 classes x 9 methods = 10 050 entities, in creation order."

	| all |
	all := OrderedCollection new: 10100.
	1 to: 50 do: [ :p |
			| pkg |
			pkg := self named: FamixJavaPackage name: 'pkg' , p printString.
			all add: pkg.
			1 to: 20 do: [ :c |
					| cls |
					cls := self
						       named: FamixJavaClass
						       name: 'Cls' , p printString , '_' , c printString.
					pkg addType: cls.
					all add: cls.
					1 to: 9 do: [ :m |
							| method |
							method := self named: FamixJavaMethod name: 'm' , m printString.
							cls addMethod: method.
							all add: method ] ] ].
	^ all
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> buildLargeModelAndCoverages [
	"Answer { model. coverage A. coverage B } on 10 050 entities. A covers the classes with c \\ 10 < 7 (700 classes, 7 000 regions: 700 + 6 300), B those with c \\ 10 >= 3 (also 700 classes, 7 000 regions). Heavy: only called by the performance test."

	| entities |
	entities := self buildLargeEntities.
	^ {
		  (self modelWith: entities).
		  (self largeCoverageOf: entities coveredWhen: [ :c | c \\ 10 < 7 ]).
		  (self largeCoverageOf: entities coveredWhen: [ :c | c \\ 10 >= 3 ]) }
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> buildSmallFixture [
	"Text of 100 characters. Hierarchy: pkgA(Alpha(run, count), Aardvark), pkgB(Beta(stop), Gamma(abort)), pkgC(Delta).
	Regions of #coverage: Alpha 1-50, run 10-30, count 35-45, Beta 60-90, stop 70-80. Covered: Alpha, run, count, Beta, stop (+ ancestors pkgA, pkgB, which are not covered themselves but visible). Never covered: pkgC, Delta, Aardvark, Gamma, abort.
	Regions of #otherCoverage: Gamma 1-20, abort 5-10 (only pkgB, Gamma, abort visible in covered mode)."

	| d |
	d := Dictionary new.
	d at: #pkgA put: (self named: FamixJavaPackage name: 'pkgA').
	d at: #pkgB put: (self named: FamixJavaPackage name: 'pkgB').
	d at: #pkgC put: (self named: FamixJavaPackage name: 'pkgC').
	d at: #alpha put: (self named: FamixJavaClass name: 'Alpha').
	d at: #aardvark put: (self named: FamixJavaClass name: 'Aardvark').
	d at: #beta put: (self named: FamixJavaClass name: 'Beta').
	d at: #gamma put: (self named: FamixJavaClass name: 'Gamma').
	d at: #delta put: (self named: FamixJavaClass name: 'Delta').
	d at: #run put: (self named: FamixJavaMethod name: 'run').
	d at: #count put: (self named: FamixJavaAttribute name: 'count').
	d at: #stop put: (self named: FamixJavaMethod name: 'stop').
	d at: #abort put: (self named: FamixJavaMethod name: 'abort').
	(d at: #pkgA)
		addType: (d at: #alpha);
		addType: (d at: #aardvark).
	(d at: #pkgB)
		addType: (d at: #beta);
		addType: (d at: #gamma).
	(d at: #pkgC) addType: (d at: #delta).
	(d at: #alpha)
		addMethod: (d at: #run);
		addAttribute: (d at: #count).
	(d at: #beta) addMethod: (d at: #stop).
	(d at: #gamma) addMethod: (d at: #abort).
	d at: #model put: (self modelWith:
			 (d select: [ :each | each isKindOf: FamixJavaEntity ]) values).
	d at: #coverage put: (self coverageOfSize: 100 regions: {
				 (self regionFor: (d at: #alpha) from: 1 to: 50).
				 (self regionFor: (d at: #run) from: 10 to: 30).
				 (self regionFor: (d at: #count) from: 35 to: 45).
				 (self regionFor: (d at: #beta) from: 60 to: 90).
				 (self regionFor: (d at: #stop) from: 70 to: 80) }).
	d at: #otherCoverage put: (self coverageOfSize: 100 regions: {
				 (self regionFor: (d at: #gamma) from: 1 to: 20).
				 (self regionFor: (d at: #abort) from: 5 to: 10) }).
	^ d
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> coverageOfSize: aSize regions: aCollection [
	"Coverage without file. Regions must be sorted by start, then by decreasing size."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: (String new: aSize withAll: $x)
			   regions: aCollection asOrderedCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> largeCoverageOf: entities coveredWhen: aBlock [
	"Coverage without file on 200 000 characters. Class number c (0-based, creation order, 1000 classes) owns the block c*200+1 to c*200+200; when aBlock answers true for c, its region is b+1 to b+190 (b = c*200) and its 9 methods get b+1+k*20 to b+1+k*20+14 (k = 0 to 8): 1 + 9 = 10 regions per covered class, sorted by start then decreasing size."

	| regions classIndex |
	regions := OrderedCollection new: 7000.
	classIndex := 0.
	entities do: [ :each |
			(each isKindOf: FamixJavaClass) ifTrue: [
					| base |
					base := classIndex * 200.
					(aBlock value: classIndex) ifTrue: [
							regions add:
								(self regionFor: each from: base + 1 to: base + 190).
							(each methods asSortedCollection: [ :a :b | a name <= b name ])
								doWithIndex: [ :method :k |
										| start |
										start := base + 1 + (k - 1 * 20).
										regions add:
											(self regionFor: method from: start to: start + 14) ] ].
					classIndex := classIndex + 1 ] ].
	^ self coverageOfSize: 200000 regions: regions
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> modelWith: aCollection [

	| aModel |
	aModel := FamixJavaModel new.
	aCollection do: [ :each | aModel add: each ].
	^ aModel
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> named: aFamixClass name: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> namesOf: aCollection [

	^ aCollection asArray collect: [ :each | each name ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> newCoverageFor: aText regions: aCollection [
	"Readable coverage of aText with the given regions (no ignored, no other file anchor)."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: aText
			   regions: aCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> newPresenter [
	"Not opened presenter on the small fixture: coverage and Moose model."

	^ self presenterClass
		  on: (self small: #coverage)
		  model: (self small: #model)
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> presenterClass [

	^ MMCCoveragePresenter
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> regionFor: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-v2-' , UUID new asString).
	folder ensureCreateDirectory
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> small: aKey [
	"Answer a named element of the small fixture (entity, #model, #coverage or #otherCoverage)."

	fixture ifNil: [ fixture := self buildSmallFixture ].
	^ fixture at: aKey
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testCheckingTheToggleSwitchesTheTreeToTheWholeModel [

	| presenter |
	presenter := self newPresenter.
	presenter wholeModelTogglePresenter state: true.
	self assert: presenter treeFilter equals: #all.
	self assert: presenter navigator filter equals: #all.
	self assert: presenter treePresenter roots size equals: 3
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testChildrenFollowTheFilter [
	"pkgA children: covered mode Alpha only; all mode Alpha then Aardvark (navigator order: entities with a region first, then the others)."

	| presenter |
	presenter := self newPresenter.
	self
		assert: (self namesOf:
				 (presenter treePresenter childrenFor: (self small: #pkgA)))
		equals: #( 'Alpha' ).
	presenter treeFilter: #all.
	self
		assert: (self namesOf:
				 (presenter treePresenter childrenFor: (self small: #pkgA)))
		equals: #( 'Alpha' 'Aardvark' )
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testClickingTheToggleTogglesTheFilter [
	"click inverts the state (Mock backend emits whenChangedDo: for it)."

	| presenter |
	presenter := self newPresenter.
	presenter wholeModelTogglePresenter click.
	self assert: presenter treeFilter equals: #all.
	presenter wholeModelTogglePresenter click.
	self assert: presenter treeFilter equals: #covered
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testExistingSubPresentersAreStillInTheLayout [

	| presenter |
	presenter := self newPresenter.
	{
		presenter textPresenter.
		presenter uncoveredListPresenter.
		presenter detailsPresenter.
		presenter summaryPresenter } do: [ :each |
		self assert: (presenter presenters includes: each) ]
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testForModelFileKeepsTheModel [
	"forModel:file: reads the file through the anchors of the model and must keep that very model (identity)."

	| aModel ref presenter |
	aModel := FamixJavaModel new.
	aModel rootFolder: folder asFileReference.
	ref := folder / 'A.java'.
	ref binaryWriteStreamDo: [ :s |
		s nextPutAll: 'class A {}' utf8Encoded ].
	presenter := self presenterClass forModel: aModel file: ref.
	self assert: presenter model == aModel.
	self assert: presenter navigator model == aModel
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testInvalidTreeFilterLeavesTheStateUnchanged [

	| presenter |
	presenter := self newPresenter.
	[ presenter treeFilter: #everything ]
		on: Error
		do: [ :error | error return ].
	self assert: presenter treeFilter equals: #covered.
	self assert: presenter navigator filter equals: #covered.
	self deny: presenter wholeModelTogglePresenter state.
	self assert: presenter treePresenter roots size equals: 2
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testModelDoesNotChangeTextDecoratorsAndSummary [
	"Same coverage with and without model: identical text, decorators count, summary and uncovered zones."

	| with without |
	with := self newPresenter.
	without := self presenterClass on: (self small: #coverage).
	self
		assert: with textPresenter text asString
		equals: without textPresenter text asString.
	self assert: with decorators size equals: without decorators size.
	self assert: with summaryText equals: without summaryText.
	self
		assert: with uncoveredListPresenter items size
		equals: without uncoveredListPresenter items size
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testNavigatorIsEmptyButNeverNilWithoutModel [

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	self assert: (presenter navigator isKindOf: MMCModelNavigator).
	self assert: presenter navigator roots isEmpty.
	self assert: presenter navigator size equals: 0
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testNothingIsSelectedInTheTreeInitially [

	self assert: self newPresenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testOnModelKeepsTheMooseModel [

	| presenter |
	presenter := self newPresenter.
	self assert: presenter model == (self small: #model)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testOnModelThemeKeepsTheModelAndForcesTheTheme [

	| presenter |
	presenter := self presenterClass
		             on: (self small: #coverage)
		             model: (self small: #model)
		             theme: #light.
	self assert: presenter model == (self small: #model).
	self assert: presenter theme equals: #light
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testOnWithoutModelHasNoModel [
	"The existing on: constructor means a nil Moose model."

	self assert: (self presenterClass on: self zonesCoverage) model isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testPerformanceOnTenThousandEntities [
	"10 050 entities, 7 000 regions (see buildLargeModelAndCoverages), heavy fixture built here only. Presenter construction under 3 s, switch to the whole model under 2 s, update between two coverages under 3 s. Roots: 50 packages in every mode."

	| data presenter time |
	data := self buildLargeModelAndCoverages.
	time := [
	        presenter := self presenterClass
		                     on: (data at: 2)
		                     model: (data at: 1) ] timeToRun.
	self assert: time < 3 seconds description: 'construction too slow'.
	self assert: presenter treePresenter roots size equals: 50.
	time := [ presenter treeFilter: #all ] timeToRun.
	self
		assert: time < 2 seconds
		description: 'treeFilter: #all too slow'.
	self assert: presenter navigator size equals: 10050.
	self assert: presenter treePresenter roots size equals: 50.
	time := [ presenter updateFileCoverage: (data at: 3) ] timeToRun.
	self
		assert: time < 3 seconds
		description: 'updateFileCoverage: too slow'.
	self assert: presenter treeFilter equals: #all.
	self assert: presenter treePresenter roots size equals: 50
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingADeepEntitySelectsItInTheTree [
	"run is at path 1 (pkgA), 1 (Alpha), 1 (run): selection answers that very entity."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	self assert: presenter selectedEntityInTree == (self small: #run)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingARootEntitySelectsIt [

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #pkgB).
	self assert: presenter selectedEntityInTree == (self small: #pkgB)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingAnEntityHiddenByTheFilterClearsTheSelection [
	"Aardvark is in the model but not visible in #covered mode."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	presenter selectEntityInTree: (self small: #aardvark).
	self assert: presenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingAnEntityInTheTreeMovesTheTextSelectionToItsFirstRegion [
	"Inverted step: selecting an entity in the tree selects its first region in the text. #run has the region 10-30 in the small fixture (hand computed)."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	self
		assert: presenter textPresenter selectionInterval
		equals: (10 to: 30).
	self
		assert: presenter textPresenter selectionInterval
		equals:
		(presenter navigator firstRegionOf: (self small: #run)) interval
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingAnEntityInTheTreeUsesTheNavigatorPath [
	"The tree selection path is navigator pathTo: (Alpha: 1 1, stop: 2 1 1)."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #stop).
	self
		assert: presenter treePresenter selection selectedPath
		equals: #( 2 1 1 ).
	self
		assert: presenter treePresenter selection selectedPath
		equals: (presenter navigator pathTo: (self small: #stop))
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingAnHiddenEntityWorksOnceTheWholeModelIsShown [
	"pkgC (root 3), Delta (3 1) become selectable in #all mode."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter selectEntityInTree: (self small: #delta).
	self assert: presenter selectedEntityInTree == (self small: #delta)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingAnUnknownEntityClearsTheSelectionWithoutError [
	"An entity of no model is not in the tree."

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	presenter selectEntityInTree:
		(self named: FamixJavaClass name: 'Stranger').
	self assert: presenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingAnotherEntityReplacesTheSelection [

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	presenter selectEntityInTree: (self small: #stop).
	self assert: presenter selectedEntityInTree == (self small: #stop)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingInTheTreeWithoutModelDoesNotFail [

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	presenter selectEntityInTree: (self small: #run).
	presenter selectEntityInTree: nil.
	self assert: presenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSelectingNilClearsTheSelectionWithoutError [

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	presenter selectEntityInTree: nil.
	self assert: presenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testSmokeOpenShowsTheTreeOnTheLeft [
	"Only real window test. Opened in a forked process, closed in ensure:. Checks: (1) the tree has an adapter and its visible root rows (FTTableMorph dataSource numberOfRows, roots are collapsed) are the navigator roots (2 in covered mode); (2) horizontal order tree < text < uncovered zones list; (3) switching to the whole model in the open window gives 3 root rows; (4) no SpWindow is left on the World. Skipped without World."

	| presenter window semaphore timedOut openError windowsBefore treeLeft textLeft listLeft rowsCovered rowsAll |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isKindOf: SpWindow ].
	presenter := self newPresenter.
	semaphore := Semaphore new.
	openError := nil.
	[
		[
			[ window := presenter open ]
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
		self
			assert: presenter treePresenter adapter notNil
			description: 'the tree has no adapter'.
		rowsCovered := presenter treePresenter adapter widget dataSource
			               numberOfRows.
		self assert: rowsCovered equals: presenter navigator roots size.
		self assert: rowsCovered equals: 2.
		treeLeft := presenter treePresenter adapter widget bounds left.
		textLeft := presenter textPresenter adapter widget bounds left.
		listLeft := presenter uncoveredListPresenter adapter widget bounds
			            left.
		self
			assert: treeLeft < textLeft
			description: 'the tree is not left of the text'.
		self
			assert: textLeft < listLeft
			description: 'the text is not left of the uncovered zones'.
		presenter treeFilter: #all.
		rowsAll := presenter treePresenter adapter widget dataSource
			           numberOfRows.
		self assert: rowsAll equals: 3.
		self assert: rowsAll equals: presenter navigator roots size ]
		ensure: [
				window ifNotNil: [
						[ window close ]
							on: Error
							do: [ :e | e return ] ].
				self
					assert:
					(World submorphs count: [ :each | each isKindOf: SpWindow ])
					equals: windowsBefore ]
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeChildrenAreComputedFromTheNavigator [
	"pkgA -> Alpha (Aardvark never covered); Alpha -> run, count; run -> nothing."

	| presenter tree |
	presenter := self newPresenter.
	tree := presenter treePresenter.
	self
		assert: (self namesOf: (tree childrenFor: (self small: #pkgA)))
		equals: #( 'Alpha' ).
	self
		assert: (self namesOf: (tree childrenFor: (self small: #alpha)))
		equals: #( 'run' 'count' ).
	self assert: (tree childrenFor: (self small: #run)) isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeChildrenEqualNavigatorChildrenOf [

	| presenter |
	presenter := self newPresenter.
	#( #pkgA #pkgB #alpha #beta #run ) do: [ :key |
			self
				assert:
				(presenter treePresenter childrenFor: (self small: key)) asArray
				equals:
				(presenter navigator childrenOf: (self small: key)) asArray ]
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeColorIsNilExactlyForCoveredEntities [
	"Whatever the entity, nil color <=> navigator isCovered:."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	#( #pkgA #pkgC #alpha #aardvark #delta #count #gamma #abort ) do: [
			:key |
			self
				assert: (presenter treeColorFor: (self small: key)) isNil
				equals: (presenter navigator isCovered: (self small: key)) ]
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeColorOfACoveredEntityIsNil [
	"Alpha (1-50) is covered: default color."

	self assert:
		(self newPresenter treeColorFor: (self small: #alpha)) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeColorOfAnAncestorWithoutRegionIsGrey [
	"AMBIGUITY (decided): pkgA has no region of its own (isCovered: is false, it is only visible as an ancestor of Alpha), so it is grey even in #covered mode."

	| presenter |
	presenter := self newPresenter.
	self deny: (presenter navigator isCovered: (self small: #pkgA)).
	self assert: (presenter treeColorFor: (self small: #pkgA)) notNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeColorOfAnUncoveredEntityIsAnOpaqueGrey [
	"Aardvark has no region (visible in #all mode only): grey, opaque (alpha 1), without saturation (r = g = b)."

	| presenter color |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	color := presenter treeColorFor: (self small: #aardvark).
	self assert: (color isKindOf: Color).
	self assert: color alpha equals: 1.
	self assert: color saturation equals: 0
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeColorOfCoveredEntityStaysNilInAllMode [

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	self assert: (presenter treeColorFor: (self small: #run)) isNil.
	self assert: (presenter treeColorFor: (self small: #stop)) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeDisplayBlockShowsTheTreeLabel [
	"The label shown by the tree widget is the one of treeLabelFor:."

	| presenter |
	presenter := self newPresenter.
	self
		assert:
		(presenter treePresenter display value: (self small: #alpha))
		equals: (presenter treeLabelFor: (self small: #alpha))
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterAllChecksTheToggle [

	self newPresenter in: [ :presenter |
			presenter treeFilter: #all.
			self assert: presenter wholeModelTogglePresenter state ]
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterAllDoesNotFailWithoutModel [

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	presenter treeFilter: #all.
	self assert: presenter treeFilter equals: #all.
	self assert: presenter treePresenter roots isEmpty.
	self assert: presenter wholeModelTogglePresenter state
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterAllDoesNotLoopThroughTheToggleEvents [
	"treeFilter: #all sets the box, which emits once (false to true), which calls treeFilter: again: no further event, no infinite recursion."

	| presenter events |
	presenter := self newPresenter.
	events := 0.
	presenter wholeModelTogglePresenter whenChangedDo: [ :state |
		events := events + 1 ].
	presenter treeFilter: #all.
	self assert: events equals: 1.
	presenter treeFilter: #all.
	self assert: events equals: 1.
	presenter treeFilter: #covered.
	self assert: events equals: 2
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterAllShowsEveryRootAndUpdatesTheNavigator [
	"Covered: pkgA, pkgB. All: pkgA, pkgB, pkgC (the root without any covered descendant appears)."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	self assert: presenter treeFilter equals: #all.
	self assert: presenter navigator filter equals: #all.
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'pkgA' 'pkgB' 'pkgC' ).
	self
		assert: presenter treePresenter roots asArray
		equals: presenter navigator roots asArray
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterBackToCoveredUnchecksTheToggleAndRestoresTheRoots [

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter treeFilter: #covered.
	self assert: presenter treeFilter equals: #covered.
	self deny: presenter wholeModelTogglePresenter state.
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'pkgA' 'pkgB' )
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterIsCoveredByDefault [

	self assert: self newPresenter treeFilter equals: #covered.
	self deny: self newPresenter wholeModelTogglePresenter state
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterIsIdempotent [

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter treeFilter: #all.
	self assert: presenter treeFilter equals: #all.
	self assert: presenter treePresenter roots size equals: 3.
	self assert: presenter wholeModelTogglePresenter state.
	presenter treeFilter: #covered.
	presenter treeFilter: #covered.
	self assert: presenter treePresenter roots size equals: 2.
	self deny: presenter wholeModelTogglePresenter state
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeFilterWithAnInvalidValueRaisesAnErrorMentioningFilter [

	| presenter message |
	presenter := self newPresenter.
	message := nil.
	[ presenter treeFilter: #everything ]
		on: Error
		do: [ :error | message := error messageText ].
	self assert: message notNil.
	self assert: (message includesSubstring: 'filter')
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeIsEmptyWithoutModel [

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	self assert: (presenter treePresenter isKindOf: SpTreePresenter).
	self assert: presenter treePresenter roots isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeLabelEqualsNavigatorTypeNameAndLabel [

	| presenter entity |
	presenter := self newPresenter.
	entity := self small: #stop.
	self
		assert: (presenter treeLabelFor: entity)
		equals: (presenter navigator typeNameOf: entity) , ' '
			, (presenter navigator labelOf: entity)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeLabelIsAString [

	self assert:
		(self newPresenter treeLabelFor: (self small: #beta)) isString
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeLabelOfANamedClassIsTypeNameThenName [

	self
		assert: (self newPresenter treeLabelFor: (self small: #alpha))
		equals: 'Class Alpha'
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeLabelOfAnUnnamedEntityIsUnnamedPlaceholder [

	self
		assert: (self newPresenter treeLabelFor: FamixJavaMethod new)
		equals: 'Method <unnamed>'
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeLabelOfNamedMethodAndPackage [

	| presenter |
	presenter := self newPresenter.
	self
		assert: (presenter treeLabelFor: (self small: #run))
		equals: 'Method run'.
	self
		assert: (presenter treeLabelFor: (self small: #pkgA))
		equals: 'Package pkgA'.
	self
		assert: (presenter treeLabelFor: (self small: #count))
		equals: 'Attribute count'
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreePresenterAndToggleAreSubPresenters [

	| presenter |
	presenter := self newPresenter.
	self assert: (presenter presenters includes: presenter treePresenter).
	self assert:
		(presenter presenters includes: presenter wholeModelTogglePresenter)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreePresenterIsASpTreePresenterAndToggleACheckBox [

	| presenter |
	presenter := self newPresenter.
	self assert: (presenter treePresenter isKindOf: SpTreePresenter).
	self assert:
		(presenter wholeModelTogglePresenter isKindOf: SpCheckBoxPresenter)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeRootsAreSameEntitiesAsNavigatorRoots [
	"Identity, not copies."

	| presenter |
	presenter := self newPresenter.
	presenter treePresenter roots
		with: presenter navigator roots
		do: [ :a :b | self assert: a == b ]
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testTreeRootsAreTheNavigatorRootsInTheSameOrder [
	"Covered mode on the small fixture: pkgA and pkgB (pkgC has no covered descendant)."

	| presenter |
	presenter := self newPresenter.
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'pkgA' 'pkgB' ).
	self
		assert: presenter treePresenter roots asArray
		equals: presenter navigator roots asArray
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUncheckingTheToggleSwitchesBackToCoveredEntities [

	| presenter |
	presenter := self newPresenter.
	presenter wholeModelTogglePresenter state: true.
	presenter wholeModelTogglePresenter state: false.
	self assert: presenter treeFilter equals: #covered.
	self assert: presenter treePresenter roots size equals: 2
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageClearsTheTreeSelection [

	| presenter |
	presenter := self newPresenter.
	presenter selectEntityInTree: (self small: #run).
	self assert: presenter selectedEntityInTree notNil.
	presenter updateFileCoverage: (self small: #otherCoverage).
	self assert: presenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageKeepsTheCoveredFilter [

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self small: #otherCoverage).
	self assert: presenter treeFilter equals: #covered.
	self deny: presenter wholeModelTogglePresenter state
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageKeepsTheCurrentFilter [
	"All mode kept: the three roots stay visible with the new coverage, the box stays checked."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter updateFileCoverage: (self small: #otherCoverage).
	self assert: presenter treeFilter equals: #all.
	self assert: presenter navigator filter equals: #all.
	self assert: presenter wholeModelTogglePresenter state.
	self assert: presenter treePresenter roots size equals: 3
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageKeepsTheModel [

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self small: #otherCoverage).
	self assert: presenter model == (self small: #model)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageModelKeepsTheFilterAndClearsTheSelection [

	| presenter other |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter selectEntityInTree: (self small: #delta).
	other := self buildSmallFixture.
	presenter
		updateFileCoverage: (other at: #coverage)
		model: (other at: #model).
	self assert: presenter treeFilter equals: #all.
	self assert: presenter treePresenter roots size equals: 3.
	self assert: presenter selectedEntityInTree isNil
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageModelReplacesTheModelAndTheCoverage [
	"Another model (distinct entities): navigator, roots and model are those of the new one."

	| presenter other |
	presenter := self newPresenter.
	other := self buildSmallFixture.
	presenter
		updateFileCoverage: (other at: #coverage)
		model: (other at: #model).
	self assert: presenter model == (other at: #model).
	self assert: presenter navigator model == (other at: #model).
	self assert: presenter treePresenter roots size equals: 2.
	self assert: presenter treePresenter roots first == (other at: #pkgA)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageModelWithNilModelEmptiesTheTree [

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self small: #coverage) model: nil.
	self assert: presenter model isNil.
	self assert: presenter treePresenter roots isEmpty.
	self assert: presenter navigator roots isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageRebuildsTheNavigatorOnTheNewCoverageAndSameModel [

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self small: #otherCoverage).
	self assert: presenter navigator model == (self small: #model).
	self assert:
		presenter navigator coverage == (self small: #otherCoverage)
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageRecomputesTheTreeRoots [
	"otherCoverage covers Gamma and abort only: in covered mode the only visible root is pkgB."

	| presenter |
	presenter := self newPresenter.
	presenter updateFileCoverage: (self small: #otherCoverage).
	self
		assert: (self namesOf: presenter treePresenter roots)
		equals: #( 'pkgB' ).
	self
		assert: (self namesOf:
				 (presenter treePresenter childrenFor: (self small: #pkgB)))
		equals: #( 'Gamma' )
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageStillShowsTheNewText [
	"The existing behavior is kept: the text widget shows the text of the new coverage."

	| presenter other |
	presenter := self newPresenter.
	other := self zonesCoverage.
	presenter updateFileCoverage: other.
	self
		assert: presenter textPresenter text asString
		equals: 'aaaa xxxx bbbb'
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testUpdateFileCoverageWithoutModelKeepsTheTreeEmpty [

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	presenter updateFileCoverage: self zonesCoverage.
	self assert: presenter model isNil.
	self assert: presenter treePresenter roots isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testWholeModelToggleExistsAndIsUncheckedWithoutModel [

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	self assert:
		(presenter wholeModelTogglePresenter isKindOf: SpCheckBoxPresenter).
	self deny: presenter wholeModelTogglePresenter state
]

{ #category : 'tests' }
MMCCoveragePresenterTreeTest >> testWithoutModelTextDecoratorsAndSummaryAreThoseOfBefore [
	"Regression on zonesCoverage: 14 characters, 3 decorators (class A, class B, the uncovered zone xxxx), and the summary computed by hand: 8 of 14 characters covered (4 + 4) = 57.1 %, 8 of 12 significant characters (2 blanks) = 66.7 %, 1 uncovered zone, nothing ignored."

	| presenter |
	presenter := self presenterClass on: self zonesCoverage.
	self
		assert: presenter textPresenter text asString
		equals: 'aaaa xxxx bbbb'.
	self assert: presenter decorators size equals: 3.
	self
		assert: presenter summaryText
		equals:
		'Covered 8/14 characters (57.1 %) | significant 8/12 (66.7 %) | 1 uncovered zone(s) | 0 ignored anchor(s) | 0 anchor(s) in other files'
]

{ #category : 'helpers' }
MMCCoveragePresenterTreeTest >> zonesCoverage [
	"'aaaa xxxx bbbb' (14 characters): class A 1-4 and class B 11-14; one uncovered zone 'xxxx' (6-9). Entities are not in any model."

	^ self newCoverageFor: 'aaaa xxxx bbbb' regions: {
			  (self
				   regionFor: (self named: FamixJavaClass name: 'A')
				   from: 1
				   to: 4).
			  (self
				   regionFor: (self named: FamixJavaClass name: 'B')
				   from: 11
				   to: 14) }
]
