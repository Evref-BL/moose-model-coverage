"
Tests of the coverage presenter when Famix types are hidden by the color scheme: the hidden types disappear from the tree of the model, from the highlights and from the percentages, the status and the summary say so, and nothing is computed again without reason.
"
Class {
	#name : 'MMCCoveragePresenterHiddenTypesTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'entities',
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'fixture' }
MMCCoveragePresenterHiddenTypesTest >> add: anEntityClass named: aName on: aFileName from: start to: end [
	"Add to the model an entity (kept in entities) with an indexed file anchor."

	| entity anchor |
	entity := anEntityClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor.
	entities at: aName put: entity.
	^ entity
]

{ #category : 'fixture' }
MMCCoveragePresenterHiddenTypesTest >> buildFixture [
	"a/A.java (100 chars) holds the method onlyInA (1-50). b/B.java (120 chars) holds the class ClassB (1-90) with the method methodB (10-40), that is 90 characters covered, 31 once the class is hidden. The types are Class and Method."

	self writeText: (String new: 100 withAll: $x) to: 'a/A.java'.
	self writeText: (String new: 120 withAll: $y) to: 'b/B.java'.
	self
		add: FamixJavaMethod
		named: 'onlyInA'
		on: 'a/A.java'
		from: 1
		to: 50.
	self
		add: FamixJavaClass
		named: 'ClassB'
		on: 'b/B.java'
		from: 1
		to: 90.
	self
		add: FamixJavaMethod
		named: 'methodB'
		on: 'b/B.java'
		from: 10
		to: 40
]

{ #category : 'fixture' }
MMCCoveragePresenterHiddenTypesTest >> newPresenterOnB [
	"A not opened presenter on the fixture, showing b/B.java; closed in tearDown."

	| presenter |
	self buildFixture.
	presenter := presenters add: (MMCCoveragePresenter forModel: model).
	presenter showFile: (presenter modelFiles files detect: [ :each |
			 each basename = 'B.java' ]).
	^ presenter
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> segmentsOfTypeNamed: aTypeName in: aPresenter [
	"The covered segments of the plan of the presenter that belong to the type."

	^ aPresenter plan segments select: [ :each |
		  each isUncovered not and: [ each typeName asString = aTypeName ] ]
]

{ #category : 'fixture' }
MMCCoveragePresenterHiddenTypesTest >> setUp [
	"A temporary folder, an empty FamixJava model rooted in it, no presenter."

	super setUp.
	folder := FileLocator temp
	          / ('mmc-hidden-presenter-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new
]

{ #category : 'fixture' }
MMCCoveragePresenterHiddenTypesTest >> tearDown [

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	MMCColorSchemeRegistry removeFor: model.
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testAColorChangeDoesNotComputeTheCoverageAgain [

	| presenter coverage files |
	presenter := self newPresenterOnB.
	presenter colorScheme hideType: 'Class'.
	coverage := presenter fileCoverage.
	files := presenter modelFiles.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	self assert: presenter fileCoverage == coverage.
	self assert: presenter modelFiles == files.
	self assert:
		(presenter modelFiles coverageFor: presenter currentFile)
		== coverage
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testApplyingTheSameHiddenTypesDoesNotComputeTheCoverageAgain [

	| presenter coverage palette |
	presenter := self newPresenterOnB.
	presenter colorScheme hideType: 'Class'.
	coverage := presenter fileCoverage.
	palette := presenter palette.
	presenter applyColorScheme: presenter colorScheme.
	self assert: presenter fileCoverage == coverage.
	self deny: presenter palette == palette.
	self assert: presenter hiddenTypeCount equals: 1
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testColorsButtonIsLabelledSetting [

	| presenter |
	presenter := self newPresenterOnB.
	self assert: presenter colorsButton label equals: 'Setting'
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingATypeChangesThePercentage [

	| presenter |
	presenter := self newPresenterOnB.
	self assert: presenter fileCoverage coveredPercentage equals: 75.
	self assert: (presenter summaryText includesSubstring:
			 'Covered 90/120 characters (75.0 %)').
	presenter colorScheme hideType: 'Class'.
	self assert: presenter fileCoverage coveredSet size equals: 31.
	self assert: (presenter summaryText includesSubstring:
			 'Covered 31/120 characters (25.8 %)').
	self assert:
		(presenter globalSummaryText includesSubstring: 'covered 25.8%')
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingATypeGivesItsNameToTheFilesOfTheModel [

	| presenter |
	presenter := self newPresenterOnB.
	presenter colorScheme hideType: 'Class'.
	self
		assert: presenter modelFiles hiddenTypeNames
		equals: #( 'Class' ) asSet.
	self assert: presenter hiddenTypeCount equals: 1
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingATypeRemovesItFromTheModelTree [

	| presenter |
	presenter := self newPresenterOnB.
	self assert: (presenter navigator includes: (entities at: 'ClassB')).
	presenter colorScheme hideType: 'Class'.
	self deny: (presenter navigator includes: (entities at: 'ClassB')).
	self assert: (presenter navigator includes: (entities at: 'methodB')).
	self
		assert: presenter navigator hiddenTypeNames
		equals: #( 'Class' ) asSet
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingATypeRemovesItFromTheTreeOfTheWholeModelToo [

	| presenter |
	presenter := self newPresenterOnB.
	presenter treeFilter: #all.
	self assert: (presenter navigator includes: (entities at: 'ClassB')).
	presenter colorScheme hideType: 'Class'.
	self deny: (presenter navigator includes: (entities at: 'ClassB')).
	self assert: (presenter navigator includes: (entities at: 'methodB'))
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingATypeRemovesItsHighlightsAndKeepsTheOthers [

	| presenter decoratorsBefore |
	presenter := self newPresenterOnB.
	decoratorsBefore := presenter decorators size.
	self assert:
		(self segmentsOfTypeNamed: 'Class' in: presenter) isNotEmpty.
	self assert:
		(self segmentsOfTypeNamed: 'Method' in: presenter) isNotEmpty.
	presenter colorScheme hideType: 'Class'.
	self assert:
		(self segmentsOfTypeNamed: 'Class' in: presenter) isEmpty.
	self assert:
		(self segmentsOfTypeNamed: 'Method' in: presenter) isNotEmpty.
	self assert: presenter decorators size < decoratorsBefore.
	self
		assert: presenter decorators size
		equals: presenter plan segments size
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingAnAlreadyHiddenTypeChangesNothing [

	| presenter coverage |
	presenter := self newPresenterOnB.
	presenter colorScheme hideType: 'Class'.
	coverage := presenter fileCoverage.
	presenter colorScheme hideType: 'Class'.
	self assert: presenter fileCoverage == coverage
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testHidingEveryTypeShowsTheNoVisibleEntityStatus [

	| presenter |
	presenter := self newPresenterOnB.
	self assert: presenter treeStatusText equals: ''.
	presenter colorScheme hideAll: #( 'Class' 'Method' ).
	self assert:
		(presenter treeStatusText includesSubstring: 'No visible entity').
	self assert: presenter navigator roots isEmpty.
	self assert:
		(presenter plan segments allSatisfy: [ :each | each isUncovered ]).
	self assert: presenter fileCoverage coveredSet isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testNothingIsHiddenByDefault [

	| presenter |
	presenter := self newPresenterOnB.
	self assert: presenter hiddenTypeCount equals: 0.
	self assert: presenter modelFiles hiddenTypeNames isEmpty.
	self deny: (presenter summaryText includesSubstring: 'hidden').
	self assert: (presenter navigator includes: (entities at: 'ClassB'))
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testOtherFilesAreComputedAgainWhenTheyAreShown [

	| presenter other |
	presenter := self newPresenterOnB.
	other := presenter modelFiles files detect: [ :each |
		         each basename = 'A.java' ].
	presenter modelFiles coverageFor: other.
	self assert: presenter modelFiles globalSummary fileCount equals: 2.
	presenter colorScheme hideType: 'Class'.
	self assert: presenter modelFiles globalSummary fileCount equals: 1.
	presenter showFile: other.
	self assert: presenter modelFiles globalSummary fileCount equals: 2.
	self assert: (presenter summaryText endsWith: ' | 1 type(s) hidden')
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testShowingTheTypesAgainRestoresEverything [

	| presenter summary |
	presenter := self newPresenterOnB.
	summary := presenter summaryText.
	presenter colorScheme hideAll: #( 'Class' 'Method' ).
	presenter colorScheme showAll.
	self assert: presenter summaryText equals: summary.
	self assert: presenter treeStatusText equals: ''.
	self assert: presenter hiddenTypeCount equals: 0.
	self assert: (presenter navigator includes: (entities at: 'ClassB'))
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testSummaryEndsWithTheNumberOfHiddenTypes [

	| presenter |
	presenter := self newPresenterOnB.
	self deny: (presenter summaryText endsWith: 'hidden').
	presenter colorScheme hideType: 'Class'.
	self assert: (presenter summaryText endsWith: ' | 1 type(s) hidden').
	presenter colorScheme hideType: 'Method'.
	self assert: (presenter summaryText endsWith: ' | 2 type(s) hidden')
]

{ #category : 'tests' }
MMCCoveragePresenterHiddenTypesTest >> testTheSchemeOfTheModelIsTheOneThatHidesTheTypes [

	| presenter |
	presenter := self newPresenterOnB.
	(MMCColorSchemeRegistry for: model) hideType: 'Class'.
	self assert: presenter hiddenTypeCount equals: 1.
	self deny: (presenter navigator includes: (entities at: 'ClassB'))
]

{ #category : 'fixture' }
MMCCoveragePresenterHiddenTypesTest >> writeText: aString to: aRelativeName [

	| ref |
	ref := folder resolve: aRelativeName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
