"
Tests for MMCIntervalSet: normalized set of 1-based inclusive character intervals.
"
Class {
	#name : 'MMCIntervalSetTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'tests' }
MMCIntervalSetTest >> testAddAdjacentIntervalsMerge [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1
		add: (1 to: 3);
		add: (4 to: 6).
	self
		assert: tmp1 intervals asArray equals: { (1 to: 6) };
		assert: tmp1 size equals: 6
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddAdjacentIntervalsMergeInReverseOrder [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1
		add: (4 to: 6);
		add: (1 to: 3).
	self assert: tmp1 intervals asArray equals: { (1 to: 6) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddEmptyIntervalRaisesError [

	self should: [ MMCIntervalSet new add: (5 to: 3) ] raise: Error
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddFromToReturnsReceiver [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	self assert: (tmp1 addFrom: 1 to: 3) identicalTo: tmp1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddFromToWithSingleCharacter [

	| tmp1 |
	tmp1 := MMCIntervalSet new addFrom: 5 to: 5.
	self
		assert: tmp1 intervals asArray equals: { (5 to: 5) };
		assert: tmp1 size equals: 1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddFromToWithStopBeforeStartRaisesError [

	self should: [ MMCIntervalSet new addFrom: 5 to: 4 ] raise: Error
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddInterval [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1 add: (2 to: 4).
	self assert: tmp1 intervals asArray equals: { (2 to: 4) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddIntervalBridgingSeveralIntervalsMergesThemAll [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 2).
			        (5 to: 6).
			        (9 to: 10).
			        (20 to: 22) }.
	tmp1 add: (2 to: 9).
	self assert: tmp1 intervals asArray equals: {
			(1 to: 10).
			(20 to: 22) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddIntervalContainedInExistingOneChangesNothing [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 10) }.
	tmp1 add: (3 to: 5).
	self assert: tmp1 intervals asArray equals: { (1 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddIntervalContainingExistingOneAbsorbsIt [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (3 to: 5) }.
	tmp1 add: (1 to: 10).
	self assert: tmp1 intervals asArray equals: { (1 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddIntervalsSeparatedByOneCharacterGapAreNotMerged [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1
		add: (1 to: 3);
		add: (5 to: 6).
	self
		assert: tmp1 intervals asArray equals: {
				(1 to: 3).
				(5 to: 6) };
		deny: (tmp1 includes: 4)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddNegativeStepIntervalRaisesError [

	self
		should: [ MMCIntervalSet new add: (5 to: 1 by:  -1) ]
		raise: Error
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddPartiallyOverlappingIntervalsMerge [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1
		add: (1 to: 5);
		add: (3 to: 8).
	self assert: tmp1 intervals asArray equals: { (1 to: 8) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddReturnsReceiver [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	self assert: (tmp1 add: (1 to: 3)) identicalTo: tmp1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddSameIntervalTwiceIsIdempotent [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1
		add: (2 to: 5);
		add: (2 to: 5).
	self
		assert: tmp1 intervals asArray equals: { (2 to: 5) };
		assert: tmp1 size equals: 4
]

{ #category : 'tests' }
MMCIntervalSetTest >> testAddUnorderedIntervalsAreSorted [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1
		add: (10 to: 12);
		add: (1 to: 3);
		add: (5 to: 6).
	self assert: tmp1 intervals asArray equals: {
			(1 to: 3).
			(5 to: 6).
			(10 to: 12) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testClampedToCutsIntervalsAtBounds [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        ( -3 to: 4).
			        (8 to: 20) }.
	self
		assert: (tmp1 clampedTo: (1 to: 10)) intervals asArray
		equals: {
				(1 to: 4).
				(8 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testClampedToDropsIntervalsOutsideBounds [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        ( -5 to:  -1).
			        (3 to: 4).
			        (50 to: 60) }.
	self
		assert: (tmp1 clampedTo: (1 to: 10)) intervals asArray
		equals: { (3 to: 4) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testClampedToKeepsBoundaryCharacters [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (10 to: 15) }.
	self
		assert: (tmp1 clampedTo: (1 to: 10)) intervals asArray
		equals: { (10 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testClampedToKeepsIntervalsInsideBounds [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (2 to: 3).
			        (5 to: 6) }.
	self assert: (tmp1 clampedTo: (1 to: 10)) equals: tmp1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testClampedToLeavesReceiverUnchanged [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { ( -3 to: 4) }.
	tmp1 clampedTo: (1 to: 10).
	self assert: tmp1 intervals asArray equals: { ( -3 to: 4) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testComplementWithinIgnoresIntervalsOutsideBounds [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (20 to: 30) }.
	tmp2 := tmp1 complementWithin: (1 to: 10).
	self assert: tmp2 intervals asArray equals: { (1 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testComplementWithinLeavesReceiverUnchanged [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (3 to: 4) }.
	tmp1 complementWithin: (1 to: 10).
	self assert: tmp1 intervals asArray equals: { (3 to: 4) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testComplementWithinOfEmptySetIsWholeInterval [

	| tmp1 |
	tmp1 := MMCIntervalSet new complementWithin: (1 to: 10).
	self assert: tmp1 intervals asArray equals: { (1 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testComplementWithinOfFullyCoveringSetIsEmpty [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 10) }.
	self assert: (tmp1 complementWithin: (1 to: 10)) isEmpty
]

{ #category : 'tests' }
MMCIntervalSetTest >> testComplementWithinReturnsGaps [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: {
			        (3 to: 4).
			        (7 to: 8) }.
	tmp2 := tmp1 complementWithin: (1 to: 10).
	self
		assert: tmp2 class equals: MMCIntervalSet;
		assert: tmp2 intervals asArray equals: {
				(1 to: 2).
				(5 to: 6).
				(9 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testComplementWithinTruncatesOverflowingIntervals [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: {
			        ( -5 to: 3).
			        (8 to: 20) }.
	tmp2 := tmp1 complementWithin: (1 to: 10).
	self assert: tmp2 intervals asArray equals: { (4 to: 7) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testCopyIsIndependent [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := tmp1 copy.
	tmp2 addFrom: 10 to: 12.
	self
		assert: tmp1 intervals asArray equals: { (1 to: 3) };
		assert: tmp2 intervals asArray equals: {
				(1 to: 3).
				(10 to: 12) }.
	tmp1 addFrom: 20 to: 22.
	self deny: (tmp2 includes: 20)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceLeavesOperandsUnchanged [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 10) }.
	tmp2 := MMCIntervalSet withAll: { (4 to: 6) }.
	tmp1 difference: tmp2.
	self
		assert: tmp1 intervals asArray equals: { (1 to: 10) };
		assert: tmp2 intervals asArray equals: { (4 to: 6) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceRemovesOverlappingCharacters [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 10) }.
	tmp2 := MMCIntervalSet withAll: { (8 to: 15) }.
	self
		assert: (tmp1 difference: tmp2) intervals asArray
		equals: { (1 to: 7) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceSplitsIntervalInTwo [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 10) }.
	tmp2 := MMCIntervalSet withAll: { (4 to: 6) }.
	self assert: (tmp1 difference: tmp2) intervals asArray equals: {
			(1 to: 3).
			(7 to: 10) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceWithDisjointSetChangesNothing [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := MMCIntervalSet withAll: { (5 to: 8) }.
	self assert: (tmp1 difference: tmp2) equals: tmp1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceWithEmptySetChangesNothing [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (6 to: 8) }.
	self assert: (tmp1 difference: MMCIntervalSet new) equals: tmp1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceWithSingleCharacterSplits [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 5) }.
	tmp2 := MMCIntervalSet withAll: { (3 to: 3) }.
	self assert: (tmp1 difference: tmp2) intervals asArray equals: {
			(1 to: 2).
			(4 to: 5) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testDifferenceWithSupersetIsEmpty [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (3 to: 5) }.
	tmp2 := MMCIntervalSet withAll: { (1 to: 10) }.
	self assert: (tmp1 difference: tmp2) isEmpty
]

{ #category : 'tests' }
MMCIntervalSetTest >> testEmptySetsAreEqual [

	self
		assert: MMCIntervalSet new equals: MMCIntervalSet new;
		assert: MMCIntervalSet new hash equals: MMCIntervalSet new hash
]

{ #category : 'tests' }
MMCIntervalSetTest >> testEqualityIgnoresConstructionOrder [

	| tmp1 tmp2 tmp3 tmp5 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (4 to: 6) }.
	tmp2 := MMCIntervalSet withAll: { (1 to: 6) }.
	tmp5 := MMCIntervalSet new.
	tmp5
		add: (4 to: 6);
		add: (2 to: 3);
		add: (1 to: 1).
	tmp3 := tmp5 yourself.
	self
		assert: tmp1 equals: tmp2;
		assert: tmp2 equals: tmp3;
		assert: tmp1 hash equals: tmp2 hash;
		assert: tmp2 hash equals: tmp3 hash
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesBoundsAreInclusive [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (3 to: 7) }.
	self
		assert: (tmp1 includes: 3);
		assert: (tmp1 includes: 5);
		assert: (tmp1 includes: 7)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesIntervalIsFalseAcrossGap [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (5 to: 7) }.
	self deny: (tmp1 includesInterval: (1 to: 7))
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesIntervalIsFalseWhenPartiallyCovered [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (3 to: 10) }.
	self
		deny: (tmp1 includesInterval: (2 to: 5));
		deny: (tmp1 includesInterval: (8 to: 11));
		deny: (tmp1 includesInterval: (1 to: 20))
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesIntervalIsTrueAcrossAdjacentIntervals [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (4 to: 7) }.
	self assert: (tmp1 includesInterval: (2 to: 6))
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesIntervalWhenFullyContained [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (3 to: 10) }.
	self
		assert: (tmp1 includesInterval: (3 to: 10));
		assert: (tmp1 includesInterval: (4 to: 6));
		assert: (tmp1 includesInterval: (7 to: 7))
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesOnEmptySetIsFalse [

	self deny: (MMCIntervalSet new includes: 1)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIncludesOutsideIntervalsIsFalse [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (3 to: 7).
			        (10 to: 12) }.
	self
		deny: (tmp1 includes: 2);
		deny: (tmp1 includes: 8);
		deny: (tmp1 includes: 9);
		deny: (tmp1 includes: 13)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testInequalityOfDifferentSets [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := MMCIntervalSet withAll: { (1 to: 4) }.
	self
		deny: tmp1 = tmp2;
		deny: tmp1 = MMCIntervalSet new
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntersectionKeepsCommonCharacters [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 10).
			        (20 to: 30) }.
	tmp2 := MMCIntervalSet withAll: {
			        (5 to: 22).
			        (28 to: 40) }.
	self assert: (tmp1 intersection: tmp2) intervals asArray equals: {
			(5 to: 10).
			(20 to: 22).
			(28 to: 30) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntersectionLeavesOperandsUnchanged [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 10) }.
	tmp2 := MMCIntervalSet withAll: { (5 to: 15) }.
	tmp1 intersection: tmp2.
	self
		assert: tmp1 intervals asArray equals: { (1 to: 10) };
		assert: tmp2 intervals asArray equals: { (5 to: 15) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntersectionOfAdjacentSetsIsEmpty [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := MMCIntervalSet withAll: { (4 to: 6) }.
	self assert: (tmp1 intersection: tmp2) isEmpty
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntersectionOfDisjointSetsIsEmpty [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := MMCIntervalSet withAll: { (5 to: 8) }.
	self assert: (tmp1 intersection: tmp2) isEmpty
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntersectionSharingOnlyOneCharacter [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 5) }.
	tmp2 := MMCIntervalSet withAll: { (5 to: 9) }.
	self
		assert: (tmp1 intersection: tmp2) intervals asArray
		equals: { (5 to: 5) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntervalCountCountsNormalizedIntervals [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (6 to: 8).
			        (10 to: 10) }.
	self assert: tmp1 intervalCount equals: 3.
	tmp1 addFrom: 4 to: 5.
	self assert: tmp1 intervalCount equals: 2
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntervalsDoIteratesInAscendingOrder [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: {
			        (10 to: 12).
			        (1 to: 3).
			        (5 to: 6) }.
	tmp2 := OrderedCollection new.
	tmp1 intervalsDo: [ :arg1 | tmp2 add: arg1 ].
	self assert: tmp2 asArray equals: {
			(1 to: 3).
			(5 to: 6).
			(10 to: 12) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testIntervalsDoOnEmptySetDoesNothing [

	| tmp2 |
	tmp2 := 0.
	MMCIntervalSet new intervalsDo: [ :arg1 | tmp2 := tmp2 + 1 ].
	self assert: tmp2 equals: 0
]

{ #category : 'tests' }
MMCIntervalSetTest >> testNewSetIsEmpty [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	self
		assert: tmp1 isEmpty;
		deny: tmp1 notEmpty;
		assert: tmp1 size equals: 0;
		assert: tmp1 intervalCount equals: 0;
		assert: tmp1 intervals isEmpty
]

{ #category : 'tests' }
MMCIntervalSetTest >> testNotEqualToNonIntervalSet [

	self deny: (MMCIntervalSet withAll: { (1 to: 3) }) = (1 to: 3)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testPrintOnEmptySetMentionsClassName [

	self assert:
		(MMCIntervalSet new printString includesSubstring: 'MMCIntervalSet')
]

{ #category : 'tests' }
MMCIntervalSetTest >> testPrintOnShowsIntervalBounds [

	| tmp1 |
	tmp1 := (MMCIntervalSet withAll: {
			         (1 to: 3).
			         (6 to: 8) }) printString.
	self assert: (tmp1 includesSubstring: 'MMCIntervalSet').
	#( '1' '3' '6' '8' ) do: [ :arg1 |
		self assert: (tmp1 includesSubstring: arg1) ]
]

{ #category : 'tests' }
MMCIntervalSetTest >> testSingleCharacterInterval [

	| tmp1 |
	tmp1 := MMCIntervalSet new.
	tmp1 add: (5 to: 5).
	self
		assert: tmp1 size equals: 1;
		assert: (tmp1 includes: 5);
		deny: (tmp1 includes: 4);
		deny: (tmp1 includes: 6)
]

{ #category : 'tests' }
MMCIntervalSetTest >> testSizeCountsCharactersNotIntervals [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (6 to: 8).
			        (10 to: 10) }.
	self assert: tmp1 size equals: 7
]

{ #category : 'tests' }
MMCIntervalSetTest >> testUnionCombinesBothSets [

	| tmp1 tmp2 tmp3 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (10 to: 12) }.
	tmp2 := MMCIntervalSet withAll: {
			        (3 to: 5).
			        (20 to: 21) }.
	tmp3 := tmp1 union: tmp2.
	self assert: tmp3 intervals asArray equals: {
			(1 to: 5).
			(10 to: 12).
			(20 to: 21) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testUnionLeavesOperandsUnchanged [

	| tmp1 tmp2 tmp3 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := MMCIntervalSet withAll: { (5 to: 6) }.
	tmp3 := tmp1 union: tmp2.
	self
		deny: tmp3 == tmp1;
		assert: tmp1 intervals asArray equals: { (1 to: 3) };
		assert: tmp2 intervals asArray equals: { (5 to: 6) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testUnionMergesAdjacentIntervalsAcrossSets [

	| tmp1 tmp2 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	tmp2 := MMCIntervalSet withAll: { (4 to: 6) }.
	self
		assert: (tmp1 union: tmp2) intervals asArray
		equals: { (1 to: 6) }
]

{ #category : 'tests' }
MMCIntervalSetTest >> testUnionWithEmptySetIsEquivalentToReceiver [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: { (1 to: 3) }.
	self
		assert: (tmp1 union: MMCIntervalSet new) equals: tmp1;
		assert: (MMCIntervalSet new union: tmp1) equals: tmp1
]

{ #category : 'tests' }
MMCIntervalSetTest >> testWithAllBuildsSetFromIntervals [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (1 to: 3).
			        (6 to: 8) }.
	self
		assert: tmp1 intervals asArray equals: {
				(1 to: 3).
				(6 to: 8) };
		assert: tmp1 notEmpty
]

{ #category : 'tests' }
MMCIntervalSetTest >> testWithAllNormalizesIntervals [

	| tmp1 |
	tmp1 := MMCIntervalSet withAll: {
			        (6 to: 8).
			        (1 to: 3).
			        (4 to: 5) }.
	self assert: tmp1 intervals asArray equals: { (1 to: 8) }
]
