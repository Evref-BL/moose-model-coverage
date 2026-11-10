"
I read the file designated by a matcher once and extract, for each matching indexed file anchor of a model, the text region of its entity. Invalid anchors are reported, never clamped. Without pre-computed entries I scan the model; with model:file:entries:otherFileAnchorCount: I only use the given entries (see MMCModelFiles), so no scan is done.
"
Class {
	#name : 'MMCAnchorReader',
	#superclass : 'Object',
	#instVars : [
		'model',
		'matcher',
		'presetEntries',
		'presetOtherFileAnchorCount',
		'astralText',
		'astralStarts',
		'hiddenTypeNames',
		'typeNamesByClass'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCAnchorReader class >> model: aModel file: aFile entries: aCollection otherFileAnchorCount: anInteger [
	"Answer a reader of aFile that does not scan aModel: aCollection holds the anchor -> entity associations to consider (those of aFile and the non file anchors), anInteger the number of file anchors of other files."

	^ (self
		   model: aModel
		   matcher: (MMCCanonicalPathMatcher forFile: aFile))
		  setEntries: aCollection otherFileAnchorCount: anInteger;
		  yourself
]

{ #category : 'instance creation' }
MMCAnchorReader class >> model: aModel matcher: aFileMatcher [
	"Answer a reader of the anchors of aModel selected by aFileMatcher."

	^ self new
		  setModel: aModel matcher: aFileMatcher;
		  yourself
]

{ #category : 'instance creation' }
MMCAnchorReader class >> sourceAnchorEntriesOf: aModel [
	"Answer the anchor -> entity associations of aModel, deduplicated by anchor, scanning the model once."

	^ (self model: aModel matcher: nil) sourceAnchorEntries
]

{ #category : 'private' }
MMCAnchorReader >> characterIndexOfUtf16: anInteger [
	"Answer the index of the character containing the UTF-16 unit anInteger (1-based). The text must have been prepared."

	| low high mid |
	astralStarts isEmpty ifTrue: [ ^ anInteger ].
	low := 0.
	high := astralStarts size.
	[ low < high ] whileTrue: [
			mid := low + high + 1 // 2.
			(astralStarts at: mid) < anInteger
				ifTrue: [ low := mid ]
				ifFalse: [ high := mid - 1 ] ].
	^ anInteger - low
]

{ #category : 'accessing' }
MMCAnchorReader >> hiddenTypeNames [
	"Answer the type names (see MMCTypeName) whose entities are ignored silently; empty by default."

	^ hiddenTypeNames ifNil: [ hiddenTypeNames := Set new ]
]

{ #category : 'accessing' }
MMCAnchorReader >> hiddenTypeNames: aTypeNameCollection [
	"Ignore silently the entries whose entity has one of these type names: they give no region and are not reported as ignored anchors. They are still used to find the file and its text."

	hiddenTypeNames := Set withAll: aTypeNameCollection
]

{ #category : 'accessing' }
MMCAnchorReader >> isHiddenEntry: anEntry [
	"Answer true when the entity of anEntry has a hidden type. An entry without entity is never hidden."

	| entity |
	self hiddenTypeNames isEmpty ifTrue: [ ^ false ].
	entity := anEntry value.
	entity ifNil: [ ^ false ].
	typeNamesByClass ifNil: [ typeNamesByClass := IdentityDictionary new ].
	^ hiddenTypeNames includes: (typeNamesByClass
			   at: entity class
			   ifAbsentPut: [ MMCTypeName ofClass: entity class ])
]

{ #category : 'private' }
MMCAnchorReader >> prepareAstralStartsFor: aString [
	"Compute once per text the UTF-16 start positions (1-based) of its astral characters. Empty when the text has none."

	| extra starts |
	astralText == aString ifTrue: [ ^ self ].
	astralText := aString.
	astralStarts := #(  ).
	aString isByteString ifTrue: [ ^ self ].
	extra := 0.
	starts := nil.
	1 to: aString size do: [ :i |
			(aString at: i) codePoint > 16rFFFF ifTrue: [
					starts ifNil: [ starts := OrderedCollection new ].
					starts add: i + extra.
					extra := extra + 1 ] ].
	starts ifNotNil: [ astralStarts := starts asArray ]
]

{ #category : 'reading' }
MMCAnchorReader >> read [
	"Read the matched file once and answer an MMCAnchorReadResult.
	Only the anchors added to the model are seen. File anchors that do not match, or that designate a file other than the one read, are only counted. If several distinct files match, the one with the smallest path is read. The non file anchors of a hidden type (see hiddenTypeNames:) are not reported as ignored, and the entries of a hidden type give no region; they still count to find the file and its text."

	| ignored matched inFile otherFileAnchorCount file text |
	ignored := OrderedCollection new.
	matched := OrderedCollection new.
	otherFileAnchorCount := presetOtherFileAnchorCount ifNil: [ 0 ].
	self sourceAnchorEntries do: [ :entry |
			entry key isFileAnchor
				ifFalse: [
						(self isHiddenEntry: entry) ifFalse: [
								ignored add:
									(MMCIgnoredAnchor anchor: entry key reason: #notFileAnchor) ] ]
				ifTrue: [
						(matcher matchesAnchor: entry key)
							ifTrue: [ matched add: entry ]
							ifFalse: [ otherFileAnchorCount := otherFileAnchorCount + 1 ] ] ].
	matched ifEmpty: [
			^ self
				  resultFile: nil
				  text: ''
				  regions: #(  )
				  ignored: ignored
				  otherFileAnchorCount: otherFileAnchorCount ].
	file := (matched collect: [ :entry |
		         matcher canonicalFileOf: entry key ]) detectMin: [ :each |
		        each pathString ].
	inFile := matched select: [ :entry |
		          (matcher canonicalFileOf: entry key) = file ].
	otherFileAnchorCount := otherFileAnchorCount + matched size
	                        - inFile size.
	text := self textOf: inFile first key.
	text ifEmpty: [
			inFile do: [ :entry |
					ignored add:
						(MMCIgnoredAnchor anchor: entry key reason: #unreadableFile) ].
			^ self
				  resultFile: file
				  text: ''
				  regions: #(  )
				  ignored: ignored
				  otherFileAnchorCount: otherFileAnchorCount ].
	^ self
		  resultFile: file
		  text: text
		  regions: (self regionsOf: inFile in: text ignored: ignored)
		  ignored: ignored
		  otherFileAnchorCount: otherFileAnchorCount
]

{ #category : 'private' }
MMCAnchorReader >> reasonToIgnore: anEntry textSize: anInteger [
	"Answer the reason why anEntry gives no region, or nil when it is valid. anInteger is the number of characters of the text prepared by prepareAstralStartsFor:; the anchor positions are compared to its UTF-16 length."

	| anchor start end |
	anchor := anEntry key.
	(anchor class usesTrait: FamixTIndexedFileNavigation) ifFalse: [
		^ #notIndexed ].
	start := anchor startPos.
	end := anchor endPos.
	(start isNil or: [ end isNil ]) ifTrue: [ ^ #nilPositions ].
	(start < 1 or: [ start > end ]) ifTrue: [ ^ #invalidPositions ].
	end > (anInteger + astralStarts size) ifTrue: [ ^ #outOfBounds ].
	anEntry value ifNil: [ ^ #noElement ].
	^ nil
]

{ #category : 'private' }
MMCAnchorReader >> regionOf: anEntry in: aString [
	"Anchor positions are UTF-16 units; convert them to character indexes of aString."

	| anchor start end |
	anchor := anEntry key.
	self prepareAstralStartsFor: aString.
	start := self characterIndexOfUtf16: anchor startPos.
	end := self characterIndexOfUtf16: anchor endPos.
	^ MMCEntityRegion
		  entity: anEntry value
		  anchor: anchor
		  interval: (start to: end)
		  text: (aString copyFrom: start to: end)
]

{ #category : 'private' }
MMCAnchorReader >> regionsOf: anEntryCollection in: aString ignored: anIgnoredCollection [
	"Answer the sorted regions of valid entries; add the others to anIgnoredCollection with their reason. The entries of a hidden type are skipped silently: no region and no ignored anchor."

	| regions textSize |
	self prepareAstralStartsFor: aString.
	textSize := aString size.
	regions := OrderedCollection new.
	anEntryCollection do: [ :entry |
			| reason |
			(self isHiddenEntry: entry) ifFalse: [
					reason := self reasonToIgnore: entry textSize: textSize.
					reason
						ifNil: [ regions add: (self regionOf: entry in: aString) ]
						ifNotNil: [
								anIgnoredCollection add:
									(MMCIgnoredAnchor anchor: entry key reason: reason) ] ] ].
	^ regions asArray sort: [ :a :b |
			  a interval first ~= b interval first
				  ifTrue: [ a interval first < b interval first ]
				  ifFalse: [
						  a size ~= b size
							  ifTrue: [ a size > b size ]
							  ifFalse: [ a entity printString <= b entity printString ] ] ]
]

{ #category : 'private' }
MMCAnchorReader >> resultFile: aFile text: aString regions: aRegionCollection ignored: anIgnoredCollection otherFileAnchorCount: anInteger [

	^ MMCAnchorReadResult
		  fileReference: aFile
		  text: aString
		  regions: aRegionCollection
		  ignoredAnchors: anIgnoredCollection
		  otherFileAnchorCount: anInteger
]

{ #category : 'reading' }
MMCAnchorReader >> setEntries: aCollection otherFileAnchorCount: anInteger [
	"Use aCollection of anchor -> entity associations instead of scanning the model; anInteger file anchors designating other files are added to the count of those seen in aCollection."

	presetEntries := aCollection.
	presetOtherFileAnchorCount := anInteger
]

{ #category : 'private' }
MMCAnchorReader >> setModel: aModel matcher: aFileMatcher [

	model := aModel.
	matcher := aFileMatcher
]

{ #category : 'reading' }
MMCAnchorReader >> sourceAnchorEntries [
	"Answer associations anchor -> entity for the file-level anchors of the model; multiple anchors are unrolled. When the reader was given pre-computed entries, answer them without scanning the model.
	A leaf of a multiple anchor may be visited before its multiple anchor, when it has no entity yet: the entity is then completed when the multiple anchor is visited."

	| seen entries |
	presetEntries ifNotNil: [ :preset | ^ preset ].
	seen := IdentityDictionary new.
	entries := OrderedCollection new.
	(model allUsing: FamixTSourceAnchor) do: [ :anchor |
			anchor allSourceAnchors do: [ :leaf |
					| entity entry |
					entity := leaf element ifNil: [ anchor element ].
					entry := seen at: leaf ifAbsent: [ nil ].
					entry
						ifNil: [
								entry := leaf -> entity.
								seen at: leaf put: entry.
								entries add: entry ]
						ifNotNil: [ entry value ifNil: [ entry value: entity ] ] ] ].
	^ entries
]

{ #category : 'private' }
MMCAnchorReader >> textOf: anAnchor [
	"Answer the complete text of the file of anAnchor, read once; '' when the file is missing or empty."

	^ anAnchor sourcesAreReadable
		  ifTrue: [ anAnchor completeText ]
		  ifFalse: [ '' ]
]

{ #category : 'private' }
MMCAnchorReader >> utf16Length: aString [
	"Answer the length of aString in UTF-16 units (the unit of FileAnchor positions)."

	self prepareAstralStartsFor: aString.
	^ aString size + astralStarts size
]
