"
Tests of the intervals of the decorators of MMCCoveragePresenter: the plan intervals are inclusive, the end of a Rubric text segment is exclusive, so a decorator covers first to: last + 1 (see buildDecorators). A real window checks the text of the Rubric segments.
"
Class {
	#name : 'MMCCoveragePresenterDecoratorIntervalTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterDecoratorIntervalTest >> coverageOf: aText classFrom: start to: end [
	"Readable coverage of aText with one class region start to: end."

	| region |
	region := MMCEntityRegion
		          entity: (FamixJavaClass new
				           name: 'C';
				           yourself)
		          anchor: nil
		          interval: (start to: end)
		          text: (aText copyFrom: start to: end).
	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: aText
			   regions: { region }
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterDecoratorIntervalTest >> decoratorIntervalsOf: aPresenter [

	^ (aPresenter decorators collect: [ :each | each interval asArray ])
		  asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterDecoratorIntervalTest >> segmentIntervalsOf: aPresenter [

	^ (aPresenter plan segments collect: [ :each | each interval asArray ])
		  asArray
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testEveryDecoratorIsItsSegmentIntervalWithAnExclusiveEnd [

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdefghij' classFrom: 4 to: 4).
	presenter plan segments
		with: presenter decorators
		do: [ :segment :decorator |
				self
					assert: decorator interval first
					equals: segment interval first.
				self
					assert: decorator interval last
					equals: segment interval last + 1 ]
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testLastSegmentGoesUpToTheSizePlusOne [
	"The last segment (here a region 6-10 of a 10 characters text) has a decorator ending at 11 = size + 1; the presenter builds without error."

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdefghij' classFrom: 6 to: 10).
	self assert: presenter decorators last interval last equals: 11.
	self assert: presenter decorators last interval first equals: 6.
	self assert: presenter decorators size equals: presenter plan size
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testOneCharacterSegmentHasATwoPositionsInterval [
	"The region 3-3 is a one character segment: its decorator 3 to: 4 is not empty (it was invisible with the inclusive interval)."

	| presenter decorator |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdef' classFrom: 3 to: 3).
	decorator := presenter decorators at: 2.
	self assert: decorator interval asArray equals: (3 to: 4) asArray.
	self assert: decorator interval size equals: 2
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testPlanSegmentThreeToFiveHasADecoratorThreeToSix [
	"'abcdefghij', class 3-5: segments 1-2 (uncovered), 3-5, 6-10 (uncovered); decorators 1-3, 3-6, 6-11 (Rubric, end exclusive)."

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdefghij' classFrom: 3 to: 5).
	self assert: (self segmentIntervalsOf: presenter) equals: {
			(1 to: 2) asArray.
			(3 to: 5) asArray.
			(6 to: 10) asArray }.
	self assert: (self decoratorIntervalsOf: presenter) equals: {
			(1 to: 3) asArray.
			(3 to: 6) asArray.
			(6 to: 11) asArray }
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testRealWindowLastSegmentReachesTheEndOfTheText [
	"Real window: the last segment, whose decorator ends at size + 1, is built without error and has the end of the text."

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdefghij' classFrom: 6 to: 10).
	self withRealWindowOf: presenter do: [ :window |
			self
				assert: (self textsOfSegmentsIn: presenter)
				equals: #( 'abcde' 'fghij' ) ]
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testRealWindowOneCharacterSegmentIsVisible [
	"Real window: the segment of the one character region 3-3 has the text 'c' (it was empty before, hence invisible)."

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdef' classFrom: 3 to: 3).
	self withRealWindowOf: presenter do: [ :window |
			self
				assert: (self textsOfSegmentsIn: presenter)
				equals: #( 'ab' 'c' 'def' ).
			self assert:
				(presenter textPresenter adapter widget textArea segments
					 allSatisfy: [ :each | each getText isEmpty not ]) ]
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testRealWindowSegmentsHaveTheTextOfThePlanSegments [
	"Real window: the text of every Rubric segment (getText) is the text of its plan segment, last character included."

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdefghij' classFrom: 3 to: 5).
	self withRealWindowOf: presenter do: [ :window |
			self
				assert: (self textsOfSegmentsIn: presenter)
				equals: #( 'ab' 'cde' 'fghij' ) ]
]

{ #category : 'tests' }
MMCCoveragePresenterDecoratorIntervalTest >> testWholeTextSegmentGoesFromOneToSizePlusOne [

	| presenter |
	presenter := MMCCoveragePresenter on:
		             (self coverageOf: 'abcdefghij' classFrom: 1 to: 10).
	self assert: presenter decorators size equals: 1.
	self
		assert: presenter decorators first interval asArray
		equals: (1 to: 11) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterDecoratorIntervalTest >> textsOfSegmentsIn: aPresenter [
	"Texts (as strings) of the Rubric segment morphs of the built text area, sorted."

	^ ((aPresenter textPresenter adapter widget textArea segments
		    collect: [ :each | each getText asString ]) asSortedCollection: [
		   :a
		   :b | a <= b ]) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterDecoratorIntervalTest >> withRealWindowOf: aPresenter do: aBlock [
	"Skipped without World. Open aPresenter in a forked process (10 s guard: the test runner is never blocked longer), evaluate aBlock, then always close the window."

	| window semaphore timedOut openError |
	World ifNil: [ self skip: 'no world' ].
	semaphore := Semaphore new.
	openError := nil.
	[
		[
			[ window := aPresenter open ]
				on: Error
				do: [ :e | openError := e ] ] ensure: [ semaphore signal ] ] fork.
	[
		timedOut := semaphore waitTimeoutSeconds: 10.
		self
			deny: timedOut
			description: 'the window did not open within 10 seconds'.
		self
			assert: openError isNil
			description: 'open raised ' , openError printString.
		aBlock value: window ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ]
]
