"
Characterization tests of CodeCoverageAnalyzer: they pin the CURRENT behavior (before the refactoring). Some of them document KNOWN DEFECTS (basename substring matching, line granularity) and will have to be inverted when the analyzer is reworked.
"
Class {
	#name : 'CodeCoverageAnalyzerTest',
	#superclass : 'TestCase',
	#instVars : [
		'tempDir',
		'model',
		'analyzer'
	],
	#category : 'MooseModelCoverage-Tests',
	#package : 'MooseModelCoverage-Tests'
}

{ #category : 'helpers' }
CodeCoverageAnalyzerTest >> addEntity: anEntity file: aFile from: start to: end [

	| anchor |
	anchor := FamixJavaIndexedFileAnchor new
		          fileName: aFile fullName;
		          startPos: start;
		          endPos: end;
		          yourself.
	anEntity sourceAnchor: anchor.
	model add: anEntity.
	model add: anchor.
	^ anEntity
]

{ #category : 'helpers' }
CodeCoverageAnalyzerTest >> analyzeFile: aFile [

	analyzer loadModel: model file: aFile fullName.
	analyzer processAnchors
]

{ #category : 'helpers' }
CodeCoverageAnalyzerTest >> fiveLinesContents [
	"Line 1: aaaa (pos 1-4), line 2: bbbb (pos 6-9), line 3: empty, line 4: cccc (pos 12-15), line 5: dddd (pos 17-20)"

	^ 'aaaa' , String lf , 'bbbb' , String lf , String lf , 'cccc'
	  , String lf , 'dddd'
]

{ #category : 'helpers' }
CodeCoverageAnalyzerTest >> fiveLinesFile [

	^ self writeFile: 'a.txt' contents: self fiveLinesContents
]

{ #category : 'running' }
CodeCoverageAnalyzerTest >> setUp [

	super setUp.
	tempDir := FileLocator temp
	           / ('mmc-analyzer-test-' , UUID new asString).
	tempDir ensureCreateDirectory.
	model := MooseModel new.
	analyzer := CodeCoverageAnalyzer new
]

{ #category : 'running' }
CodeCoverageAnalyzerTest >> tearDown [

	tempDir ifNotNil: [ tempDir ensureDeleteAll ].
	super tearDown
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testAnchorBeyondFileEndIsClampedToLastLine [
	"Characterization (differs from what one might expect): positions past the end of the file are clamped by lineNumberCorrespondingToIndex:, so the anchor is NOT ignored and covers up to the last line."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaMethod new
		file: file
		from: 12
		to: 500.
	self analyzeFile: file.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 4 5 )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testAnchorOfAnotherFileIsIgnored [
	"Characterization: anchors of another file (different basename) are ignored."

	| file other |
	file := self fiveLinesFile.
	other := self writeFile: 'other.txt' contents: self fiveLinesContents.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self
		addEntity: FamixJavaMethod new
		file: other
		from: 12
		to: 15.
	self analyzeFile: file.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 1 )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testAnchorWithEndBeforeStartIsIgnored [
	"Characterization: an anchor whose endLine < startLine is filtered out by processAnchors (startPos 12 is on line 4, endPos 9 on line 2)."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self
		addEntity: FamixJavaMethod new
		file: file
		from: 12
		to: 9.
	self analyzeFile: file.
	self assert: analyzer coveredLines asArray equals: #( 1 )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testCoveragePercentageFullCoverage [
	"Characterization: full coverage gives 100.00."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 20.
	self analyzeFile: file.
	self assert: analyzer coveragePercentage equals: '100.00'
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testCoveragePercentageIsTwoDecimalsString [
	"Characterization: coveragePercentage answers a String with 2 decimals, empty lines counting in the denominator."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 9.
	self analyzeFile: file.
	self assert: analyzer coveragePercentage isString.
	self assert: analyzer coveragePercentage equals: '40.00'
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testCoveragePercentageWithoutAnyCoverage [
	"Characterization: with no covered line the percentage is 0.00."

	analyzer loadModel: model file: self fiveLinesFile fullName.
	self assert: analyzer coveragePercentage equals: '0.00'
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testCoveredLines [
	"Characterization: every line from startLine to endLine of an anchor is covered; others are not."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 6
		to: 15.
	self analyzeFile: file.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 2 3 4 )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testEntitiesForLineIsEmptyForUncoveredLine [
	"Characterization: entitiesForLine: answers an empty collection for an uncovered line."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self analyzeFile: file.
	self assert: (analyzer entitiesForLine: 1) size equals: 1.
	self assert: (analyzer entitiesForLine: 5) isEmpty
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testEntityTypesCollectClassNames [
	"Characterization: entityTypes holds the class names of the covering entities, without duplicates."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self
		addEntity: FamixJavaMethod new
		file: file
		from: 6
		to: 9.
	self
		addEntity: FamixJavaMethod new
		file: file
		from: 12
		to: 15.
	self analyzeFile: file.
	self
		assert: analyzer entityTypes asSortedCollection asArray
		equals: #( FamixJavaClass FamixJavaMethod )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testKnownDefectBasenameSubstringMatchesOtherFile [
	"Characterization of a KNOWN DEFECT: files are matched by basename as a substring, so an anchor of data.txt is counted for a.txt. To be inverted after the refactoring (expected: only line 1)."

	| file other |
	file := self fiveLinesFile.
	other := self writeFile: 'data.txt' contents: self fiveLinesContents.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self
		addEntity: FamixJavaMethod new
		file: other
		from: 12
		to: 15.
	self analyzeFile: file.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 1 4 )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLineGranularityPartialLineMarksWholeLineCovered [
	"Characterization: coverage is per LINE. An entity covering only characters 2-3 of line 1 marks the whole line covered. The future target is character granularity, so this test will have to change."

	| file info |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 2
		to: 3.
	self analyzeFile: file.
	self assert: analyzer coveredLines asArray equals: #( 1 ).
	info := (analyzer entitiesForLine: 1) first.
	self assert: (info at: #startPos) equals: 2.
	self assert: (info at: #endPos) equals: 3.
	self assert: analyzer coveragePercentage equals: '20.00'
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLinesForEntity [
	"Characterization: linesForEntity: answers all lines of the entity anchor."

	| file class method |
	file := self fiveLinesFile.
	class := self
		         addEntity: FamixJavaClass new
		         file: file
		         from: 1
		         to: 9.
	method := self
		          addEntity: FamixJavaMethod new
		          file: file
		          from: 12
		          to: 20.
	self analyzeFile: file.
	self
		assert: (analyzer linesForEntity: class) asSortedCollection asArray
		equals: #( 1 2 ).
	self
		assert: (analyzer linesForEntity: method) asSortedCollection asArray
		equals: #( 4 5 ).
	self assert: (analyzer linesForEntity: FamixJavaClass new) isEmpty
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLoadModelFileDoesNotResetCollectionsBetweenCalls [
	"Characterization of a known defect: loading a second file keeps the coverage collected for the first one. The future version should reset them."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self analyzeFile: file.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 1 ).
	analyzer
		loadModel: model
		file:
		(self writeFile: 'b.txt' contents: 'x' , String lf , 'y') fullName.
	self assert: analyzer totalLines equals: 2.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 1 ).
	self assert: analyzer entitiesPerLine size equals: 1
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLoadModelFileFailsOnEmptyFile [
	"Characterization: an empty file raises an error."

	| file |
	file := self writeFile: 'empty.txt' contents: ''.
	self
		should: [ analyzer loadModel: model file: file fullName ]
		raise: Error
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLoadModelFileFailsOnMissingFile [
	"Characterization: a missing file raises an error."

	self
		should: [
		analyzer loadModel: model file: (tempDir / 'missing.txt') fullName ]
		raise: Error
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLoadModelFileFailsWhenModelIsNil [
	"Characterization: a nil model is rejected when no model was loaded before."

	self
		should: [ analyzer loadModel: nil file: self fiveLinesFile fullName ]
		raise: Error
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testLoadModelFileReadsLinesAndSetsTotalLines [
	"Characterization: loadModel:file: reads the file and fixes sourceLines / totalLines / fileName."

	| file |
	file := self fiveLinesFile.
	analyzer loadModel: model file: file fullName.
	self assert: analyzer model equals: model.
	self assert: analyzer fileName equals: file fullName.
	self assert: analyzer totalLines equals: 5.
	self
		assert: analyzer sourceLines asArray
		equals: #( 'aaaa' 'bbbb' '' 'cccc' 'dddd' )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testOverlappingEntitiesAreAllListedOnSharedLine [
	"Characterization: nested / overlapping entities are all listed for a shared line."

	| file class method |
	file := self fiveLinesFile.
	class := self
		         addEntity: FamixJavaClass new
		         file: file
		         from: 1
		         to: 15.
	method := self
		          addEntity: FamixJavaMethod new
		          file: file
		          from: 6
		          to: 9.
	self analyzeFile: file.
	self assert: (analyzer entitiesForLine: 2) size equals: 2.
	self
		assert:
			((analyzer entitiesForLine: 2) collect: [ :info | info at: #entity ])
				asSet
		equals: {
				class.
				method } asSet.
	self assert: (analyzer entitiesForLine: 1) size equals: 1.
	self assert: (analyzer entitiesForLine: 4) size equals: 1
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testPartialCoverageForLine [
	"Characterization: 100.0 for a covered line, 0.0 otherwise (including the empty line 3)."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 4.
	self analyzeFile: file.
	self assert: (analyzer partialCoverageForLine: 1) equals: 100.0.
	self assert: (analyzer partialCoverageForLine: 2) equals: 0.0.
	self assert: (analyzer partialCoverageForLine: 3) equals: 0.0
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testProcessAnchorCoversAllLinesOfAnchor [
	"Characterization: processAnchor: fills coveredLines, entitiesPerLine (entity, className, startPos, endPos) and entityTypes."

	| file entity info |
	file := self fiveLinesFile.
	entity := self
		          addEntity: FamixJavaClass new
		          file: file
		          from: 6
		          to: 15.
	analyzer loadModel: model file: file fullName.
	analyzer processAnchor: entity sourceAnchor.
	self
		assert: analyzer coveredLines asSortedCollection asArray
		equals: #( 2 3 4 ).
	info := (analyzer entitiesForLine: 3) first.
	self assert: (info at: #entity) equals: entity.
	self assert: (info at: #className) equals: #FamixJavaClass.
	self assert: (info at: #startPos) equals: 6.
	self assert: (info at: #endPos) equals: 15.
	self assert: analyzer entityTypes asArray equals: #( FamixJavaClass )
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testProcessAnchorsFailsWhenFirstAnchorIsNotIndexedFileAnchor [
	"Characterization: the guard only inspects the first anchor and requires a class name ending with IndexedFileAnchor."

	analyzer loadModel: model file: self fiveLinesFile fullName.
	model add: FamixJavaSourceTextAnchor new.
	self should: [ analyzer processAnchors ] raise: Error
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testProcessAnchorsFailsWhenModelNotLoaded [
	"Characterization: processAnchors on a fresh analyzer raises an error."

	self should: [ analyzer processAnchors ] raise: Error
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testProcessAnchorsFailsWithoutAnyAnchor [
	"Characterization: a model without anchors raises an error."

	analyzer loadModel: model file: self fiveLinesFile fullName.
	self should: [ analyzer processAnchors ] raise: Error
]

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testUncoveredLinesAndEmptyLinesCountAsUncovered [
	"Characterization: uncoveredLines lists lines without entity; the empty line 3 is uncovered when no entity spans it."

	| file |
	file := self fiveLinesFile.
	self
		addEntity: FamixJavaClass new
		file: file
		from: 1
		to: 9.
	self
		addEntity: FamixJavaMethod new
		file: file
		from: 17
		to: 20.
	self analyzeFile: file.
	self assert: analyzer uncoveredLines asArray equals: #( 3 4 )
]

{ #category : 'helpers' }
CodeCoverageAnalyzerTest >> writeFile: aName contents: aString [
	"Write a real file in the temporary directory (anchors read the file from disk)."

	| file |
	file := tempDir / aName.
	file writeStreamDo: [ :stream | stream nextPutAll: aString ].
	^ file
]
