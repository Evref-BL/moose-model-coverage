"
TDD tests of MMCModelNavigator (pure navigation model of a Moose model against an MMCFileCoverage). The production class is only reached through navigatorClass.
"
Class {
	#name : 'MMCModelNavigatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'fixture'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCModelNavigatorTest >> buildLargeEntities [
	"50 packages x 20 classes x 9 methods = 10 050 entities, answered as an OrderedCollection in creation order (package, then each class followed by its methods)."

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
MMCModelNavigatorTest >> buildLargeModelAndCoverage [
	"Answers { model. coverage }: 10 050 entities and a coverage without file on a text of 200 000 characters.
	Class number c (0-based, in creation order, 1000 classes) owns the block c*200+1 to c*200+200; it is covered when c \\ 10 < 7 (700 classes): its region is b+1 to b+190 (b = c*200) and its 9 methods get b+1+k*20 to b+1+k*20+14 (k = 0 to 8).
	That makes 700 + 6300 = 7000 regions, sorted by start then by decreasing size (class region first)."

	| entities regions classIndex |
	entities := self buildLargeEntities.
	regions := OrderedCollection new: 7000.
	classIndex := 0.
	entities do: [ :each |
			(each isKindOf: FamixJavaClass) ifTrue: [
					| base |
					base := classIndex * 200.
					classIndex \\ 10 < 7 ifTrue: [
							regions add:
								(self regionFor: each from: base + 1 to: base + 190).
							(each methods asSortedCollection: [ :a :b | a name <= b name ])
								doWithIndex: [ :method :k |
										| start |
										start := base + 1 + (k - 1 * 20).
										regions add:
											(self regionFor: method from: start to: start + 14) ] ].
					classIndex := classIndex + 1 ] ].
	^ {
		  (self modelWith: entities).
		  (self coverageOfSize: 200000 regions: regions) }
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> buildLargeNavigatorFilter: aSymbol [

	| pair |
	pair := self buildLargeModelAndCoverage.
	^ (self navigatorOn: pair first coverage: pair second)
		  filter: aSymbol;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> buildSmallFixture [
	"Text of 100 characters. Hierarchy: pkgA(Alpha(run, count), Aardvark), pkgB(Beta(stop), Gamma(abort)).
	Regions: Alpha 1-50, run 10-30, count 35-45, Beta 60-90, stop 70-80. Packages, Aardvark, Gamma, abort are not covered."

	| d |
	d := Dictionary new.
	d at: #pkgA put: (self named: FamixJavaPackage name: 'pkgA').
	d at: #pkgB put: (self named: FamixJavaPackage name: 'pkgB').
	d at: #alpha put: (self named: FamixJavaClass name: 'Alpha').
	d at: #aardvark put: (self named: FamixJavaClass name: 'Aardvark').
	d at: #beta put: (self named: FamixJavaClass name: 'Beta').
	d at: #gamma put: (self named: FamixJavaClass name: 'Gamma').
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
	^ d
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> coverageOfSize: aSize regions: aCollection [
	"Coverage without file. Regions must be sorted by start, then by decreasing size."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: (String new: aSize withAll: $x)
			   regions: aCollection asOrderedCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> entityNamed: aString in: aCollection [

	^ aCollection detect: [ :each | each name = aString ]
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> modelWith: aCollection [

	| model |
	model := FamixJavaModel new.
	aCollection do: [ :each | model add: each ].
	^ model
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> multiContainerNavigatorFilter: aSymbol [
	"pkgX contains Shared (typeContainer: outerClass, parentPackage: pkgX, so containers = outerClass then pkgX).
	Outer belongs to pkgY. Text of 50 characters, Shared 1-10 and Outer 1-30."

	| pkgX pkgY outer shared |
	pkgX := self named: FamixJavaPackage name: 'pkgX'.
	pkgY := self named: FamixJavaPackage name: 'pkgY'.
	outer := self named: FamixJavaClass name: 'Outer'.
	shared := self named: FamixJavaClass name: 'Shared'.
	pkgY addType: outer.
	shared typeContainer: outer.
	shared parentPackage: pkgX.
	^ (self
		   navigatorOn: (self modelWith: {
						    pkgX.
						    pkgY.
						    outer.
						    shared })
		   coverage: (self coverageOfSize: 50 regions: {
						    (self regionFor: outer from: 1 to: 30).
						    (self regionFor: shared from: 1 to: 10) }))
		  filter: aSymbol;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> multiRegionNavigator [
	"Text of 100 characters. pkgM contains Multi, TwinA, TwinB.
	Regions in reader order: Multi 5-20, Multi 5-10, Multi 40-60, TwinB 70-80, TwinA 70-80 (same interval)."

	| pkg multi twinA twinB |
	pkg := self named: FamixJavaPackage name: 'pkgM'.
	multi := self named: FamixJavaClass name: 'Multi'.
	twinA := self named: FamixJavaClass name: 'TwinA'.
	twinB := self named: FamixJavaClass name: 'TwinB'.
	pkg
		addType: multi;
		addType: twinA;
		addType: twinB.
	^ self
		  navigatorOn: (self modelWith: {
					   pkg.
					   multi.
					   twinA.
					   twinB })
		  coverage: (self coverageOfSize: 100 regions: {
					   (self regionFor: multi from: 5 to: 20).
					   (self regionFor: multi from: 5 to: 10).
					   (self regionFor: multi from: 40 to: 60).
					   (self regionFor: twinB from: 70 to: 80).
					   (self regionFor: twinA from: 70 to: 80) })
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> named: aFamixClass name: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> namesOf: aCollection [
	"Names of entities as an Array (never print entities)."

	^ (aCollection collect: [ :each | each name ]) asArray
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> navigatorClass [
	"The only place referencing the production class, by name lookup."

	^ Smalltalk globals at: #MMCModelNavigator
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> navigatorOn: aModel coverage: aCoverage [

	^ self navigatorClass on: aModel coverage: aCoverage
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> navigatorWithoutRegionsFilter: aSymbol [
	"Small model, coverage with no region at all."

	^ (self
		   navigatorOn: (self small: #model)
		   coverage: (self coverageOfSize: 100 regions: #(  )))
		  filter: aSymbol;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> regionFor: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> small: aKey [
	"Answer a named element of the small fixture (entity, #model or #coverage)."

	fixture ifNil: [ fixture := self buildSmallFixture ].
	^ fixture at: aKey
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> smallNavigator [
	"Navigator on the small fixture, default filter (#covered)."

	^ self
		  navigatorOn: (self small: #model)
		  coverage: (self small: #coverage)
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> smallNavigatorAll [
	"Navigator on the small fixture showing every entity."

	^ self smallNavigator
		  filter: #all;
		  yourself
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testAccessorsAnswerModelAndCoverage [

	| navigator |
	navigator := self smallNavigator.
	self assert: navigator model identicalTo: (self small: #model).
	self assert: navigator coverage identicalTo: (self small: #coverage)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testAllModeShowsUncoveredEntities [

	| navigator |
	navigator := self smallNavigatorAll.
	#( #aardvark #gamma #abort ) do: [ :key |
		self
			assert: (navigator includes: (self small: key))
			description: key ]
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testAllModeSizeCountsEveryEntity [
	"2 packages + 4 classes + 3 methods + 1 attribute = 10."

	self assert: self smallNavigatorAll size equals: 10
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testAncestorsAreACopy [

	| navigator stop |
	navigator := self smallNavigator.
	stop := self small: #stop.
	(navigator ancestorsOf: stop) at: 1 put: nil.
	self
		assert: (self namesOf: (navigator ancestorsOf: stop))
		equals: #( 'pkgB' 'Beta' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testAncestorsOfExcludeTheEntityItself [
	"stop: pkgB then Beta, from the root to the immediate parent."

	self
		assert:
		(self namesOf:
			 (self smallNavigator ancestorsOf: (self small: #stop)))
		equals: #( 'pkgB' 'Beta' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testAncestorsOfRootOrHiddenEntityIsEmpty [

	| navigator |
	navigator := self smallNavigator.
	self
		assert: (navigator ancestorsOf: (self small: #pkgA))
		equals: #(  ).
	self
		assert: (navigator ancestorsOf: (self small: #abort))
		equals: #(  )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testChangingFilterRebuildsTheIndex [
	"Size is read before and after each change: 7 (covered), 10 (all), 7 (covered)."

	| navigator |
	navigator := self smallNavigator.
	self assert: navigator size equals: 7.
	navigator filter: #all.
	self assert: navigator size equals: 10.
	navigator filter: #covered.
	self assert: navigator size equals: 7
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testChangingFilterUpdatesRoots [
	"After #all, the roots still are pkgA and pkgB, but the children of pkgB gain Gamma."

	| navigator pkgB |
	navigator := self smallNavigator.
	pkgB := self small: #pkgB.
	self
		assert: (self namesOf: (navigator childrenOf: pkgB))
		equals: #( 'Beta' ).
	navigator filter: #all.
	self
		assert: (self namesOf: (navigator childrenOf: pkgB))
		equals: #( 'Beta' 'Gamma' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testChangingNameFilterRebuildsTheIndex [

	| navigator |
	navigator := self smallNavigator.
	self assert: navigator size equals: 7.
	navigator nameFilter: 'count'.
	self assert: navigator size equals: 3.
	self assert: navigator nameFilter equals: 'count'.
	navigator nameFilter: ''.
	self assert: navigator size equals: 7
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testChildrenAreACopy [

	| navigator alpha |
	navigator := self smallNavigator.
	alpha := self small: #alpha.
	(navigator childrenOf: alpha) at: 1 put: nil.
	self
		assert: (self namesOf: (navigator childrenOf: alpha))
		equals: #( 'run' 'count' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testChildrenAreSortedByPositionBeforeName [
	"run starts at 10, count at 35: position order (run, count) differs from name order (count, run)."

	self
		assert:
		(self namesOf:
			 (self smallNavigator childrenOf: (self small: #alpha)))
		equals: #( 'run' 'count' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testChildrenOfUnknownEntityIsEmpty [

	self
		assert: (self smallNavigator childrenOf: Object new)
		equals: #(  )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testCoveredModeHidesUncoveredLeaves [

	| navigator |
	navigator := self smallNavigator.
	#( #aardvark #gamma #abort ) do: [ :key |
		self deny: (navigator includes: (self small: key)) description: key ]
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testCoveredModeSizeCountsCoveredEntitiesAndAncestors [
	"Covered: Alpha, run, count, Beta, stop (5) + ancestors pkgA, pkgB (2) = 7."

	self assert: self smallNavigator size equals: 7
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testCoveredModeVisibleEntities [

	self
		assert: (self namesOf: self smallNavigator visibleEntities) asSet
		equals: #( 'pkgA' 'Alpha' 'run' 'count' 'pkgB' 'Beta' 'stop' ) asSet
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testDeepestEntityAtAnswersInnermostEntity [

	| navigator |
	navigator := self smallNavigator.
	self
		assert: (navigator deepestEntityAt: 20)
		identicalTo: (self small: #run).
	self
		assert: (navigator deepestEntityAt: 5)
		identicalTo: (self small: #alpha)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testDeepestEntityAtSameIntervalIsTheLastRegion [

	| navigator |
	navigator := self multiRegionNavigator.
	self assert: (navigator deepestEntityAt: 75) name equals: 'TwinA'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testDeepestEntityAtUncoveredOrOutsideTextIsNil [
	"Positions 55 (between regions), 95 (after last region), 0 and 500 (outside the 100 characters text)."

	| navigator |
	navigator := self smallNavigator.
	#( 55 95 0 500 ) do: [ :position |
			self
				assert: (navigator deepestEntityAt: position) isNil
				description: position printString.
			self assert: (navigator entitiesAt: position) equals: #(  ) ]
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testDefaultFilterIsCovered [

	self assert: self smallNavigator filter equals: #covered
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testDefaultNameFilterIsEmpty [

	self assert: self smallNavigator nameFilter equals: ''
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntitiesAtDoNotRepeatAnEntityWithOverlappingRegions [
	"Position 7 is in Multi 5-20 and Multi 5-10: Multi is answered once."

	| navigator |
	navigator := self multiRegionNavigator.
	self
		assert: (self namesOf: (navigator entitiesAt: 7))
		equals: #( 'Multi' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntitiesAtGoFromOutermostToInnermost [
	"Position 20: Alpha (1-50) then run (10-30). Position 75: Beta (60-90) then stop (70-80)."

	| navigator |
	navigator := self smallNavigator.
	self
		assert: (self namesOf: (navigator entitiesAt: 20))
		equals: #( 'Alpha' 'run' ).
	self
		assert: (self namesOf: (navigator entitiesAt: 75))
		equals: #( 'Beta' 'stop' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntitiesAtOutsideInnerRegion [
	"Position 32 is inside Alpha only (run ends at 30, count starts at 35)."

	self
		assert: (self namesOf: (self smallNavigator entitiesAt: 32))
		equals: #( 'Alpha' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntitiesWithSameIntervalAreBothAnswered [
	"TwinB then TwinA share 70-80 (reader order): outer to inner is TwinB, TwinA."

	| navigator |
	navigator := self multiRegionNavigator.
	self
		assert: (self namesOf: (navigator entitiesAt: 75))
		equals: #( 'TwinB' 'TwinA' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntitiesWithSameIntervalAreSortedByLabel [
	"Multi starts at 5; TwinA and TwinB tie on start 70 and are ordered by label."

	| navigator |
	navigator := self multiRegionNavigator.
	self
		assert:
		(self namesOf: (navigator childrenOf: navigator roots first))
		equals: #( 'Multi' 'TwinA' 'TwinB' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntityAtPathAnswersEntity [

	| navigator |
	navigator := self smallNavigator.
	self
		assert: (navigator entityAtPath: #( 1 ))
		identicalTo: (self small: #pkgA).
	self
		assert: (navigator entityAtPath: #( 2 1 1 ))
		identicalTo: (self small: #stop)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntityAtPathIsNilForInvalidPaths [
	"Empty, zero, too large, too deep: all answer nil."

	| navigator |
	navigator := self smallNavigator.
	self assert: (navigator entityAtPath: #(  )) isNil.
	self assert: (navigator entityAtPath: #( 0 )) isNil.
	self assert: (navigator entityAtPath: #( 3 )) isNil.
	self assert: (navigator entityAtPath: #( 1 1 5 )) isNil.
	self assert: (navigator entityAtPath: #( 2 1 1 1 )) isNil
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testEntityWithSeveralRegionsKeepsThemInReaderOrder [
	"Multi has 3 regions: 5-20, 5-10, 40-60."

	| navigator regions |
	navigator := self multiRegionNavigator.
	regions := navigator regionsOf:
		           (self entityNamed: 'Multi' in: navigator visibleEntities).
	self assert: (regions collect: #interval) asArray equals: {
			(5 to: 20).
			(5 to: 10).
			(40 to: 60) }
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testFilterAcceptsAll [

	self assert: self smallNavigatorAll filter equals: #all
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testFirstRegionIsTheOneWithSmallestStartThenLargest [
	"Regions 5-20 and 5-10 share the smallest start 5: the largest one (5-20) wins."

	| navigator |
	navigator := self multiRegionNavigator.
	self
		assert: (navigator firstRegionOf:
				 (self entityNamed: 'Multi' in: navigator visibleEntities))
				interval
		equals: (5 to: 20)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testFirstRegionOfSingleRegion [

	self
		assert:
		(self smallNavigator firstRegionOf: (self small: #alpha)) interval
		equals: (1 to: 50)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testFirstRegionOfUncoveredEntityIsNil [

	self assert:
		(self smallNavigator firstRegionOf: (self small: #pkgA)) isNil
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testIncludesOnlyVisibleEntities [

	| navigator |
	navigator := self smallNavigator.
	self assert: (navigator includes: (self small: #stop)).
	self deny: (navigator includes: (self small: #abort)).
	self deny: (navigator includes: Object new)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testInvalidFilterRaisesErrorMentioningFilter [
	"Any value other than #covered or #all is rejected with a message containing 'filter'."

	| navigator message |
	navigator := self smallNavigator.
	message := nil.
	[ navigator filter: #bogus ]
		on: Error
		do: [ :error | message := error messageText ].
	self assert: message notNil.
	self assert: (message includesSubstring: 'filter')
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testIsCoveredOnlyForEntitiesWithRegions [
	"Alpha has a region; pkgA (ancestor) and Aardvark do not."

	| navigator |
	navigator := self smallNavigatorAll.
	self assert: (navigator isCovered: (self small: #alpha)).
	self deny: (navigator isCovered: (self small: #pkgA)).
	self deny: (navigator isCovered: (self small: #aardvark))
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testLabelOfEmptyNameIsPlaceholder [

	self
		assert:
		(self smallNavigator labelOf: (self named: FamixJavaClass name: ''))
		equals: '<unnamed>'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testLabelOfNamedEntityIsItsName [

	self
		assert: (self smallNavigator labelOf: (self small: #alpha))
		equals: 'Alpha'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testLabelOfObjectWithoutNameMessageIsPlaceholder [
	"Object does not understand name: no error."

	self
		assert: (self smallNavigator labelOf: Object new)
		equals: '<unnamed>'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testLabelOfUnnamedEntityIsPlaceholder [
	"A FamixJavaMethod without name answers nil to name."

	self
		assert: (self smallNavigator labelOf: FamixJavaMethod new)
		equals: '<unnamed>'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testModelWithoutRegionIsEmptyInCoveredMode [

	| navigator |
	navigator := self navigatorWithoutRegionsFilter: #covered.
	self assert: navigator roots equals: #(  ).
	self assert: navigator size equals: 0
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testModelWithoutRegionShowsEverythingInAllMode [

	self
		assert: (self navigatorWithoutRegionsFilter: #all) size
		equals: 10
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testMultiContainerEntityAppearsOnceInTheTree [
	"#all: pkgX, pkgY, Outer, Shared are visible (4); walking the tree meets each exactly once."

	| navigator tree |
	navigator := self multiContainerNavigatorFilter: #all.
	tree := self treeOf: navigator.
	self assert: tree size equals: 4.
	self assert: (self namesOf: tree) asSet size equals: 4
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testMultiContainerEntityInCoveredModeKeepsOnlyItsParentChain [
	"Covered: Outer, Shared and the ancestor chain of Shared (Outer, pkgY). pkgX is not an ancestor: 3 entities."

	| navigator |
	navigator := self multiContainerNavigatorFilter: #covered.
	self assert: navigator size equals: 3.
	self assert: (self namesOf: navigator roots) equals: #( 'pkgY' ).
	self
		assert: (self namesOf: (navigator ancestorsOf:
					  (self entityNamed: 'Shared' in: navigator visibleEntities)))
		equals: #( 'pkgY' 'Outer' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testMultiContainerEntityIsNotChildOfItsSecondContainer [

	| navigator pkgX |
	navigator := self multiContainerNavigatorFilter: #all.
	pkgX := self entityNamed: 'pkgX' in: navigator visibleEntities.
	self assert: (navigator childrenOf: pkgX) equals: #(  )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testMultiContainerEntityIsPlacedUnderItsFirstContainer [
	"Shared has containers (Outer, pkgX): its parent is Outer, the first one."

	| navigator shared |
	navigator := self multiContainerNavigatorFilter: #all.
	shared := self entityNamed: 'Shared' in: navigator visibleEntities.
	self assert: (navigator parentOf: shared) name equals: 'Outer'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNameFilterAppliesToCurrentMode [
	"#all mode, filter 'a' ... use 'abort': abort, Gamma, pkgB are kept even though abort is uncovered."

	| navigator |
	navigator := self smallNavigatorAll.
	navigator nameFilter: 'abort'.
	self
		assert: (self namesOf: navigator visibleEntities) asSet
		equals: #( 'abort' 'Gamma' 'pkgB' ) asSet
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNameFilterIsCaseInsensitive [

	| navigator |
	navigator := self smallNavigator.
	navigator nameFilter: 'ALPHA'.
	self assert: (navigator includes: (self small: #alpha)).
	self assert: (navigator includes: (self small: #pkgA))
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNameFilterIsNotAppliedToUncoveredEntitiesInCoveredMode [
	"abort matches but is uncovered: in covered mode nothing is visible."

	| navigator |
	navigator := self smallNavigator.
	navigator nameFilter: 'abort'.
	self assert: navigator size equals: 0
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNameFilterKeepsMatchingEntitiesAndTheirAncestors [
	"Filter 'count' in covered mode: count matches; its ancestors Alpha and pkgA stay: 3 entities."

	| navigator |
	navigator := self smallNavigator.
	navigator nameFilter: 'count'.
	self assert: navigator size equals: 3.
	self
		assert: (self namesOf: navigator visibleEntities) asSet
		equals: #( 'count' 'Alpha' 'pkgA' ) asSet
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNameFilterMatchesSubstrings [
	"'ta' is inside Beta only (also 'stop' does not contain 'ta'): Beta, pkgB."

	| navigator |
	navigator := self smallNavigator.
	navigator nameFilter: 'eta'.
	self
		assert: (self namesOf: navigator visibleEntities) asSet
		equals: #( 'Beta' 'pkgB' ) asSet
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNameFilterWithoutMatchGivesNoRoot [

	| navigator |
	navigator := self smallNavigator.
	navigator nameFilter: 'zzz'.
	self assert: navigator roots equals: #(  ).
	self assert: navigator size equals: 0
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testNilModelGivesEmptyNavigator [
	"A nil model is accepted: no root, no visible entity, no error."

	| navigator |
	navigator := self navigatorOn: nil coverage: (self small: #coverage).
	self assert: navigator roots equals: #(  ).
	self assert: navigator size equals: 0.
	self assert: navigator model isNil
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testParentOfIsDeterministic [

	| navigator |
	navigator := self smallNavigatorAll.
	self
		assert: (navigator parentOf: (self small: #abort))
		identicalTo: (navigator parentOf: (self small: #abort)).
	self
		assert: (navigator parentOf: (self small: #abort))
		identicalTo: (self small: #gamma)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testParentOfMethodIsItsClass [

	self
		assert: (self smallNavigator parentOf: (self small: #run))
		identicalTo: (self small: #alpha)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testParentOfRootAndHiddenEntityIsNil [
	"pkgA is a root; Aardvark is not visible in covered mode."

	| navigator |
	navigator := self smallNavigator.
	self assert: (navigator parentOf: (self small: #pkgA)) isNil.
	self assert: (navigator parentOf: (self small: #aardvark)) isNil
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testPathRoundTripAllMode [

	| navigator |
	navigator := self smallNavigatorAll.
	self assert: navigator visibleEntities size equals: 10.
	navigator visibleEntities do: [ :each |
			self
				assert: (navigator entityAtPath: (navigator pathTo: each)) == each
				description: each name ]
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testPathRoundTripCoveredMode [

	| navigator |
	navigator := self smallNavigator.
	navigator visibleEntities do: [ :each |
			self
				assert: (navigator entityAtPath: (navigator pathTo: each)) == each
				description: each name ]
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testPathToGivesOneBasedIndicesFromRoots [
	"Roots (pkgA, pkgB); pkgA children (Alpha); Alpha children (run, count); pkgB children (Beta); Beta children (stop)."

	| navigator |
	navigator := self smallNavigator.
	self assert: (navigator pathTo: (self small: #pkgA)) equals: #( 1 ).
	self
		assert: (navigator pathTo: (self small: #run))
		equals: #( 1 1 1 ).
	self
		assert: (navigator pathTo: (self small: #count))
		equals: #( 1 1 2 ).
	self assert: (navigator pathTo: (self small: #beta)) equals: #( 2 1 ).
	self
		assert: (navigator pathTo: (self small: #stop))
		equals: #( 2 1 1 )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testPathToHiddenEntityIsNil [

	self assert: (self smallNavigator pathTo: (self small: #abort)) isNil.
	self assert: (self smallNavigator pathTo: Object new) isNil
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testPathToInAllMode [
	"Gamma is the second child of pkgB (after covered Beta); abort its only method."

	| navigator |
	navigator := self smallNavigatorAll.
	self
		assert: (navigator pathTo: (self small: #aardvark))
		equals: #( 1 2 ).
	self
		assert: (navigator pathTo: (self small: #gamma))
		equals: #( 2 2 ).
	self
		assert: (navigator pathTo: (self small: #abort))
		equals: #( 2 2 1 )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testPerformanceOnTenThousandEntities [
	"10 050 entities, 7 000 regions. Covered entities: 700 classes + 6 300 methods + 50 ancestor packages = 7 050. First roots (index build) under 2 s in covered mode, under 3 s in all mode; pathTo: of 1 000 entities drawn with a fixed seed under 1 s. The fixture is heavy: built here only, in this single test."

	| navigator rootsTime sample random pathTime |
	navigator := self buildLargeNavigatorFilter: #covered.
	rootsTime := [ navigator roots ] timeToRun.
	self
		assert: rootsTime < 2 seconds
		description: 'covered roots too slow'.
	self assert: navigator size equals: 7050.
	navigator filter: #all.
	rootsTime := [ navigator roots ] timeToRun.
	self assert: rootsTime < 3 seconds description: 'all roots too slow'.
	self assert: navigator size equals: 10050.
	random := Random seed: 42.
	sample := navigator visibleEntities asArray.
	sample := (1 to: 1000) collect: [ :i |
		          sample at: (random nextInteger: sample size) ].
	pathTime := [ sample do: [ :each | navigator pathTo: each ] ]
		            timeToRun.
	self assert: pathTime < 1 second description: 'pathTo: too slow'.
	self assert: navigator roots size equals: 50
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testRegionsAreACopy [

	| navigator run |
	navigator := self smallNavigator.
	run := self small: #run.
	(navigator regionsOf: run) at: 1 put: nil.
	self assert: (navigator regionsOf: run) size equals: 1.
	self assert: (navigator regionsOf: run) first notNil
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testRegionsOfEntityAnswersItsOwnRegion [

	| regions |
	regions := self smallNavigator regionsOf: (self small: #run).
	self assert: regions size equals: 1.
	self assert: regions first interval equals: (10 to: 30).
	self assert: regions first entity == (self small: #run)
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testRegionsOfUncoveredEntityIsEmpty [

	self
		assert: (self smallNavigator regionsOf: (self small: #aardvark))
		equals: #(  ).
	self
		assert: (self smallNavigator regionsOf: Object new)
		equals: #(  )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testRootsAreACopy [

	| navigator |
	navigator := self smallNavigator.
	navigator roots at: 1 put: nil.
	self
		assert: (self namesOf: navigator roots)
		equals: #( 'pkgA' 'pkgB' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testRootsInCoveredMode [
	"Both packages are uncovered (key +infinity): ordered by label, pkgA then pkgB."

	self
		assert: (self namesOf: self smallNavigator roots)
		equals: #( 'pkgA' 'pkgB' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testTypeNameDropsFamixAndMetamodelPrefix [
	"FamixJavaMethod gives Method, FamixJavaClass gives Class, FamixJavaPackage gives Package."

	| navigator |
	navigator := self smallNavigator.
	self
		assert: (navigator typeNameOf: (self small: #run))
		equals: 'Method'.
	self
		assert: (navigator typeNameOf: (self small: #alpha))
		equals: 'Class'.
	self
		assert: (navigator typeNameOf: (self small: #pkgA))
		equals: 'Package'.
	self
		assert: (navigator typeNameOf: (self small: #count))
		equals: 'Attribute'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testTypeNameOfPlainObjectIsItsClassName [

	self
		assert: (self smallNavigator typeNameOf: Object new)
		equals: 'Object'
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testUncoveredAncestorsAreVisibleInCoveredMode [
	"pkgA and pkgB have no region but contain covered entities."

	| navigator |
	navigator := self smallNavigator.
	self deny: (navigator isCovered: (self small: #pkgA)).
	self assert: (navigator includes: (self small: #pkgA)).
	self assert: (navigator includes: (self small: #pkgB))
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testUncoveredChildrenComeAfterCoveredOnesSortedByName [
	"pkgA in #all mode: Alpha is covered (start 1) so it precedes Aardvark (uncovered) although 'Aardvark' < 'Alpha'."

	self
		assert: (self namesOf:
				 (self smallNavigatorAll childrenOf: (self small: #pkgA)))
		equals: #( 'Alpha' 'Aardvark' )
]

{ #category : 'tests' }
MMCModelNavigatorTest >> testVisibleEntitiesAreACopy [
	"Overwriting an element of the answered collection leaves the navigator unchanged."

	| navigator |
	navigator := self smallNavigator.
	navigator visibleEntities at: 1 put: nil.
	self assert: navigator size equals: 7.
	self deny: (navigator visibleEntities includes: nil)
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> treeOf: aNavigator [
	"All entities met when walking the tree from roots through childrenOf:, in depth-first order, duplicates kept."

	| result |
	result := OrderedCollection new.
	aNavigator roots do: [ :root |
		self walk: root in: aNavigator into: result ].
	^ result
]

{ #category : 'helpers' }
MMCModelNavigatorTest >> walk: anEntity in: aNavigator into: aCollection [

	aCollection add: anEntity.
	(aNavigator childrenOf: anEntity) do: [ :child |
		self walk: child in: aNavigator into: aCollection ]
]
