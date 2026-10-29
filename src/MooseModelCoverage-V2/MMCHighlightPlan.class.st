"
The ordered, disjoint highlight segments of a file coverage: deepest region per covered piece, plus the uncovered zones. Built by an event sweep in O(n log n).
"
Class {
	#name : 'MMCHighlightPlan',
	#superclass : 'Object',
	#instVars : [
		'fileCoverage',
		'segments'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCHighlightPlan class >> for: anMMCFileCoverage [

	^ self new
		  setFileCoverage: anMMCFileCoverage;
		  yourself
]

{ #category : 'initialization' }
MMCHighlightPlan >> buildSegments [
	"Sweep the clamped region bounds from left to right; a max-heap of region indexes (lazily purged) gives the last region of the order covering the current piece."

	| size regions starts ends order points heap pointer pieces result source indexOfRegion |
	result := OrderedCollection new.
	fileCoverage isReadable ifFalse: [ ^ result ].
	size := fileCoverage size.
	regions := fileCoverage regions.
	starts := Array new: regions size.
	ends := Array new: regions size.
	order := (1 to: regions size) select: [ :i |
			         | interval |
			         interval := (regions at: i) interval.
			         starts at: i put: (interval first max: 1).
			         ends at: i put: (interval last min: size).
			         (starts at: i) <= (ends at: i) ].
	order := order asArray sort: [ :a :b |
		         (starts at: a) <= (starts at: b) ].
	points := Set new.
	order do: [ :i |
			points
				add: (starts at: i);
				add: (ends at: i) + 1 ].
	points := points asArray sort.
	heap := Heap sortBlock: [ :a :b | a >= b ].
	pointer := 1.
	pieces := OrderedCollection new.
	1 to: points size - 1 do: [ :k |
			| position winner region last |
			position := points at: k.
			[
				pointer <= order size and: [
					(starts at: (order at: pointer)) = position ] ] whileTrue: [
					heap add: (order at: pointer).
					pointer := pointer + 1 ].
			[ heap notEmpty and: [ (ends at: heap first) < position ] ]
				whileTrue: [ heap removeFirst ].
			heap isEmpty ifFalse: [
					winner := heap first.
					region := regions at: winner.
					last := pieces isEmpty
						        ifTrue: [ nil ]
						        ifFalse: [ pieces last ].
					(last notNil and: [
						 last second + 1 = position and: [ last third == region ] ])
						ifTrue: [ last at: 2 put: (points at: k + 1) - 1 ]
						ifFalse: [
								pieces add: {
										position.
										((points at: k + 1) - 1).
										region } ] ] ].
	source := fileCoverage text.
	indexOfRegion := IdentityDictionary new.
	regions doWithIndex: [ :each :i |
		indexOfRegion at: each ifAbsentPut: [ i ] ].
	pieces do: [ :piece |
			result add: ((MMCHighlightSegment
					  interval: (piece first to: piece second)
					  region: piece third
					  depth:
						  (fileCoverage cachedDepths at: (indexOfRegion at: piece third)))
					 setSource: source;
					 yourself) ].
	fileCoverage uncoveredRegions do: [ :zone |
			result add:
				((MMCHighlightSegment uncoveredInterval: zone interval)
					 setSource: source;
					 yourself) ].
	^ result asArray
		  sort: [ :a :b | a interval first <= b interval first ];
		  yourself
]

{ #category : 'accessing' }
MMCHighlightPlan >> coveredSegments [

	^ (segments reject: [ :each | each isUncovered ]) asOrderedCollection
]

{ #category : 'accessing' }
MMCHighlightPlan >> fileCoverage [

	^ fileCoverage
]

{ #category : 'accessing' }
MMCHighlightPlan >> isEmpty [

	^ segments isEmpty
]

{ #category : 'accessing' }
MMCHighlightPlan >> segmentAt: aPosition [
	"Answer the segment holding aPosition, nil when none (blank between segments or outside the text)."

	| low high mid segment |
	(aPosition isInteger and: [ segments notEmpty ]) ifFalse: [ ^ nil ].
	low := 1.
	high := segments size.
	[ low <= high ] whileTrue: [
			mid := low + high // 2.
			segment := segments at: mid.
			aPosition < segment interval first
				ifTrue: [ high := mid - 1 ]
				ifFalse: [
						aPosition > segment interval last
							ifTrue: [ low := mid + 1 ]
							ifFalse: [ ^ segment ] ] ].
	^ nil
]

{ #category : 'accessing' }
MMCHighlightPlan >> segments [
	"Answer a fresh collection of the segments, in increasing order."

	^ OrderedCollection withAll: segments
]

{ #category : 'initialization' }
MMCHighlightPlan >> setFileCoverage: aFileCoverage [

	fileCoverage := aFileCoverage.
	segments := self buildSegments asArray
]

{ #category : 'accessing' }
MMCHighlightPlan >> size [

	^ segments size
]

{ #category : 'accessing' }
MMCHighlightPlan >> uncoveredSegments [

	^ (segments select: [ :each | each isUncovered ]) asOrderedCollection
]
