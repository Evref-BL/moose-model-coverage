Class {
	#name : 'MMCHiddenTypesCoverageTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'files',
		'file'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCHiddenTypesCoverageTest >> add: anEntityClass named: aName from: start to: end [

	| entity anchor |
	entity := anEntityClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor.
	^ entity
]

{ #category : 'helpers' }
MMCHiddenTypesCoverageTest >> coverageHiding: aCollection [

	files hiddenTypeNames: aCollection.
	^ files coverageFor: file
]

{ #category : 'helpers' }
MMCHiddenTypesCoverageTest >> depthsOf: aCoverage [
	"Depths of the regions by entity name."

	| result |
	result := Dictionary new.
	aCoverage regions do: [ :each |
		result at: each entity name put: (aCoverage depthOf: each) ].
	^ result
]

{ #category : 'helpers' }
MMCHiddenTypesCoverageTest >> setUp [
	"a.txt holds abcdefghijkl (12 characters): class 1-10, method 3-8, attribute 4-6."

	| ref |
	super setUp.
	folder := FileLocator temp / ('mmc-cov-hidden-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	ref := folder / 'a.txt'.
	ref binaryWriteStreamDo: [ :s |
		s nextPutAll: 'abcdefghijkl' utf8Encoded ].
	self
		add: FamixJavaClass
		named: 'A'
		from: 1
		to: 10.
	self
		add: FamixJavaMethod
		named: 'm'
		from: 3
		to: 8.
	self
		add: FamixJavaAttribute
		named: 'x'
		from: 4
		to: 6.
	files := MMCModelFiles on: model.
	file := files files first
]

{ #category : 'helpers' }
MMCHiddenTypesCoverageTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testAllTypesHiddenGiveZeroPercentAndOneUncoveredZone [

	| coverage |
	coverage := self coverageHiding: #( 'Class' 'Method' 'Attribute' ).
	self assert: coverage isReadable.
	self assert: coverage size equals: 12.
	self assert: coverage regions isEmpty.
	self assert: coverage coveredSet size equals: 0.
	self assert: coverage coveredPercentage equals: 0.0.
	self assert: coverage maxDepth equals: 0.
	self assert: coverage uncoveredRegions size equals: 1.
	self
		assert: coverage uncoveredRegions first interval
		equals: (1 to: 12)
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testCharactersCoveredAlsoByAVisibleTypeStayCovered [
	"The method and the attribute lie inside the class: hiding the class and the method leaves only the attribute."

	| coverage |
	coverage := self coverageHiding: #( 'Class' 'Method' ).
	self assert: coverage coveredSet size equals: 3.
	self assert: (coverage isCovered: 4).
	self deny: (coverage isCovered: 3).
	self deny: (coverage isCovered: 7).
	self
		assert:
		(coverage regions collect: [ :each | each entity name ]) asArray
		equals: #( 'x' )
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testCharactersCoveredOnlyByAHiddenTypeBecomeUncovered [

	| coverage |
	coverage := self coverageHiding: #( 'Class' ).
	"Only the method (3-8) still covers."
	self assert: coverage coveredSet size equals: 6.
	self deny: (coverage isCovered: 1).
	self deny: (coverage isCovered: 2).
	self assert: (coverage isCovered: 3).
	self assert: (coverage isCovered: 8).
	self deny: (coverage isCovered: 9).
	self deny: (coverage isCovered: 12).
	self assert: coverage coveredPercentage equals: 50.0.
	self
		assert:
		(coverage uncoveredRegions collect: [ :each | each interval ])
		equals: {
				(1 to: 2).
				(9 to: 12) }
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testDepthsWithoutHiddenType [

	| depths |
	depths := self depthsOf: (self coverageHiding: #(  )).
	self assert: depths equals: {
			('A' -> 0).
			('m' -> 1).
			('x' -> 2) } asDictionary.
	self assert: (files coverageFor: file) maxDepth equals: 2
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testHidingTheInnermostTypeKeepsTheOtherDepths [

	| coverage |
	coverage := self coverageHiding: #( 'Attribute' ).
	self assert: (self depthsOf: coverage) equals: {
			('A' -> 0).
			('m' -> 1) } asDictionary.
	self assert: coverage maxDepth equals: 1
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testHidingTheMiddleTypeRemovesOneLevelBelowIt [

	| coverage |
	coverage := self coverageHiding: #( 'Method' ).
	self assert: (self depthsOf: coverage) equals: {
			('A' -> 0).
			('x' -> 1) } asDictionary.
	self assert: coverage maxDepth equals: 1
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testHidingTheOutermostTypeRemovesOneLevelForEveryNestedType [

	| coverage |
	coverage := self coverageHiding: #( 'Class' ).
	self assert: (self depthsOf: coverage) equals: {
			('m' -> 0).
			('x' -> 1) } asDictionary.
	self assert: coverage maxDepth equals: 1
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testHighlightPlanFollowsTheHiddenTypes [

	| plan |
	plan := MMCHighlightPlan for: (self coverageHiding: #(  )).
	self assert: plan coveredSegments size equals: 5.
	self assert: (plan coveredSegments collect: #depth) max equals: 2.
	plan := MMCHighlightPlan for: (self coverageHiding: #( 'Method' )).
	self assert: (plan coveredSegments collect: #depth) max equals: 1.
	self
		assert:
		((plan coveredSegments collect: #typeName) asSet includes: 'Method')
		equals: false.
	self assert: plan uncoveredSegments size equals: 1.
	self
		assert: plan uncoveredSegments first interval
		equals: (11 to: 12)
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testHighlightPlanWithEverythingHiddenIsOneUncoveredZone [

	| plan |
	plan := MMCHighlightPlan for:
		        (self coverageHiding: #( 'Class' 'Method' 'Attribute' )).
	self assert: plan coveredSegments isEmpty.
	self assert: plan uncoveredSegments size equals: 1.
	self assert: plan uncoveredSegments first interval equals: (1 to: 12).
	self assert: plan size equals: 1
]

{ #category : 'tests' }
MMCHiddenTypesCoverageTest >> testShowingTheTypesAgainRestoresTheCoverage [

	| coverage |
	self coverageHiding: #( 'Class' 'Method' ).
	coverage := self coverageHiding: #(  ).
	self assert: coverage coveredSet size equals: 10.
	self assert: coverage maxDepth equals: 2.
	self assert: coverage regions size equals: 3
]
