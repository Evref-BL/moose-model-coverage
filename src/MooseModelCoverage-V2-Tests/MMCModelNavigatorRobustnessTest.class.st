"
Robustness of MMCModelNavigator: case-insensitive deterministic sibling order (first region position stays the main key), entityAtPath: with arguments that are not paths, and the documented behavior for a container that is not in the model (ancestors are always shown).
"
Class {
	#name : 'MMCModelNavigatorRobustnessTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> chainNavigator [
	"Package p (not covered itself) > class C (region 1-20) > method m (region 5-10), all in the model. Answer { navigator. p. C. m }. Paths: p = #(1), C = #(1 1), m = #(1 1 1)."

	| pkg c m |
	pkg := self named: FamixJavaPackage name: 'p'.
	c := self named: FamixJavaClass name: 'C'.
	m := self named: FamixJavaMethod name: 'm'.
	pkg addType: c.
	c addMethod: m.
	^ {
		  (MMCModelNavigator
			   on: (self modelWith: {
						    pkg.
						    c.
						    m })
			   coverage: (self coverageOfSize: 30 regions: {
						    (self regionFor: c from: 1 to: 20).
						    (self regionFor: m from: 5 to: 10) })).
		  pkg.
		  c.
		  m }
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> coverageOfSize: aSize regions: aCollection [
	"Coverage without file. Regions must be sorted by start, then by decreasing size."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: (String new: aSize withAll: $x)
			   regions: aCollection asOrderedCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> modelWith: aCollection [

	| aModel |
	aModel := FamixJavaModel new.
	aCollection do: [ :each | aModel add: each ].
	^ aModel
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> named: aFamixClass name: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> namesOf: aCollection [

	^ aCollection asArray collect: [ :each | each name ]
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> outsideNavigatorFilter: aSymbol [
	"Class C and its method m are in the model; their package outsidePkg is NOT added to it. Regions: C 1-20, m 5-10. Answer { navigator. outsidePkg. C. m. model }."

	| pkg c m aModel |
	pkg := self named: FamixJavaPackage name: 'outsidePkg'.
	c := self named: FamixJavaClass name: 'C'.
	m := self named: FamixJavaMethod name: 'm'.
	pkg addType: c.
	c addMethod: m.
	aModel := self modelWith: {
			          c.
			          m }.
	^ {
		  ((MMCModelNavigator
			    on: aModel
			    coverage: (self coverageOfSize: 30 regions: {
							     (self regionFor: c from: 1 to: 20).
							     (self regionFor: m from: 5 to: 10) }))
			   filter: aSymbol;
			   yourself).
		  pkg.
		  c.
		  m.
		  aModel }
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> regionFor: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCModelNavigatorRobustnessTest >> siblingNamesOf: aCollectionOfNames filter: aSymbol [
	"Names of the children of package 'p' (all classes without region) in the order of the navigator. The classes are added to the package and to the model in the given order."

	| pkg classes navigator |
	pkg := self named: FamixJavaPackage name: 'p'.
	classes := aCollectionOfNames collect: [ :each |
		           self named: FamixJavaClass name: each ].
	classes do: [ :each | pkg addType: each ].
	navigator := (MMCModelNavigator
		              on: (self modelWith: { pkg } , classes)
		              coverage: (self coverageOfSize: 100 regions: #(  )))
		             filter: aSymbol;
		             yourself.
	^ self namesOf: (navigator childrenOf: pkg)
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testAllModeSizeCountsTheContainerOutsideTheModel [
	"DOCUMENTED CHOICE: size is 3 in #all mode (outsidePkg, C, m) whereas the model has only 2 entities (C and m): the ancestors are always shown."

	| fixture |
	fixture := self outsideNavigatorFilter: #all.
	self assert: (fixture at: 5) allModelEntities size equals: 2.
	self assert: fixture first size equals: 3
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testContainerOutsideTheModelIsNotCovered [
	"outsidePkg has no region of its own: isCovered: is false in both modes."

	#( #covered #all ) do: [ :mode |
			| fixture |
			fixture := self outsideNavigatorFilter: mode.
			self deny: (fixture first isCovered: (fixture at: 2)) ]
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testContainerOutsideTheModelIsStillIncludedInAllMode [
	"Same documented choice in #all mode."

	| fixture navigator |
	fixture := self outsideNavigatorFilter: #all.
	navigator := fixture first.
	self assert: (navigator includes: (fixture at: 2)).
	self assert: (navigator parentOf: (fixture at: 3)) == (fixture at: 2).
	self assert: navigator roots size equals: 1.
	self assert: navigator roots first == (fixture at: 2)
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testContainerOutsideTheModelIsStillIncludedInCoveredMode [
	"DOCUMENTED CHOICE: the ancestors of an entity are always shown, even when their container is not in the model. outsidePkg is not in the model but is included, is the parent of C and the only root."

	| fixture navigator |
	fixture := self outsideNavigatorFilter: #covered.
	navigator := fixture first.
	self assert: (navigator includes: (fixture at: 2)).
	self assert: (navigator parentOf: (fixture at: 3)) == (fixture at: 2).
	self assert: navigator roots size equals: 1.
	self assert: navigator roots first == (fixture at: 2)
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testCoveredEntityComesBeforeUncoveredOneWhateverTheCase [
	"Zed is covered (position 1), abc and ABC are not (infinity): Zed first although it sorts after them alphabetically."

	| pkg zed abc upper navigator |
	pkg := self named: FamixJavaPackage name: 'p'.
	zed := self named: FamixJavaClass name: 'Zed'.
	abc := self named: FamixJavaClass name: 'abc'.
	upper := self named: FamixJavaClass name: 'ABC'.
	{
		zed.
		abc.
		upper } do: [ :each | pkg addType: each ].
	navigator := (MMCModelNavigator
		              on: (self modelWith: {
						               pkg.
						               abc.
						               upper.
						               zed })
		              coverage: (self
				               coverageOfSize: 100
				               regions: { (self regionFor: zed from: 1 to: 10) }))
		             filter: #all;
		             yourself.
	self
		assert: (self namesOf: (navigator childrenOf: pkg)) first
		equals: 'Zed'.
	self
		assert: (self namesOf: (navigator childrenOf: pkg)) allButFirst
				asSortedCollection asArray
		equals: #( 'ABC' 'abc' )
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testEntityAtPathAcceptsOrderedCollectionAndInterval [
	"An OrderedCollection (1 1 1) gives m; the Interval 1 to: 1 gives the root p; the Interval 1 to: 2 asks for a second child of p, which does not exist: nil. Identity is compared (never print Famix entities)."

	| fixture navigator |
	fixture := self chainNavigator.
	navigator := fixture first.
	self assert: (navigator entityAtPath: (OrderedCollection withAll: #( 1 1 1 ))) == (fixture at: 4).
	self assert: (navigator entityAtPath: (1 to: 1)) == (fixture at: 2).
	self assert: (navigator entityAtPath: (1 to: 2)) isNil
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testEntityAtPathWithANonIntegerElementIsNil [
	"nil, a string, 1.5, -1 and 0 are not valid indices, alone or after a valid one."

	| navigator |
	navigator := self chainNavigator first.
	{ nil. 'a'. 1.5. -1. 0 } do: [ :bad |
			self assert: (navigator entityAtPath: { bad }) isNil.
			self assert: (navigator entityAtPath: {
						 1.
						 bad }) isNil ]
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testEntityAtPathWithANumberIsNil [
	"3 and 3.5 are not paths: nil, no MessageNotUnderstood."

	| navigator |
	navigator := self chainNavigator first.
	self assert: (navigator entityAtPath: 3) isNil.
	self assert: (navigator entityAtPath: 3.5) isNil
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testEntityAtPathWithASymbolOrAnEmptyDictionaryIsNil [
	"A Symbol is a collection of characters, an empty Dictionary an empty collection: nil."

	| navigator |
	navigator := self chainNavigator first.
	self assert: (navigator entityAtPath: #abc) isNil.
	self assert: (navigator entityAtPath: Dictionary new) isNil
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testEntityAtPathWithAnObjectABooleanOrACharacterIsNil [
	"Object new, true and $a are not paths: nil."

	| navigator |
	navigator := self chainNavigator first.
	self assert: (navigator entityAtPath: Object new) isNil.
	self assert: (navigator entityAtPath: true) isNil.
	self assert: (navigator entityAtPath: $a) isNil
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testFirstRegionPositionStaysTheMainKeyOverTheLabel [
	"beta starts at 5 and Alpha at 30: position order (beta, Alpha) wins over label order (Alpha, beta)."

	| pkg beta alpha navigator |
	pkg := self named: FamixJavaPackage name: 'p'.
	beta := self named: FamixJavaClass name: 'beta'.
	alpha := self named: FamixJavaClass name: 'Alpha'.
	pkg
		addType: beta;
		addType: alpha.
	navigator := MMCModelNavigator
		             on: (self modelWith: {
					              pkg.
					              alpha.
					              beta })
		             coverage: (self coverageOfSize: 100 regions: {
					              (self regionFor: beta from: 5 to: 10).
					              (self regionFor: alpha from: 30 to: 40) }).
	self
		assert: (self namesOf: (navigator childrenOf: pkg))
		equals: #( 'beta' 'Alpha' )
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testPathAndAncestorsGoThroughTheContainerOutsideTheModel [
	"pathTo: m is #(1 1 1) (outsidePkg, C, m) and ancestorsOf: m are outsidePkg then C, in both modes."

	#( #covered #all ) do: [ :mode |
			| fixture navigator ancestors |
			fixture := self outsideNavigatorFilter: mode.
			navigator := fixture first.
			self assert: (navigator pathTo: (fixture at: 4)) equals: #( 1 1 1 ).
			ancestors := navigator ancestorsOf: (fixture at: 4).
			self assert: ancestors size equals: 2.
			self assert: ancestors first == (fixture at: 2).
			self assert: ancestors last == (fixture at: 3) ]
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testRootWithARegionComesBeforeRootWithoutWhateverTheCase [
	"Package Zed has a region at 1-10 (key 1), package abc none (key infinity): Zed first although abc < Zed ignoring case."

	| zed abc navigator |
	zed := self named: FamixJavaPackage name: 'Zed'.
	abc := self named: FamixJavaPackage name: 'abc'.
	navigator := (MMCModelNavigator
		              on: (self modelWith: { zed. abc })
		              coverage: (self coverageOfSize: 100 regions: { (self regionFor: zed from: 1 to: 10) }))
		             filter: #all;
		             yourself.
	self assert: (self namesOf: navigator roots) equals: #( 'Zed' 'abc' )
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testRootsAreSortedIgnoringCase [
	"Two root packages without region in #all mode: abc before Zed."

	| zed abc navigator |
	zed := self named: FamixJavaPackage name: 'Zed'.
	abc := self named: FamixJavaPackage name: 'abc'.
	navigator := (MMCModelNavigator
		              on: (self modelWith: {
						               zed.
						               abc })
		              coverage: (self coverageOfSize: 100 regions: #(  )))
		             filter: #all;
		             yourself.
	self assert: (self namesOf: navigator roots) equals: #( 'abc' 'Zed' )
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testSiblingsAreInAlphabeticalOrderIgnoringCase [
	"alpha < Beta < beta2 < Charlie ignoring case, whatever the insertion order."

	self
		assert: (self
				 siblingNamesOf: #( 'Charlie' 'beta2' 'alpha' 'Beta' )
				 filter: #all)
		equals: #( 'alpha' 'Beta' 'beta2' 'Charlie' ).
	self
		assert: (self
				 siblingNamesOf: #( 'Beta' 'Charlie' 'alpha' 'beta2' )
				 filter: #all)
		equals: #( 'alpha' 'Beta' 'beta2' 'Charlie' )
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testSiblingsEqualIgnoringCaseAreInTheSameOrderWhateverTheInsertionOrder [
	"abc and ABC tie on the label ignoring case: the tie is broken by mooseName then case, so the order does not depend on the insertion order, nor on the navigator."

	| first second third |
	first := self siblingNamesOf: #( 'abc' 'ABC' ) filter: #all.
	second := self siblingNamesOf: #( 'ABC' 'abc' ) filter: #all.
	third := self siblingNamesOf: #( 'abc' 'ABC' ) filter: #all.
	self
		assert: first asSortedCollection asArray
		equals: #( 'ABC' 'abc' ).
	self assert: second equals: first.
	self assert: third equals: first
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testSiblingsStartingAtTheSamePositionAreSortedByLabelIgnoringCase [
	"b and A share the start 1: tie on position, the label ignoring case decides: A before b."

	| pkg b a navigator |
	pkg := self named: FamixJavaPackage name: 'p'.
	b := self named: FamixJavaClass name: 'b'.
	a := self named: FamixJavaClass name: 'A'.
	pkg
		addType: b;
		addType: a.
	navigator := MMCModelNavigator
		             on: (self modelWith: {
					              pkg.
					              b.
					              a })
		             coverage: (self coverageOfSize: 100 regions: {
					              (self regionFor: b from: 1 to: 10).
					              (self regionFor: a from: 1 to: 10) }).
	self
		assert: (self namesOf: (navigator childrenOf: pkg))
		equals: #( 'A' 'b' )
]

{ #category : 'tests' }
MMCModelNavigatorRobustnessTest >> testSiblingsWithoutRegionAreSortedIgnoringCase [
	"abc and Zed have no region (same key, infinity): the label decides, ignoring case: abc before Zed (a plain comparison gives Zed first because $Z < $a)."

	self
		assert: (self siblingNamesOf: #( 'Zed' 'abc' ) filter: #all)
		equals: #( 'abc' 'Zed' )
]
