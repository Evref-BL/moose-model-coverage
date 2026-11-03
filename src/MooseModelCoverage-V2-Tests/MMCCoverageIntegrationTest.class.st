Class {
	#name : 'MMCCoverageIntegrationTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> attributeNamed: aName on: aFileName from: start to: end [

	| entity |
	entity := FamixJavaAttribute new.
	entity name: aName.
	^ self
		  newEntity: entity
		  on: aFileName
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> classNamed: aName on: aFileName from: start to: end [

	| entity |
	entity := FamixJavaClass new.
	entity name: aName.
	^ self
		  newEntity: entity
		  on: aFileName
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> coverageOf: arg1 [

	^ MMCFileCoverage fromReadResult: (self readFile: arg1)
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> methodNamed: aName on: aFileName from: start to: end [

	| entity |
	entity := FamixJavaMethod new.
	entity name: aName.
	^ self
		  newEntity: entity
		  on: aFileName
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> newEntity: anEntity on: aFileName from: start to: end [
	"Add anEntity and an indexed anchor on aFileName (start to: end) to the model."

	| anchor |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anEntity.
	model add: anchor.
	anEntity sourceAnchor: anchor.
	^ anEntity
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> readFile: aFileName [
	"Read aFileName (relative to the fixture folder) with a canonical path matcher."

	^ (MMCAnchorReader
		   model: model
		   matcher: (MMCCanonicalPathMatcher forFile: folder / aFileName))
		  read
]

{ #category : 'running' }
MMCCoverageIntegrationTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-v2-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> sourceText [
	"Lines (LF terminated):
	1 'class A {' (1-9, LF 10)
	2 '  int x;' (11-18, LF 19)
	3 '  void m() {}' (20-32, LF 33)
	4 '}' (34, LF 35). 35 characters."

	^ 'class A {' , String lf , '  int x;' , String lf , '  void m() {}'
	  , String lf , '}' , String lf
]

{ #category : 'running' }
MMCCoverageIntegrationTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testCrLfFile [
	"f1 o2 o3 CR4 LF5 b6 a7 r8 CR9 LF10 with 'foo' covered: raw 3/10, significant 3/6, uncovered region 'bar' on line 2."

	| coverage regions |
	self
		writeText: 'foo' , String crlf , 'bar' , String crlf
		to: 'crlf.txt'.
	self
		classNamed: 'C'
		on: 'crlf.txt'
		from: 1
		to: 3.
	coverage := self coverageOf: 'crlf.txt'.
	self assert: coverage size equals: 10.
	self assert: (coverage coveredPercentage closeTo: 30.0).
	self assert: (coverage significantPercentage closeTo: 50.0).
	self assert: coverage lineCount equals: 2.
	regions := coverage uncoveredRegions.
	self assert: regions size equals: 1.
	self assert: regions first interval equals: (6 to: 8).
	self assert: regions first text equals: 'bar'.
	self assert: regions first startLine equals: 2
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testFileWithoutMatchedAnchorIsUnreadable [
	"Only b.txt has an anchor: a.txt has no readable coverage (nil percentages, no uncovered region)."

	| coverage |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'uvwxyz' to: 'b.txt'.
	self
		classNamed: 'B'
		on: 'b.txt'
		from: 1
		to: 3.
	coverage := self coverageOf: 'a.txt'.
	self deny: coverage isReadable.
	self assert: coverage size equals: 0.
	self assert: coverage coveredPercentage isNil.
	self assert: coverage significantPercentage isNil.
	self assert: coverage uncoveredRegions isEmpty.
	self assert: coverage otherFileAnchorCount equals: 1
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testIgnoredAnchorLeavesItsCharactersUncovered [
	"An anchor ending beyond the text is ignored by the reader, so it covers nothing: only 1-3 of 'abcdef' is covered."

	| coverage |
	self writeText: 'abcdef' to: 'a.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	self
		classNamed: 'Bad'
		on: 'a.txt'
		from: 4
		to: 99.
	coverage := self coverageOf: 'a.txt'.
	self assert: coverage ignoredAnchors size equals: 1.
	self assert: (coverage coveredPercentage closeTo: 50.0).
	self assert: coverage uncoveredRegions size equals: 1.
	self assert: coverage uncoveredRegions first text equals: 'def'
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testMultiByteFileIsMeasuredInCharacters [
	"'a', e acute, euro, emoji, 'z' (5 characters, 11 UTF-8 bytes) with 2-4 covered: 60 percent and two uncovered regions (a and z)."

	| text coverage regions |
	text := 'a' , (String
		         with: (Character value: 233)
		         with: (Character value: 8364)
		         with: (Character value: 128512)) , 'z'.
	self writeText: text to: 'u.txt'.
	self
		classNamed: 'U'
		on: 'u.txt'
		from: 2
		to: 4.
	coverage := self coverageOf: 'u.txt'.
	self assert: coverage size equals: 5.
	self assert: (coverage coveredPercentage closeTo: 60.0).
	self assert: (coverage significantPercentage closeTo: 60.0).
	regions := coverage uncoveredRegions.
	self
		assert: (regions collect: [ :each | each interval ]) asArray
		equals: {
				(1 to: 1).
				(5 to: 5) }.
	self
		assert: (regions collect: [ :each | each text ]) asArray
		equals: #( 'a' 'z' )
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testNestedAnchorsGiveLayers [
	"Class 1-34 containing method 22-32: depth 1, the method is the deepest region at 25, only the final line break stays uncovered (blank, so no uncovered region)."

	| coverage method |
	self writeText: self sourceText to: 'A.java'.
	self
		classNamed: 'A'
		on: 'A.java'
		from: 1
		to: 34.
	method := self
		          methodNamed: 'm'
		          on: 'A.java'
		          from: 22
		          to: 32.
	coverage := self coverageOf: 'A.java'.
	self assert: coverage maxDepth equals: 1.
	self assert: coverage typeNames asArray equals: #( 'Class' 'Method' ).
	self
		assert: (coverage deepestRegionAt: 25) entity
		identicalTo: method.
	self assert: (coverage entitiesAt: 25) size equals: 2.
	self assert:
		(coverage coveredPercentage closeTo: (34 / 35 * 100) asFloat).
	self assert: (coverage significantPercentage closeTo: 100.0).
	self assert: coverage uncoveredRegions isEmpty
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testPercentagesOfFlatAnchors [
	"Class 1-9, attribute 13-18, method 22-32 over the 35 characters of sourceText: 26 characters covered; 13 blanks of which 5 covered, so 21 of 22 significant characters covered."

	| coverage |
	self writeText: self sourceText to: 'A.java'.
	self
		classNamed: 'A'
		on: 'A.java'
		from: 1
		to: 9.
	self
		attributeNamed: 'x'
		on: 'A.java'
		from: 13
		to: 18.
	self
		methodNamed: 'm'
		on: 'A.java'
		from: 22
		to: 32.
	coverage := self coverageOf: 'A.java'.
	self assert: coverage size equals: 35.
	self assert: coverage regions size equals: 3.
	self assert:
		(coverage coveredPercentage closeTo: (26 / 35 * 100) asFloat).
	self assert:
		(coverage significantPercentage closeTo: (21 / 22 * 100) asFloat)
]

{ #category : 'tests' }
MMCCoverageIntegrationTest >> testUncoveredRegionsOfFlatAnchors [
	"Uncovered set 10-12, 19-21, 33-35: the first two are blank only, the last one is trimmed to the closing brace (34, line 4)."

	| regions |
	self writeText: self sourceText to: 'A.java'.
	self
		classNamed: 'A'
		on: 'A.java'
		from: 1
		to: 9.
	self
		attributeNamed: 'x'
		on: 'A.java'
		from: 13
		to: 18.
	self
		methodNamed: 'm'
		on: 'A.java'
		from: 22
		to: 32.
	regions := (self coverageOf: 'A.java') uncoveredRegions.
	self assert: regions size equals: 1.
	self assert: regions first interval equals: (34 to: 34).
	self assert: regions first text equals: '}'.
	self assert: regions first startLine equals: 4.
	self assert: regions first endLine equals: 4
]

{ #category : 'helpers' }
MMCCoverageIntegrationTest >> writeText: aString to: aFileName [
	"Write aString encoded in UTF-8 (no BOM) in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
