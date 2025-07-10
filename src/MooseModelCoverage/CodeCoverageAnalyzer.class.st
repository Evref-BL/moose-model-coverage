Class {
	#name : 'CodeCoverageAnalyzer',
	#superclass : 'Object',
	#instVars : [
		'model',
		'fileName',
		'sourceLines',
		'entitiesPerLine',
		'coveredLines',
		'totalLines',
		'entityTypes'
	],
	#category : 'MooseModelCoverage',
	#package : 'MooseModelCoverage'
}

{ #category : 'actions' }
CodeCoverageAnalyzer class >> example [
    ^ self runCoverageForModel: (MooseModel root at: 1)
        file: 'C:\Users\mea.belhadj\Documents\comparision\todo-list-java\src\main\java\com\example\todolist\Main.java'

]

{ #category : 'actions' }
CodeCoverageAnalyzer class >> runCoverageForModel: aMooseModel file: aFileName [
	| analyzer ui |
	analyzer := CodeCoverageAnalyzer basicNew initialize.
	analyzer loadModel: aMooseModel file: aFileName.
	analyzer processAnchors.
	ui := CoverageUIBuilder new initializeWithAnalyzer: analyzer.
	ui open.
	^ ui
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> coveragePercentage [
	| total covered percentage |
	total := totalLines max: 1.
	covered := coveredLines size min: total.
	percentage := (covered / total asFloat) * 100. "Use asFloat to avoid Fraction"
	^ percentage printShowingDecimalPlaces: 2
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> coveredLines [
    ^ coveredLines
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> entitiesForLine: lineNumber [
    ^ entitiesPerLine at: lineNumber ifAbsent: [ OrderedCollection new ]
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> entitiesPerLine [
    ^ entitiesPerLine
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> entityTypes [
	^ entityTypes
	
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> fileName [
    ^ fileName
]

{ #category : 'initialization' }
CodeCoverageAnalyzer >> initialize [
    super initialize.
    entitiesPerLine := Dictionary new.
    coveredLines := Set new.
    entityTypes := Set new.
]

{ #category : 'querying' }
CodeCoverageAnalyzer >> linesForEntity: anEntity [
	^ entitiesPerLine keys select: [ :line |
		(entitiesPerLine at: line) anySatisfy: [ :info | (info at: #entity) = anEntity ] ]
]

{ #category : 'loading' }
CodeCoverageAnalyzer >> loadModel: aMooseModel file: aFileName [
	(model isNil and: [ aMooseModel isNil ]) ifTrue: [ 
		self error: 'Moose model is required' ].
	model := aMooseModel.
	fileName := aFileName asFileReference fullName.
	sourceLines := fileName asFileReference exists
		ifTrue: [ fileName asFileReference contents lines ]
		ifFalse: [ self error: 'Source file ', aFileName, ' does not exist' ].
	totalLines := sourceLines size.
	totalLines = 0 ifTrue: [ self error: 'Source file is empty' ].
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> model [
    ^ model
]

{ #category : 'querying' }
CodeCoverageAnalyzer >> partialCoverageForLine: lineNumber [
	| entitiesForLine lineLength |
	entitiesForLine := self entitiesForLine: lineNumber.
	lineLength := (sourceLines at: lineNumber ifAbsent: [ '' ]) size.
	entitiesForLine ifNotEmpty: [ ^ 100.0 ].
	(lineLength = 0) ifTrue: [
		entitiesPerLine keysAndValuesDo: [ :line :entities |
			entities do: [ :info |
				| startLine endLine className |
				startLine := info at: #startLine ifAbsent: [ line ].
				endLine := info at: #endLine ifAbsent: [ startLine ].
				className := info at: #className ifAbsent: [ 'Unknown' ].
				((startLine <= lineNumber) and: [ lineNumber <= endLine ]) ifTrue: [
					(#('FamixTypeScriptClass' 'FamixTypeScriptModule') includes: className) ifTrue: [
						^ 100.0 ] ] ] ] ].
	^ 0.0
]

{ #category : 'processing' }
CodeCoverageAnalyzer >> processAnchor: anchor [
	| startLine endLine entity entityInfo |
	startLine := anchor startLine ifNil: [ ^ self ].
	endLine := (anchor endLine ifNil: [ ^ self ]) min: totalLines.
	entity := anchor element.
	"entity ifNil: [ ^ self ]."
	(startLine < 1 or: [ endLine < startLine or: [ endLine > totalLines ] ]) ifTrue: [ ^ self ].
	entityInfo := Dictionary new
		at: #entity put: entity;
		at: #className put: (entity class name ifNil: ['Unknown']);
		at: #startPos put: (anchor startPos ifNil: [ 1 ]);
		at: #endPos put: (anchor endPos ifNil: [ (sourceLines at: endLine ifAbsent: [ '' ]) size ]);
		yourself.
		
	entityTypes add: entity class name.
	(startLine to: endLine) do: [ :line |
		(entitiesPerLine at: line ifAbsentPut: [ OrderedCollection new ]) add: entityInfo.
		coveredLines add: line ].
]

{ #category : 'processing' }
CodeCoverageAnalyzer >> processAnchors [
    | anchors indexedFileAnchorClass |
    
    model ifNil: [ self error: 'Model not loaded' ].
    
    "Get all source anchors and find the IndexedFileAnchor type that's actually in the model"
    indexedFileAnchorClass := (model allUsing: FamixTSourceAnchor) 
        detect: [ :anchor | anchor class name asString endsWith: 'IndexedFileAnchor' ]
        ifFound: [ :anchor | anchor class ]
        ifNone: [ self error: 'No IndexedFileAnchor found in model' ].
    
    "Now get all anchors of that type"
    anchors := model allWithType: indexedFileAnchorClass.
    
    "Rest of the filtering logic stays the same"
    anchors := anchors select: [ :anchor |
        | matchesFile anchorPath fileBaseName |
        anchorPath := anchor fileName ifNil: [ '' ].
        fileBaseName := fileName asFileReference basename.
        anchorPath := anchorPath replaceAll: $\ with: $/.
        fileBaseName := fileBaseName replaceAll: $\ with: $/.
        matchesFile := anchorPath = fileName or: [ 
            anchorPath = fileBaseName or: [ 
                anchorPath includesSubstring: fileBaseName ] ].
        matchesFile and: [
            anchor startLine notNil and: [
                anchor endLine notNil and: [
                    anchor startLine >= 1 and: [
                        anchor endLine >= anchor startLine and: [
                            anchor endLine <= totalLines ] ] ] ] ] ].
    
    anchors ifEmpty: [ ^ self ].
    anchors do: [ :anchor | self processAnchor: anchor ].
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> sourceLines [
    ^ sourceLines
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> totalLines [
    ^ totalLines
]

{ #category : 'accessing' }
CodeCoverageAnalyzer >> uncoveredLines [
    ^ (1 to: totalLines) reject: [ :i | coveredLines includes: i ]
]
