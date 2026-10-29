"
Immutable coverage model of one file: its text, the entity regions read from the anchors, and derived character sets, ratios, uncovered regions, region layers and line tables. Positions are 1-based character indices.
"
Class {
	#name : 'MMCFileCoverage',
	#superclass : 'Object',
	#instVars : [
		'readResult',
		'coveredSet',
		'blankSet',
		'depths',
		'lineStarts',
		'lineContentEnds',
		'lineBreakEnds'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCFileCoverage class >> fromReadResult: anMMCAnchorReadResult [

	^ self new
		  setReadResult: anMMCAnchorReadResult;
		  yourself
]

{ #category : 'private' }
MMCFileCoverage >> areSortedForSweep: aRegionArray [
	"Answer whether regions are ordered by increasing start, then decreasing end."

	2 to: aRegionArray size do: [ :i |
			| previous current |
			previous := (aRegionArray at: i - 1) interval.
			current := (aRegionArray at: i) interval.
			(previous first < current first or: [
				 previous first = current first and: [
					 previous last >= current last ] ]) ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'sets' }
MMCFileCoverage >> blankSet [
	"Answer the characters that are separators (spaces, tabs, line breaks)."

	^ self cachedBlankSet copy
]

{ #category : 'private' }
MMCFileCoverage >> buildLineTable [
	"Compute once the start, content end and break end of every line, in one pass. LF, CR and CRLF end a line."

	| aText starts contentEnds breakEnds start i breakEnd char limit |
	lineStarts ifNotNil: [ ^ self ].
	starts := OrderedCollection new.
	contentEnds := OrderedCollection new.
	breakEnds := OrderedCollection new.
	aText := self text.
	limit := self size.
	start := 1.
	i := 1.
	[ i <= limit ] whileTrue: [
			char := aText at: i.
			(char == Character lf or: [ char == Character cr ])
				ifTrue: [
						breakEnd := (char == Character cr and: [
							             i < limit and: [
								             (aText at: i + 1) == Character lf ] ])
							            ifTrue: [ i + 1 ]
							            ifFalse: [ i ].
						starts add: start.
						contentEnds add: i - 1.
						breakEnds add: breakEnd.
						start := breakEnd + 1.
						i := breakEnd + 1 ]
				ifFalse: [ i := i + 1 ] ].
	start <= limit ifTrue: [
			starts add: start.
			contentEnds add: limit.
			breakEnds add: limit ].
	lineContentEnds := contentEnds asArray.
	lineBreakEnds := breakEnds asArray.
	lineStarts := starts asArray
]

{ #category : 'private' }
MMCFileCoverage >> cachedBlankSet [
	"Answer the cached blank set (do not expose)."

	^ blankSet ifNil: [ blankSet := self computeBlankSet ]
]

{ #category : 'private' }
MMCFileCoverage >> cachedCoveredSet [
	"Answer the cached union of the region intervals (do not expose)."

	^ coveredSet ifNil: [ coveredSet := self computeCoveredSet ]
]

{ #category : 'private' }
MMCFileCoverage >> cachedDepths [
	"Answer the depth of each region, in the order of regions (cached, do not expose)."

	^ depths ifNil: [ depths := self computeDepths ]
]

{ #category : 'private' }
MMCFileCoverage >> computeBlankSet [
	"Collect the runs of separators in one pass over the text."

	| aText runs start |
	self isReadable ifFalse: [ ^ MMCIntervalSet new ].
	aText := self text.
	runs := OrderedCollection new.
	start := nil.
	1 to: aText size do: [ :i |
			(aText at: i) isSeparator
				ifTrue: [ start ifNil: [ start := i ] ]
				ifFalse: [
						start ifNotNil: [
								runs add: (start to: i - 1).
								start := nil ] ] ].
	start ifNotNil: [ runs add: (start to: aText size) ].
	^ MMCIntervalSet new
		  setRanges: runs;
		  yourself
]

{ #category : 'private' }
MMCFileCoverage >> computeCoveredSet [
	"Merge the sorted region intervals in one pass."

	| sorted merged last start stop |
	self isReadable ifFalse: [ ^ MMCIntervalSet new ].
	sorted := (self regions collect: [ :each | each interval ])
		          asSortedCollection: [ :a :b | a first <= b first ].
	merged := OrderedCollection new.
	sorted do: [ :each |
			start := each first max: 1.
			stop := each last min: self size.
			start <= stop ifTrue: [
					last := merged ifNotEmpty: [ merged last ] ifEmpty: [ nil ].
					(last notNil and: [ last last + 1 >= start ])
						ifTrue: [
						merged
							at: merged size
							put: (last first to: (last last max: stop)) ]
						ifFalse: [ merged add: (start to: stop) ] ] ].
	^ MMCIntervalSet new
		  setRanges: merged;
		  yourself
]

{ #category : 'private' }
MMCFileCoverage >> computeDepths [
	"Regions ordered by start then decreasing end allow a stack sweep; otherwise compare pairwise."

	| all result stack current |
	all := self regions.
	result := Array new: all size withAll: 0.
	(self areSortedForSweep: all) ifFalse: [
			1 to: all size do: [ :i |
					result at: i put: ((1 to: i - 1) count: [ :j |
							 self region: (all at: j) contains: (all at: i) ]) ].
			^ result ].
	stack := OrderedCollection new.
	1 to: all size do: [ :i |
			current := (all at: i) interval.
			[
				stack notEmpty and: [
					(all at: stack last) interval last < current first ] ]
				whileTrue: [ stack removeLast ].
			result
				at: i
				put:
				(stack count: [ :j | (all at: j) interval last >= current last ]).
			stack addLast: i ].
	^ result
]

{ #category : 'ratios' }
MMCFileCoverage >> coveredPercentage [
	"Answer the raw ratio as a Float percentage, or nil."

	^ self rawRatio ifNotNil: [ :ratio | (ratio * 100) asFloat ]
]

{ #category : 'sets' }
MMCFileCoverage >> coveredSet [
	"Answer the characters covered by at least one region."

	^ self cachedCoveredSet copy
]

{ #category : 'sets' }
MMCFileCoverage >> coveredSignificantSet [
	"Answer the covered characters that are not blank."

	^ self cachedCoveredSet difference: self cachedBlankSet
]

{ #category : 'layers' }
MMCFileCoverage >> deepestRegionAt: aPosition [
	"Answer the innermost region at aPosition, or nil."

	| all |
	all := self regionsAt: aPosition.
	^ all ifEmpty: [ nil ] ifNotEmpty: [ all last ]
]

{ #category : 'layers' }
MMCFileCoverage >> depthOf: aRegion [
	"Answer how many regions placed earlier in regions entirely contain aRegion."

	| index all |
	all := self regions.
	index := all identityIndexOf: aRegion.
	index > 0 ifTrue: [ ^ self cachedDepths at: index ].
	^ all count: [ :each | self region: each contains: aRegion ]
]

{ #category : 'layers' }
MMCFileCoverage >> entitiesAt: aPosition [
	"Answer the entities of the regions at aPosition, from the outermost to the innermost."

	^ (self regionsAt: aPosition) collect: [ :each | each entity ]
]

{ #category : 'accessing' }
MMCFileCoverage >> fileReference [

	^ readResult fileReference
]

{ #category : 'accessing' }
MMCFileCoverage >> ignoredAnchors [
	"Answer the matched anchors that gave no region."

	^ readResult ignoredAnchors
]

{ #category : 'layers' }
MMCFileCoverage >> isCovered: aPosition [
	"Answer whether a region contains aPosition."

	^ self cachedCoveredSet includes: aPosition
]

{ #category : 'accessing' }
MMCFileCoverage >> isReadable [
	"Answer whether the file text could be read."

	^ readResult isReadable
]

{ #category : 'lines' }
MMCFileCoverage >> lineCount [
	"Answer the number of lines (a final line break does not start a new line)."

	self buildLineTable.
	^ lineStarts size
]

{ #category : 'lines' }
MMCFileCoverage >> lineInterval: aLineNumber [
	"Answer the interval of the characters of the line without its line break (empty for an empty line), or nil when the line does not exist."

	self buildLineTable.
	(aLineNumber isInteger and: [
		 aLineNumber between: 1 and: lineStarts size ]) ifFalse: [ ^ nil ].
	^ (lineStarts at: aLineNumber) to: (lineContentEnds at: aLineNumber)
]

{ #category : 'lines' }
MMCFileCoverage >> lineOf: aPosition [
	"Answer the 1-based line holding the character at aPosition (a line break belongs to the line it ends), or nil outside the text."

	| low high mid ends |
	(aPosition isInteger and: [ aPosition between: 1 and: self size ])
		ifFalse: [ ^ nil ].
	self buildLineTable.
	ends := lineBreakEnds.
	low := 1.
	high := ends size.
	[ low < high ] whileTrue: [
			mid := low + high // 2.
			(ends at: mid) >= aPosition
				ifTrue: [ high := mid ]
				ifFalse: [ low := mid + 1 ] ].
	^ low
]

{ #category : 'layers' }
MMCFileCoverage >> maxDepth [
	"Answer the deepest nesting depth, 0 without region."

	^ self cachedDepths ifEmpty: [ 0 ] ifNotEmpty: [ :all | all max ]
]

{ #category : 'accessing' }
MMCFileCoverage >> otherFileAnchorCount [
	"Answer how many file anchors designate another file."

	^ readResult otherFileAnchorCount
]

{ #category : 'printing' }
MMCFileCoverage >> printOn: aStream [
	aStream nextPutAll: self class name; nextPut: $(.
	self fileReference ifNotNil: [ :f | aStream nextPutAll: f basename ].
	aStream nextPutAll: ' '; print: self size; nextPutAll: ' chars, '; print: self regions size; nextPutAll: ' regions)'
]

{ #category : 'ratios' }
MMCFileCoverage >> rawRatio [
	"Answer covered characters over all characters, or nil when there is no character."

	self size = 0 ifTrue: [ ^ nil ].
	^ self cachedCoveredSet size / self size
]

{ #category : 'private' }
MMCFileCoverage >> region: anOuterRegion contains: anInnerRegion [

	^ anOuterRegion interval first <= anInnerRegion interval first and: [
		  anOuterRegion interval last >= anInnerRegion interval last ]
]

{ #category : 'accessing' }
MMCFileCoverage >> regions [
	"Answer the entity regions, in the order of the read result."

	^ readResult regions
]

{ #category : 'layers' }
MMCFileCoverage >> regionsAt: aPosition [
	"Answer the regions containing aPosition, from the outermost to the innermost (order of regions)."

	(self cachedCoveredSet includes: aPosition) ifFalse: [ ^ #(  ) ].
	^ self regions select: [ :each | each interval includes: aPosition ]
]

{ #category : 'types' }
MMCFileCoverage >> regionsOfType: aTypeName [
	"Answer the regions of the given type name, in the order of regions."

	^ self regions select: [ :each | each typeName = aTypeName ]
]

{ #category : 'private' }
MMCFileCoverage >> setReadResult: anMMCAnchorReadResult [

	readResult := anMMCAnchorReadResult
]

{ #category : 'ratios' }
MMCFileCoverage >> significantPercentage [
	"Answer the significant ratio as a Float percentage, or nil."

	^ self significantRatio ifNotNil: [ :ratio | (ratio * 100) asFloat ]
]

{ #category : 'ratios' }
MMCFileCoverage >> significantRatio [
	"Answer covered significant characters over significant characters, or nil when there is none."

	| significantSize |
	significantSize := self size - self cachedBlankSet size.
	significantSize = 0 ifTrue: [ ^ nil ].
	^ self coveredSignificantSet size / significantSize
]

{ #category : 'sets' }
MMCFileCoverage >> significantSet [
	"Answer the characters that are not blank."

	^ self cachedBlankSet complementWithin: (1 to: self size)
]

{ #category : 'accessing' }
MMCFileCoverage >> size [
	"Answer the number of characters of the text (0 when unreadable)."

	^ self isReadable
		  ifTrue: [ self text size ]
		  ifFalse: [ 0 ]
]

{ #category : 'accessing' }
MMCFileCoverage >> text [
	"Answer the whole text of the file."

	^ readResult text
]

{ #category : 'lines' }
MMCFileCoverage >> textOfLine: aLineNumber [
	"Answer the text of the line without its line break, or nil when the line does not exist."

	| interval |
	interval := self lineInterval: aLineNumber.
	interval ifNil: [ ^ nil ].
	^ self text copyFrom: interval first to: interval last
]

{ #category : 'types' }
MMCFileCoverage >> typeNames [
	"Answer the sorted type names of the regions, without duplicate."

	^ (self regions collect: [ :each | each typeName ]) asSet
		  asSortedCollection asArray
]

{ #category : 'uncovered regions' }
MMCFileCoverage >> uncoveredRegions [
	"Answer the uncovered runs trimmed of leading and trailing blanks, in increasing order. Runs of blanks only are dropped."

	| aText result start stop |
	self isReadable ifFalse: [ ^ #(  ) ].
	aText := self text.
	result := OrderedCollection new.
	self uncoveredSet intervalsDo: [ :each |
			start := each first.
			stop := each last.
			[ start <= stop and: [ (aText at: start) isSeparator ] ]
				whileTrue: [ start := start + 1 ].
			[ stop >= start and: [ (aText at: stop) isSeparator ] ] whileTrue: [
				stop := stop - 1 ].
			start <= stop ifTrue: [
				result add:
					(MMCUncoveredRegion interval: (start to: stop) in: self) ] ].
	^ result asArray
]

{ #category : 'sets' }
MMCFileCoverage >> uncoveredSet [
	"Answer the characters covered by no region, blanks included."

	^ self cachedCoveredSet complementWithin: (1 to: self size)
]

{ #category : 'sets' }
MMCFileCoverage >> uncoveredSignificantSet [
	"Answer the uncovered characters that are not blank."

	^ self significantSet difference: self cachedCoveredSet
]
