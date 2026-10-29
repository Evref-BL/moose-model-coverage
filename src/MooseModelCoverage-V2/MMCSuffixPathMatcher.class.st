"
I match the anchors whose canonical path ends with a given suffix, compared by whole path segments.
"
Class {
	#name : 'MMCSuffixPathMatcher',
	#superclass : 'MMCFileMatcher',
	#instVars : [
		'segments'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCSuffixPathMatcher class >> forSuffix: aString [
	"Answer a matcher for the paths ending with aString, whole segments only."

	^ self new
		  suffix: aString;
		  yourself
]

{ #category : 'matching' }
MMCSuffixPathMatcher >> matchesAnchor: anAnchor [
	"Answer whether the trailing segments of the canonical path of anAnchor are the suffix segments."

	| file pathSegments |
	segments isEmpty ifTrue: [ ^ false ].
	file := self canonicalFileOf: anAnchor.
	file ifNil: [ ^ false ].
	pathSegments := file path segments.
	pathSegments size < segments size ifTrue: [ ^ false ].
	^ (pathSegments last: segments size) asArray = segments asArray
]

{ #category : 'matching' }
MMCSuffixPathMatcher >> suffix: aString [
	"Split aString on both / and \ separators; empty segments are dropped."

	segments := (aString substrings: '/\') asArray
]
