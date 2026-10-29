"
Tests of MMCAnchorReader, MMCAnchorReadResult, MMCEntityRegion and MMCIgnoredAnchor.
"
Class {
	#name : 'MMCAnchorReaderTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCAnchorReaderTest >> anchorOn: aFileName from: start to: end for: anEntity [
	"Answer an indexed anchor added to the model and attached to anEntity."
	| anchor |
	anchor := self newAnchorOn: aFileName from: start to: end.
	anEntity sourceAnchor: anchor.
	^ anchor
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> classNamed: aName on: aFileName from: start to: end [
	| entity |
	entity := self newClassNamed: aName.
	self anchorOn: aFileName from: start to: end for: entity.
	^ entity
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> newAnchorOn: aFileName from: start to: end [
	"Answer an indexed anchor added to the model, not yet attached to an entity."
	| anchor |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	^ anchor
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> newClassNamed: aName [
	| entity |
	entity := FamixJavaClass new.
	entity name: aName.
	model add: entity.
	^ entity
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> newMethodNamed: aName [
	| entity |
	entity := FamixJavaMethod new.
	entity name: aName.
	model add: entity.
	^ entity
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> readFile: aFileName [
	"Read aFileName (relative to the fixture folder) with a canonical path matcher."

	^ (MMCAnchorReader
		   model: model
		   matcher: (MMCCanonicalPathMatcher forFile: folder / aFileName))
		  read
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> regionIntervals: aResult [
	"Intervals of the regions, in the order of the result."
	^ aResult regions asArray collect: [ :each | each interval ]
]

{ #category : 'running' }
MMCAnchorReaderTest >> setUp [
	super setUp.
	folder := FileLocator temp / ('mmc-v2-', UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'running' }
MMCAnchorReaderTest >> tearDown [
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testAnchorNotAddedToModelIsNotSeen [
	"entity sourceAnchor: does not add the anchor to the model, and the reader enumerates the model anchors only."
	| entity anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'Seen' on: 'a.txt' from: 1 to: 2.
	entity := self newClassNamed: 'Unseen'.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	anchor startPos: 3.
	anchor endPos: 4.
	entity sourceAnchor: anchor.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 1.
	self assert: result regions first entity name equals: 'Seen'.
	self assert: result ignoredAnchors isEmpty.
	self assert: result otherFileAnchorCount equals: 0
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testAnchorsOfOtherFilesAreNotValidatedNorIgnored [
	"Invalid positions on a file that is not matched count as other-file anchors, not as ignored ones."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'xy' to: 'b.txt'.
	self classNamed: 'A' on: 'a.txt' from: 1 to: 2.
	self classNamed: 'Bad' on: 'b.txt' from: 50 to: 60.
	result := self readFile: 'a.txt'.
	self assert: result otherFileAnchorCount equals: 1.
	self assert: result ignoredAnchors isEmpty.
	self assert: result regions size equals: 1
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testCrLfCountsAsTwoCharacters [
	"Text ab CR LF cd: a=1 b=2 CR=3 LF=4 c=5 d=6."
	| result |
	self writeText: 'ab', String crlf, 'cd' to: 'crlf.txt'.
	self classNamed: 'Tail' on: 'crlf.txt' from: 5 to: 6.
	self classNamed: 'Across' on: 'crlf.txt' from: 2 to: 5.
	result := self readFile: 'crlf.txt'.
	self assert: result text size equals: 6.
	self assert: result ignoredAnchors isEmpty.
	self assert: (result regions detect: [ :each | each entity name = 'Tail' ]) text equals: 'cd'.
	self assert: (result regions detect: [ :each | each entity name = 'Across' ]) text equals: 'b', String crlf, 'c'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testEmptyFileIsUnreadable [
	| result |
	self writeText: '' to: 'empty.txt'.
	self classNamed: 'C' on: 'empty.txt' from: 1 to: 3.
	result := self readFile: 'empty.txt'.
	self deny: result isReadable.
	self assert: result text equals: ''.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #unreadableFile
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testEmptyModelGivesEmptyResult [
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors isEmpty.
	self assert: result otherFileAnchorCount equals: 0
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testFileIsReadOnlyOnce [

	| tmp1 tmp2 tmp3 tmp4 |
	self writeText: 'abcdef' to: 'a.txt'.
	MMCCountingIndexedFileAnchorStub resetCompleteTextCalls.
	{
		(1 to: 2).
		(3 to: 4).
		(5 to: 6) } do: [ :arg1 |
			| tmp5 tmp6 |
			tmp5 := MMCCountingIndexedFileAnchorStub new.
			tmp5
				fileName: 'a.txt';
				startPos: arg1 first;
				endPos: arg1 last.
			model add: tmp5.
			tmp6 := self newClassNamed: 'C' , arg1 first printString.
			tmp6 sourceAnchor: tmp5 ].
	tmp1 := self readFile: 'a.txt'.
	self
		assert: tmp1 regions size equals: 3;
		assert: (tmp1 regions collect: [ :arg2 | arg2 text ]) asArray
		equals: #( 'ab' 'cd' 'ef' );
		assert: MMCCountingIndexedFileAnchorStub completeTextCalls <= 1
		description: 'the file text must be read at most once'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorIsNotAFileAnchor [
	"FamixJavaSourceTextAnchor holds an immediate source and no file."
	| entity anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'A' on: 'a.txt' from: 1 to: 2.
	entity := self newClassNamed: 'Immediate'.
	anchor := FamixJavaSourceTextAnchor new.
	anchor source: 'abc'.
	model add: anchor.
	entity sourceAnchor: anchor.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 1.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first anchor identicalTo: anchor.
	self assert: result ignoredAnchors first reason equals: #notFileAnchor.
	self assert: result otherFileAnchorCount equals: 0
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorIsNotIndexed [
	"Line/column anchors (FamixTFileNavigation without position setters) are out of scope.
	FamixTest1FileAnchor is the available file anchor that is not an indexed one."
	| entity anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'A' on: 'a.txt' from: 1 to: 2.
	entity := self newClassNamed: 'Lines'.
	anchor := FamixTest1FileAnchor new.
	anchor fileName: 'a.txt'.
	model add: anchor.
	entity sourceAnchor: anchor.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 1.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first anchor identicalTo: anchor.
	self assert: result ignoredAnchors first reason equals: #notIndexed
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorPrintOnShowsReason [
	| result string |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 4 to: 99.
	result := self readFile: 'a.txt'.
	string := result ignoredAnchors first printString.
	self assert: (string includesSubstring: 'outOfBounds')
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithEndBeyondTextSizeIsNotClamped [
	"V1 clamped end to the text size; V2 ignores the anchor with #outOfBounds."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 4 to: 7.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #outOfBounds
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithNegativeStart [
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: -2 to: 3.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors first reason equals: #invalidPositions
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithNilEndPosition [
	| entity anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	entity := self newClassNamed: 'C'.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	anchor startPos: 2.
	model add: anchor.
	entity sourceAnchor: anchor.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors first reason equals: #nilPositions
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithNilStartAndEndPositions [
	| entity anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	entity := self newClassNamed: 'C'.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	model add: anchor.
	entity sourceAnchor: anchor.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #nilPositions
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithNilStartPosition [
	| entity anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	entity := self newClassNamed: 'C'.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	anchor endPos: 3.
	model add: anchor.
	entity sourceAnchor: anchor.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors first reason equals: #nilPositions
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithStartAfterEnd [
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 5 to: 3.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #invalidPositions
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithStartBelowOne [
	"Positions are 1-based: start 0 is invalid (no silent clamp to 1)."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 0 to: 3.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #invalidPositions
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithStartBeyondTextSize [
	"start > size implies end > size: out of bounds."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 10 to: 12.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors first reason equals: #outOfBounds
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorWithoutElement [
	"An anchor added to the model but attached to no entity: element is nil."
	| anchor result |
	self writeText: 'abcdef' to: 'a.txt'.
	anchor := self newAnchorOn: 'a.txt' from: 1 to: 3.
	result := self readFile: 'a.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first anchor identicalTo: anchor.
	self assert: result ignoredAnchors first reason equals: #noElement
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testIgnoredAnchorsKeepValidRegions [
	"Valid and invalid anchors of the same file: one region, one ignored anchor per problem."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'Good' on: 'a.txt' from: 1 to: 3.
	self classNamed: 'Bad' on: 'a.txt' from: 4 to: 99.
	self newAnchorOn: 'a.txt' from: 1 to: 2.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 1.
	self assert: result regions first text equals: 'abc'.
	self assert: (result ignoredAnchors collect: [ :each | each reason ]) asSet equals: #(outOfBounds noElement) asSet.
	self assert: result ignoredAnchors size equals: 2
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testMissingFileIsUnreadable [
	| result |
	self classNamed: 'C' on: 'missing.txt' from: 1 to: 3.
	result := self readFile: 'missing.txt'.
	self deny: result isReadable.
	self assert: result text equals: ''.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #unreadableFile
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testMultiByteUtf8PositionBeyondCharacterCountButWithinByteCountIsIgnored [
	"The file has 5 characters but 11 bytes: end 8 is out of bounds when counting characters."
	| result |
	self writeText: self unicodeText to: 'u.txt'.
	self classNamed: 'C' on: 'u.txt' from: 4 to: 8.
	result := self readFile: 'u.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #outOfBounds
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testMultiByteUtf8PositionsCountCharactersNotBytes [
	"Text a, e acute, euro, grinning face, z: positions 4-5 (characters) are the last two characters."
	| result region anchor entity |
	self writeText: self unicodeText to: 'u.txt'.
	entity := self classNamed: 'C' on: 'u.txt' from: 4 to: 5.
	anchor := entity sourceAnchor.
	result := self readFile: 'u.txt'.
	self assert: result text size equals: 5.
	self assert: result regions size equals: 1.
	region := result regions first.
	self assert: region text equals: (String withAll: { Character value: 16r1F600. $z }).
	self assert: region size equals: 2.
	"anchor sourceText works on bytes and is wrong with multi-byte characters: V2 must not use it."
	self deny: region text = anchor sourceText
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testMultiByteUtf8WholeTextRegion [
	| result |
	self writeText: self unicodeText to: 'u.txt'.
	self classNamed: 'C' on: 'u.txt' from: 1 to: 5.
	result := self readFile: 'u.txt'.
	self assert: result ignoredAnchors isEmpty.
	self assert: result regions first text equals: self unicodeText
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testNestedEntitiesGiveOneRegionEach [
	"Class 1-20 containing method 5-12: two regions, the nesting is not flattened."
	| class method result |
	self writeText: 'abcdefghijklmnopqrstuvwxyz' to: 'a.txt'.
	class := self newClassNamed: 'C'.
	method := self newMethodNamed: 'm'.
	class addMethod: method.
	self anchorOn: 'a.txt' from: 1 to: 20 for: class.
	self anchorOn: 'a.txt' from: 5 to: 12 for: method.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 2.
	self assert: result regions first entity identicalTo: class.
	self assert: result regions first text equals: 'abcdefghijklmnopqrst'.
	self assert: result regions last entity identicalTo: method.
	self assert: result regions last text equals: 'efghijkl'.
	self assert: result regions last typeName equals: 'Method'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testNoMatchedAnchorGivesUnreadableEmptyResult [
	"Decision: the text is read through a matched anchor, so without any matched anchor the result is
	not readable (text empty, no region); anchors of other files are still counted."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'uvwxyz' to: 'b.txt'.
	self classNamed: 'B' on: 'b.txt' from: 1 to: 3.
	result := self readFile: 'a.txt'.
	self deny: result isReadable.
	self assert: result text equals: ''.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors isEmpty.
	self assert: result otherFileAnchorCount equals: 1
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testOnlyMatchedFileProducesRegionsAndOtherFileAnchorsAreCounted [
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'uvwxyz' to: 'b.txt'.
	self classNamed: 'A1' on: 'a.txt' from: 1 to: 2.
	self classNamed: 'A2' on: 'a.txt' from: 3 to: 4.
	self classNamed: 'B1' on: 'b.txt' from: 1 to: 2.
	self classNamed: 'B2' on: 'b.txt' from: 3 to: 4.
	self classNamed: 'B3' on: 'b.txt' from: 5 to: 6.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 2.
	self assert: (result regions collect: [ :each | each text ]) asArray equals: #('ab' 'cd').
	self assert: result otherFileAnchorCount equals: 3.
	self assert: result ignoredAnchors isEmpty.
	self assert: result text equals: 'abcdef'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testOtherFileAnchorCountIsZeroWhenAllAnchorsMatch [
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'A' on: 'a.txt' from: 1 to: 2.
	result := self readFile: 'a.txt'.
	self assert: result otherFileAnchorCount equals: 0
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testReadWithSuffixMatcher [

	| result |
	self writeText: 'abcdef' to: 'x/a/Foo.txt'.
	self writeText: 'uvwxyz' to: 'x/aa/Foo.txt'.
	self
		classNamed: 'A'
		on: 'x/a/Foo.txt'
		from: 1
		to: 3.
	self
		classNamed: 'B'
		on: 'x/aa/Foo.txt'
		from: 1
		to: 3.
	result := (MMCAnchorReader
		           model: model
		           matcher: (MMCSuffixPathMatcher forSuffix: 'a/Foo.txt'))
		          read.
	self assert: result regions size equals: 1.
	self assert: result regions first text equals: 'abc'.
	self assert: result otherFileAnchorCount equals: 1
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testReadWithTargetGivenAsAbsolutePath [

	| result |
	self writeText: 'abcdef' to: 'sub/a.txt'.
	self
		classNamed: 'C'
		on: 'sub/a.txt'
		from: 1
		to: 3.
	result := (MMCAnchorReader
		           model: model
		           matcher: (MMCCanonicalPathMatcher forFile:
				            (folder / 'sub' / 'a.txt') pathString)) read.
	self assert: result regions size equals: 1.
	self assert: result regions first text equals: 'abc'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionBoundsAreInclusive [
	"Positions are 1-based and endPos is inclusive: 1-1 is the first character, 6-6 the last one of abcdef."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'First' on: 'a.txt' from: 1 to: 1.
	self classNamed: 'Last' on: 'a.txt' from: 6 to: 6.
	result := self readFile: 'a.txt'.
	self assert: result ignoredAnchors isEmpty.
	self assert: (result regions collect: [ :each | each text ]) asArray equals: #('a' 'f')
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionCoveringWholeFileIsKept [
	"end = text size is in bounds (inclusive end), so this anchor is not ignored."
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 1 to: 6.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 1.
	self assert: result regions first text equals: 'abcdef'.
	self assert: result ignoredAnchors isEmpty
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionOrderDoesNotDependOnCreationOrder [
	| first second |
	self writeText: 'abcdefghijklmnopqrstuvwxyz' to: 'a.txt'.
	self classNamed: 'A' on: 'a.txt' from: 10 to: 12.
	self classNamed: 'B' on: 'a.txt' from: 1 to: 3.
	self classNamed: 'C' on: 'a.txt' from: 1 to: 9.
	first := self regionIntervals: (self readFile: 'a.txt').
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	self classNamed: 'C' on: 'a.txt' from: 1 to: 9.
	self classNamed: 'B' on: 'a.txt' from: 1 to: 3.
	self classNamed: 'A' on: 'a.txt' from: 10 to: 12.
	second := self regionIntervals: (self readFile: 'a.txt').
	self assert: first equals: second.
	self assert: first equals: { 1 to: 9. 1 to: 3. 10 to: 12 }
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionPrintOnIsReadable [
	| region string |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 2 to: 4.
	region := (self readFile: 'a.txt') regions first.
	string := region printString.
	self assert: (string includesSubstring: 'Class').
	self assert: (string includesSubstring: '2').
	self assert: (string includesSubstring: '4')
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionTypeNameForClass [
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 1 to: 3.
	self assert: (self readFile: 'a.txt') regions first typeName equals: 'Class'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionTypeNameForMethod [
	| method |
	self writeText: 'abcdef' to: 'a.txt'.
	method := self newMethodNamed: 'm'.
	self anchorOn: 'a.txt' from: 1 to: 3 for: method.
	self assert: (self readFile: 'a.txt') regions first typeName equals: 'Method'
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRegionsAreOrderedByStartThenByDecreasingSize [
	"Anchors are created in scrambled order; regions are sorted by start, then larger first."
	| result |
	self writeText: 'abcdefghijklmnopqrstuvwxyz0123456789' to: 'a.txt'.
	self classNamed: 'D' on: 'a.txt' from: 30 to: 35.
	self classNamed: 'B' on: 'a.txt' from: 1 to: 5.
	self classNamed: 'C' on: 'a.txt' from: 5 to: 12.
	self classNamed: 'A' on: 'a.txt' from: 1 to: 20.
	result := self readFile: 'a.txt'.
	self assert: (self regionIntervals: result) equals: { 1 to: 20. 1 to: 5. 5 to: 12. 30 to: 35 }.
	self assert: (result regions collect: [ :each | each entity name ]) asArray equals: #('A' 'B' 'C' 'D')
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testRelativeAndAbsoluteAnchorFileNamesBothMatch [
	| result |
	self writeText: 'abcdef' to: 'sub/a.txt'.
	self classNamed: 'Rel' on: 'sub/a.txt' from: 1 to: 2.
	self classNamed: 'Abs' on: (folder / 'sub' / 'a.txt') pathString from: 3 to: 4.
	self classNamed: 'Raw' on: './sub/../sub/a.txt' from: 5 to: 6.
	result := self readFile: 'sub/a.txt'.
	self assert: result regions size equals: 3.
	self assert: (result regions collect: [ :each | each text ]) asArray equals: #('ab' 'cd' 'ef').
	self assert: result otherFileAnchorCount equals: 0
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testResultFileReferenceIsCanonical [
	| result |
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 1 to: 3.
	result := self readFile: 'a.txt'.
	self assert: result fileReference equals: (folder / 'a.txt') asFileReference canonicalize
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testResultTextIsTheWholeFileText [
	self writeText: 'abcdef' to: 'a.txt'.
	self classNamed: 'C' on: 'a.txt' from: 1 to: 3.
	self assert: (self readFile: 'a.txt') text equals: 'abcdef'.
	self assert: (self readFile: 'a.txt') isReadable
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testSameBasenameInOtherFolderIsAnotherFile [
	| result |
	self writeText: 'abcdef' to: 'a/Foo.txt'.
	self writeText: 'uvwxyz' to: 'b/Foo.txt'.
	self classNamed: 'A' on: 'a/Foo.txt' from: 1 to: 2.
	self classNamed: 'B' on: 'b/Foo.txt' from: 1 to: 2.
	result := self readFile: 'a/Foo.txt'.
	self assert: result regions size equals: 1.
	self assert: result regions first text equals: 'ab'.
	self assert: result otherFileAnchorCount equals: 1
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testSeveralEntitiesOnSameFileGiveSeveralRegions [
	| result |
	self writeText: 'abcdefghij' to: 'a.txt'.
	self classNamed: 'A' on: 'a.txt' from: 1 to: 2.
	self classNamed: 'B' on: 'a.txt' from: 5 to: 6.
	self classNamed: 'C' on: 'a.txt' from: 9 to: 10.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 3.
	self assert: (result regions collect: [ :each | each text ]) asArray equals: #('ab' 'ef' 'ij')
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testSimpleRegionExtractsText [
	| entity result region |
	self writeText: 'abcdef' to: 'a.txt'.
	entity := self classNamed: 'C' on: 'a.txt' from: 1 to: 3.
	result := self readFile: 'a.txt'.
	self assert: result regions size equals: 1.
	region := result regions first.
	self assert: region interval equals: (1 to: 3).
	self assert: region text equals: 'abc'.
	self assert: region size equals: 3.
	self assert: region entity identicalTo: entity.
	self assert: region anchor identicalTo: entity sourceAnchor
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testUnreadableFileIgnoresEveryMatchedAnchor [
	| result |
	self classNamed: 'A' on: 'missing.txt' from: 1 to: 3.
	self classNamed: 'B' on: 'missing.txt' from: 4 to: 6.
	result := self readFile: 'missing.txt'.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 2.
	self assert: (result ignoredAnchors allSatisfy: [ :each | each reason = #unreadableFile ])
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testUnreadableFileStillCountsOtherFileAnchors [
	| result |
	self writeText: 'abcdef' to: 'b.txt'.
	self classNamed: 'A' on: 'missing.txt' from: 1 to: 3.
	self classNamed: 'B' on: 'b.txt' from: 1 to: 3.
	result := self readFile: 'missing.txt'.
	self assert: result otherFileAnchorCount equals: 1.
	self assert: result ignoredAnchors size equals: 1
]

{ #category : 'tests' }
MMCAnchorReaderTest >> testUtf8BomIsNotCountedInPositions [
	"completeText drops the BOM: positions 1-3 of BOM+abcdef are abc."
	| result |
	self writeBytes: #[16rEF 16rBB 16rBF], 'abcdef' asByteArray to: 'bom.txt'.
	self classNamed: 'C' on: 'bom.txt' from: 1 to: 3.
	result := self readFile: 'bom.txt'.
	self assert: result text equals: 'abcdef'.
	self assert: result regions first text equals: 'abc'.
	self assert: result regions first interval equals: (1 to: 3)
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> unicodeText [
	"a, e acute, euro sign, grinning face (outside the BMP), z: 5 characters, 1+2+3+4+1 = 11 bytes in UTF-8."
	^ String withAll: { $a. Character value: 16rE9. Character value: 16r20AC. Character value: 16r1F600. $z }
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> writeBytes: aByteArray to: aFileName [
	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aByteArray ].
	^ ref
]

{ #category : 'helpers' }
MMCAnchorReaderTest >> writeText: aString to: aFileName [
	"Write aString encoded in UTF-8 (no BOM) in the fixture folder."
	^ self writeBytes: aString utf8Encoded to: aFileName
]
