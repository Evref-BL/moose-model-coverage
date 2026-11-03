Class {
	#name : 'MMCFileCoverageTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCFileCoverageTest >> assertRegions: actual are: expected [
	"Same regions (identity), same order."

	self assert: actual size equals: expected size.
	actual asArray
		with: expected asArray
		do: [ :a :e | self assert: a identicalTo: e ]
]

{ #category : 'helpers' }
MMCFileCoverageTest >> assertSet: aSet equals: anIntervalCollection [
	"Compare the normalized intervals of aSet with the expected ones."

	self
		assert: aSet intervals asArray
		equals: anIntervalCollection asArray
]

{ #category : 'helpers' }
MMCFileCoverageTest >> coverageFor: aText covering: anIntervalCollection [
	"Answer a coverage of aText with one Class region per interval, in the given order."

	^ self
		  newCoverageFor: aText
		  regions: (anIntervalCollection collect: [ :each |
				   self newRegionFrom: each first to: each last ])
]

{ #category : 'helpers' }
MMCFileCoverageTest >> nestedCoverage [

	^ self
		  newCoverageFor: (String new: 25 withAll: $x)
		  regions: self nestedRegions
]

{ #category : 'helpers' }
MMCFileCoverageTest >> nestedRegions [
	"Answer class 1-20, method 5-12, attribute 6-8 (in this order) as regions with distinct entities."

	^ {
		  (self newRegionOf: FamixJavaClass new from: 1 to: 20).
		  (self newRegionOf: FamixJavaMethod new from: 5 to: 12).
		  (self newRegionOf: FamixJavaAttribute new from: 6 to: 8) }
]

{ #category : 'helpers' }
MMCFileCoverageTest >> newCoverageFor: aText regions: aCollection [
	"Answer a readable coverage of aText with the given regions (no ignored anchor)."
	^ self newCoverageFor: aText regions: aCollection ignored: #() otherFileAnchorCount: 0
]

{ #category : 'helpers' }
MMCFileCoverageTest >> newCoverageFor: arg1 regions: arg2 ignored: arg3 otherFileAnchorCount: arg4 [

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: arg1
			   regions: arg2
			   ignoredAnchors: arg3
			   otherFileAnchorCount: arg4)
]

{ #category : 'helpers' }
MMCFileCoverageTest >> newRegionFrom: start to: end [
	"Answer a Class region on start to: end (placeholder text)."

	^ self newRegionOf: FamixJavaClass new from: start to: end
]

{ #category : 'helpers' }
MMCFileCoverageTest >> newRegionOf: anEntity from: start to: end [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (start to: end)
		  text: (String new: end - start + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCFileCoverageTest >> newUnreadableCoverage [

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: nil
			   text: ''
			   regions: #(  )
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testAdjacentRegionsDoNotNestAndLeaveNoHole [

	| coverage regions |
	regions := {
		           (self newRegionFrom: 1 to: 5).
		           (self newRegionFrom: 6 to: 10) }.
	coverage := self
		            newCoverageFor: (String new: 10 withAll: $x)
		            regions: regions.
	self assert: (coverage depthOf: regions first) equals: 0.
	self assert: (coverage depthOf: regions last) equals: 0.
	self assertSet: coverage coveredSet equals: { (1 to: 10) }.
	self assert: coverage uncoveredSet isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testBlankGapBetweenCoveredRegionsIsNotAnUncoveredRegion [
	"'abc   def' with abc and def covered: the 3 blanks in between are not a region."

	self assert: (self coverageFor: 'abc   def' covering: {
				 (1 to: 3).
				 (7 to: 9) }) uncoveredRegions isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testBlankOnlyTextHasNoUncoveredRegion [

	self assert: (self
			 coverageFor: '  ' , String lf , (String with: Character tab) , ' '
			 covering: #(  )) uncoveredRegions isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testBlankSetContainsSpacesTabsAndLineBreaks [
	"a1 b2 sp3 sp4 c5 tab6 d7 CR8 LF9 e10"

	| coverage |
	coverage := self
		            newCoverageFor:
			            'ab  c' , (String with: Character tab) , 'd'
			            , (String with: Character cr with: Character lf) , 'e'
		            regions: #(  ).
	self assertSet: coverage blankSet equals: {
			(3 to: 4).
			(6 to: 6).
			(8 to: 9) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testBlankSetIsEmptyWithoutBlank [

	self assert:
		(self newCoverageFor: 'abc' regions: #(  )) blankSet isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testBlankSetOfBlankOnlyText [
	"sp sp LF sp"

	self
		assertSet:
		(self newCoverageFor: '  ' , String lf , ' ' regions: #(  ))
			blankSet
		equals: { (1 to: 4) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredAndUncoveredSetsPartitionTheText [

	| coverage whole |
	coverage := self coverageFor: 'abcdefghij' covering: {
			            (3 to: 5).
			            (8 to: 10) }.
	whole := MMCIntervalSet withAll: { (1 to: 10) }.
	self
		assert: (coverage coveredSet union: coverage uncoveredSet)
		equals: whole.
	self assert:
		(coverage coveredSet intersection: coverage uncoveredSet) isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredAndUncoveredSignificantSetsPartitionTheSignificantSet [

	| coverage |
	coverage := self
		            newCoverageFor:
			            'ab  c' , (String with: Character tab) , 'd'
			            , (String with: Character cr with: Character lf) , 'e'
		            regions: { (self newRegionFrom: 2 to: 6) }.
	self
		assert: (coverage coveredSignificantSet union:
				 coverage uncoveredSignificantSet)
		equals: coverage significantSet.
	self assert: (coverage coveredSignificantSet intersection:
			 coverage uncoveredSignificantSet) isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredBlanksDoNotCountInSignificantRatio [
	"Only the 2 blanks of 'ab  cd' are covered."

	| coverage |
	coverage := self coverageFor: 'ab  cd' covering: { (3 to: 4) }.
	self assert: (coverage significantRatio closeTo: 0).
	self assert: (coverage rawRatio closeTo: 1 / 3)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredPercentageIsTheRawRatioTimesOneHundredAsFloat [

	| percentage |
	percentage := (self coverageFor: 'abcd' covering: { (1 to: 1) })
		              coveredPercentage.
	self assert: (percentage isKindOf: Float).
	self assert: (percentage closeTo: 25.0)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredSetIsEmptyWithoutRegion [

	self assert:
		(self coverageFor: 'abc' covering: #(  )) coveredSet isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredSetIsTheUnionOfTheRegionIntervals [

	| coverage |
	coverage := self coverageFor: 'abcdefghij' covering: {
			            (1 to: 3).
			            (2 to: 5).
			            (8 to: 9) }.
	self assertSet: coverage coveredSet equals: {
			(1 to: 5).
			(8 to: 9) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredSetMergesAdjacentRegions [
	"Adjacent regions leave no hole."

	| coverage |
	coverage := self coverageFor: 'abcdefghij' covering: {
			            (1 to: 3).
			            (4 to: 10) }.
	self assertSet: coverage coveredSet equals: { (1 to: 10) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredSetOfNestedRegionsIsTheOuterInterval [

	self assertSet: self nestedCoverage coveredSet equals: { (1 to: 20) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testCoveredSignificantSetIsCoveredSetWithoutBlanks [
	"covered 2-6 over 'ab  c<tab>d<CR><LF>e': significant covered are b (2) and c (5)"

	| coverage |
	coverage := self
		            newCoverageFor:
			            'ab  c' , (String with: Character tab) , 'd'
			            , (String with: Character cr with: Character lf) , 'e'
		            regions: { (self newRegionFrom: 2 to: 6) }.
	self assertSet: coverage coveredSignificantSet equals: {
			(2 to: 2).
			(5 to: 5) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testDeepestRegionAtIsNilOutsideCoverage [

	self assert: (self nestedCoverage deepestRegionAt: 22) isNil
]

{ #category : 'tests' }
MMCFileCoverageTest >> testDeepestRegionAtIsTheInnermostRegion [

	| coverage regions |
	regions := self nestedRegions.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assert: (coverage deepestRegionAt: 7) identicalTo: regions third.
	self
		assert: (coverage deepestRegionAt: 10)
		identicalTo: regions second.
	self assert: (coverage deepestRegionAt: 2) identicalTo: regions first
]

{ #category : 'tests' }
MMCFileCoverageTest >> testDepthOfNestedRegions [
	"class 1-20 > method 5-12 > attribute 6-8"

	| coverage regions |
	regions := self nestedRegions.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assert: (coverage depthOf: regions first) equals: 0.
	self assert: (coverage depthOf: regions second) equals: 1.
	self assert: (coverage depthOf: regions third) equals: 2
]

{ #category : 'tests' }
MMCFileCoverageTest >> testDepthOfSiblingsInsideAParentIsOne [
	"class 1-20 containing methods 2-5 and 8-12: the siblings do not contain each other."

	| coverage regions |
	regions := {
		           (self newRegionFrom: 1 to: 20).
		           (self newRegionFrom: 2 to: 5).
		           (self newRegionFrom: 8 to: 12) }.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assert: (coverage depthOf: regions first) equals: 0.
	self assert: (coverage depthOf: regions second) equals: 1.
	self assert: (coverage depthOf: regions third) equals: 1
]

{ #category : 'tests' }
MMCFileCoverageTest >> testEmptyTextIsNotReadableAndHasNilRatios [
	"A read result with an empty text is not readable (see MMCAnchorReadResult>>isReadable)."

	| coverage |
	coverage := self newCoverageFor: '' regions: #(  ).
	self deny: coverage isReadable.
	self assert: coverage size equals: 0.
	self assert: coverage rawRatio isNil.
	self assert: coverage significantRatio isNil.
	self assert: coverage coveredSet isEmpty.
	self assert: coverage uncoveredRegions isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testEntitiesAtAreTheEntitiesOfRegionsAt [

	| coverage regions |
	regions := self nestedRegions.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self
		assert: (coverage entitiesAt: 7) asArray
		equals: (regions collect: [ :each | each entity ]).
	self assert: (coverage entitiesAt: 10) size equals: 2.
	self
		assert: (coverage entitiesAt: 10) first
		identicalTo: regions first entity.
	self assert: (coverage entitiesAt: 23) isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testFullyCoveredTextHasNoUncoveredRegion [

	self assert:
		(self coverageFor: 'ab cd' covering: { (1 to: 5) }) uncoveredRegions
			isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testIgnoredAnchorsAndOtherFileAnchorCountComeFromReadResult [

	| coverage |
	coverage := self
		            newCoverageFor: 'abc'
		            regions: #(  )
		            ignored: #( #first #second )
		            otherFileAnchorCount: 3.
	self
		assert: coverage ignoredAnchors asArray
		equals: #( #first #second ).
	self assert: coverage otherFileAnchorCount equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testIsCoveredTellsWhetherARegionContainsThePosition [

	| coverage |
	coverage := self coverageFor: 'abcdefghij' covering: {
			            (3 to: 5).
			            (8 to: 8) }.
	self assert: (coverage isCovered: 3).
	self assert: (coverage isCovered: 5).
	self assert: (coverage isCovered: 8).
	self deny: (coverage isCovered: 2).
	self deny: (coverage isCovered: 6).
	self deny: (coverage isCovered: 9).
	self deny: (coverage isCovered: 10)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineCountCountsCrLfOnce [

	self
		assert: (self
				 newCoverageFor: 'a' , String crlf , 'b' , String crlf , 'c'
				 regions: #(  )) lineCount
		equals: 3.
	self
		assert: (self
				 newCoverageFor: 'a' , String cr , 'b' , String lf , 'c'
				 regions: #(  )) lineCount
		equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineCountOfEmptyTextIsZero [

	self
		assert: (self newCoverageFor: '' regions: #(  )) lineCount
		equals: 0
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineCountOfTextWithoutTrailingLineBreak [

	self
		assert:
		(self newCoverageFor: 'a' , String lf , 'b' regions: #(  ))
			lineCount
		equals: 2.
	self
		assert: (self newCoverageFor: 'abc' regions: #(  )) lineCount
		equals: 1
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineIntervalExcludesBothCharactersOfCrLf [
	"a1 b2 CR3 LF4 c5 d6 CR7 LF8 e9 f10"

	| coverage |
	coverage := self
		            newCoverageFor:
		            'ab' , String crlf , 'cd' , String crlf , 'ef'
		            regions: #(  ).
	self assert: (coverage lineInterval: 1) equals: (1 to: 2).
	self assert: (coverage lineInterval: 2) equals: (5 to: 6).
	self assert: (coverage lineInterval: 3) equals: (9 to: 10)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineIntervalExcludesLineBreaks [
	"a1 b2 LF3 c4 d5 LF6 e7 f8"

	| coverage |
	coverage := self
		            newCoverageFor:
		            'ab' , String lf , 'cd' , String lf , 'ef'
		            regions: #(  ).
	self assert: (coverage lineInterval: 1) equals: (1 to: 2).
	self assert: (coverage lineInterval: 2) equals: (4 to: 5).
	self assert: (coverage lineInterval: 3) equals: (7 to: 8)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineIntervalOfEmptyLineIsEmpty [
	"a1 LF2 LF3 b4: line 2 has no character."

	| coverage |
	coverage := self
		            newCoverageFor: 'a' , String lf , String lf , 'b'
		            regions: #(  ).
	self assert: (coverage lineInterval: 2) isEmpty.
	self assert: (coverage textOfLine: 2) equals: ''.
	self assert: (coverage lineInterval: 3) equals: (4 to: 4)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineIntervalOfLastLineWithTrailingLineBreak [
	"a1 LF2: the only line is 1-1."

	self
		assert:
		((self newCoverageFor: 'a' , String lf regions: #(  ))
			 lineInterval: 1)
		equals: (1 to: 1)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineIntervalOutOfRangeIsNil [
	"Decision: nil for line 0 and for lines after lineCount."

	| coverage |
	coverage := self
		            newCoverageFor: 'ab' , String lf , 'cd'
		            regions: #(  ).
	self assert: (coverage lineInterval: 0) isNil.
	self assert: (coverage lineInterval: 3) isNil.
	self assert: (coverage textOfLine: 0) isNil.
	self assert: (coverage textOfLine: 3) isNil
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineOfCountsEmptyLines [
	"a1 LF2 LF3 b4: the second LF is an empty line 2."

	| coverage |
	coverage := self
		            newCoverageFor: 'a' , String lf , String lf , 'b'
		            regions: #(  ).
	self assert: (coverage lineOf: 3) equals: 2.
	self assert: (coverage lineOf: 4) equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineOfOutsideTheTextIsNil [
	"Decision: nil (no error) for a position below 1 or above the size."

	| coverage |
	coverage := self
		            newCoverageFor: 'ab' , String lf , 'cd'
		            regions: #(  ).
	self assert: (coverage lineOf: 0) isNil.
	self assert: (coverage lineOf: -3) isNil.
	self assert: (coverage lineOf: 6) isNil
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineOfWithCrLfCountsOneLineBreak [
	"a1 b2 CR3 LF4 c5 d6 CR7 LF8 e9 f10: CR and LF of a CRLF both end the line."

	| coverage |
	coverage := self
		            newCoverageFor:
		            'ab' , String crlf , 'cd' , String crlf , 'ef'
		            regions: #(  ).
	self assert: (coverage lineOf: 2) equals: 1.
	self assert: (coverage lineOf: 3) equals: 1.
	self assert: (coverage lineOf: 4) equals: 1.
	self assert: (coverage lineOf: 5) equals: 2.
	self assert: (coverage lineOf: 7) equals: 2.
	self assert: (coverage lineOf: 8) equals: 2.
	self assert: (coverage lineOf: 9) equals: 3.
	self assert: (coverage lineOf: 10) equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineOfWithCrOnlyLineBreaks [
	"a1 b2 CR3 c4 d5 CR6 e7 f8"

	| coverage |
	coverage := self
		            newCoverageFor:
		            'ab' , String cr , 'cd' , String cr , 'ef'
		            regions: #(  ).
	self assert: (coverage lineOf: 3) equals: 1.
	self assert: (coverage lineOf: 4) equals: 2.
	self assert: (coverage lineOf: 6) equals: 2.
	self assert: (coverage lineOf: 7) equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineOfWithLfLineBreaks [
	"a1 b2 LF3 c4 d5 LF6 e7 f8: a line break belongs to the line it ends."

	| coverage |
	coverage := self
		            newCoverageFor:
		            'ab' , String lf , 'cd' , String lf , 'ef'
		            regions: #(  ).
	self assert: (coverage lineOf: 1) equals: 1.
	self assert: (coverage lineOf: 2) equals: 1.
	self assert: (coverage lineOf: 3) equals: 1.
	self assert: (coverage lineOf: 4) equals: 2.
	self assert: (coverage lineOf: 6) equals: 2.
	self assert: (coverage lineOf: 7) equals: 3.
	self assert: (coverage lineOf: 8) equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testLineOfWithMixedLineBreaks [
	"a1 LF2 b3 CR4 LF5 c6 CR7 d8: four lines (a / b with CRLF / c with CR / d)."

	| coverage |
	coverage := self
		            newCoverageFor:
		            'a' , String lf , 'b' , String crlf , 'c' , String cr
		            , 'd'
		            regions: #(  ).
	self assert: (coverage lineOf: 1) equals: 1.
	self assert: (coverage lineOf: 2) equals: 1.
	self assert: (coverage lineOf: 3) equals: 2.
	self assert: (coverage lineOf: 4) equals: 2.
	self assert: (coverage lineOf: 5) equals: 2.
	self assert: (coverage lineOf: 6) equals: 3.
	self assert: (coverage lineOf: 7) equals: 3.
	self assert: (coverage lineOf: 8) equals: 4
]

{ #category : 'tests' }
MMCFileCoverageTest >> testMaxDepthOfNestedRegionsIsTheDeepestDepth [

	self assert: self nestedCoverage maxDepth equals: 2
]

{ #category : 'tests' }
MMCFileCoverageTest >> testMaxDepthOfSiblingsIsZero [

	self
		assert: (self coverageFor: 'abcdef' covering: {
					 (1 to: 3).
					 (4 to: 6) }) maxDepth
		equals: 0
]

{ #category : 'tests' }
MMCFileCoverageTest >> testMaxDepthOfSingleRegionIsZero [

	self
		assert:
		(self coverageFor: 'abcdef' covering: { (1 to: 3) }) maxDepth
		equals: 0
]

{ #category : 'tests' }
MMCFileCoverageTest >> testMaxDepthWithoutRegionIsZero [
	"Decision: 0 (not -1) when there is no region, like a single flat layer."

	self
		assert: (self coverageFor: 'abcdef' covering: #(  )) maxDepth
		equals: 0
]

{ #category : 'tests' }
MMCFileCoverageTest >> testNestedCoverageUncoveredRegionIsTheTail [
	"Class 1-20 covers everything below it: only 21-25 stays uncovered."

	self
		assert: (self uncoveredIntervalsOf: self nestedCoverage)
		equals: { (21 to: 25) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testPartiallyOverlappingRegionsDoNotNest [
	"1-8 and 5-12 overlap without containment."

	| coverage regions |
	regions := {
		           (self newRegionFrom: 1 to: 8).
		           (self newRegionFrom: 5 to: 12) }.
	coverage := self
		            newCoverageFor: (String new: 12 withAll: $x)
		            regions: regions.
	self assert: (coverage depthOf: regions first) equals: 0.
	self assert: (coverage depthOf: regions last) equals: 0
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRatiosCountCharactersNotBytes [
	"5 characters (a, e acute, euro, emoji, z); covering characters 2 to 4 gives 3/5 whatever their UTF-8 size."

	| coverage |
	coverage := self
		            coverageFor: self unicodeText
		            covering: { (2 to: 4) }.
	self assert: (coverage rawRatio closeTo: 0.6).
	self assert: (coverage significantRatio closeTo: 0.6)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRatiosCountCharactersNotBytesWithABlank [
	"'a', e acute, space, euro, emoji, 'z': 6 characters, 1 blank at 3; covered 1-3: raw 3/6, significant 2/5."

	| text coverage |
	text := 'a' , (String with: (Character value: 233)) , ' '
	        ,
	        (String
		         with: (Character value: 8364)
		         with: (Character value: 128512)) , 'z'.
	coverage := self coverageFor: text covering: { (1 to: 3) }.
	self assert: coverage size equals: 6.
	self assert: (coverage rawRatio closeTo: 0.5).
	self assert: (coverage significantRatio closeTo: 0.4)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRatiosWithCrLfAndBlanks [
	"a1 b2 CR3 LF4 c5 d6, covered 1-2: raw 2/6 = 1/3, significant 2/4."

	| coverage |
	coverage := self
		            coverageFor: 'ab' , String crlf , 'cd'
		            covering: { (1 to: 2) }.
	self assert: (coverage rawRatio closeTo: 1 / 3).
	self assert: (coverage significantRatio closeTo: 0.5)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRawRatioCountsOverlappingRegionsOnce [
	"1-6 and 4-8 cover 8 of 10 characters, not 9."

	self assert: ((self coverageFor: 'abcdefghij' covering: {
				  (1 to: 6).
				  (4 to: 8) }) rawRatio closeTo: 0.8)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRawRatioIsCoveredCharactersOverSize [

	self assert:
		((self coverageFor: 'abcdefghij' covering: { (1 to: 5) }) rawRatio
			 closeTo: 0.5)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRawRatioIsOneWhenFullyCovered [

	self assert:
		((self coverageFor: 'abcdefghij' covering: { (1 to: 10) }) rawRatio
			 closeTo: 1)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRawRatioIsZeroWithoutRegion [

	self assert:
		((self coverageFor: 'abcdefghij' covering: #(  )) rawRatio closeTo:
			 0)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRawRatioWithNestedRegionsCountsTheOuterIntervalOnly [
	"class 1-20 over 25 characters: nested regions add nothing"

	self assert: (self nestedCoverage rawRatio closeTo: 0.8)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsAreThoseOfTheReadResultInSameOrder [

	| regions coverage |
	regions := self nestedRegions.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assertRegions: coverage regions are: regions
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsAtAnswersOutermostToInnermost [

	| coverage regions |
	regions := self nestedRegions.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assertRegions: (coverage regionsAt: 7) are: regions.
	self assertRegions: (coverage regionsAt: 10) are: {
			regions first.
			regions second }.
	self assertRegions: (coverage regionsAt: 3) are: { regions first }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsAtIncludesBoundaries [

	| coverage regions |
	regions := self nestedRegions.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assertRegions: (coverage regionsAt: 1) are: { regions first }.
	self assertRegions: (coverage regionsAt: 5) are: {
			regions first.
			regions second }.
	self assertRegions: (coverage regionsAt: 6) are: regions.
	self assertRegions: (coverage regionsAt: 8) are: regions.
	self assertRegions: (coverage regionsAt: 9) are: {
			regions first.
			regions second }.
	self assertRegions: (coverage regionsAt: 12) are: {
			regions first.
			regions second }.
	self assertRegions: (coverage regionsAt: 20) are: { regions first }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsAtIsEmptyOutsideCoverage [

	| coverage |
	coverage := self nestedCoverage.
	self assert: (coverage regionsAt: 21) isEmpty.
	self assert: (coverage regionsAt: 25) isEmpty.
	self assert: (coverage regionsAt: 0) isEmpty.
	self assert: (coverage regionsAt: 26) isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsAtWithPartialOverlapAnswersBothInRegionsOrder [

	| coverage regions |
	regions := {
		           (self newRegionFrom: 1 to: 8).
		           (self newRegionFrom: 5 to: 12) }.
	coverage := self
		            newCoverageFor: (String new: 12 withAll: $x)
		            regions: regions.
	self assertRegions: (coverage regionsAt: 6) are: regions.
	self assertRegions: (coverage regionsAt: 3) are: { regions first }.
	self assertRegions: (coverage regionsAt: 10) are: { regions last }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsOfTypeKeepsRegionsOrder [

	| regions coverage |
	regions := {
		           (self newRegionOf: FamixJavaClass new from: 1 to: 20).
		           (self newRegionOf: FamixJavaMethod new from: 2 to: 5).
		           (self newRegionOf: FamixJavaMethod new from: 8 to: 12) }.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self assertRegions: (coverage regionsOfType: 'Method') are: {
			regions second.
			regions third }.
	self
		assertRegions: (coverage regionsOfType: 'Class')
		are: { regions first }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsOfUnknownTypeIsEmpty [

	self assert: (self nestedCoverage regionsOfType: 'Interface') isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testRegionsWithIdenticalIntervalsEarlierOneIsOuter [

	| coverage regions |
	regions := {
		           (self newRegionFrom: 5 to: 10).
		           (self newRegionFrom: 5 to: 10) }.
	coverage := self
		            newCoverageFor: (String new: 12 withAll: $x)
		            regions: regions.
	self assert: (coverage depthOf: regions first) equals: 0.
	self assert: (coverage depthOf: regions last) equals: 1
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSignificantAndBlankSetsPartitionTheText [

	| coverage whole |
	coverage := self
		            newCoverageFor:
			            'ab  c' , (String with: Character tab) , 'd'
			            , (String with: Character cr with: Character lf) , 'e'
		            regions: #(  ).
	whole := MMCIntervalSet withAll: { (1 to: 10) }.
	self assert:
		(coverage significantSet intersection: coverage blankSet) isEmpty.
	self
		assert: (coverage significantSet union: coverage blankSet)
		equals: whole
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSignificantPercentageIsTheSignificantRatioTimesOneHundredAsFloat [

	| percentage |
	percentage := (self coverageFor: 'ab  cd' covering: { (1 to: 4) })
		              significantPercentage.
	self assert: (percentage isKindOf: Float).
	self assert: (percentage closeTo: 50.0)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSignificantRatioIgnoresBlanks [
	"'ab  cd': covered 1-4 is a b and 2 blanks: 2 significant covered over 4 significant; raw ratio is 4/6."

	| coverage |
	coverage := self coverageFor: 'ab  cd' covering: { (1 to: 4) }.
	self assert: (coverage significantRatio closeTo: 0.5).
	self assert: (coverage rawRatio closeTo: 4 / 6)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSignificantRatioIsNilWhenTextIsOnlyBlanks [
	"The significant set is empty: no denominator. The raw ratio is still defined."

	| coverage |
	coverage := self
		            coverageFor: '  ' , String lf , ' '
		            covering: { (1 to: 4) }.
	self assert: coverage significantRatio isNil.
	self assert: coverage significantPercentage isNil.
	self assert: (coverage rawRatio closeTo: 1)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSignificantRatioIsZeroWithoutRegionWhenTextHasSignificantCharacters [

	self assert:
		((self coverageFor: 'ab cd' covering: #(  )) significantRatio
			 closeTo: 0)
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSignificantSetExcludesBlanks [
	"blanks 3-4, 6, 8-9 of a 10 characters text"

	| coverage |
	coverage := self
		            newCoverageFor:
			            'ab  c' , (String with: Character tab) , 'd'
			            , (String with: Character cr with: Character lf) , 'e'
		            regions: #(  ).
	self assertSet: coverage significantSet equals: {
			(1 to: 2).
			(5 to: 5).
			(7 to: 7).
			(10 to: 10) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testSizeIsTheNumberOfCharacters [

	self
		assert: (self newCoverageFor: 'abcdef' regions: #(  )) size
		equals: 6.
	self
		assert: (self newCoverageFor: self unicodeText regions: #(  )) size
		equals: 5
]

{ #category : 'tests' }
MMCFileCoverageTest >> testTextAndFileReferenceComeFromReadResult [

	| coverage |
	coverage := self newCoverageFor: 'abc' regions: #(  ).
	self assert: coverage text equals: 'abc'.
	self assert: coverage fileReference equals: 'a.txt' asFileReference.
	self assert: coverage isReadable
]

{ #category : 'tests' }
MMCFileCoverageTest >> testTextOfLineIsTheLineWithoutLineBreaks [

	| coverage |
	coverage := self
		            newCoverageFor:
		            'ab' , String crlf , 'cd' , String lf , 'ef' , String cr
		            , 'gh'
		            regions: #(  ).
	self assert: (coverage textOfLine: 1) equals: 'ab'.
	self assert: (coverage textOfLine: 2) equals: 'cd'.
	self assert: (coverage textOfLine: 3) equals: 'ef'.
	self assert: (coverage textOfLine: 4) equals: 'gh'
]

{ #category : 'tests' }
MMCFileCoverageTest >> testTrailingLineBreakDoesNotCreateAnEmptyLine [
	"Decision: 'a<LF>' has one line, 'a<LF><LF>' has two (the second one is empty)."

	self
		assert:
		(self newCoverageFor: 'a' , String lf regions: #(  )) lineCount
		equals: 1.
	self
		assert:
		(self newCoverageFor: 'a' , String cr regions: #(  )) lineCount
		equals: 1.
	self
		assert:
		(self newCoverageFor: 'a' , String crlf regions: #(  )) lineCount
		equals: 1.
	self
		assert:
			(self newCoverageFor: 'a' , String lf , String lf regions: #(  ))
				lineCount
		equals: 2.
	self
		assert: (self
				 newCoverageFor: 'a' , String crlf , 'b' , String crlf
				 regions: #(  )) lineCount
		equals: 2.
	self
		assert: (self newCoverageFor: String lf regions: #(  )) lineCount
		equals: 1
]

{ #category : 'tests' }
MMCFileCoverageTest >> testTypeNamesAreEmptyWithoutRegion [

	self assert:
		(self coverageFor: 'abc' covering: #(  )) typeNames isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testTypeNamesAreSortedWithoutDuplicates [

	| regions coverage |
	regions := {
		           (self newRegionOf: FamixJavaClass new from: 1 to: 20).
		           (self newRegionOf: FamixJavaMethod new from: 2 to: 5).
		           (self newRegionOf: FamixJavaMethod new from: 8 to: 12).
		           (self newRegionOf: FamixJavaAttribute new from: 14 to: 16) }.
	coverage := self
		            newCoverageFor: (String new: 25 withAll: $x)
		            regions: regions.
	self
		assert: coverage typeNames asArray
		equals: #( 'Attribute' 'Class' 'Method' )
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionAfterCrLf [
	"a1 b2 CR3 LF4 c5 d6 with 'ab' covered: uncovered 3-6 trimmed 5-6."

	| coverage |
	coverage := self
		            coverageFor: 'ab' , String crlf , 'cd'
		            covering: { (1 to: 2) }.
	self
		assert: (self uncoveredIntervalsOf: coverage)
		equals: { (5 to: 6) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionBetweenTwoCoveredOnes [
	"'aaa bbb ccc' with aaa and ccc covered: uncovered 4-8, trimmed 5-7."

	self
		assert: (self uncoveredIntervalsOf:
				 (self coverageFor: 'aaa bbb ccc' covering: {
						  (1 to: 3).
						  (9 to: 11) }))
		equals: { (5 to: 7) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionIsTrimmedOfLeadingAndTrailingBlanks [
	"'foo  bar<LF>' with 'foo' covered: uncovered set 4-9, trimmed 6-8."

	| coverage regions |
	coverage := self
		            coverageFor: 'foo  bar' , String lf
		            covering: { (1 to: 3) }.
	regions := coverage uncoveredRegions.
	self assert: regions size equals: 1.
	self assert: regions first interval equals: (6 to: 8).
	self assert: regions first text equals: 'bar'
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionKeepsInternalBlanks [

	| coverage regions |
	coverage := self coverageFor: 'ab cd' covering: #(  ).
	regions := coverage uncoveredRegions.
	self assert: regions size equals: 1.
	self assert: regions first interval equals: (1 to: 5).
	self assert: regions first text equals: 'ab cd'
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionWithMultiByteCharacters [
	"'a', e acute, space, euro, emoji, 'z' with 1-2 covered: trimmed uncovered 4-6."

	| text coverage regions |
	text := 'a' , (String with: (Character value: 233)) , ' '
	        ,
	        (String
		         with: (Character value: 8364)
		         with: (Character value: 128512)) , 'z'.
	coverage := self coverageFor: text covering: { (1 to: 2) }.
	regions := coverage uncoveredRegions.
	self assert: regions size equals: 1.
	self assert: regions first interval equals: (4 to: 6).
	self assert: regions first text size equals: 3
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionsAreInAscendingOrder [
	"'aa bb cc dd' with bb and dd covered: aa (1-2) then cc (7-8)."

	| coverage regions |
	coverage := self coverageFor: 'aa bb cc dd' covering: {
			            (4 to: 5).
			            (10 to: 11) }.
	regions := coverage uncoveredRegions.
	self assert: (self uncoveredIntervalsOf: coverage) equals: {
			(1 to: 2).
			(7 to: 8) }.
	self
		assert: (regions collect: [ :each | each text ]) asArray
		equals: #( 'aa' 'cc' )
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredRegionsAtStartAndEndOfFile [
	"'aa bb cc dd ee' with 'cc' (7-8) covered: uncovered 1-6 and 9-14, trimmed 1-5 and 10-14."

	| coverage |
	coverage := self
		            coverageFor: 'aa bb cc dd ee'
		            covering: { (7 to: 8) }.
	self assert: (self uncoveredIntervalsOf: coverage) equals: {
			(1 to: 5).
			(10 to: 14) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredSetIsEmptyWhenFullyCovered [

	self assert:
		(self coverageFor: 'abcde' covering: { (1 to: 5) }) uncoveredSet
			isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredSetIsTheComplementOfCoveredSetIncludingBlanks [
	"1-3 and 8-9 covered over 10 characters."

	self
		assertSet: (self coverageFor: 'abcdefghij' covering: {
					 (1 to: 3).
					 (8 to: 9) }) uncoveredSet
		equals: {
				(4 to: 7).
				(10 to: 10) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredSetOfFileWithoutRegionIsTheWholeText [

	self
		assertSet: (self coverageFor: 'abcde' covering: #(  )) uncoveredSet
		equals: { (1 to: 5) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUncoveredSignificantSetIsSignificantSetWithoutCoveredSet [
	"significant 1-2, 5, 7, 10 minus covered 2-6"

	| coverage |
	coverage := self
		            newCoverageFor:
			            'ab  c' , (String with: Character tab) , 'd'
			            , (String with: Character cr with: Character lf) , 'e'
		            regions: { (self newRegionFrom: 2 to: 6) }.
	self assertSet: coverage uncoveredSignificantSet equals: {
			(1 to: 1).
			(7 to: 7).
			(10 to: 10) }
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUnreadableFileHasEmptySets [

	| coverage |
	coverage := self newUnreadableCoverage.
	self assert: coverage coveredSet isEmpty.
	self assert: coverage blankSet isEmpty.
	self assert: coverage uncoveredSet isEmpty.
	self assert: coverage significantSet isEmpty.
	self assert: coverage coveredSignificantSet isEmpty.
	self assert: coverage uncoveredSignificantSet isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUnreadableFileHasNilRatios [

	| coverage |
	coverage := self newUnreadableCoverage.
	self assert: coverage rawRatio isNil.
	self assert: coverage significantRatio isNil.
	self assert: coverage coveredPercentage isNil.
	self assert: coverage significantPercentage isNil
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUnreadableFileHasNoLineAndNoLayer [

	| coverage |
	coverage := self newUnreadableCoverage.
	self assert: coverage lineCount equals: 0.
	self assert: (coverage lineOf: 1) isNil.
	self assert: coverage maxDepth equals: 0.
	self assert: (coverage regionsAt: 1) isEmpty.
	self assert: coverage typeNames isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUnreadableFileHasNoUncoveredRegion [

	self assert: self newUnreadableCoverage uncoveredRegions isEmpty
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUnreadableFileHasSizeZero [

	self assert: self newUnreadableCoverage size equals: 0.
	self assert: self newUnreadableCoverage text equals: ''
]

{ #category : 'tests' }
MMCFileCoverageTest >> testUnreadableFileIsNotReadable [

	self deny: self newUnreadableCoverage isReadable.
	self assert: self newUnreadableCoverage regions isEmpty
]

{ #category : 'helpers' }
MMCFileCoverageTest >> uncoveredIntervalsOf: aCoverage [

	^ (aCoverage uncoveredRegions collect: [ :each | each interval ])
		  asArray
]

{ #category : 'helpers' }
MMCFileCoverageTest >> unicodeText [
	"'a', e acute, euro sign, grinning face emoji (non BMP), 'z': 5 characters."

	^ String new , 'a' , (String with: (Character value: 233))
	  , (String with: (Character value: 8364))
	  , (String with: (Character value: 128512)) , 'z'
]
