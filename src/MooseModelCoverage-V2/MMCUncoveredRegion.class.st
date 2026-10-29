"
A run of uncovered significant characters of a file coverage: a 1-based inclusive interval, trimmed of leading and trailing blanks.
"
Class {
	#name : 'MMCUncoveredRegion',
	#superclass : 'Object',
	#instVars : [
		'interval',
		'fileCoverage'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCUncoveredRegion class >> interval: anInterval in: aFileCoverage [

	^ self new
		  setInterval: anInterval fileCoverage: aFileCoverage;
		  yourself
]

{ #category : 'comparing' }
MMCUncoveredRegion >> = other [

	^ self == other or: [
			  other class == self class and: [
				  interval = other interval and: [ self text = other text ] ] ]
]

{ #category : 'accessing' }
MMCUncoveredRegion >> endLine [
	"Answer the line of the last character."

	^ fileCoverage lineOf: interval last
]

{ #category : 'comparing' }
MMCUncoveredRegion >> hash [

	^ interval hash bitXor: self text hash
]

{ #category : 'accessing' }
MMCUncoveredRegion >> interval [
	"Answer the 1-based inclusive interval of characters."

	^ interval
]

{ #category : 'printing' }
MMCUncoveredRegion >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: interval first;
		nextPut: $-;
		print: interval last;
		nextPut: $)
]

{ #category : 'initialization' }
MMCUncoveredRegion >> setInterval: anInterval fileCoverage: aFileCoverage [

	interval := anInterval.
	fileCoverage := aFileCoverage
]

{ #category : 'accessing' }
MMCUncoveredRegion >> size [
	"Answer the number of characters of the region."

	^ interval size
]

{ #category : 'accessing' }
MMCUncoveredRegion >> startLine [
	"Answer the line of the first character."

	^ fileCoverage lineOf: interval first
]

{ #category : 'accessing' }
MMCUncoveredRegion >> text [
	"Answer the characters of the region."

	^ fileCoverage text copyFrom: interval first to: interval last
]
