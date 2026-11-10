"
A contiguous run of characters to highlight: either covered by an entity region (with its nesting depth) or an uncovered zone.
"
Class {
	#name : 'MMCHighlightSegment',
	#superclass : 'Object',
	#instVars : [
		'interval',
		'region',
		'depth',
		'source'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCHighlightSegment class >> interval: anInterval region: aRegion depth: anInteger [

	^ self new setInterval: anInterval region: aRegion depth: anInteger
]

{ #category : 'instance creation' }
MMCHighlightSegment class >> uncoveredInterval: anInterval [

	^ self new setInterval: anInterval region: nil depth: nil
]

{ #category : 'testing' }
MMCHighlightSegment >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	^ self class == anObject class and: [
			  interval = anObject interval and: [
				  region == anObject region and: [ depth = anObject depth ] ] ]
]

{ #category : 'accessing' }
MMCHighlightSegment >> depth [
	"Answer the nesting depth of the region, nil when uncovered."

	^ depth
]

{ #category : 'testing' }
MMCHighlightSegment >> hash [

	^ (interval hash bitXor: region identityHash) bitXor: depth hash
]

{ #category : 'accessing' }
MMCHighlightSegment >> interval [
	"Answer the first to last positions of the segment."

	^ interval
]

{ #category : 'testing' }
MMCHighlightSegment >> isUncovered [

	^ region isNil
]

{ #category : 'printing' }
MMCHighlightSegment >> printOn: aStream [

	aStream
		nextPutAll: 'Segment(';
		print: interval first;
		nextPutAll: '-';
		print: interval last;
		nextPutAll: ' '.
	self isUncovered
		ifTrue: [ aStream nextPutAll: 'uncovered' ]
		ifFalse: [
				aStream
					nextPutAll: self typeName printString;
					nextPutAll: ' depth ';
					print: depth ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
MMCHighlightSegment >> region [
	"Answer the entity region of the segment, nil when uncovered."

	^ region
]

{ #category : 'initialization' }
MMCHighlightSegment >> setInterval: anInterval region: aRegion depth: anInteger [

	interval := anInterval first to: anInterval last.
	region := aRegion.
	depth := anInteger
]

{ #category : 'initialization' }
MMCHighlightSegment >> setSource: aText [
	"Private. Share the whole file text to answer text lazily."

	source := aText
]

{ #category : 'accessing' }
MMCHighlightSegment >> size [

	^ interval size
]

{ #category : 'accessing' }
MMCHighlightSegment >> text [
	"Answer the substring of the file text of the segment, nil when the segment was built without a text."

	^ source ifNotNil: [ :aText |
		  aText copyFrom: interval first to: interval last ]
]

{ #category : 'accessing' }
MMCHighlightSegment >> typeName [
	"Answer the type name of the region, nil when uncovered."

	^ region ifNotNil: [ :aRegion | aRegion typeName ]
]
