"
I check that MMCAnchorReader keeps the entity of the regions of a multiple file anchor (FamixTest1MultipleFileAnchor) whose leaf anchors are indexed in the model, whatever the order in which the model lists the leaves and the multiple anchor. Read-only checks on a file written in a temporary folder.
"
Class {
	#name : 'MMCAnchorReaderMultipleAnchorTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'entity',
		'multiple'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'running' }
MMCAnchorReaderMultipleAnchorTest >> leafFrom: start to: end [

	| leaf |
	leaf := FamixTest1IndexedFileAnchor new.
	leaf fileName: 'A.txt'.
	leaf startPos: start.
	leaf endPos: end.
	^ leaf
]

{ #category : 'running' }
MMCAnchorReaderMultipleAnchorTest >> linkMultipleOver: leaves [

	multiple := FamixTest1MultipleFileAnchor new.
	multiple fileAnchors: leaves asOrderedCollection.
	entity sourceAnchor: multiple
]

{ #category : 'running' }
MMCAnchorReaderMultipleAnchorTest >> readResult [

	^ (MMCAnchorReader
		   model: model
		   matcher: (MMCCanonicalPathMatcher forFile:
				    (folder / 'A.txt') asFileReference canonicalize)) read
]

{ #category : 'running' }
MMCAnchorReaderMultipleAnchorTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-multi-' , UUID new asString).
	folder ensureCreateDirectory.
	folder / 'A.txt' writeStreamDo: [ :stream |
		stream nextPutAll: '0123456789ABCDEFGHIJ' ].
	model := FamixTest1Model new.
	model rootFolder: folder asFileReference.
	entity := FamixTest1Class new.
	entity name: 'C1'.
	model add: entity
]

{ #category : 'running' }
MMCAnchorReaderMultipleAnchorTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCAnchorReaderMultipleAnchorTest >> testMultipleAnchorKeepsEntityWhenLeavesAreIndexedInTheModel [
	"Reported defect. The model lists the leaves of a multiple anchor before the multiple anchor itself (whatever the order of the add: calls). MMCAnchorReader>>sourceAnchorEntries meets each leaf with a nil element and memorizes it, so the entity is lost: expected 2 regions on the entity, none is built and both leaves are ignored as #noElement."

	| first second result |
	first := self leafFrom: 1 to: 10.
	second := self leafFrom: 11 to: 20.
	self linkMultipleOver: {
			first.
			second }.
	model add: first.
	model add: second.
	model add: multiple.
	result := self readResult.
	self assert: result regions size equals: 2.
	self assert:
		(result regions allSatisfy: [ :region | region entity == entity ]).
	self assert: result ignoredAnchors isEmpty
]
