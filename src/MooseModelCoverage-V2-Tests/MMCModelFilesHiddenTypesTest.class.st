Class {
	#name : 'MMCModelFilesHiddenTypesTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCModelFilesHiddenTypesTest >> add: anEntityClass named: aName on: aFileName from: start to: end [
	"Add to the model an entity of anEntityClass with an indexed file anchor and answer it."

	| entity anchor |
	entity := anEntityClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor.
	^ entity
]

{ #category : 'helpers' }
MMCModelFilesHiddenTypesTest >> buildNestedFixture [
	"a.txt (10 characters): the class covers 1-10, the method 3-6 inside it. b.txt (4 characters): a class covers 1-4."

	self writeText: 'abcdefghij' to: 'a.txt'.
	self writeText: 'wxyz' to: 'b.txt'.
	self
		add: FamixJavaClass
		named: 'A'
		on: 'a.txt'
		from: 1
		to: 10.
	self
		add: FamixJavaMethod
		named: 'm'
		on: 'a.txt'
		from: 3
		to: 6.
	self
		add: FamixJavaClass
		named: 'B'
		on: 'b.txt'
		from: 1
		to: 4
]

{ #category : 'helpers' }
MMCModelFilesHiddenTypesTest >> fileNamed: aFileName in: aModelFiles [

	^ aModelFiles files detect: [ :each | each basename = aFileName ]
]

{ #category : 'helpers' }
MMCModelFilesHiddenTypesTest >> setUp [

	super setUp.
	folder := FileLocator temp
	          / ('mmc-files-hidden-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'helpers' }
MMCModelFilesHiddenTypesTest >> tearDown [

	MMCColorSchemeRegistry removeFor: model.
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testChangingTheHiddenTypesDropsTheCachedCoverages [

	| files a before |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	a := self fileNamed: 'a.txt' in: files.
	before := files coverageFor: a.
	self assert: (files coverageFor: a) identicalTo: before.
	files hiddenTypeNames: #( 'Class' ).
	self assert: (files summaryFor: a) isNil.
	self deny: (files coverageFor: a) == before
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testFilesAndEntitiesOfTheInventoryAreNotFiltered [

	| files a |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	a := self fileNamed: 'a.txt' in: files.
	files hiddenTypeNames: #( 'Class' 'Method' ).
	self assert: files fileCount equals: 2.
	self assert: (files entitiesIn: a) size equals: 2.
	self assert: (files coverageFor: a) isReadable.
	self assert: (files coverageFor: a) text equals: 'abcdefghij'
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testGlobalSummaryFollowsTheHiddenTypes [

	| files a |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	files computeAll.
	self assert: files globalSummary fileCount equals: 2.
	self assert: files globalSummary size equals: 14.
	self assert: files globalSummary coveredSize equals: 14.
	files hiddenTypeNames: #( 'Class' ).
	self assert: files globalSummary fileCount equals: 0.
	self assert: files globalSummary size equals: 0.
	a := self fileNamed: 'a.txt' in: files.
	files coverageFor: a.
	self assert: files globalSummary fileCount equals: 1.
	self assert: files globalSummary size equals: 10.
	self assert: files globalSummary coveredSize equals: 4.
	files computeAll.
	self assert: files globalSummary coveredSize equals: 4.
	self assert: files globalSummary size equals: 14
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testHiddenTypeNamesAnswersACopy [

	| files names |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	files hiddenTypeNames: #( 'Class' ).
	names := files hiddenTypeNames.
	names add: 'Method'.
	self assert: files hiddenTypeNames equals: #( 'Class' ) asSet
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testHiddenTypesAreTakenFromTheSchemeOfTheModel [

	| files |
	self buildNestedFixture.
	(MMCColorSchemeRegistry for: model)
		hideType: 'Method';
		hideType: 'Attribute'.
	files := MMCModelFiles on: model.
	self
		assert: files hiddenTypeNames
		equals: #( 'Method' 'Attribute' ) asSet.
	self
		assert:
			(files coverageFor: (self fileNamed: 'a.txt' in: files)) coveredSet
				size
		equals: 10.
	self
		assert:
		(files coverageFor: (self fileNamed: 'a.txt' in: files)) regions
			size
		equals: 1
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testInitializationCreatesNoEntryInTheRegistry [

	| files size |
	self buildNestedFixture.
	size := MMCColorSchemeRegistry size.
	self deny: (MMCColorSchemeRegistry schemes includesKey: model).
	files := MMCModelFiles on: model.
	self assert: files hiddenTypeNames isEmpty.
	self deny: (MMCColorSchemeRegistry schemes includesKey: model).
	self assert: MMCColorSchemeRegistry size equals: size
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testMutatingTheSetGivenToHiddenTypeNamesDoesNotAffectTheFiles [

	| files given |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	given := Set withAll: #( 'Class' ).
	files hiddenTypeNames: given.
	given add: 'Method'.
	given remove: 'Class'.
	self assert: files hiddenTypeNames equals: #( 'Class' ) asSet
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testNothingIsHiddenByDefault [

	| files |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	self assert: files hiddenTypeNames isEmpty.
	self
		assert:
			(files coverageFor: (self fileNamed: 'a.txt' in: files)) coveredSet
				size
		equals: 10
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testOtherFileAnchorCountIsNotFiltered [
	"The anchors of the other files are counted whatever their type is hidden or not."

	| files a visible hidden |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	a := self fileNamed: 'a.txt' in: files.
	visible := (files coverageFor: a) otherFileAnchorCount.
	self assert: visible equals: 1.
	files hiddenTypeNames: #( 'Class' ).
	hidden := (files coverageFor: a) otherFileAnchorCount.
	self assert: hidden equals: visible.
	files hiddenTypeNames: #( 'Class' 'Method' ).
	self
		assert: (files coverageFor: a) otherFileAnchorCount
		equals: visible
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testPercentageCountsTheVisibleTypesOnly [

	| files a |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	a := self fileNamed: 'a.txt' in: files.
	self assert: (files coverageFor: a) coveredPercentage equals: 100.0.
	files hiddenTypeNames: #( 'Class' ).
	self assert: (files coverageFor: a) coveredPercentage equals: 40.0.
	self assert: (files coverageFor: a) regions size equals: 1.
	files hiddenTypeNames: #( 'Method' ).
	self assert: (files coverageFor: a) coveredPercentage equals: 100.0.
	files hiddenTypeNames: #( 'Class' 'Method' ).
	self assert: (files coverageFor: a) coveredPercentage equals: 0.0
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testSchemeChangeAfterInitializationIsNotFollowedByItself [
	"MMCModelFiles reads the scheme once at creation; the presenter pushes the changes with hiddenTypeNames:."

	| files |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	(MMCColorSchemeRegistry for: model) hideType: 'Class'.
	self assert: files hiddenTypeNames isEmpty.
	files hiddenTypeNames:
		(MMCColorSchemeRegistry for: model) hiddenTypeNames.
	self assert: files hiddenTypeNames equals: #( 'Class' ) asSet
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testSettingTheSameHiddenTypesKeepsTheCachedCoverages [

	| files a before |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	a := self fileNamed: 'a.txt' in: files.
	files hiddenTypeNames: #( 'Class' 'Method' ).
	before := files coverageFor: a.
	files hiddenTypeNames: #( 'Method' 'Class' ).
	files hiddenTypeNames:
		#( 'Method' 'Class' 'Method' ) asOrderedCollection.
	self assert: (files coverageFor: a) identicalTo: before.
	files hiddenTypeNames: #(  ).
	self deny: (files coverageFor: a) == before
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testSummariesOfTheOtherFilesAreUnknownAfterAChange [

	| files a b |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	files computeAll.
	a := self fileNamed: 'a.txt' in: files.
	b := self fileNamed: 'b.txt' in: files.
	self assert: (files summaryFor: a) notNil.
	self assert: (files summaryFor: b) notNil.
	files hiddenTypeNames: #( 'Method' ).
	self assert: (files summaryFor: a) isNil.
	self assert: (files summaryFor: b) isNil.
	files coverageFor: a.
	self assert: (files summaryFor: a) notNil.
	self assert: (files summaryFor: b) isNil
]

{ #category : 'tests' }
MMCModelFilesHiddenTypesTest >> testTypeCountsStayCompleteWhenTypesAreHidden [

	| files counts |
	self buildNestedFixture.
	files := MMCModelFiles on: model.
	counts := files typeCounts copy.
	files hiddenTypeNames: #( 'Class' 'Method' ).
	self assert: files typeCounts equals: counts.
	self assert: files typeNames equals: #( 'Class' 'Method' ).
	self assert: (files typeCounts at: 'Class') equals: 2.
	self
		assert: (files classNamesOfType: 'Method')
		equals: #( 'FamixJavaMethod' )
]

{ #category : 'helpers' }
MMCModelFilesHiddenTypesTest >> writeText: aString to: aFileName [

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
