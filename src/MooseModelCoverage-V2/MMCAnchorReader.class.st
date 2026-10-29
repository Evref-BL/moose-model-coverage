"
I read the file designated by a matcher once and extract, for each matching indexed file anchor of a model, the text region of its entity. Invalid anchors are reported, never clamped.
"
Class {
	#name : 'MMCAnchorReader',
	#superclass : 'Object',
	#instVars : [
		'model',
		'matcher'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCAnchorReader class >> model: aModel matcher: aFileMatcher [
	"Answer a reader of the anchors of aModel selected by aFileMatcher."

	^ self new
		  setModel: aModel matcher: aFileMatcher;
		  yourself
]

{ #category : 'reading' }
MMCAnchorReader >> read [
	"Read the matched file once and answer an MMCAnchorReadResult.
	Only the anchors added to the model are seen. File anchors that do not match, or that designate a file other than the one read, are only counted. If several distinct files match, the one with the smallest path is read."

	| ignored matched inFile otherFileAnchorCount file text |
	ignored := OrderedCollection new.
	matched := OrderedCollection new.
	otherFileAnchorCount := 0.
	self sourceAnchorEntries do: [ :entry |
			entry key isFileAnchor
				ifFalse: [
						ignored add:
							(MMCIgnoredAnchor anchor: entry key reason: #notFileAnchor) ]
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
	"Answer the reason why anEntry gives no region, or nil when it is valid."

	| anchor start end |
	anchor := anEntry key.
	(anchor class usesTrait: FamixTIndexedFileNavigation) ifFalse: [
		^ #notIndexed ].
	start := anchor startPos.
	end := anchor endPos.
	(start isNil or: [ end isNil ]) ifTrue: [ ^ #nilPositions ].
	(start < 1 or: [ start > end ]) ifTrue: [ ^ #invalidPositions ].
	end > anInteger ifTrue: [ ^ #outOfBounds ].
	anEntry value ifNil: [ ^ #noElement ].
	^ nil
]

{ #category : 'private' }
MMCAnchorReader >> regionOf: anEntry in: aString [

	| anchor |
	anchor := anEntry key.
	^ MMCEntityRegion
		  entity: anEntry value
		  anchor: anchor
		  interval: (anchor startPos to: anchor endPos)
		  text: (aString copyFrom: anchor startPos to: anchor endPos)
]

{ #category : 'private' }
MMCAnchorReader >> regionsOf: anEntryCollection in: aString ignored: anIgnoredCollection [
	"Answer the sorted regions of valid entries; add the others to anIgnoredCollection with their reason."

	| regions |
	regions := OrderedCollection new.
	anEntryCollection do: [ :entry |
			| reason |
			reason := self reasonToIgnore: entry textSize: aString size.
			reason
				ifNil: [ regions add: (self regionOf: entry in: aString) ]
				ifNotNil: [
						anIgnoredCollection add:
							(MMCIgnoredAnchor anchor: entry key reason: reason) ] ].
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

{ #category : 'private' }
MMCAnchorReader >> setModel: aModel matcher: aFileMatcher [

	model := aModel.
	matcher := aFileMatcher
]

{ #category : 'private' }
MMCAnchorReader >> sourceAnchorEntries [
	"Answer associations anchor -> entity for the file-level anchors of the model; multiple anchors are unrolled."

	| seen entries |
	seen := IdentitySet new.
	entries := OrderedCollection new.
	(model allUsing: FamixTSourceAnchor) do: [ :anchor |
			anchor allSourceAnchors do: [ :leaf |
					(seen includes: leaf) ifFalse: [
							seen add: leaf.
							entries add: leaf -> (leaf element ifNil: [ anchor element ]) ] ] ].
	^ entries
]

{ #category : 'private' }
MMCAnchorReader >> textOf: anAnchor [
	"Answer the complete text of the file of anAnchor, read once; '' when the file is missing or empty."

	^ anAnchor sourcesAreReadable
		  ifTrue: [ anAnchor completeText ]
		  ifFalse: [ '' ]
]
