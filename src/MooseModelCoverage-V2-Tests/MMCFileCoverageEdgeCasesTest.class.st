Class {
	#name : 'MMCFileCoverageEdgeCasesTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCFileCoverageEdgeCasesTest >> emojiText [
	"a, b, grinning face emoji (non BMP, one character), c, d, space, e, f: 8 characters."
	^ 'ab' , (String with: (Character value: 128512)) , 'cd ef'
]

{ #category : 'helpers' }
MMCFileCoverageEdgeCasesTest >> newCoverageFor: aText regions: aCollection [
	"Answer a readable coverage of aText with the given regions (no ignored anchor)."
	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: aText
			   regions: aCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCFileCoverageEdgeCasesTest >> newRegionFrom: start to: end [
	"Answer a Class region on start to: end."
	^ self newRegionOf: FamixJavaClass new from: start to: end
]

{ #category : 'helpers' }
MMCFileCoverageEdgeCasesTest >> newRegionOf: anEntity from: start to: end [
	"Answer a region of anEntity on start to: end (placeholder text)."
	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (start to: end)
		  text: (String new: (end - start + 1 max: 0) withAll: $x)
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testBlankSetReturnedIsACopy [
	"Text 'ab cd' has one blank at 3."
	| coverage set |
	coverage := self newCoverageFor: 'ab cd' regions: #(  ).
	set := coverage blankSet.
	set add: (1 to: 1).
	self assert: coverage blankSet intervals asArray equals: { (3 to: 3) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testCoveredSetReturnedIsACopy [
	"Adding an interval to the returned set does not change the coverage."
	| coverage set |
	coverage := self newCoverageFor: 'abcdefgh' regions: { (self newRegionFrom: 4 to: 5) }.
	set := coverage coveredSet.
	set add: (1 to: 2).
	self assert: coverage coveredSet intervals asArray equals: { (4 to: 5) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testCrLfTextHasThreeLinesWithEmptySecondLine [
	"Second line starts at 4 and its content ends at 3: empty."
	| coverage |
	coverage := self newCoverageFor: (String crlf join: { 'a'. ''. 'b' }) regions: #(  ).
	self assert: coverage lineCount equals: 3.
	self assert: (coverage lineInterval: 2) isEmpty
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testCrLfTextMapsPositionsToLines [
	"a(1) CR(2) LF(3) CR(4) LF(5) b(6): lines 1 1 1 2 2 3."
	| coverage |
	coverage := self newCoverageFor: (String crlf join: { 'a'. ''. 'b' }) regions: #(  ).
	self assert: (coverage lineOf: 1) equals: 1.
	self assert: (#( 1 2 3 4 5 6 ) collect: [ :each | coverage lineOf: each ]) equals: #( 1 1 1 2 2 3 )
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testLineBreaksOnlyTextHasEmptyLineIntervals [
	| coverage |
	coverage := self newCoverageFor: (String new: 3 withAll: Character lf) regions: #(  ).
	self assert: ((1 to: 3) allSatisfy: [ :line | (coverage lineInterval: line) isEmpty ])
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testLineBreaksOnlyTextHasNoSignificantRatio [
	"Every character is blank: no significant character, ratio is nil."
	| coverage |
	coverage := self newCoverageFor: (String new: 3 withAll: Character lf) regions: #(  ).
	self assert: coverage significantRatio isNil
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testLineBreaksOnlyTextHasNoUncoveredRegion [
	"The uncovered run is only blanks: it is dropped."
	| coverage |
	coverage := self newCoverageFor: (String new: 3 withAll: Character lf) regions: #(  ).
	self assert: coverage uncoveredRegions isEmpty
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testLineBreaksOnlyTextHasThreeLines [
	"Three line feeds: three lines, each one ended by its break."
	| coverage |
	coverage := self newCoverageFor: (String new: 3 withAll: Character lf) regions: #(  ).
	self assert: coverage lineCount equals: 3
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testNonBmpCharacterCountsAsOneCharacter [
	| coverage |
	coverage := self newCoverageFor: self emojiText regions: #(  ).
	self assert: coverage size equals: 8
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testNonBmpCharacterCoveredSplitsUncoveredRegions [
	"Region on the emoji only (position 3): uncovered runs 1-2 (ab) and 4-8 (cd ef)."
	| coverage |
	coverage := self newCoverageFor: self emojiText regions: { (self newRegionFrom: 3 to: 3) }.
	self assert: (coverage uncoveredRegions collect: [ :each | each interval ]) asArray equals: { (1 to: 2). (4 to: 8) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testNonBmpTextHasBlankOnlyAtPositionSix [
	"Positions: a1 b2 emoji3 c4 d5 space6 e7 f8."
	| coverage |
	coverage := self newCoverageFor: self emojiText regions: #(  ).
	self assert: coverage blankSet intervals asArray equals: { (6 to: 6) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testNonBmpTextHasNoLineBeyondItsEnd [
	| coverage |
	coverage := self newCoverageFor: self emojiText regions: #(  ).
	self assert: (coverage lineOf: 9) isNil
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testNonBmpTextIsOnOneLine [
	| coverage |
	coverage := self newCoverageFor: self emojiText regions: #(  ).
	self assert: (#( 1 2 3 4 5 6 7 8 ) collect: [ :each | coverage lineOf: each ]) equals: #( 1 1 1 1 1 1 1 1 )
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testNonBmpTextWithoutRegionHasOneUncoveredRegionOfWholeText [
	"The only blank (6) is inside the run, so trimming changes nothing: 1-8."
	| coverage |
	coverage := self newCoverageFor: self emojiText regions: #(  ).
	self assert: (coverage uncoveredRegions collect: [ :each | each interval ]) asArray equals: { (1 to: 8) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testPositionBeyondTextHasNoRegion [
	| coverage |
	coverage := self newCoverageFor: 'abcde' regions: { (self newRegionFrom: 3 to: 10) }.
	self assert: (coverage regionsAt: 8) isEmpty
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testPositionBeyondTextIsNotCovered [
	"Position 8 is outside the 5-character text although the region interval reaches it."
	| coverage |
	coverage := self newCoverageFor: 'abcde' regions: { (self newRegionFrom: 3 to: 10) }.
	self deny: (coverage isCovered: 8)
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testRegionOverflowingTextGivesRawRatioOfInsideCharacters [
	"3 covered characters (3, 4, 5) over 5 characters: 3/5."
	| coverage |
	coverage := self newCoverageFor: 'abcde' regions: { (self newRegionFrom: 3 to: 10) }.
	self assert: coverage rawRatio equals: 3 / 5
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testRegionOverflowingTextIsClampedInCoveredSet [
	"Text of 5 characters, region 3-10: only 3-5 are inside the text."
	| coverage |
	coverage := self newCoverageFor: 'abcde' regions: { (self newRegionFrom: 3 to: 10) }.
	self assert: coverage coveredSet intervals asArray equals: { (3 to: 5) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testRegionStartingAtZeroIsClampedToFirstCharacter [
	"Region 0-2 on a 5-character text covers 1-2."
	| coverage |
	coverage := self newCoverageFor: 'abcde' regions: { (self newRegionFrom: 0 to: 2) }.
	self assert: coverage coveredSet intervals asArray equals: { (1 to: 2) }
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testRegionsReturnedCannotAlterTheCoverage [
	"Writing into the returned regions leaves the coverage regions unchanged."
	| region coverage returned |
	region := self newRegionFrom: 1 to: 3.
	coverage := self newCoverageFor: 'abcde' regions: { region }.
	returned := coverage regions.
	[ returned at: 1 put: nil ] on: Error do: [ :error | error return ].
	self assert: coverage regions size equals: 1.
	self assert: coverage regions first identicalTo: region
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testTrailingLoneCarriageReturnDoesNotStartNewLine [
	"ab then CR: a single line, the CR belongs to it."
	| coverage |
	coverage := self newCoverageFor: ('ab' , (String with: Character cr)) regions: #(  ).
	self assert: coverage lineCount equals: 1.
	self assert: (coverage lineOf: 3) equals: 1.
	self assert: (coverage lineInterval: 2) isNil
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testTrailingLoneCarriageReturnLineIntervalExcludesBreak [
	| coverage |
	coverage := self newCoverageFor: ('ab' , (String with: Character cr)) regions: #(  ).
	self assert: (coverage lineInterval: 1) equals: (1 to: 2)
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testUnsortedRegionsGetDepthsFollowingRegionOrder [
	"Regions 6-8, 1-10, 2-3 on 10 characters. 6-8 comes first: depth 0. 1-10 is not inside an earlier region: depth 0. 2-3 is inside 1-10 (earlier): depth 1."
	| regions coverage |
	regions := { (self newRegionFrom: 6 to: 8). (self newRegionFrom: 1 to: 10). (self newRegionFrom: 2 to: 3) }.
	coverage := self newCoverageFor: (String new: 10 withAll: $x) regions: regions.
	self assert: (regions collect: [ :each | coverage depthOf: each ]) equals: #( 0 0 1 )
]

{ #category : 'tests' }
MMCFileCoverageEdgeCasesTest >> testUnsortedRegionsGiveMaxDepthOne [
	| coverage |
	coverage := self newCoverageFor: (String new: 10 withAll: $x) regions: { (self newRegionFrom: 6 to: 8). (self newRegionFrom: 1 to: 10). (self newRegionFrom: 2 to: 3) }.
	self assert: coverage maxDepth equals: 1
]
