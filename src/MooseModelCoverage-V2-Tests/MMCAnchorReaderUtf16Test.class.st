"
Tests of the UTF-16 positions of MMCAnchorReader: the positions of the file anchors (VerveineJ, Java) are UTF-16 units, converted into character indexes of the Pharo text when it holds characters outside the BMP (astral, 2 UTF-16 units). Reference text (see referenceText): a, emoji, b, c, emoji = 5 characters, 7 UTF-16 units.
"
Class {
	#name : 'MMCAnchorReaderUtf16Test',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> assertAnchor: aPair gives: anExpected in: aText [
	"aPair is start -> end (UTF-16 units); anExpected an interval or a reason."

	| actual |
	actual := self resultFrom: aPair key to: aPair value in: aText.
	self assert: actual equals: anExpected
]

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> emoji [
	"Grinning face, U+1F600: outside the BMP, 2 UTF-16 units, 1 Pharo character."

	^ Character value: 16r1F600
]

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> entryFrom: start to: end [
	"Anchor -> entity association of an indexed file anchor start to: end."

	| anchor entity |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'a.txt'.
	anchor startPos: start.
	anchor endPos: end.
	entity := FamixJavaClass new.
	entity name: 'C'.
	^ anchor -> entity
]

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> readerWithEntries: aCollection [

	^ MMCAnchorReader new
		  setEntries: aCollection otherFileAnchorCount: 0;
		  yourself
]

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> referenceText [
	"a, emoji, b, c, emoji: 5 characters, 7 UTF-16 units (a = 1, emoji = 2-3, b = 4, c = 5, emoji = 6-7)."

	^ String withAll: {
			  $a.
			  self emoji.
			  $b.
			  $c.
			  self emoji }
]

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> resultFrom: start to: end in: aText [

	^ self
		  resultOf: (self readerWithEntries: #(  ))
		  from: start
		  to: end
		  in: aText
]

{ #category : 'helpers' }
MMCAnchorReaderUtf16Test >> resultOf: aReader from: start to: end in: aText [
	"The interval of the only region of the anchor start to: end in aText, or the reason why it is ignored."

	| ignored regions |
	ignored := OrderedCollection new.
	regions := aReader
		           regionsOf: { (self entryFrom: start to: end) }
		           in: aText
		           ignored: ignored.
	^ regions isEmpty
		  ifTrue: [ ignored first reason ]
		  ifFalse: [ regions first interval ]
]

{ #category : 'running' }
MMCAnchorReaderUtf16Test >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-utf16-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> severalEmojisText [
	"x, emoji, y, emoji, emoji, z: 6 characters, 9 UTF-16 units (x 1, emoji 2-3, y 4, emoji 5-6, emoji 7-8, z 9)."

	^ String withAll: {
			  $x.
			  self emoji.
			  $y.
			  self emoji.
			  self emoji.
			  $z }
]

{ #category : 'running' }
MMCAnchorReaderUtf16Test >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorFiveToSevenIsCAndTheLastEmoji [

	self assertAnchor: 5 -> 7 gives: (4 to: 5) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorFourToFiveIsThreeToFour [
	"Units 4-5 = b and c, characters 3-4."

	self assertAnchor: 4 -> 5 gives: (3 to: 4) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorOnTheSecondHalfOfTheLastEmojiIsTheLastCharacter [

	self assertAnchor: 7 -> 7 gives: (5 to: 5) in: self referenceText.
	self assertAnchor: 6 -> 6 gives: (5 to: 5) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorOneToEightIsOutOfBounds [
	"The text has 7 UTF-16 units (not 5 characters, not 8)."

	self assertAnchor: 1 -> 8 gives: #outOfBounds in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorOneToOneIsA [

	self assertAnchor: 1 -> 1 gives: (1 to: 1) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorOneToSevenIsTheWholeText [

	self assertAnchor: 1 -> 7 gives: (1 to: 5) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorOneToThreeIsOneToTwo [
	"Units 1-3 = a and the whole emoji."

	self assertAnchor: 1 -> 3 gives: (1 to: 2) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorSixToSevenIsTheLastEmoji [

	self assertAnchor: 6 -> 7 gives: (5 to: 5) in: self referenceText
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testAnchorSpanningSeveralEmojis [
	"Units 3-7: second half of the first emoji ... first half of the third: characters 2 to 5."

	| text |
	text := self severalEmojisText.
	self assertAnchor: 3 -> 7 gives: (2 to: 5) in: text.
	self assertAnchor: 5 -> 8 gives: (4 to: 5) in: text.
	self assertAnchor: 2 -> 8 gives: (2 to: 5) in: text.
	self assertAnchor: 4 -> 9 gives: (3 to: 6) in: text
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorThreeToFourIsTheEmojiAndB [

	self assertAnchor: 3 -> 4 gives: (2 to: 3) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorThreeToThreeInTheMiddleOfAPairIsTheEmoji [
	"Unit 3 = second half of the emoji: brought back to the emoji."

	self assertAnchor: 3 -> 3 gives: (2 to: 2) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testAnchorTwoToTwoIsTheEmoji [
	"Unit 2 = first half of the emoji."

	self assertAnchor: 2 -> 2 gives: (2 to: 2) in: self referenceText
]

{ #category : 'tests - cache' }
MMCAnchorReaderUtf16Test >> testAstralTextThenAnotherOfTheSameSizeWithEmojisElsewhere [
	"Same number of characters, emojis at other places: the table of the first text must not be reused."

	| reader first second |
	reader := self readerWithEntries: #(  ).
	first := self referenceText.
	second := String withAll: {
			          self emoji.
			          $a.
			          $b.
			          $c.
			          $d }.
	self assert: second size equals: first size.
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 3
				 in: first)
		equals: (1 to: 2).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 3
				 in: second)
		equals: (1 to: 2).
	self
		assert: (self
				 resultOf: reader
				 from: 2
				 to: 3
				 in: first)
		equals: (2 to: 2).
	self
		assert: (self
				 resultOf: reader
				 from: 2
				 to: 3
				 in: second)
		equals: (1 to: 2).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 7
				 in: second)
		equals: #outOfBounds.
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 6
				 in: second)
		equals: (1 to: 5)
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testCharacterIndexOfUtf16Units [
	"With the reference text: units 1 2 3 4 5 6 7 are in the characters 1 2 2 3 4 5 5; without astral the index is the position."

	| reader |
	reader := self readerWithEntries: #(  ).
	reader utf16Length: self referenceText.
	self
		assert:
		((1 to: 7) collect: [ :each | reader characterIndexOfUtf16: each ])
		equals: #( 1 2 2 3 4 5 5 ).
	reader utf16Length: 'abc' copy.
	self
		assert:
		((1 to: 3) collect: [ :each | reader characterIndexOfUtf16: each ])
		equals: #( 1 2 3 )
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testEndBeyondTheCharacterCountButWithinTheUtf16LengthIsKept [
	"End 6 and 7 are greater than the 5 characters but are valid UTF-16 units."

	self assertAnchor: 5 -> 6 gives: (4 to: 5) in: self referenceText.
	self assertAnchor: 6 -> 6 gives: (5 to: 5) in: self referenceText
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testEveryPositionBeyondTheUtf16LengthIsOutOfBounds [

	8 to: 12 do: [ :each |
			self
				assertAnchor: 1 -> each
				gives: #outOfBounds
				in: self referenceText.
			self
				assertAnchor: each -> each
				gives: #outOfBounds
				in: self referenceText ]
]

{ #category : 'tests - file' }
MMCAnchorReaderUtf16Test >> testFileReadKeepsUtf16AnchorsOnTheReferenceText [
	"End to end: UTF-8 file on the disk, model anchors in UTF-16 units: the regions are those of the truth table and their texts are right."

	| ref result texts |
	ref := folder / 'u.txt'.
	ref binaryWriteStreamDo: [ :s |
		s nextPutAll: self referenceText utf8Encoded ].
	#( #( 'A' 1 3 ) #( 'B' 4 5 ) #( 'C' 6 7 ) #( 'D' 3 3 ) ) do: [ :each |
			| entity anchor |
			entity := FamixJavaClass new.
			entity name: each first.
			model add: entity.
			anchor := FamixJavaIndexedFileAnchor new.
			anchor fileName: 'u.txt'.
			anchor startPos: each second.
			anchor endPos: each third.
			model add: anchor.
			entity sourceAnchor: anchor ].
	result := (MMCAnchorReader
		           model: model
		           matcher: (MMCCanonicalPathMatcher forFile: ref)) read.
	self assert: result ignoredAnchors isEmpty.
	self assert: result text size equals: 5.
	texts := Dictionary new.
	result regions do: [ :each |
		texts at: each entity name put: each interval ].
	self assert: (texts at: 'A') equals: (1 to: 2).
	self assert: (texts at: 'B') equals: (3 to: 4).
	self assert: (texts at: 'C') equals: (5 to: 5).
	self assert: (texts at: 'D') equals: (2 to: 2).
	(result regions detect: [ :each | each entity name = 'B' ]) text in: [
		:text | self assert: text equals: 'bc' ]
]

{ #category : 'tests - file' }
MMCAnchorReaderUtf16Test >> testFileReadWithAnchorBeyondTheUtf16LengthIsOutOfBounds [

	| ref entity anchor result |
	ref := folder / 'u.txt'.
	ref binaryWriteStreamDo: [ :s |
		s nextPutAll: self referenceText utf8Encoded ].
	entity := FamixJavaClass new.
	entity name: 'C'.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: 'u.txt'.
	anchor startPos: 1.
	anchor endPos: 8.
	model add: anchor.
	entity sourceAnchor: anchor.
	result := (MMCAnchorReader
		           model: model
		           matcher: (MMCCanonicalPathMatcher forFile: ref)) read.
	self assert: result regions isEmpty.
	self assert: result ignoredAnchors size equals: 1.
	self assert: result ignoredAnchors first reason equals: #outOfBounds
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testInvalidPositionsAreStillIgnoredWithAnAstralText [

	| text |
	text := self referenceText.
	self assertAnchor: 0 -> 3 gives: #invalidPositions in: text.
	self assertAnchor: 4 -> 3 gives: #invalidPositions in: text.
	self assertAnchor: nil -> 3 gives: #nilPositions in: text.
	self assertAnchor: 3 -> nil gives: #nilPositions in: text
]

{ #category : 'tests - truth table' }
MMCAnchorReaderUtf16Test >> testReferenceTextHasFiveCharactersAndSevenUtf16Units [

	| reader |
	reader := self readerWithEntries: #(  ).
	self assert: self referenceText size equals: 5.
	self assert: (reader utf16Length: self referenceText) equals: 7.
	self deny: self referenceText isByteString
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testRegionTextIsTheCharactersOfTheInterval [

	| regions text |
	text := self referenceText.
	regions := (self readerWithEntries: #(  ))
		           regionsOf: { (self entryFrom: 4 to: 5) }
		           in: text
		           ignored: OrderedCollection new.
	self assert: regions first interval equals: (3 to: 4).
	self assert: regions first text equals: 'bc'.
	self assert: regions first size equals: 2
]

{ #category : 'tests - cache' }
MMCAnchorReaderUtf16Test >> testSameTextTwiceGivesTheSameResult [

	| reader text |
	reader := self readerWithEntries: #(  ).
	text := self referenceText.
	2 timesRepeat: [
			self
				assert: (self
						 resultOf: reader
						 from: 3
						 to: 4
						 in: text)
				equals: (2 to: 3).
			self
				assert: (self
						 resultOf: reader
						 from: 6
						 to: 7
						 in: text)
				equals: (5 to: 5) ]
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testSeveralEmojisAreEachTwoUnits [

	| text |
	text := self severalEmojisText.
	self assert: text size equals: 6.
	self assertAnchor: 1 -> 1 gives: (1 to: 1) in: text.
	self assertAnchor: 4 -> 4 gives: (3 to: 3) in: text.
	self assertAnchor: 5 -> 6 gives: (4 to: 4) in: text.
	self assertAnchor: 7 -> 8 gives: (5 to: 5) in: text.
	self assertAnchor: 9 -> 9 gives: (6 to: 6) in: text.
	self assertAnchor: 1 -> 9 gives: (1 to: 6) in: text.
	self assertAnchor: 1 -> 10 gives: #outOfBounds in: text
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testSeveralEmojisRegionText [

	| regions |
	regions := (self readerWithEntries: #(  ))
		           regionsOf: { (self entryFrom: 4 to: 9) }
		           in: self severalEmojisText
		           ignored: OrderedCollection new.
	self assert: regions first text equals: (String withAll: {
				 $y.
				 self emoji.
				 self emoji.
				 $z })
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testTextWithoutAstralCharacterIsUnchanged [
	"A ByteString: positions are character indexes, as before."

	| text |
	text := 'hello' copy.
	self assert: text isByteString.
	self assertAnchor: 1 -> 5 gives: (1 to: 5) in: text.
	self assertAnchor: 2 -> 3 gives: (2 to: 3) in: text.
	self assertAnchor: 5 -> 5 gives: (5 to: 5) in: text.
	self assertAnchor: 1 -> 6 gives: #outOfBounds in: text.
	self
		assert: ((self readerWithEntries: #(  )) utf16Length: text)
		equals: 5
]

{ #category : 'tests - cache' }
MMCAnchorReaderUtf16Test >> testTwoSuccessiveTextsDoNotPolluteEachOther [
	"One reader, an astral text then a text without astral then another astral text: the conversion table is that of the text read, never that of the previous one."

	| reader astral plain other |
	reader := self readerWithEntries: #(  ).
	astral := self referenceText.
	plain := 'abcdefg' copy.
	other := String withAll: {
			         self emoji.
			         $a.
			         $b.
			         self emoji.
			         self emoji }.
	self
		assert: (self
				 resultOf: reader
				 from: 4
				 to: 5
				 in: astral)
		equals: (3 to: 4).
	self
		assert: (self
				 resultOf: reader
				 from: 4
				 to: 5
				 in: plain)
		equals: (4 to: 5).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 7
				 in: plain)
		equals: (1 to: 7).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 8
				 in: plain)
		equals: #outOfBounds.
	"Other: emoji 1-2, a 3, b 4, emoji 5-6, emoji 7-8: 5 characters, 8 units."
	self
		assert: (self
				 resultOf: reader
				 from: 3
				 to: 4
				 in: other)
		equals: (2 to: 3).
	self
		assert: (self
				 resultOf: reader
				 from: 7
				 to: 8
				 in: other)
		equals: (5 to: 5).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 8
				 in: other)
		equals: (1 to: 5).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 9
				 in: other)
		equals: #outOfBounds.
	"Back to the first text."
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 7
				 in: astral)
		equals: (1 to: 5).
	self
		assert: (self
				 resultOf: reader
				 from: 1
				 to: 8
				 in: astral)
		equals: #outOfBounds
]

{ #category : 'tests - texts' }
MMCAnchorReaderUtf16Test >> testWideTextWithoutAstralCharacterIsUnchanged [
	"a, e acute, euro sign: a WideString whose characters are all in the BMP."

	| text |
	text := String withAll: {
			        $a.
			        (Character value: 16rE9).
			        (Character value: 16r20AC) }.
	self deny: text isByteString.
	self assertAnchor: 1 -> 3 gives: (1 to: 3) in: text.
	self assertAnchor: 2 -> 3 gives: (2 to: 3) in: text.
	self assertAnchor: 1 -> 4 gives: #outOfBounds in: text.
	self
		assert: ((self readerWithEntries: #(  )) utf16Length: text)
		equals: 3
]
