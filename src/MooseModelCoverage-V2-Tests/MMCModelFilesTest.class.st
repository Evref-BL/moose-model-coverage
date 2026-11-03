"
Tests of MMCModelFiles (inventory of the source files of a Moose model), inventory part, TDD.
API under test (MMCModelFiles, package MooseModelCoverage-V2):
 class side  on: aModel
 inventory   files (canonical absolute FileReferences, sorted by relativeNameOf: ignoring case), fileCount,
             relativeNameOf: aFile (String relative to model rootFolder, '/' separators; absolute pathString when outside the root),
             entitiesIn: aFile (unique entities, empty collection for an unknown file), filesOf: anEntity (Array, empty if none),
             fileOf: anEntity (first of filesOf:, nil if none), ignoredAnchorCount (anchors of the model that are not file anchors),
             isReadable: aFile (file exists on disk and is not empty), unreadableFiles (listed files for which isReadable: is false).
Unreadable files stay listed in files.
"
Class {
	#name : 'MMCModelFilesTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCModelFilesTest >> classNamed: aName on: aFileName from: start to: end [
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
MMCModelFilesTest >> fileNamed: aFileName [
	"Answer the canonical FileReference expected in MMCModelFiles>>files for a file of the fixture folder."

	^ (folder / aFileName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCModelFilesTest >> modelFiles [

	^ (Smalltalk globals at: #MMCModelFiles) on: model
]

{ #category : 'running' }
MMCModelFilesTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-files-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'running' }
MMCModelFilesTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCModelFilesTest >> testAnchorsWithoutFileAreCountedAsIgnored [
	"FamixJavaSourceTextAnchor holds an immediate source, no file: not listed, counted by ignoredAnchorCount, its entity has no file."

	| entity anchor files |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	entity := FamixJavaClass new.
	entity name: 'Immediate'.
	model add: entity.
	anchor := FamixJavaSourceTextAnchor new.
	anchor source: 'abc'.
	model add: anchor.
	entity sourceAnchor: anchor.
	files := self modelFiles.
	self assert: files fileCount equals: 1.
	self assert: files ignoredAnchorCount equals: 1.
	self assert: (files filesOf: entity) isEmpty.
	self assert: (files fileOf: entity) isNil
]

{ #category : 'tests' }
MMCModelFilesTest >> testBomAndMultiByteFilesAreListedAndReadable [

	| files text |
	text := String withAll: {
			        $a.
			        (Character value: 16rE9).
			        (Character value: 16r20AC).
			        (Character value: 16r1F600).
			        $z }.
	self
		writeBytes: #[ 16rEF 16rBB 16rBF ] , 'abcdef' asByteArray
		to: 'bom.txt'.
	self writeText: text to: 'utf8.txt'.
	self
		classNamed: 'Bom'
		on: 'bom.txt'
		from: 1
		to: 3.
	self
		classNamed: 'Utf'
		on: 'utf8.txt'
		from: 2
		to: 4.
	files := self modelFiles.
	self assert: files fileCount equals: 2.
	self assert: files unreadableFiles isEmpty.
	self assert: (files isReadable: (self fileNamed: 'bom.txt')).
	self assert: (files isReadable: (self fileNamed: 'utf8.txt'))
]

{ #category : 'tests' }
MMCModelFilesTest >> testEmptyModel [

	| files |
	files := self modelFiles.
	self assert: files fileCount equals: 0.
	self assert: files files isEmpty.
	self assert: files ignoredAnchorCount equals: 0.
	self assert: files unreadableFiles isEmpty
]

{ #category : 'tests' }
MMCModelFilesTest >> testEntityInTwoFiles [
	"FamixJava has no multiple file anchor: use the FamixTest1 metamodel (FamixTMultipleFileAnchor). Its leaf anchors are not indexed, the inventory is by file name only."

	| other anchor entity files |
	self writeText: 'abc' to: 'a.txt'.
	self writeText: 'abc' to: 'b.txt'.
	other := FamixTest1Model new.
	other rootFolder: folder asFileReference.
	anchor := FamixTest1MultipleFileAnchor new.
	other add: anchor.
	anchor addFileAnchorWithPath: 'a.txt'.
	anchor addFileAnchorWithPath: 'b.txt'.
	entity := FamixTest1Class new.
	entity name: 'Split'.
	other add: entity.
	entity sourceAnchor: anchor.
	files := (Smalltalk globals at: #MMCModelFiles) on: other.
	self assert: files fileCount equals: 2.
	self assert: (files filesOf: entity) asArray equals: {
			(self fileNamed: 'a.txt').
			(self fileNamed: 'b.txt') }.
	self assert: (files fileOf: entity) equals: (self fileNamed: 'a.txt').
	self
		assert: (files entitiesIn: (self fileNamed: 'a.txt')) asArray
		equals: { entity }.
	self
		assert: (files entitiesIn: (self fileNamed: 'b.txt')) asArray
		equals: { entity }
]

{ #category : 'tests' }
MMCModelFilesTest >> testEntityWithoutAnchorHasNoFile [

	| entity files |
	self writeText: 'abc' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	entity := FamixJavaClass new.
	entity name: 'Lonely'.
	model add: entity.
	files := self modelFiles.
	self assert: (files filesOf: entity) isEmpty.
	self assert: (files fileOf: entity) isNil.
	self assert: files ignoredAnchorCount equals: 0
]

{ #category : 'tests' }
MMCModelFilesTest >> testFileOutsideRootFolderIsNamedByItsAbsolutePath [

	| outside files |
	outside := FileLocator temp / ('mmc-outside-' , UUID new asString).
	outside ensureCreateDirectory.
	[
		outside / 'o.txt' writeStreamDo: [ :s | s nextPutAll: 'abc' ].
		self
			classNamed: 'O'
			on: (outside / 'o.txt') pathString
			from: 1
			to: 2.
		files := self modelFiles.
		self assert: files fileCount equals: 1.
		self
			assert: files files first
			equals: (outside / 'o.txt') asFileReference canonicalize.
		self
			assert: (files relativeNameOf: files files first)
			equals: files files first pathString ] ensure: [
		outside ensureDeleteAll ]
]

{ #category : 'tests' }
MMCModelFilesTest >> testInventoryReadsNoFileText [
	"The inventory must not read the files: only file names are needed. Uses the counting anchor stub of MMCAnchorReaderTest."

	| anchor entity |
	self writeText: 'abcdef' to: 'a.txt'.
	MMCCountingIndexedFileAnchorStub resetCompleteTextCalls.
	entity := FamixJavaClass new.
	entity name: 'C'.
	model add: entity.
	anchor := MMCCountingIndexedFileAnchorStub new.
	anchor
		fileName: 'a.txt';
		startPos: 1;
		endPos: 2.
	model add: anchor.
	entity sourceAnchor: anchor.
	self assert: self modelFiles fileCount equals: 1.
	self
		assert: MMCCountingIndexedFileAnchorStub completeTextCalls
		equals: 0
]

{ #category : 'tests' }
MMCModelFilesTest >> testMissingFileIsListedAsUnreadable [
	"Unreadable (missing on disk or empty) files stay in files; isReadable: is false for them and unreadableFiles lists them."

	| files |
	self writeText: 'abcdef' to: 'ok.txt'.
	self writeText: '' to: 'empty.txt'.
	self
		classNamed: 'Ok'
		on: 'ok.txt'
		from: 1
		to: 2.
	self
		classNamed: 'Gone'
		on: 'gone.txt'
		from: 1
		to: 2.
	self
		classNamed: 'Empty'
		on: 'empty.txt'
		from: 1
		to: 2.
	files := self modelFiles.
	self assert: files fileCount equals: 3.
	self assert: (files isReadable: (self fileNamed: 'ok.txt')).
	self deny: (files isReadable: (self fileNamed: 'gone.txt')).
	self deny: (files isReadable: (self fileNamed: 'empty.txt')).
	self
		assert:
			(files unreadableFiles collect: [ :each |
				 files relativeNameOf: each ]) asArray
		equals: #( 'empty.txt' 'gone.txt' ).
	self
		assert: (files entitiesIn: (self fileNamed: 'gone.txt')) size
		equals: 1
]

{ #category : 'tests' }
MMCModelFilesTest >> testOneFile [

	| files entity |
	self writeText: 'abcdef' to: 'a.txt'.
	entity := self
		          classNamed: 'A'
		          on: 'a.txt'
		          from: 1
		          to: 3.
	files := self modelFiles.
	self assert: files fileCount equals: 1.
	self
		assert: files files asArray
		equals: { (self fileNamed: 'a.txt') }.
	self
		assert: (files relativeNameOf: files files first)
		equals: 'a.txt'.
	self
		assert: (files entitiesIn: files files first) asArray
		equals: { entity }.
	self assert: (files fileOf: entity) equals: (self fileNamed: 'a.txt').
	self assert: (files isReadable: files files first)
]

{ #category : 'tests' }
MMCModelFilesTest >> testRelativeAndAbsoluteNamesGiveSameCanonicalFile [
	"Relative names are resolved against MooseModel rootFolder."

	| files rel abs |
	self writeText: 'abcdef' to: 'sub/a.txt'.
	rel := self
		       classNamed: 'Rel'
		       on: 'sub/a.txt'
		       from: 1
		       to: 2.
	abs := self
		       classNamed: 'Abs'
		       on: (folder / 'sub' / 'a.txt') pathString
		       from: 3
		       to: 4.
	files := self modelFiles.
	self assert: files fileCount equals: 1.
	self assert: files files first equals: (self fileNamed: 'sub/a.txt').
	self
		assert: (files relativeNameOf: files files first)
		equals: 'sub/a.txt'.
	self assert: (files fileOf: rel) equals: (files fileOf: abs).
	self assert: (files entitiesIn: files files first) size equals: 2
]

{ #category : 'tests' }
MMCModelFilesTest >> testSameBasenameInOtherFolderIsAnotherFile [

	| files |
	self writeText: 'abc' to: 'x/a.txt'.
	self writeText: 'abc' to: 'y/a.txt'.
	self
		classNamed: 'X'
		on: 'x/a.txt'
		from: 1
		to: 2.
	self
		classNamed: 'Y'
		on: 'y/a.txt'
		from: 1
		to: 2.
	files := self modelFiles.
	self assert: files fileCount equals: 2.
	self
		assert:
		(files files collect: [ :each | files relativeNameOf: each ])
			asArray
		equals: #( 'x/a.txt' 'y/a.txt' )
]

{ #category : 'tests' }
MMCModelFilesTest >> testSameFileViaSeveralSpellings [

	| files |
	self writeText: 'abcdef' to: 'sub/a.txt'.
	self
		classNamed: 'One'
		on: 'sub/a.txt'
		from: 1
		to: 2.
	self
		classNamed: 'Two'
		on: './sub/../sub/a.txt'
		from: 3
		to: 4.
	self
		classNamed: 'Three'
		on: (folder / 'sub' / '.' / 'a.txt') pathString
		from: 5
		to: 6.
	files := self modelFiles.
	self assert: files fileCount equals: 1.
	self assert: (files entitiesIn: files files first) size equals: 3
]

{ #category : 'tests' }
MMCModelFilesTest >> testSeveralFilesAreSortedByRelativeName [

	| files |
	self writeText: 'abc' to: 'z.txt'.
	self writeText: 'abc' to: 'sub/m.txt'.
	self writeText: 'abc' to: 'a.txt'.
	self
		classNamed: 'Z'
		on: 'z.txt'
		from: 1
		to: 2.
	self
		classNamed: 'M'
		on: 'sub/m.txt'
		from: 1
		to: 2.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	files := self modelFiles.
	self assert: files fileCount equals: 3.
	self
		assert:
		(files files collect: [ :each | files relativeNameOf: each ])
			asArray
		equals: #( 'a.txt' 'sub/m.txt' 'z.txt' )
]

{ #category : 'tests' }
MMCModelFilesTest >> testSortingIgnoresCase [

	| files |
	self writeText: 'abc' to: 'b.txt'.
	self writeText: 'abc' to: 'A.txt'.
	self writeText: 'abc' to: 'C.txt'.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 2.
	self
		classNamed: 'A'
		on: 'A.txt'
		from: 1
		to: 2.
	self
		classNamed: 'C'
		on: 'C.txt'
		from: 1
		to: 2.
	files := self modelFiles.
	self
		assert:
		(files files collect: [ :each | files relativeNameOf: each ])
			asArray
		equals: #( 'A.txt' 'b.txt' 'C.txt' )
]

{ #category : 'helpers' }
MMCModelFilesTest >> writeBytes: aByteArray to: aFileName [

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aByteArray ].
	^ ref
]

{ #category : 'helpers' }
MMCModelFilesTest >> writeText: aString to: aFileName [
	"UTF-8 without BOM."

	^ self writeBytes: aString utf8Encoded to: aFileName
]
