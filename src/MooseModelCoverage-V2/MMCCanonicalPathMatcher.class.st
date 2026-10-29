"
I match the anchors whose canonical file path equals a canonical target path. The target need not exist.
"
Class {
	#name : 'MMCCanonicalPathMatcher',
	#superclass : 'MMCFileMatcher',
	#instVars : [
		'target'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCCanonicalPathMatcher class >> forFile: aFileReferenceOrString [
	"Answer a matcher for the file aFileReferenceOrString (which need not exist)."

	^ self new
		  target: aFileReferenceOrString;
		  yourself
]

{ #category : 'matching' }
MMCCanonicalPathMatcher >> matchesAnchor: anAnchor [
	"Answer whether the canonical file of anAnchor is the target."

	^ (self canonicalFileOf: anAnchor) = target
]

{ #category : 'matching' }
MMCCanonicalPathMatcher >> target: aFileReference [

	target := aFileReference asFileReference canonicalize
]
