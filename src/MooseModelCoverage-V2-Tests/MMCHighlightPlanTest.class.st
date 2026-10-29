Class {
	#name : 'MMCHighlightPlanTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCHighlightPlanTest >> fixedPropertyCoverages [
	| words size |
	words := 'ab  cd efg  hij   kl mnop  qr s tuv   wx  yz ab cd  efgh ij kl   mn op qr  st uv wx yz'.
	size := words size.
	^ { 
		  self nestedCoverage.
		  self newCoverageFor: words regions: #(  ).
		  self newCoverageFor: ''  regions: #(  ).
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 1 to: 10). (self newClassRegionFrom: 11 to: 20) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 1 to: 30). (self newMethodRegionFrom: 5 to: 12). (self newAttributeRegionFrom: 6 to: 8). (self newMethodRegionFrom: 20 to: 25) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 3 to: 20). (self newMethodRegionFrom: 15 to: 40). (self newAttributeRegionFrom: 38 to: 60) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 10 to: 20). (self newMethodRegionFrom: 10 to: 20). (self newAttributeRegionFrom: 10 to: 20) }.
		  self newCoverageFor: words regions: { (self newMethodRegionFrom: 4 to: 6). (self newClassRegionFrom: 1 to: 10) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: -5 to: 10). (self newMethodRegionFrom: size - 5 to: size + 100) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 10 to: 15). (self newClassRegionFrom: 30 to: 35). (self newMethodRegionFrom: 50 to: 55) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 1 to: size) }.
		  self newCoverageFor: words regions: { (self newMethodRegionFrom: 1 to: 1) }.
		  self newCoverageFor: words regions: { (self newClassRegionFrom: 0 to: 0). (self newMethodRegionFrom: size + 1 to: size + 3) }.
		  self newUnreadableCoverage }
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> nestedCoverage [
	^ self newCoverageFor: (String new: 34 withAll: $x) regions: self nestedRegions
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> nestedRegions [
	"Answer class 1-34, method 10-30, attribute 15-20 (in this order)."
	^ { (self newClassRegionFrom: 1 to: 34). (self newMethodRegionFrom: 10 to: 30). (self newAttributeRegionFrom: 15 to: 20) }
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newAttributeRegionFrom: start to: end [
	^ self newRegionOf: FamixJavaAttribute new from: start to: end
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newClassRegionFrom: start to: end [
	^ self newRegionOf: FamixJavaClass new from: start to: end
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newCoverageFor: aText regions: aCollection [
	"Answer a readable coverage of aText with the given regions (no ignored anchor)."
	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: aText
			   regions: aCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newMethodRegionFrom: start to: end [
	^ self newRegionOf: FamixJavaMethod new from: start to: end
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newPlanFor: arg1 [

	^ MMCHighlightPlan for: arg1
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newPlanForText: aText regions: aCollection [
	^ self newPlanFor: (self newCoverageFor: aText regions: aCollection)
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newRegionOf: anEntity from: start to: end [
	"Answer a region of anEntity on start to: end (placeholder text, the interval may overflow the file text)."
	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (start to: end)
		  text: (String new: (end - start + 1 max: 0) withAll: $x)
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newSegmentInterval: arg1 region: arg2 depth: arg3 [

	^ MMCHighlightSegment interval: arg1 region: arg2 depth: arg3
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newUncoveredSegmentInterval: arg1 [

	^ MMCHighlightSegment uncoveredInterval: arg1
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> newUnreadableCoverage [
	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: nil
			   text: ''
			   regions: #(  )
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> propertyCoverages [
	^ self fixedPropertyCoverages , self randomPropertyCoverages
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> randomPropertyCoverages [
	"Thirty pseudo-random coverages (fixed seed) with up to 8 regions, some overflowing the text."
	| words random result |
	words := 'ab  cd efg  hij   kl mnop  qr s tuv   wx  yz ab cd  efgh ij kl   mn op qr  st uv wx yz'.
	random := Random seed: 20260.
	result := OrderedCollection new.
	30 timesRepeat: [ | regions |
		regions := ((1 to: 1 + (random nextInteger: 8)) collect: [ :each | | start |
			start := (random nextInteger: words size + 6) - 3.
			self
				newRegionOf: ({ FamixJavaClass new. FamixJavaMethod new. FamixJavaAttribute new } atRandom: random)
				from: start
				to: start + (random nextInteger: 25) - 1 ]).
		result add: (self newCoverageFor: words regions: regions) ].
	^ result
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> summaryOf: aPlan [
	"Answer the segments as an array of { first. last. typeName } (typeName nil when uncovered)."
	^ aPlan segments asArray collect: [ :each | { each interval first. each interval last. each typeName } ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testAdjacentRegionsOfSameTypeAreNotMerged [
	"Class 1-5 and Class 6-10 are different regions: two segments."
	| plan |
	plan := self newPlanForText: (String new: 10 withAll: $x) regions: { (self newClassRegionFrom: 1 to: 5). (self newClassRegionFrom: 6 to: 10) }.
	self assert: (self summaryOf: plan) equals: { { 1. 5. 'Class' }. { 6. 10. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testAdjacentRegionsOfSameTypeKeepTheirOwnRegion [
	| first second plan |
	first := self newClassRegionFrom: 1 to: 5.
	second := self newClassRegionFrom: 6 to: 10.
	plan := self newPlanForText: (String new: 10 withAll: $x) regions: { first. second }.
	self assert: plan segments first region identicalTo: first.
	self assert: plan segments last region identicalTo: second
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testBlankOnlyTextHasNoSegment [
	"Only blanks and no region: the uncovered run is blanks only, so there is no uncovered zone."
	self assert: (self newPlanForText: ('   ' , String lf , '  ') regions: #(  )) isEmpty
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testBlanksAtMethodBordersBelongToTheDeepestCoveringRegion [
	"'aa  bb  cc  dd' (14 characters), Class 1-14, Method 5-10 (bb, 2 blanks, cc): blanks 3-4 stay with the class, blanks 7-8 are inside the method."
	| plan |
	plan := self newPlanForText: 'aa  bb  cc  dd' regions: { (self newClassRegionFrom: 1 to: 14). (self newMethodRegionFrom: 5 to: 10) }.
	self assert: (self summaryOf: plan) equals: { { 1. 4. 'Class' }. { 5. 10. 'Method' }. { 11. 14. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testBlanksInsideAMethodBelongToTheMethodSegment [
	"'abc   def   ghi' (15 characters), Method 1-15: one segment including the blanks."
	| plan |
	plan := self newPlanForText: 'abc   def   ghi' regions: { (self newMethodRegionFrom: 1 to: 15) }.
	self assert: (self summaryOf: plan) equals: { { 1. 15. 'Method' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testClassIsCutInTwoDisjointSegmentsAroundItsMethod [
	"The segments before and after the method share the class region but are not adjacent: not merged."
	| plan |
	plan := self newPlanFor: self nestedCoverage.
	self assert: plan segments first region identicalTo: plan segments last region.
	self assert: plan segments first interval equals: (1 to: 9).
	self assert: plan segments last interval equals: (31 to: 34)
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testCoveredAndUncoveredSegmentsPartitionTheSegments [
	"zonesCoverage: two Class segments and one uncovered segment 6-9."
	| plan |
	plan := self newPlanFor: self zonesCoverage.
	self assert: (plan coveredSegments collect: [ :each | each interval ]) asArray equals: { (1 to: 4). (11 to: 14) }.
	self assert: (plan uncoveredSegments collect: [ :each | each interval ]) asArray equals: { (6 to: 9) }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testCoveredSegmentExposesRegionTypeDepthAndSize [
	"Attribute segment 15-20 of the nested coverage: 6 characters, depth 2."
	| coverage plan segment |
	coverage := self nestedCoverage.
	plan := self newPlanFor: coverage.
	segment := plan segmentAt: 15.
	self assert: segment region identicalTo: (coverage regions at: 3).
	self assert: segment typeName equals: 'Attribute'.
	self assert: segment depth equals: 2.
	self assert: segment size equals: 6.
	self assert: segment interval equals: (15 to: 20).
	self deny: segment isUncovered
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testCoveredSegmentPrintStringShowsIntervalAndType [
	| text |
	text := (self newSegmentInterval: (3 to: 9) region: (self newMethodRegionFrom: 3 to: 9) depth: 1) printString.
	self assert: (text includesSubstring: '3').
	self assert: (text includesSubstring: '9').
	self assert: (text includesSubstring: 'Method')
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testDeepestSegmentRegionIsDeepestRegionAtForEveryCoveredPosition [
	self propertyCoverages withIndexDo: [ :coverage :index | | plan |
		plan := self newPlanFor: coverage.
		(1 to: coverage size) do: [ :position |
			(coverage isCovered: position) ifTrue: [ | segment |
				segment := plan segmentAt: position.
				self assert: segment notNil description: 'covered position without segment, case ' , index printString.
				self
					assert: segment region == (coverage deepestRegionAt: position)
					description: 'deepest region differs at ' , position printString , ', case ' , index printString.
				self assert: segment depth equals: (coverage depthOf: segment region) ] ] ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testEmptyTextHasNoSegment [
	| plan |
	plan := self newPlanForText: '' regions: #(  ).
	self assert: plan isEmpty.
	self assert: plan size equals: 0
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testFlatTextWithoutRegionIsOneUncoveredSegment [
	"'abc def' (7 characters) has no region: one uncovered segment 1-7 (inner blank included)."
	| plan |
	plan := self newPlanForText: 'abc def' regions: #(  ).
	self assert: (self summaryOf: plan) equals: { { 1. 7. nil } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testFullyUncoveredTextIsOneSegmentWithoutLeadingAndTrailingBlanks [
	"'  xx yy  ' (9 characters): uncovered zone trimmed to 3-7."
	| plan |
	plan := self newPlanForText: '  xx yy  ' regions: #(  ).
	self assert: (self summaryOf: plan) equals: { { 3. 7. nil } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testIdenticalIntervalsGiveTheLastRegion [
	"Class 1-5 then Method 1-5: the method (last in order, deepest) wins."
	| method plan |
	method := self newMethodRegionFrom: 1 to: 5.
	plan := self newPlanForText: (String new: 5 withAll: $x) regions: { (self newClassRegionFrom: 1 to: 5). method }.
	self assert: (self summaryOf: plan) equals: { { 1. 5. 'Method' } }.
	self assert: plan segments first region identicalTo: method
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testIdenticalIntervalsInReverseOrderGiveTheClass [
	| plan |
	plan := self newPlanForText: (String new: 5 withAll: $x) regions: { (self newMethodRegionFrom: 1 to: 5). (self newClassRegionFrom: 1 to: 5) }.
	self assert: (self summaryOf: plan) equals: { { 1. 5. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testModifyingTheSegmentsAnsweredDoesNotChangeThePlan [
	| plan returned |
	plan := self newPlanFor: self nestedCoverage.
	returned := plan segments.
	returned removeFirst.
	returned add: returned first.
	self assert: plan size equals: 5.
	self assert: plan segments size equals: 5.
	self assert: plan segments first interval equals: (1 to: 9)
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testNestedRegionsGiveDepthsZeroOneTwoOneZero [
	| plan |
	plan := self newPlanFor: self nestedCoverage.
	self assert: (plan segments asArray collect: [ :each | each depth ]) equals: #( 0 1 2 1 0 )
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testNestedRegionsInReverseOrderLetTheLastRegionWin [
	"Attribute 15-20 and Method 10-30 listed BEFORE Class 1-34: the class is the deepest (last) everywhere: one segment."
	| plan |
	plan := self newPlanForText: (String new: 34 withAll: $x) regions: { (self newAttributeRegionFrom: 15 to: 20). (self newMethodRegionFrom: 10 to: 30). (self newClassRegionFrom: 1 to: 34) }.
	self assert: (self summaryOf: plan) equals: { { 1. 34. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testNestedRegionsOnThreeLevelsGiveFiveSegments [
	"Text of 34 characters. Class 1-34, method 10-30, attribute 15-20.
	Class 1-9, Method 10-14, Attribute 15-20, Method 21-30, Class 31-34."
	| plan |
	plan := self newPlanFor: self nestedCoverage.
	self assert: (self summaryOf: plan) equals: { { 1. 9. 'Class' }. { 10. 14. 'Method' }. { 15. 20. 'Attribute' }. { 21. 30. 'Method' }. { 31. 34. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testNoTwoAdjacentSegmentsShareRegionAndState [
	self propertyCoverages withIndexDo: [ :coverage :index | | segments |
		segments := (self newPlanFor: coverage) segments asArray.
		2 to: segments size do: [ :i | | previous next |
			previous := segments at: i - 1.
			next := segments at: i.
			(previous interval last + 1 = next interval first) ifTrue: [
				self
					deny: (previous region == next region and: [ previous isUncovered = next isUncovered ])
					description: 'mergeable adjacent segments, case ' , index printString ] ] ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testPartiallyOverlappingRegionsGiveTheLastRegionInTheOverlap [
	"Class 1-6 then Method 4-10: overlap 4-6 goes to the method. Class 1-3, Method 4-10."
	| plan |
	plan := self newPlanForText: (String new: 10 withAll: $x) regions: { (self newClassRegionFrom: 1 to: 6). (self newMethodRegionFrom: 4 to: 10) }.
	self assert: (self summaryOf: plan) equals: { { 1. 3. 'Class' }. { 4. 10. 'Method' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testPartiallyOverlappingRegionsInReverseOrder [
	"Method 4-10 then Class 1-6: overlap 4-6 goes to the class. Class 1-6, Method 7-10."
	| plan |
	plan := self newPlanForText: (String new: 10 withAll: $x) regions: { (self newMethodRegionFrom: 4 to: 10). (self newClassRegionFrom: 1 to: 6) }.
	self assert: (self summaryOf: plan) equals: { { 1. 6. 'Class' }. { 7. 10. 'Method' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testPiecesOfTheSameRegionAreMergedWhenEarlierRegionIsHidden [
	"Method 4-6 is listed BEFORE Class 1-10, so the class is deepest everywhere: the pieces 1-3, 4-6, 7-10 all belong to the class and merge into 1-10."
	| class plan |
	class := self newClassRegionFrom: 1 to: 10.
	plan := self newPlanForText: (String new: 10 withAll: $x) regions: { (self newMethodRegionFrom: 4 to: 6). class }.
	self assert: (self summaryOf: plan) equals: { { 1. 10. 'Class' } }.
	self assert: plan segments first region identicalTo: class
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testPlanKeepsItsFileCoverage [
	| coverage |
	coverage := self nestedCoverage.
	self assert: (self newPlanFor: coverage) fileCoverage identicalTo: coverage
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testPlanOf7000NestedRegionsOnHalfAMillionCharactersIsBuiltInUnderTwoSeconds [
	"1000 classes of 500 characters tile the text; each holds 3 methods (100 characters, starting at offsets 51, 201, 351) and each method an attribute (20 characters, 30 after its start). Per class: 4 class pieces + 3 x (2 method pieces + 1 attribute) = 13 segments, so 13000 segments covering all 500000 characters."
	| text classEntity methodEntity attributeEntity classes methods attributes coverage plan duration total |
	text := String new: 500000 withAll: $x.
	classEntity := FamixJavaClass new.
	methodEntity := FamixJavaMethod new.
	attributeEntity := FamixJavaAttribute new.
	classes := OrderedCollection new.
	methods := OrderedCollection new.
	attributes := OrderedCollection new.
	0 to: 999 do: [ :k | | base |
		base := k * 500.
		classes add: (self newRegionOf: classEntity from: base + 1 to: base + 500).
		0 to: 2 do: [ :j | | start |
			start := base + 51 + (j * 150).
			methods add: (self newRegionOf: methodEntity from: start to: start + 99).
			attributes add: (self newRegionOf: attributeEntity from: start + 30 to: start + 49) ] ].
	coverage := self newCoverageFor: text regions: classes asArray , methods asArray , attributes asArray.
	self assert: coverage regions size equals: 7000.
	duration := [ plan := self newPlanFor: coverage ] timeToRun.
	self assert: duration < 2 seconds description: 'plan built in ' , duration printString.
	self assert: plan size equals: 13000.
	total := 0.
	plan segments do: [ :each | total := total + each size ].
	self assert: total equals: 500000
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testRegionCoveringWholeTextIsOneSegment [
	| plan |
	plan := self newPlanForText: 'abcdefghij' regions: { (self newClassRegionFrom: 1 to: 10) }.
	self assert: (self summaryOf: plan) equals: { { 1. 10. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testRegionEntirelyOutsideTheTextLeavesTheTextUncovered [
	| plan |
	plan := self newPlanForText: 'abcde' regions: { (self newClassRegionFrom: 10 to: 20) }.
	self assert: (self summaryOf: plan) equals: { { 1. 5. nil } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testRegionLargerThanTheTextOnBothSidesIsClamped [
	| plan |
	plan := self newPlanForText: 'abcde' regions: { (self newClassRegionFrom: -5 to: 100) }.
	self assert: (self summaryOf: plan) equals: { { 1. 5. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testRegionOverflowingTheTextIsClamped [
	"'abcde', Class 3-10: uncovered 1-2, Class 3-5."
	| plan |
	plan := self newPlanForText: 'abcde' regions: { (self newClassRegionFrom: 3 to: 10) }.
	self assert: (self summaryOf: plan) equals: { { 1. 2. nil }. { 3. 5. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testRegionStartingAtZeroIsClamped [
	"'abcde', Class 0-2: Class 1-2, uncovered 3-5."
	| plan |
	plan := self newPlanForText: 'abcde' regions: { (self newClassRegionFrom: 0 to: 2) }.
	self assert: (self summaryOf: plan) equals: { { 1. 2. 'Class' }. { 3. 5. nil } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSameRegionListedTwiceGivesOneSegment [
	| region plan |
	region := self newClassRegionFrom: 1 to: 5.
	plan := self newPlanForText: (String new: 5 withAll: $x) regions: { region. region }.
	self assert: (self summaryOf: plan) equals: { { 1. 5. 'Class' } }.
	self assert: plan segments first region identicalTo: region
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentAtGivesTheDeepestSegmentInNestedRegions [
	| plan |
	plan := self newPlanFor: self nestedCoverage.
	self assert: (plan segmentAt: 17) typeName equals: 'Attribute'.
	self assert: (plan segmentAt: 12) typeName equals: 'Method'.
	self assert: (plan segmentAt: 34) typeName equals: 'Class'
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentAtGivesTheSegmentHoldingThePositionBordersIncluded [
	"zonesCoverage segments: 1-4, 6-9, 11-14."
	| plan |
	plan := self newPlanFor: self zonesCoverage.
	self assert: (plan segmentAt: 1) interval equals: (1 to: 4).
	self assert: (plan segmentAt: 4) interval equals: (1 to: 4).
	self assert: (plan segmentAt: 6) interval equals: (6 to: 9).
	self assert: (plan segmentAt: 9) interval equals: (6 to: 9).
	self assert: (plan segmentAt: 11) interval equals: (11 to: 14).
	self assert: (plan segmentAt: 14) interval equals: (11 to: 14)
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentAtIsNilForBlanksBetweenSegments [
	| plan |
	plan := self newPlanFor: self zonesCoverage.
	self assert: (plan segmentAt: 5) isNil.
	self assert: (plan segmentAt: 10) isNil
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentAtIsNilOutsideTheText [
	"The text has 14 characters."
	| plan |
	plan := self newPlanFor: self zonesCoverage.
	self assert: (plan segmentAt: 0) isNil.
	self assert: (plan segmentAt: -3) isNil.
	self assert: (plan segmentAt: 15) isNil
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentBuiltByHandExposesItsRegionTypeAndDepth [
	| region segment |
	region := self newMethodRegionFrom: 1 to: 3.
	segment := self newSegmentInterval: (1 to: 3) region: region depth: 1.
	self assert: segment region identicalTo: region.
	self assert: segment typeName equals: 'Method'.
	self assert: segment depth equals: 1.
	self assert: segment interval equals: (1 to: 3).
	self deny: segment isUncovered
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentTextIsTheSubstringOfTheFileText [
	"zonesCoverage text is 'aaaa xxxx bbbb'."
	| plan |
	plan := self newPlanFor: self zonesCoverage.
	self assert: plan segments first text equals: 'aaaa'.
	self assert: (plan segmentAt: 7) text equals: 'xxxx'.
	self assert: plan segments last text equals: 'bbbb'
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsAnswersAFreshCollectionEachTime [
	| plan |
	plan := self newPlanFor: self nestedCoverage.
	self deny: plan segments == plan segments
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsAnswersAnOrderedCollection [
	self assert: ((self newPlanFor: self nestedCoverage) segments isKindOf: OrderedCollection)
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsAreDisjointSortedAndInsideTheText [
	self propertyCoverages withIndexDo: [ :coverage :index | | segments |
		segments := (self newPlanFor: coverage) segments asArray.
		segments do: [ :each |
			self assert: each interval isEmpty not description: 'empty segment, case ' , index printString.
			self assert: each interval first >= 1 description: 'before text, case ' , index printString.
			self assert: each interval last <= coverage size description: 'after text, case ' , index printString ].
		2 to: segments size do: [ :i |
			self
				assert: (segments at: i - 1) interval last < (segments at: i) interval first
				description: 'not disjoint or not sorted, case ' , index printString ] ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsOfUncoveredZonesNeverCoverBlanksOnTheirBorders [
	self propertyCoverages withIndexDo: [ :coverage :index |
		(self newPlanFor: coverage) uncoveredSegments do: [ :segment |
			self deny: (coverage text at: segment interval first) isSeparator.
			self deny: (coverage text at: segment interval last) isSeparator ] ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsUnionIsCoveredSetUnionUncoveredRegions [
	"The union of the segments is exactly the covered positions plus the uncovered zones; no position is counted twice."
	self propertyCoverages withIndexDo: [ :coverage :index | | expected actual count |
		expected := Set new.
		(1 to: coverage size) do: [ :each | (coverage isCovered: each) ifTrue: [ expected add: each ] ].
		coverage uncoveredRegions do: [ :zone | zone interval do: [ :each | expected add: each ] ].
		actual := Set new.
		count := 0.
		(self newPlanFor: coverage) segments do: [ :segment |
			segment interval do: [ :each |
				actual add: each.
				count := count + 1 ] ].
		self assert: actual equals: expected.
		self assert: count = actual size description: 'position counted twice, case ' , index printString ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsWithDifferentIntervalsAreNotEqual [
	| region |
	region := self newClassRegionFrom: 1 to: 3.
	self
		deny: (self newSegmentInterval: (1 to: 3) region: region depth: 0)
		equals: (self newSegmentInterval: (1 to: 2) region: region depth: 0)
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSegmentsWithSameIntervalRegionAndDepthAreEqual [
	| region |
	region := self newClassRegionFrom: 1 to: 3.
	self
		assert: (self newSegmentInterval: (1 to: 3) region: region depth: 0)
		equals: (self newSegmentInterval: (1 to: 3) region: region depth: 0).
	self
		assert: (self newSegmentInterval: (1 to: 3) region: region depth: 0) hash
		equals: (self newSegmentInterval: (1 to: 3) region: region depth: 0) hash
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSingleRegionInTheMiddleIsFlankedByUncoveredSegments [
	"'abcdefghij', Class 3-6: uncovered 1-2, Class 3-6, uncovered 7-10."
	| plan |
	plan := self newPlanForText: 'abcdefghij' regions: { (self newClassRegionFrom: 3 to: 6) }.
	self assert: (self summaryOf: plan) equals: { { 1. 2. nil }. { 3. 6. 'Class' }. { 7. 10. nil } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testSizeAndIsEmptyOfNestedPlan [
	| plan |
	plan := self newPlanFor: self nestedCoverage.
	self assert: plan size equals: 5.
	self deny: plan isEmpty
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredBlanksOutsideZonesBelongToNoSegment [
	"'  aa  bb  ' (10 characters), Class 3-4 and Class 7-8: blanks 1-2, 5-6, 9-10 are in no segment."
	| plan |
	plan := self newPlanForText: '  aa  bb  ' regions: { (self newClassRegionFrom: 3 to: 4). (self newClassRegionFrom: 7 to: 8) }.
	self assert: (self summaryOf: plan) equals: { { 3. 4. 'Class' }. { 7. 8. 'Class' } }.
	self assert: ((#( 1 2 5 6 9 10 ) collect: [ :each | plan segmentAt: each ]) allSatisfy: [ :each | each isNil ])
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredSegmentBuiltByHand [
	| segment |
	segment := self newUncoveredSegmentInterval: (4 to: 6).
	self assert: segment isUncovered.
	self assert: segment region isNil.
	self assert: segment typeName isNil.
	self assert: segment interval equals: (4 to: 6).
	self assert: segment size equals: 3
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredSegmentHasNoRegionTypeNorDepth [
	| segment |
	segment := (self newPlanFor: self zonesCoverage) segmentAt: 7.
	self assert: segment isUncovered.
	self assert: segment region isNil.
	self assert: segment typeName isNil.
	self assert: segment depth isNil.
	self assert: segment size equals: 4
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredSegmentPrintStringMentionsUncovered [
	| text |
	text := (self newUncoveredSegmentInterval: (4 to: 6)) printString.
	self assert: (text asLowercase includesSubstring: 'uncovered').
	self assert: (text includesSubstring: '4')
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredSegmentsAreEqualOnSameIntervalAndDifferFromCoveredOnes [
	| region |
	region := self newClassRegionFrom: 4 to: 6.
	self assert: (self newUncoveredSegmentInterval: (4 to: 6)) equals: (self newUncoveredSegmentInterval: (4 to: 6)).
	self assert: (self newUncoveredSegmentInterval: (4 to: 6)) hash equals: (self newUncoveredSegmentInterval: (4 to: 6)) hash.
	self deny: (self newUncoveredSegmentInterval: (4 to: 6)) equals: (self newSegmentInterval: (4 to: 6) region: region depth: 0)
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredSegmentsAreExactlyTheUncoveredRegions [
	self propertyCoverages withIndexDo: [ :coverage :index |
		self
			assert: ((self newPlanFor: coverage) uncoveredSegments collect: [ :each | each interval ]) asArray
			equals: (coverage uncoveredRegions collect: [ :each | each interval ]) asArray ]
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredZoneAtTheEnd [
	"'aaaa xxxx': Class 1-4, blank 5 excluded, uncovered 6-9."
	| plan |
	plan := self newPlanForText: 'aaaa xxxx' regions: { (self newClassRegionFrom: 1 to: 4) }.
	self assert: (self summaryOf: plan) equals: { { 1. 4. 'Class' }. { 6. 9. nil } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredZoneAtTheStart [
	"'xxxx aaaa': uncovered 1-4, blank 5 excluded, Class 6-9."
	| plan |
	plan := self newPlanForText: 'xxxx aaaa' regions: { (self newClassRegionFrom: 6 to: 9) }.
	self assert: (self summaryOf: plan) equals: { { 1. 4. nil }. { 6. 9. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUncoveredZoneInTheMiddleIsTrimmedOfBlanks [
	"aaaa(1-4) blank(5) xxxx(6-9) blank(10) bbbb(11-14): uncovered zone 6-9, blanks 5 and 10 in no segment."
	| plan |
	plan := self newPlanFor: self zonesCoverage.
	self assert: (self summaryOf: plan) equals: { { 1. 4. 'Class' }. { 6. 9. nil }. { 11. 14. 'Class' } }
]

{ #category : 'tests' }
MMCHighlightPlanTest >> testUnreadableFileHasNoSegment [
	| plan |
	plan := self newPlanFor: self newUnreadableCoverage.
	self assert: plan isEmpty.
	self assert: plan size equals: 0.
	self assert: plan segments isEmpty.
	self assert: (plan segmentAt: 1) isNil
]

{ #category : 'helpers' }
MMCHighlightPlanTest >> zonesCoverage [
	"aaaa(1-4) blank(5) xxxx(6-9) blank(10) bbbb(11-14); two Class regions on the a and b runs."
	^ self newCoverageFor: 'aaaa xxxx bbbb' regions: { (self newClassRegionFrom: 1 to: 4). (self newClassRegionFrom: 11 to: 14) }
]
