"
I am a set of character intervals. Positions are 1-based and intervals are INCLUSIVE on both ends (1 to: 3 covers characters 1, 2 and 3). Zero and negative positions are accepted to model positions outside a file.
I am always normalized: intervals are sorted and non-empty, and intervals that overlap OR are adjacent are merged (1-3 and 4-6 become 1-6), while a gap of one character keeps them apart (1-3 and 5-6).
Set operations (union:, intersection:, difference:, complementWithin:, clampedTo:) answer a new instance and leave the receiver unchanged. Internally I keep a sorted OrderedCollection of Intervals with step 1.
"
Class {
	#name : 'MMCIntervalSet',
	#superclass : 'Object',
	#instVars : [
		'ranges'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCIntervalSet class >> withAll: aCollectionOfIntervals [
	"Answer a set containing all the given intervals."

	| set |
	set := self new.
	aCollectionOfIntervals do: [ :each | set add: each ].
	^ set
]

{ #category : 'comparing' }
MMCIntervalSet >> = other [

	^ self == other or: [
		  other class == self class and: [ ranges = other intervals ] ]
]

{ #category : 'adding' }
MMCIntervalSet >> add: anInterval [
	"Add an increasing, non-empty interval (step 1). Answer the receiver."

	(anInterval isEmpty or: [ anInterval increment ~= 1 ]) ifTrue: [
			^ self error:
				  'Only non-empty increasing intervals with step 1 can be added: '
				  , anInterval printString ].
	^ self addFrom: anInterval first to: anInterval last
]

{ #category : 'adding' }
MMCIntervalSet >> addFrom: start to: stop [
	"Add the characters from start to stop, both inclusive. Answer the receiver."

	| newStart newStop result inserted |
	stop < start ifTrue: [
			^ self error:
				  'Stop must be greater than or equal to start: '
				  , start printString , '-' , stop printString ].
	newStart := start.
	newStop := stop.
	inserted := false.
	result := OrderedCollection new: ranges size + 1.
	ranges do: [ :each |
			each last + 1 < newStart
				ifTrue: [ result add: each ]
				ifFalse: [
						each first - 1 > newStop
							ifTrue: [
									inserted ifFalse: [
											result add: (newStart to: newStop).
											inserted := true ].
									result add: each ]
							ifFalse: [
									newStart := newStart min: each first.
									newStop := newStop max: each last ] ] ].
	inserted ifFalse: [ result add: (newStart to: newStop) ].
	ranges := result
]

{ #category : 'private' }
MMCIntervalSet >> append: start to: stop in: aCollection [
	"Append start-stop at the end of the sorted collection, merging with the last interval when overlapping or adjacent."

	| last |
	aCollection isEmpty ifFalse: [
			last := aCollection last.
			last last + 1 >= start ifTrue: [
					aCollection removeLast.
					^ aCollection add: (last first to: (last last max: stop)) ] ].
	^ aCollection add: (start to: stop)
]

{ #category : 'set operations' }
MMCIntervalSet >> clampedTo: anInterval [
	"Answer a new set restricted to the inclusive bounds anInterval."

	^ self intersection: (self class withAll: (anInterval isEmpty
				    ifTrue: [ #(  ) ]
				    ifFalse: [ { (anInterval first to: anInterval last) } ]))
]

{ #category : 'set operations' }
MMCIntervalSet >> complementWithin: anInterval [
	"Answer a new set of the characters of anInterval that the receiver does not cover."

	| whole |
	anInterval isEmpty ifTrue: [ ^ self class new ].
	whole := self class new
		         addFrom: anInterval first to: anInterval last;
		         yourself.
	^ whole difference: self
]

{ #category : 'copying' }
MMCIntervalSet >> copy [
	"Answer an independent copy (Intervals are immutable and shared)."

	^ self class new
		  setRanges: ranges copy;
		  yourself
]

{ #category : 'set operations' }
MMCIntervalSet >> difference: another [
	"Answer a new set covering the characters of the receiver that are absent from the argument."

	| result j theirs current other done |
	theirs := another intervals.
	result := OrderedCollection new.
	j := 1.
	ranges do: [ :range |
			current := range first.
			[ j <= theirs size and: [ (theirs at: j) last < current ] ]
				whileTrue: [ j := j + 1 ].
			done := false.
			[
				done not and: [
					j <= theirs size and: [ (theirs at: j) first <= range last ] ] ]
				whileTrue: [
						other := theirs at: j.
						other first > current ifTrue: [
							result add: (current to: other first - 1) ].
						current := other last + 1.
						other last > range last
							ifTrue: [ done := true ]
							ifFalse: [ j := j + 1 ] ].
			current <= range last ifTrue: [
				result add: (current to: range last) ] ].
	^ self class new
		  setRanges: result;
		  yourself
]

{ #category : 'comparing' }
MMCIntervalSet >> hash [

	^ ranges
		  inject: self class hash
		  into: [ :h :each |
		  (h bitXor: each first hash) * 31 bitXor: each last hash ]
]

{ #category : 'testing' }
MMCIntervalSet >> includes: aPosition [
	"Answer whether the character at aPosition is covered (binary search)."

	^ (self rangeContaining: aPosition) notNil
]

{ #category : 'testing' }
MMCIntervalSet >> includesInterval: anInterval [
	"Answer whether every character of anInterval is covered. Normalization guarantees a single range must contain it."

	| range |
	anInterval isEmpty ifTrue: [ ^ true ].
	range := self rangeContaining: anInterval first.
	^ range notNil and: [ range last >= anInterval last ]
]

{ #category : 'initialization' }
MMCIntervalSet >> initialize [

	super initialize.
	ranges := OrderedCollection new
]

{ #category : 'set operations' }
MMCIntervalSet >> intersection: another [
	"Answer a new set covering the characters present in both the receiver and the argument."

	| result i j mine theirs low high |
	mine := ranges.
	theirs := another intervals.
	result := OrderedCollection new.
	i := 1.
	j := 1.
	[ i <= mine size and: [ j <= theirs size ] ] whileTrue: [
			low := (mine at: i) first max: (theirs at: j) first.
			high := (mine at: i) last min: (theirs at: j) last.
			low <= high ifTrue: [ result add: (low to: high) ].
			(mine at: i) last < (theirs at: j) last
				ifTrue: [ i := i + 1 ]
				ifFalse: [ j := j + 1 ] ].
	^ self class new
		  setRanges: result;
		  yourself
]

{ #category : 'accessing' }
MMCIntervalSet >> intervalCount [
	"Answer the number of disjoint intervals."

	^ ranges size
]

{ #category : 'accessing' }
MMCIntervalSet >> intervals [
	"Answer a copy of the sorted normalized intervals."

	^ ranges copy
]

{ #category : 'enumerating' }
MMCIntervalSet >> intervalsDo: aBlock [
	"Evaluate aBlock on each interval, in increasing order."

	ranges do: aBlock
]

{ #category : 'testing' }
MMCIntervalSet >> isEmpty [

	^ ranges isEmpty
]

{ #category : 'testing' }
MMCIntervalSet >> notEmpty [

	^ ranges notEmpty
]

{ #category : 'printing' }
MMCIntervalSet >> printOn: aStream [
	"Print as MMCIntervalSet(1-3, 6-8)."

	aStream
		nextPutAll: self class name;
		nextPut: $(.
	ranges
		do: [ :each |
				aStream
					print: each first;
					nextPut: $-;
					print: each last ]
		separatedBy: [ aStream nextPutAll: ', ' ].
	aStream nextPut: $)
]

{ #category : 'private' }
MMCIntervalSet >> rangeContaining: aPosition [
	"Answer the interval containing aPosition, or nil."

	| low high mid range |
	low := 1.
	high := ranges size.
	[ low <= high ] whileTrue: [
			mid := low + high // 2.
			range := ranges at: mid.
			aPosition < range first
				ifTrue: [ high := mid - 1 ]
				ifFalse: [
						aPosition > range last
							ifTrue: [ low := mid + 1 ]
							ifFalse: [ ^ range ] ] ].
	^ nil
]

{ #category : 'private' }
MMCIntervalSet >> setRanges: aSortedNormalizedCollection [

	ranges := aSortedNormalizedCollection
]

{ #category : 'accessing' }
MMCIntervalSet >> size [
	"Answer the number of characters covered."

	^ ranges inject: 0 into: [ :sum :each | sum + each size ]
]

{ #category : 'set operations' }
MMCIntervalSet >> union: another [
	"Answer a new set covering the characters of the receiver or of the argument."

	| result i j mine theirs next |
	mine := ranges.
	theirs := another intervals.
	result := OrderedCollection new.
	i := 1.
	j := 1.
	[ i <= mine size or: [ j <= theirs size ] ] whileTrue: [
			(j > theirs size or: [
				 i <= mine size and: [ (mine at: i) first <= (theirs at: j) first ] ])
				ifTrue: [
						next := mine at: i.
						i := i + 1 ]
				ifFalse: [
						next := theirs at: j.
						j := j + 1 ].
			self append: next first to: next last in: result ].
	^ self class new
		  setRanges: result;
		  yourself
]
