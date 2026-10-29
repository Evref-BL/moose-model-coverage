"
I am a matched anchor that produced no region, with the reason why (a Symbol).
"
Class {
	#name : 'MMCIgnoredAnchor',
	#superclass : 'Object',
	#instVars : [
		'anchor',
		'reason'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCIgnoredAnchor class >> anchor: anAnchor reason: aSymbol [

	^ self new
		  setAnchor: anAnchor reason: aSymbol;
		  yourself
]

{ #category : 'accessing' }
MMCIgnoredAnchor >> anchor [

	^ anchor
]

{ #category : 'accessing' }
MMCIgnoredAnchor >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: reason;
		nextPutAll: ' ';
		print: anchor;
		nextPut: $)
]

{ #category : 'accessing' }
MMCIgnoredAnchor >> reason [
	"Answer a Symbol: #notFileAnchor #notIndexed #nilPositions #invalidPositions #outOfBounds #noElement or #unreadableFile."

	^ reason
]

{ #category : 'accessing' }
MMCIgnoredAnchor >> setAnchor: anAnchor reason: aSymbol [

	anchor := anAnchor.
	reason := aSymbol
]
