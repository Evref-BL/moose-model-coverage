"
I decide whether a file anchor designates the file of interest. Subclasses redefine matchesAnchor:.
"
Class {
	#name : 'MMCFileMatcher',
	#superclass : 'Object',
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'matching' }
MMCFileMatcher >> canonicalFileOf: anAnchor [
	"Answer the canonical file reference of a file anchor, or nil when it names no file."

	anAnchor fileName ifNil: [ ^ nil ].
	^ anAnchor fileReference canonicalize
]

{ #category : 'matching' }
MMCFileMatcher >> matchesAnchor: anAnchor [
	"Answer whether anAnchor designates the file of interest."

	^ self subclassResponsibility
]
