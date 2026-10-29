"
I am the immutable outcome of an MMCAnchorReader: file, whole text, entity regions, ignored anchors and number of anchors of other files.
"
Class {
	#name : 'MMCAnchorReadResult',
	#superclass : 'Object',
	#instVars : [
		'fileReference',
		'text',
		'regions',
		'ignoredAnchors',
		'otherFileAnchorCount'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCAnchorReadResult class >> fileReference: aFileReference text: aString regions: aRegionCollection ignoredAnchors: anIgnoredCollection otherFileAnchorCount: anInteger [

	^ self new
		  setFileReference: aFileReference
		  text: aString
		  regions: aRegionCollection
		  ignoredAnchors: anIgnoredCollection
		  otherFileAnchorCount: anInteger;
		  yourself
]

{ #category : 'accessing' }
MMCAnchorReadResult >> fileReference [
	"Answer the canonical file read, or nil when no anchor matched."

	^ fileReference
]

{ #category : 'accessing' }
MMCAnchorReadResult >> ignoredAnchors [
	"Answer the matched anchors that gave no region."

	^ ignoredAnchors copy
]

{ #category : 'accessing' }
MMCAnchorReadResult >> isReadable [
	"Answer whether the file text could be read."

	^ fileReference notNil and: [ text notEmpty ]
]

{ #category : 'accessing' }
MMCAnchorReadResult >> otherFileAnchorCount [
	"Answer how many file anchors designate another file."

	^ otherFileAnchorCount
]

{ #category : 'accessing' }
MMCAnchorReadResult >> regions [
	"Answer the regions, ordered by start then decreasing size."

	^ regions copy
]

{ #category : 'accessing' }
MMCAnchorReadResult >> setFileReference: aFileReference text: aString regions: aRegionCollection ignoredAnchors: anIgnoredCollection otherFileAnchorCount: anInteger [

	fileReference := aFileReference.
	text := aString.
	regions := aRegionCollection asArray.
	ignoredAnchors := anIgnoredCollection asArray.
	otherFileAnchorCount := anInteger
]

{ #category : 'accessing' }
MMCAnchorReadResult >> text [
	"Answer the whole text of the file ('' when unreadable)."

	^ text
]
