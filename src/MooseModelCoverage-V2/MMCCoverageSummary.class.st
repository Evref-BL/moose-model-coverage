"
I am an immutable aggregate of the coverage of several files: number of files, total number of characters, number of covered characters, and the covered percentage (nil when there is no character).
"
Class {
	#name : 'MMCCoverageSummary',
	#superclass : 'Object',
	#instVars : [
		'fileCount',
		'size',
		'coveredSize'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCCoverageSummary class >> fileCount: aFileCount size: aSize coveredSize: aCoveredSize [

	^ self new
		  setFileCount: aFileCount size: aSize coveredSize: aCoveredSize;
		  yourself
]

{ #category : 'accessing' }
MMCCoverageSummary >> coveredPercentage [
	"Answer the percentage of covered characters, nil when there is no character."

	size = 0 ifTrue: [ ^ nil ].
	^ coveredSize * 100.0 / size
]

{ #category : 'accessing' }
MMCCoverageSummary >> coveredSize [

	^ coveredSize
]

{ #category : 'accessing' }
MMCCoverageSummary >> fileCount [

	^ fileCount
]

{ #category : 'accessing' }
MMCCoverageSummary >> setFileCount: aFileCount size: aSize coveredSize: aCoveredSize [

	fileCount := aFileCount.
	size := aSize.
	coveredSize := aCoveredSize
]

{ #category : 'accessing' }
MMCCoverageSummary >> size [

	^ size
]
