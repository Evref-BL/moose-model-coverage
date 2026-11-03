"
Tests of the lazy coverage part of MMCModelFiles, TDD.
 coverageFor: aFile (MMCFileCoverage, computed on demand, cached: second call answers the identical object; unreadable file gives an unreadable MMCFileCoverage),
 summaryFor: aFile (the cached MMCFileCoverage, nil while not computed), globalSummary (aggregate of the computed files only: fileCount, size, coveredSize, coveredPercentage (nil when size is 0)),
 invalidate (drops every cached coverage), computeAll (computes every file, readable or not).
"
Class {
	#name : 'MMCModelFilesCoverageTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCModelFilesCoverageTest >> classNamed: aName on: aFileName from: start to: end [
	"Answer a class added to the model, with an indexed file anchor added to the model."

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
	^ entity
]

{ #category : 'helpers' }
MMCModelFilesCoverageTest >> fileNamed: aFileName [
	"Answer the canonical FileReference expected in MMCModelFiles>>files for a file of the fixture folder."

	^ (folder / aFileName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCModelFilesCoverageTest >> modelFiles [

	^ (Smalltalk globals at: #MMCModelFiles) on: model
]

{ #category : 'running' }
MMCModelFilesCoverageTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-files-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'running' }
MMCModelFilesCoverageTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testBomIsNotCountedInPositions [
	"BOM + abcdef: positions 1-3 are abc, size is 6 characters."

	| files coverage |
	self
		writeBytes: #[ 16rEF 16rBB 16rBF ] , 'abcdef' asByteArray
		to: 'bom.txt'.
	self
		classNamed: 'Bom'
		on: 'bom.txt'
		from: 1
		to: 3.
	files := self modelFiles.
	coverage := files coverageFor: files files first.
	self assert: coverage size equals: 6.
	self assert: coverage coveredSet size equals: 3.
	self assert: coverage regions first text equals: 'abc'
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testComputeAllComputesEveryFile [
	"Unreadable files are computed too (unreadable coverage), and counted by globalSummary."

	| files |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'abcd' to: 'b.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 4.
	self
		classNamed: 'Gone'
		on: 'gone.txt'
		from: 1
		to: 4.
	files := self modelFiles.
	files computeAll.
	files files do: [ :each |
		self assert: (files summaryFor: each) notNil ].
	self assert: files globalSummary fileCount equals: 3.
	self assert: files globalSummary size equals: 10.
	self assert: files globalSummary coveredSize equals: 7
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testComputeAllKeepsAlreadyComputedCoverages [

	| files first |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'abcd' to: 'b.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 4.
	files := self modelFiles.
	first := files coverageFor: (self fileNamed: 'a.txt').
	files computeAll.
	self
		assert: (files coverageFor: (self fileNamed: 'a.txt'))
		identicalTo: first
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testCoverageForIsCachedAndLazy [
	"coverageFor: answers an MMCFileCoverage, computed once: the second call answers the identical object."

	| files file first |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	files := self modelFiles.
	file := files files first.
	self assert: (files summaryFor: file) isNil.
	first := files coverageFor: file.
	self assert: first class equals: MMCFileCoverage.
	self assert: first isReadable.
	self assert: first coveredPercentage equals: 50.0.
	self assert: (files coverageFor: file) identicalTo: first.
	self assert: (files summaryFor: file) identicalTo: first
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testCoverageOfUnreadableFile [

	| files coverage |
	self
		classNamed: 'Gone'
		on: 'gone.txt'
		from: 1
		to: 3.
	files := self modelFiles.
	coverage := files coverageFor: files files first.
	self deny: coverage isReadable.
	self assert: coverage size equals: 0.
	self
		assert: (files coverageFor: files files first)
		identicalTo: coverage
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testCoverageOnlyUsesAnchorsOfItsFile [

	| files coverage |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'abcdef' to: 'b.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 6.
	files := self modelFiles.
	coverage := files coverageFor: (self fileNamed: 'a.txt').
	self assert: coverage regions size equals: 1.
	self assert: coverage coveredSet size equals: 2
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testEachFileTextIsReadAtMostOnceForSeveralEntities [
	"Computing a file reads its text once (counting anchor stub), even through computeAll then coverageFor:."

	| files |
	self writeText: 'abcdef' to: 'a.txt'.
	MMCCountingIndexedFileAnchorStub resetCompleteTextCalls.
	{
		(1 to: 2).
		(3 to: 4).
		(5 to: 6) } do: [ :interval |
			| anchor entity |
			anchor := MMCCountingIndexedFileAnchorStub new.
			anchor
				fileName: 'a.txt';
				startPos: interval first;
				endPos: interval last.
			model add: anchor.
			entity := FamixJavaClass new.
			entity name: 'C' , interval first printString.
			model add: entity.
			entity sourceAnchor: anchor ].
	files := self modelFiles.
	self
		assert: MMCCountingIndexedFileAnchorStub completeTextCalls
		equals: 0.
	files computeAll.
	files coverageFor: files files first.
	self
		assert: MMCCountingIndexedFileAnchorStub completeTextCalls <= 1
		description: 'text read at most once'.
	self
		assert: (files coverageFor: files files first) regions size
		equals: 3
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testEntityWithoutAnchorHasNoFileNorEntry [
	"An entity of the model that has no source anchor is unknown to the inventory."

	| files orphan |
	self writeText: 'abcdefghij' to: 'A.txt'.
	self
		classNamed: 'C1'
		on: 'A.txt'
		from: 1
		to: 4.
	orphan := FamixJavaClass new.
	orphan name: 'Orphan'.
	model add: orphan.
	files := self modelFiles.
	self assert: (files filesOf: orphan) isEmpty.
	self assert: (files fileOf: orphan) isNil.
	self assert: files fileCount equals: 1
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testGlobalSummaryAggregatesComputedFilesOnly [
	"globalSummary: fileCount (computed files), size, coveredSize (characters), coveredPercentage (nil when size is 0)."

	| files summary |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'abcd' to: 'b.txt'.
	self writeText: 'zzzzzz' to: 'c.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 4.
	self
		classNamed: 'C'
		on: 'c.txt'
		from: 1
		to: 6.
	files := self modelFiles.
	self assert: files globalSummary fileCount equals: 0.
	self assert: files globalSummary coveredPercentage isNil.
	files coverageFor: (self fileNamed: 'a.txt').
	files coverageFor: (self fileNamed: 'b.txt').
	summary := files globalSummary.
	self assert: summary fileCount equals: 2.
	self assert: summary size equals: 10.
	self assert: summary coveredSize equals: 7.
	self assert: summary coveredPercentage equals: 70.0
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testGlobalSummaryIsEmptyAfterInvalidateAndComputedAgain [
	"After invalidate no coverage is cached: the summary is empty; computing a file again fills it, the inventory is kept."

	| files file |
	self writeText: 'abcdefghij' to: 'A.txt'.
	self
		classNamed: 'C1'
		on: 'A.txt'
		from: 1
		to: 4.
	files := self modelFiles.
	file := files files first.
	files coverageFor: file.
	self assert: files globalSummary fileCount equals: 1.
	files invalidate.
	self assert: files globalSummary fileCount equals: 0.
	self assert: files globalSummary size equals: 0.
	self assert: files globalSummary coveredPercentage isNil.
	self assert: files fileCount equals: 1.
	self assert: (files summaryFor: file) isNil.
	files coverageFor: file.
	self assert: files globalSummary fileCount equals: 1.
	self assert: files globalSummary size equals: 10
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testInvalidateDropsCachedCoverages [

	| files file first second |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	files := self modelFiles.
	file := files files first.
	first := files coverageFor: file.
	files invalidate.
	self assert: (files summaryFor: file) isNil.
	self assert: files globalSummary fileCount equals: 0.
	second := files coverageFor: file.
	self deny: second == first.
	self assert: second coveredPercentage equals: first coveredPercentage
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testInvalidateKeepsInventory [

	| files |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	files := self modelFiles.
	files computeAll.
	files invalidate.
	self assert: files fileCount equals: 1.
	self assert: (files entitiesIn: files files first) size equals: 1
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testMultiByteFileIsMeasuredInCharacters [
	"a, e acute, euro, grinning face (outside BMP), z: 5 characters, 11 bytes. Positions 2-4 are 3 characters."

	| files coverage |
	self
		writeText: (String withAll: {
					 $a.
					 (Character value: 16rE9).
					 (Character value: 16r20AC).
					 (Character value: 16r1F600).
					 $z })
		to: 'utf8.txt'.
	self
		classNamed: 'Utf'
		on: 'utf8.txt'
		from: 2
		to: 4.
	files := self modelFiles.
	coverage := files coverageFor: files files first.
	self assert: coverage size equals: 5.
	self assert: coverage coveredSet size equals: 3.
	self assert: coverage coveredPercentage equals: 60.0
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testSummaryIsNilUntilComputedPerFile [

	| files |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'abcdef' to: 'b.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 3.
	files := self modelFiles.
	files coverageFor: (self fileNamed: 'a.txt').
	self assert: (files summaryFor: (self fileNamed: 'a.txt')) notNil.
	self assert: (files summaryFor: (self fileNamed: 'b.txt')) isNil
]

{ #category : 'tests' }
MMCModelFilesCoverageTest >> testTwoThousandFictitiousFilesInventoryIsFast [
	"Scale check: 2000 files that do not exist on disk. Measured about 170 ms for on:; the bound is generous."

	| files elapsed |
	1 to: 2000 do: [ :i |
			self
				classNamed: 'C' , i printString
				on: 'pkg' , (i \\ 50) printString , '/F' , i printString , '.java'
				from: 1
				to: 5 ].
	elapsed := [ files := self modelFiles ] timeToRun asMilliSeconds.
	self assert: files fileCount equals: 2000.
	self assert: files unreadableFiles size equals: 2000.
	self
		assert: elapsed < 3000
		description: 'on: took ' , elapsed printString , ' ms'
]

{ #category : 'helpers' }
MMCModelFilesCoverageTest >> writeBytes: aByteArray to: aFileName [

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aByteArray ].
	^ ref
]

{ #category : 'helpers' }
MMCModelFilesCoverageTest >> writeText: aString to: aFileName [
	"UTF-8 without BOM."

	^ self writeBytes: aString utf8Encoded to: aFileName
]
