"
I am the inventory of the source files of a Moose model, built in one pass over its source anchors (file names only, no file text is read): canonical absolute files sorted by name relative to the model root folder, entities of each file, files of each entity, number of anchors that are not file anchors, readability of each file. I also compute the coverage (MMCFileCoverage) of a file on demand and cache it; globalSummary aggregates the files computed so far. Use on: to create me; invalidate drops the cached coverages and keeps the inventory. The inventory also keeps the entries of each file and the non file entries, so coverageFor: gives them to MMCAnchorReader (model:file:entries:otherFileAnchorCount:) and never rescans the model.
"
Class {
	#name : 'MMCModelFiles',
	#superclass : 'Object',
	#instVars : [
		'model',
		'rootSegments',
		'files',
		'entitiesByFile',
		'filesByEntity',
		'ignoredAnchorCount',
		'coverages',
		'entriesByFile',
		'nonFileEntries',
		'fileAnchorCount'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCModelFiles class >> on: aModel [
	"Answer the file inventory of aModel. No file text is read."

	^ self new
		  setModel: aModel;
		  yourself
]

{ #category : 'private' }
MMCModelFiles >> buildInventory [
	"One pass over the source anchors (shared with MMCAnchorReader, which completes the entity of a leaf visited before its multiple anchor); only file names are used, no text is read."

	| byName matcher |
	byName := OrderedDictionary new.
	(MMCAnchorReader sourceAnchorEntriesOf: model) do: [ :entry |
			entry key isFileAnchor
				ifFalse: [
						ignoredAnchorCount := ignoredAnchorCount + 1.
						nonFileEntries add: entry ]
				ifTrue: [
						fileAnchorCount := fileAnchorCount + 1.
						entry key fileName ifNotNil: [ :name |
							(byName at: name ifAbsentPut: [ OrderedCollection new ]) add:
								entry ] ] ].
	matcher := MMCCanonicalPathMatcher new.
	byName do: [ :entries |
			(matcher canonicalFileOf: entries first key) ifNotNil: [ :file |
				self registerFile: file entries: entries ] ].
	files := entitiesByFile keys asArray sorted: [ :a :b |
			         (self relativeNameOf: a) asLowercase
			         <= (self relativeNameOf: b) asLowercase ]
]

{ #category : 'coverage' }
MMCModelFiles >> computeAll [
	"Compute the coverage of every file, readable or not."

	files do: [ :each | self coverageFor: each ]
]

{ #category : 'initialization' }
MMCModelFiles >> computeRootSegments [

	rootSegments := model rootFolder ifNotNil: [ :root |
		                root asFileReference canonicalize path segments
			                asArray ]
]

{ #category : 'private' }
MMCModelFiles >> coverageFor: aFile [
	"Answer the MMCFileCoverage of aFile, computed on first request then cached. Only the entries of aFile gathered by the inventory are used: the model is not scanned again."

	^ coverages at: aFile ifAbsentPut: [
			  | fileEntries |
			  fileEntries := entriesByFile at: aFile ifAbsent: [ #(  ) ].
			  MMCFileCoverage fromReadResult: (MMCAnchorReader
					   model: model
					   file: aFile
					   entries: nonFileEntries , fileEntries
					   otherFileAnchorCount: fileAnchorCount - fileEntries size) read ]
]

{ #category : 'accessing' }
MMCModelFiles >> entitiesIn: aFile [
	"Answer the unique entities anchored in aFile, empty when aFile is unknown."

	^ entitiesByFile at: aFile ifAbsent: [ OrderedCollection new ]
]

{ #category : 'accessing' }
MMCModelFiles >> fileCount [

	^ files size
]

{ #category : 'accessing' }
MMCModelFiles >> fileOf: anEntity [
	"Answer the first file of anEntity, nil when it has none."

	^ (self filesOf: anEntity)
		  ifEmpty: [ nil ]
		  ifNotEmpty: [ :all | all first ]
]

{ #category : 'accessing' }
MMCModelFiles >> files [
	"Answer the canonical absolute files, sorted by relative name ignoring case."

	^ files
]

{ #category : 'accessing' }
MMCModelFiles >> filesOf: anEntity [
	"Answer the files of anEntity, empty when it has none."

	^ filesByEntity at: anEntity ifAbsent: [ OrderedCollection new ]
]

{ #category : 'coverage' }
MMCModelFiles >> globalSummary [
	"Answer the aggregate of the files whose coverage is computed."

	| size covered |
	size := 0.
	covered := 0.
	coverages do: [ :each |
			size := size + each size.
			covered := covered + each coveredSet size ].
	^ MMCCoverageSummary
		  fileCount: coverages size
		  size: size
		  coveredSize: covered
]

{ #category : 'accessing' }
MMCModelFiles >> ignoredAnchorCount [
	"Answer the number of anchors of the model that are not file anchors."

	^ ignoredAnchorCount
]

{ #category : 'coverage' }
MMCModelFiles >> invalidate [
	"Drop the cached coverages; the inventory is kept."

	coverages := Dictionary new
]

{ #category : 'accessing' }
MMCModelFiles >> isReadable: aFile [
	"Answer whether aFile exists on disk and is not empty."

	^ aFile isFile and: [ aFile size > 0 ]
]

{ #category : 'private' }
MMCModelFiles >> registerFile: aFile entries: entries [

	| entities fileEntries |
	entities := entitiesByFile
		            at: aFile
		            ifAbsentPut: [ OrderedCollection new ].
	fileEntries := entriesByFile
		               at: aFile
		               ifAbsentPut: [ OrderedCollection new ].
	fileEntries addAll: entries.
	entries do: [ :entry |
			entry value ifNotNil: [ :entity |
					| entityFiles |
					(entities identityIncludes: entity) ifFalse: [
						entities add: entity ].
					entityFiles := filesByEntity
						               at: entity
						               ifAbsentPut: [ OrderedCollection new ].
					(entityFiles includes: aFile) ifFalse: [ entityFiles add: aFile ] ] ]
]

{ #category : 'accessing' }
MMCModelFiles >> relativeNameOf: aFile [
	"Answer the name of aFile relative to the model root folder, with / separators; its absolute path when outside the root folder."

	| segments |
	segments := aFile path segments asArray.
	(rootSegments notNil and: [
			 segments size > rootSegments size and: [
				 (segments first: rootSegments size) = rootSegments asArray ] ])
		ifFalse: [ ^ aFile pathString ].
	^ '/' join: (segments allButFirst: rootSegments size)
]

{ #category : 'private' }
MMCModelFiles >> setModel: aModel [

	model := aModel.
	coverages := Dictionary new.
	entitiesByFile := Dictionary new.
	entriesByFile := Dictionary new.
	nonFileEntries := OrderedCollection new.
	filesByEntity := IdentityDictionary new.
	ignoredAnchorCount := 0.
	fileAnchorCount := 0.
	self computeRootSegments.
	self buildInventory
]

{ #category : 'coverage' }
MMCModelFiles >> summaryFor: aFile [
	"Answer the cached coverage of aFile, nil while not computed."

	^ coverages at: aFile ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MMCModelFiles >> unreadableFiles [

	^ files reject: [ :each | self isReadable: each ]
]
