Class {
	#name : 'MMCModelNavigatorHiddenTypesTest',
	#superclass : 'TestCase',
	#instVars : [
		'package',
		'classC',
		'classD',
		'methodM',
		'methodN',
		'bare',
		'model',
		'coverage'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> anchored: anEntity [
	"Give anEntity a source anchor (not added to the model: only its presence counts)."

	anEntity sourceAnchor: FamixJavaIndexedFileAnchor new.
	^ anEntity
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> chainOf: aNumber hiddenClassesIn: aPackage [
	"Answer a method nested in a chain of aNumber anchored classes (typeContainer), the outermost one belonging to aPackage. The classes and the method are added to the model."

	| outer method |
	outer := nil.
	1 to: aNumber do: [ :i |
			| each |
			each := self anchored:
				        (self named: FamixJavaClass name: 'Deep' , i printString).
			model add: each.
			outer
				ifNil: [ aPackage addType: each ]
				ifNotNil: [ each typeContainer: outer ].
			outer := each ].
	method := self anchored:
		          (self named: FamixJavaMethod name: 'deepMethod').
	model add: method.
	outer addMethod: method.
	^ method
]

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> coverageOfSize: aSize regions: aCollection [

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: (String new: aSize withAll: $x)
			   regions: aCollection asOrderedCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> named: aFamixClass name: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> namesOf: aCollection [
	"Names of the entities, as an Array (never print entities)."

	^ (aCollection collect: [ :each | each name ]) asArray
]

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> navigatorFilter: aSymbol hiding: aCollection [

	^ (MMCModelNavigator on: model coverage: coverage)
		  filter: aSymbol;
		  hiddenTypeNames: aCollection;
		  yourself
]

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> regionFor: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCModelNavigatorHiddenTypesTest >> setUp [
	"Package P holds the classes C (with the method M), D (with the method N) and Bare (no source anchor). Every entity but P and Bare has a source anchor. Text of 100 characters: C 1-50, M 10-30, D 55-90, N 60-80."

	super setUp.
	package := self named: FamixJavaPackage name: 'P'.
	classC := self anchored: (self named: FamixJavaClass name: 'C').
	classD := self anchored: (self named: FamixJavaClass name: 'D').
	bare := self named: FamixJavaClass name: 'Bare'.
	methodM := self anchored: (self named: FamixJavaMethod name: 'M').
	methodN := self anchored: (self named: FamixJavaMethod name: 'N').
	package
		addType: classC;
		addType: classD;
		addType: bare.
	classC addMethod: methodM.
	classD addMethod: methodN.
	model := FamixJavaModel new.
	{
		package.
		classC.
		classD.
		bare.
		methodM.
		methodN } do: [ :each | model add: each ].
	coverage := self coverageOfSize: 100 regions: {
			            (self regionFor: classC from: 1 to: 50).
			            (self regionFor: methodM from: 10 to: 30).
			            (self regionFor: classD from: 55 to: 90).
			            (self regionFor: methodN from: 60 to: 80) }
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testAChainOfFewHiddenContainersIsSkippedUpToTheVisibleAncestor [

	| method navigator |
	method := self chainOf: 20 hiddenClassesIn: package.
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	self assert: (navigator parentOf: method) identicalTo: package.
	self assert: (navigator pathTo: method) size equals: 2
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testACycleOfHiddenContainersTerminates [
	"The cycle X -> Y -> X is closed by writing the slot directly: the setter would loop in resetMooseName. Never ask the mooseName or the printString of these entities after the cycle exists. The whole test, construction included, is bounded."

	[
		| x y method navigator |
		x := self anchored: (self named: FamixJavaClass name: 'X').
		y := self anchored: (self named: FamixJavaClass name: 'Y').
		method := self anchored:
			          (self named: FamixJavaMethod name: 'cyclic').
		{
			x.
			y.
			method } do: [ :each | model add: each ].
		x typeContainer: y.
		y instVarNamed: 'typeContainer' put: x.
		x addMethod: method.
		navigator := self navigatorFilter: #all hiding: #( 'Class' ).
		self assert: (navigator rawFirstContainerOf: x) == y.
		self assert: (navigator rawFirstContainerOf: y) == x.
		self assert: (navigator firstContainerOf: method) isNil.
		self assert: (navigator parentOf: method) isNil.
		self assert: (navigator includes: method).
		self assert: navigator size equals: 5.
		self assert: navigator roots size equals: 2 ]
		valueWithin: 10 seconds
		onTimeout: [
		self fail: 'endless loop on a cycle of hidden containers' ]
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testChangingTheHiddenTypesRebuildsTheIndex [

	| navigator |
	navigator := self navigatorFilter: #all hiding: #(  ).
	self assert: (navigator parentOf: methodM) identicalTo: classC.
	navigator hiddenTypeNames: #( 'Class' ).
	self assert: (navigator parentOf: methodM) identicalTo: package.
	self deny: (navigator includes: classC).
	navigator hiddenTypeNames: #(  ).
	self assert: (navigator parentOf: methodM) identicalTo: classC.
	self assert: (navigator includes: classC)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testEntityWithoutSourceAnchorIsNeverHidden [

	| navigator |
	navigator := self
		             navigatorFilter: #all
		             hiding: #( 'Class' 'Package' ).
	self deny: (navigator isHiddenEntity: bare).
	self deny: (navigator isHiddenEntity: package).
	self assert: (navigator includes: bare).
	self assert: (navigator includes: package).
	self assert: (navigator isHiddenEntity: classC)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testHasSourceAnchorIsNotAffectedByHiddenTypes [

	| navigator |
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	self assert: (navigator hasSourceAnchor: classC).
	self deny: (navigator hasSourceAnchor: bare).
	self deny: (navigator hasSourceAnchor: nil).
	self deny: (navigator hasSourceAnchor: 42)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testHiddenEntitiesAreAbsentInAllMode [

	| navigator |
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	self deny: (navigator includes: classC).
	self deny: (navigator includes: classD).
	self assert: (navigator includes: methodM).
	self assert: (navigator includes: methodN).
	self assert: (navigator includes: package).
	self assert: (navigator includes: bare).
	self deny: (navigator visibleEntities includes: classC)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testHiddenEntitiesAreAbsentInCoveredMode [
	"The covered mode also leaves out the entities of a hidden type that still have a region."

	| navigator |
	navigator := self navigatorFilter: #covered hiding: #( 'Class' ).
	self deny: (navigator includes: classC).
	self deny: (navigator includes: classD).
	self assert: (navigator includes: methodM).
	self assert: (navigator includes: methodN).
	self assert: (navigator includes: package).
	self deny: (navigator includes: bare).
	navigator := self
		             navigatorFilter: #covered
		             hiding: #( 'Class' 'Method' ).
	self assert: navigator size equals: 0
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testHiddenTypeNamesAnswersACopy [

	| navigator names |
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	names := navigator hiddenTypeNames.
	names add: 'Method'.
	self assert: navigator hiddenTypeNames equals: #( 'Class' ) asSet.
	self deny: (navigator isHiddenEntity: methodM)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testHidingClassAndPackageMakesTheMethodsRoots [

	| navigator |
	self anchored: package.
	navigator := self
		             navigatorFilter: #covered
		             hiding: #( 'Class' 'Package' ).
	self assert: (navigator parentOf: methodM) isNil.
	self
		assert: (self namesOf: navigator roots) asSet
		equals: #( 'M' 'N' ) asSet.
	self assert: (navigator pathTo: methodM) size equals: 1.
	self assert: (navigator ancestorsOf: methodM) isEmpty
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testHidingThePackageMakesTheClassesRoots [

	| navigator |
	self anchored: package.
	navigator := self navigatorFilter: #all hiding: #( 'Package' ).
	self deny: (navigator includes: package).
	self assert: (navigator parentOf: classC) isNil.
	self assert: (navigator parentOf: bare) isNil.
	self assert: (navigator parentOf: methodM) identicalTo: classC.
	self
		assert: (self namesOf: navigator roots) asSet
		equals: #( 'C' 'D' 'Bare' ) asSet.
	self assert: (navigator pathTo: methodM) size equals: 2
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testMethodIsAttachedToThePackageWhenItsClassIsHidden [

	| navigator |
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	self assert: (navigator parentOf: methodM) identicalTo: package.
	self assert: (navigator parentOf: methodN) identicalTo: package.
	self
		assert: (navigator ancestorsOf: methodM) asArray
		equals: { package }.
	self assert: (navigator roots includes: package).
	self deny: (navigator roots includes: classC).
	self
		assert: (self namesOf: (navigator childrenOf: package)) asSet
		equals: #( 'M' 'N' 'Bare' ) asSet
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testMutatingTheSetGivenToHiddenTypeNamesDoesNotAffectTheNavigator [

	| navigator given |
	given := Set withAll: #( 'Class' ).
	navigator := self navigatorFilter: #all hiding: given.
	given add: 'Method'.
	given remove: 'Class'.
	self assert: navigator hiddenTypeNames equals: #( 'Class' ) asSet.
	self assert: (navigator isHiddenEntity: classC).
	self deny: (navigator isHiddenEntity: methodM)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testNameFilterNeverRevealsAHiddenEntity [

	| navigator |
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	navigator nameFilter: 'C'.
	self deny: (navigator includes: classC).
	navigator nameFilter: 'M'.
	self assert: (navigator includes: methodM).
	self assert: (navigator parentOf: methodM) identicalTo: package
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testNothingIsHiddenByDefault [

	| navigator |
	navigator := MMCModelNavigator on: model coverage: coverage.
	self assert: navigator hiddenTypeNames isEmpty.
	navigator filter: #all.
	self assert: (navigator includes: classC).
	self deny: (navigator isHiddenEntity: classC)
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testPathToAHiddenEntityIsNilAndPathToItsMethodGoesThroughThePackage [

	| navigator path |
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	self assert: (navigator pathTo: classC) isNil.
	path := navigator pathTo: methodM.
	self assert: path size equals: 2.
	self assert: (navigator entityAtPath: path) identicalTo: methodM.
	self
		assert: (navigator entityAtPath: path allButLast)
		identicalTo: package.
	self assert: (navigator ancestorsOf: classC) isEmpty.
	self assert: (navigator parentOf: classC) isNil
]

{ #category : 'tests' }
MMCModelNavigatorHiddenTypesTest >> testTheSkipOfHiddenContainersIsCappedAt1000 [
	"Beyond 1000 hidden containers in a row the skipping stops (the safeguard against container cycles): the entity has no visible parent and becomes a root instead of going through an endless loop."

	| method navigator |
	method := self chainOf: 1100 hiddenClassesIn: package.
	navigator := self navigatorFilter: #all hiding: #( 'Class' ).
	self assert: (navigator parentOf: method) isNil.
	self assert: (navigator roots includes: method).
	self assert: (navigator pathTo: method) size equals: 1
]
