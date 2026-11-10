Class {
	#name : 'MMCAnchorReaderHiddenTypesTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> classNamed: aName on: aFileName from: start to: end [

	| entity |
	entity := FamixJavaClass new.
	entity name: aName.
	model add: entity.
	entity sourceAnchor:
		(self newAnchorOn: aFileName from: start to: end).
	^ entity
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> methodNamed: aName on: aFileName from: start to: end [

	| entity |
	entity := FamixJavaMethod new.
	entity name: aName.
	model add: entity.
	entity sourceAnchor:
		(self newAnchorOn: aFileName from: start to: end).
	^ entity
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> newAnchorOn: aFileName from: start to: end [

	| anchor |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	^ anchor
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> readFile: aFileName hiding: aCollection [
	"Read aFileName (relative to the fixture folder) with the given hidden type names."

	| reader |
	reader := MMCAnchorReader
		          model: model
		          matcher:
		          (MMCCanonicalPathMatcher forFile: folder / aFileName).
	reader hiddenTypeNames: aCollection.
	^ reader read
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-v2-hidden-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testAllTypesHiddenStillReadsTheFileAndItsText [
	"The hidden entries still serve to find the file and to read its text."

	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	self
		methodNamed: 'm'
		on: 'a.txt'
		from: 3
		to: 4.
	result := self readFile: 'a.txt' hiding: #( 'Class' 'Method' ).
	self assert: result fileReference notNil.
	self assert: result fileReference basename equals: 'a.txt'.
	self assert: result text equals: 'abcdef'.
	self assert: result isReadable.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors isEmpty.
	self assert: result otherFileAnchorCount equals: 0
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testAstralTextStaysCorrectWithAHiddenType [
	"UTF-16 positions of the visible entries are still converted correctly when a type before them in the text is hidden."

	| result |
	self writeText: self unicodeText to: 'u.txt'.
	self
		classNamed: 'Face'
		on: 'u.txt'
		from: 4
		to: 5.
	self
		methodNamed: 'before'
		on: 'u.txt'
		from: 1
		to: 3.
	self
		methodNamed: 'after'
		on: 'u.txt'
		from: 6
		to: 6.
	result := self readFile: 'u.txt' hiding: #( 'Class' ).
	self assert: result text size equals: 5.
	self assert: result regions size equals: 2.
	self
		assert:
		(result regions detect: [ :each | each entity name = 'before' ])
			text
		equals: (self unicodeText copyFrom: 1 to: 3).
	self
		assert:
			(result regions detect: [ :each | each entity name = 'after' ])
				interval
		equals: (5 to: 5).
	self
		assert:
		(result regions detect: [ :each | each entity name = 'after' ]) text
		equals: 'z'.
	self assert: result ignoredAnchors isEmpty.
	result := self readFile: 'u.txt' hiding: #( 'Method' ).
	self assert: result regions size equals: 1.
	self
		assert: result regions first text
		equals: (String with: (Character value: 16r1F600))
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testDefaultHidesNothing [

	| reader result |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	self
		methodNamed: 'm'
		on: 'a.txt'
		from: 3
		to: 4.
	reader := MMCAnchorReader
		          model: model
		          matcher:
		          (MMCCanonicalPathMatcher forFile: folder / 'a.txt').
	self assert: reader hiddenTypeNames isEmpty.
	result := reader read.
	self assert: result regions size equals: 2.
	self assert: result ignoredAnchors isEmpty.
	self assert: result text equals: 'abcdef'
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testEmptyHiddenSetGivesTheSameResultAsTheDefault [

	| default empty |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	self
		classNamed: 'Bad'
		on: 'a.txt'
		from: 50
		to: 60.
	default := (MMCAnchorReader
		            model: model
		            matcher:
		            (MMCCanonicalPathMatcher forFile: folder / 'a.txt'))
		           read.
	empty := self readFile: 'a.txt' hiding: Set new.
	self assert: empty regions size equals: default regions size.
	self
		assert: empty ignoredAnchors size
		equals: default ignoredAnchors size.
	self assert: empty text equals: default text
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testEntryWithoutEntityIsNeverHidden [
	"An entry whose entity is nil keeps its #noElement reason, whatever the hidden types."

	| anchor reader result |
	self writeText: 'abcdef' to: 'a.txt'.
	anchor := self newAnchorOn: 'a.txt' from: 1 to: 2.
	reader := MMCAnchorReader
		          model: model
		          file: folder / 'a.txt'
		          entries: { (anchor -> nil) }
		          otherFileAnchorCount: 0.
	reader hiddenTypeNames: #( 'Class' 'Method' 'Package' ).
	self deny: (reader isHiddenEntry: anchor -> nil).
	result := reader read.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #noElement
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testHiddenFileAnchorsOfOtherFilesAreStillCounted [
	"The count of anchors of other files is not filtered."

	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'xy' to: 'b.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 2.
	result := self readFile: 'a.txt' hiding: #( 'Class' ).
	self assert: result otherFileAnchorCount equals: 1.
	self assert: result regions isEmpty.
	self assert: result text equals: 'abcdef'
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testHiddenTypeGivesNoRegion [

	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	self
		methodNamed: 'm'
		on: 'a.txt'
		from: 3
		to: 4.
	result := self readFile: 'a.txt' hiding: #( 'Class' ).
	self assert: result regions size equals: 1.
	self assert: result regions first entity name equals: 'm'.
	self assert: result regions first text equals: 'cd'.
	self assert: result ignoredAnchors isEmpty
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testHiddenTypeNamesAcceptsAnyCollectionAndAnswersASet [

	| reader |
	reader := MMCAnchorReader model: model matcher: nil.
	reader hiddenTypeNames: #( 'Class' 'Class' 'Method' ).
	self
		assert: reader hiddenTypeNames
		equals: #( 'Class' 'Method' ) asSet
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testInvalidAnchorOfAHiddenTypeIsNotReportedAsIgnored [
	"The hidden entries are skipped before the validation: no ignored anchor either."

	| visible hidden |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'Bad'
		on: 'a.txt'
		from: 50
		to: 60.
	self
		methodNamed: 'badMethod'
		on: 'a.txt'
		from: 0
		to: 2.
	visible := self readFile: 'a.txt' hiding: #(  ).
	self assert: visible ignoredAnchors size equals: 2.
	hidden := self readFile: 'a.txt' hiding: #( 'Class' ).
	self assert: hidden ignoredAnchors size equals: 1.
	self
		assert: hidden ignoredAnchors first reason
		equals: #invalidPositions.
	hidden := self readFile: 'a.txt' hiding: #( 'Class' 'Method' ).
	self assert: hidden ignoredAnchors isEmpty.
	self assert: hidden regions isEmpty
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testMutatingTheSetGivenToHiddenTypeNamesDoesNotAffectTheReader [

	| reader given |
	reader := MMCAnchorReader model: model matcher: nil.
	given := Set withAll: #( 'Class' ).
	reader hiddenTypeNames: given.
	given add: 'Method'.
	given remove: 'Class'.
	self assert: reader hiddenTypeNames equals: #( 'Class' ) asSet
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testNonFileAnchorsOfHiddenTypesAreNotIgnored [
	"A source text anchor of a hidden type is not reported; the one of a visible type still is."

	| result classEntity methodEntity classAnchor methodAnchor |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	classEntity := FamixJavaClass new
		               name: 'Immediate';
		               yourself.
	model add: classEntity.
	classAnchor := FamixJavaSourceTextAnchor new
		               source: 'abc';
		               yourself.
	model add: classAnchor.
	classEntity sourceAnchor: classAnchor.
	methodEntity := FamixJavaMethod new
		                name: 'immediate';
		                yourself.
	model add: methodEntity.
	methodAnchor := FamixJavaSourceTextAnchor new
		                source: 'def';
		                yourself.
	model add: methodAnchor.
	methodEntity sourceAnchor: methodAnchor.
	result := self readFile: 'a.txt' hiding: #(  ).
	self assert: result ignoredAnchors size equals: 2.
	result := self readFile: 'a.txt' hiding: #( 'Class' ).
	self assert: result ignoredAnchors size equals: 1.
	self
		assert: result ignoredAnchors first anchor
		identicalTo: methodAnchor.
	self
		assert: result ignoredAnchors first reason
		equals: #notFileAnchor.
	result := self readFile: 'a.txt' hiding: #( 'Class' 'Method' ).
	self assert: result ignoredAnchors isEmpty.
	self assert: result regions isEmpty.
	self assert: result text equals: 'abcdef'
]

{ #category : 'tests' }
MMCAnchorReaderHiddenTypesTest >> testUnknownHiddenTypeNameHidesNothing [

	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 2.
	result := self readFile: 'a.txt' hiding: #( 'NoSuchType' ).
	self assert: result regions size equals: 1
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> unicodeText [
	"a, e acute, euro sign, grinning face (outside the BMP), z: UTF-16 units a=1, e acute=2, euro=3, face=4-5, z=6."

	^ String withAll: {
			  $a.
			  (Character value: 16rE9).
			  (Character value: 16r20AC).
			  (Character value: 16r1F600).
			  $z }
]

{ #category : 'helpers' }
MMCAnchorReaderHiddenTypesTest >> writeText: aString to: aFileName [
	"Write aString encoded in UTF-8 (no BOM) in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
