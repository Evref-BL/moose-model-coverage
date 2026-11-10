"
Tests of MMCModelFiles>>typeCounts, typeNames and classNamesOfType: on small FamixJava models: unique entities having at least one readable file are counted by type name (sorted by name, memoized, invalidated when the inventory is rebuilt).
"
Class {
	#name : 'MMCModelFilesTypeCountsTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'fixture' }
MMCModelFilesTypeCountsTest >> add: anEntityClass on: aFileName [
	"Add to the model a new entity of anEntityClass with an indexed file anchor on aFileName (relative to the root folder) and answer it."

	| entity anchor |
	entity := anEntityClass new.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: 1.
	anchor endPos: 3.
	model add: anchor.
	entity sourceAnchor: anchor.
	^ entity
]

{ #category : 'fixture' }
MMCModelFilesTypeCountsTest >> setUp [
	"A temporary root folder and an empty FamixJava model whose rootFolder is it."

	super setUp.
	folder := FileLocator temp / ('mmc-typecounts-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'fixture' }
MMCModelFilesTypeCountsTest >> splitModelOn: someFileNames [
	"Answer a FamixTest1 model (it has multiple file anchors, FamixJava has none) with a rootFolder, holding one class spread over the files named in someFileNames."

	| other multi entity |
	other := FamixTest1Model new.
	other rootFolder: folder asFileReference.
	multi := FamixTest1MultipleFileAnchor new.
	other add: multi.
	someFileNames do: [ :each | multi addFileAnchorWithPath: each ].
	entity := FamixTest1Class new.
	entity name: 'Split'.
	other add: entity.
	entity sourceAnchor: multi.
	^ other
]

{ #category : 'fixture' }
MMCModelFilesTypeCountsTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testClassNamesOfAKnownType [

	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	self add: FamixJavaMethod on: 'a.java'.
	self
		assert: ((MMCModelFiles on: model) classNamesOfType: 'Class')
		equals: #( 'FamixJavaClass' )
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testClassNamesOfATypeWithoutReadableFileAreEmpty [

	self add: FamixJavaClass on: 'missing.java'.
	self assert:
		((MMCModelFiles on: model) classNamesOfType: 'Class') isEmpty
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testClassNamesOfAnUnknownTypeAreEmpty [

	| files |
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	files := MMCModelFiles on: model.
	self assert: (files classNamesOfType: 'Nope') equals: #(  ).
	self assert: (files classNamesOfType: nil) equals: #(  )
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEmptyFileIsExcluded [

	self writeText: '' to: 'empty.java'.
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'empty.java'.
	self add: FamixJavaMethod on: 'a.java'.
	self
		assert: self typeCounts associations asArray
		equals: { ('Method' -> 1) }
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEmptyModelHasNoType [

	| files |
	files := MMCModelFiles on: model.
	self assert: files typeCounts isEmpty.
	self assert: files typeNames isEmpty.
	self assert: (files classNamesOfType: 'Class') isEmpty
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEntitiesAreCountedByTypeName [

	| counts |
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	self add: FamixJavaMethod on: 'a.java'.
	self add: FamixJavaAccess on: 'a.java'.
	counts := self typeCounts.
	self assert: counts size equals: 3.
	self assert: (counts at: 'Class') equals: 2.
	self assert: (counts at: 'Method') equals: 1.
	self assert: (counts at: 'Access') equals: 1
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEntityOnSeveralFilesIsCountedOnce [

	| files |
	self writeText: 'abc' to: 'a.txt'.
	self writeText: 'abc' to: 'b.txt'.
	files := MMCModelFiles on: (self splitModelOn: #( 'a.txt' 'b.txt' )).
	self assert: files fileCount equals: 2.
	self
		assert: files typeCounts associations asArray
		equals: { ('Class' -> 1) }
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEntityWithAnUnreadableAndAReadableFileIsCounted [

	| files |
	self writeText: 'abc' to: 'a.txt'.
	files := MMCModelFiles on:
		         (self splitModelOn: #( 'missing.txt' 'a.txt' )).
	self
		assert: files typeCounts associations asArray
		equals: { ('Class' -> 1) }
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEntityWithOnlyUnreadableFilesIsNotCounted [

	| files |
	files := MMCModelFiles on:
		         (self splitModelOn: #( 'missing.txt' 'other-missing.txt' )).
	self assert: files typeCounts isEmpty
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testEntityWithoutAnchorIsExcluded [

	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	model add: FamixJavaMethod new.
	model add: FamixJavaAccess new.
	self
		assert: self typeCounts associations asArray
		equals: { ('Class' -> 1) }
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testMissingFileIsExcluded [

	self add: FamixJavaClass on: 'missing.java'.
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaMethod on: 'a.java'.
	self
		assert: self typeCounts associations asArray
		equals: { ('Method' -> 1) }
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testNonFileAnchorIsExcluded [

	| entity anchor files |
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	entity := FamixJavaMethod new.
	model add: entity.
	anchor := FamixJavaSourceTextAnchor new.
	anchor source: 'void m() {}'.
	model add: anchor.
	entity sourceAnchor: anchor.
	files := MMCModelFiles on: model.
	self assert: files ignoredAnchorCount equals: 1.
	self
		assert: files typeCounts associations asArray
		equals: { ('Class' -> 1) }
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testOnlyUnreadableFilesGiveNoType [

	self add: FamixJavaClass on: 'missing.java'.
	self assert: self typeCounts isEmpty
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testRebuildingTheInventoryWithSetRootFolderRecomputesTheCounts [

	| presenter before wrong |
	wrong := folder / 'wrong'.
	wrong ensureCreateDirectory.
	model rootFolder: wrong asFileReference.
	self writeText: 'abcdef' to: 'src/A.java'.
	self add: FamixJavaClass on: 'src/A.java'.
	presenter := MMCCoveragePresenter forModel: model.
	[
		before := presenter modelFiles typeCounts.
		self assert: before isEmpty.
		presenter perform: #setRootFolder: with: folder asFileReference.
		self deny: presenter modelFiles typeCounts == before.
		self
			assert: presenter modelFiles typeCounts associations asArray
			equals: { ('Class' -> 1) } ] ensure: [
		MMCColorSchemeRegistry removeFor: model ]
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testSetModelInvalidatesTheCounts [

	| files before |
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	files := MMCModelFiles on: model.
	before := files typeCounts.
	self add: FamixJavaMethod on: 'a.java'.
	self assert: files typeCounts == before.
	files setModel: model.
	self deny: files typeCounts == before.
	self assert: files typeNames equals: #( 'Class' 'Method' ).
	self
		assert: (files classNamesOfType: 'Method')
		equals: #( 'FamixJavaMethod' )
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testSeveralClassesCanShareATypeName [
	"Two entity classes of different metamodels with the same type name are grouped, their class names sorted, their entities added."

	| files |
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	self add: FamixStClass on: 'a.java'.
	files := MMCModelFiles on: model.
	self assert: (files typeCounts at: 'Class') equals: 2.
	self
		assert: (files classNamesOfType: 'Class')
		equals: #( 'FamixJavaClass' 'FamixStClass' )
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testTypeCountsIsAnOrderedDictionary [

	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	self assert: self typeCounts class equals: OrderedDictionary
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testTypeCountsIsMemoized [

	| files |
	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	files := MMCModelFiles on: model.
	self assert: files typeCounts == files typeCounts.
	self assert: files typeNames equals: files typeNames
]

{ #category : 'tests' }
MMCModelFilesTypeCountsTest >> testTypesAreSortedByName [

	self writeText: 'abcdef' to: 'a.java'.
	self add: FamixJavaMethod on: 'a.java'.
	self add: FamixJavaClass on: 'a.java'.
	self add: FamixJavaAccess on: 'a.java'.
	self
		assert: self typeCounts keys asArray
		equals: #( 'Access' 'Class' 'Method' ).
	self
		assert: (MMCModelFiles on: model) typeNames
		equals: #( 'Access' 'Class' 'Method' )
]

{ #category : 'fixture' }
MMCModelFilesTypeCountsTest >> typeCounts [
	"Answer the type counts of a new inventory of the model."

	^ (MMCModelFiles on: model) typeCounts
]

{ #category : 'fixture' }
MMCModelFilesTypeCountsTest >> writeText: aString to: aRelativeName [
	"UTF-8 text file under the root folder."

	| ref |
	ref := folder resolve: aRelativeName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
