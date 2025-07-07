Class {
	#name : 'CoverageUIBuilder',
	#superclass : 'SpPresenter',
	#instVars : [
		'analyzer',
		'codeText',
		'entityList',
		'detailsText',
		'filterDropList',
		'uncoverButton',
		'summaryLabel',
		'table',
		'isInitialized'
	],
	#category : 'MooseModelCoverage',
	#package : 'MooseModelCoverage'
}

{ #category : 'instance creation' }
CoverageUIBuilder class >> withAnalyzer: aCodeCoverageAnalyzer [
	^ self new
		analyzer: aCodeCoverageAnalyzer;
		yourself.

]

{ #category : 'accessing' }
CoverageUIBuilder >> analyzer: aCodeCoverageAnalyzer [
	analyzer := aCodeCoverageAnalyzer.
	Transcript show: 'analyzer: set analyzer: ', analyzer printString; cr.
	self initializePresenters.
]

{ #category : 'private' }
CoverageUIBuilder >> buildTableData [
	^ self buildTableDataForFilter: 'All'
]

{ #category : 'private' }
CoverageUIBuilder >> buildTableDataForFilter: filter [
    | data |
    Transcript show: 'Starting buildTableDataForFilter: ', filter printString; cr.
    analyzer ifNil: [ 
        Transcript show: 'Error: Analyzer is nil in buildTableDataForFilter:'; cr.
        ^ OrderedCollection new ].
    analyzer totalLines ifNil: [ 
        Transcript show: 'Error: Analyzer totalLines is nil. Ensure loadModel:file: is called.'; cr.
        ^ OrderedCollection new ].
    data := OrderedCollection new.
    1 to: analyzer totalLines do: [ :i |
        | source coverage entities include partialCoverage |
        Transcript show: 'Processing line ', i printString; cr.
        source := analyzer sourceLines at: i ifAbsent: [ '' ].
        Transcript show: 'Source for line ', i printString, ': ', source; cr.
        partialCoverage := analyzer partialCoverageForLine: i.
        Transcript show: 'Partial coverage for line ', i printString, ': ', partialCoverage printString; cr.
        coverage := (analyzer coveredLines includes: i)
            ifTrue: [ 
                | percentage |
                percentage := partialCoverage isNumber
                    ifTrue: [ partialCoverage printShowingDecimalPlaces: 2 ]
                    ifFalse: [ '0.00' ].
                Transcript show: 'Coverage percentage for line ', i printString, ': ', percentage; cr.
                'Yes (', percentage, '%)' ]
            ifFalse: [ 'No' ].
        entities := self entityTypesForLine: i.
        Transcript show: 'Entities for line ', i printString, ': ', entities; cr.
        include := false.
        filter = 'All' ifTrue: [ include := true ].
        filter = 'Uncovered' ifTrue: [ include := (analyzer coveredLines includes: i) not ].
        (filter ~= 'All' and: [filter ~= 'Uncovered']) ifTrue: [
            include := (analyzer entitiesForLine: i) anySatisfy: [ :info | 
                | className |
                className := info at: #className.
                Transcript show: 'Checking filter: ', filter, ' against className: ', className; cr.
                className = filter ] ].
        include ifTrue: [
            | row |
            row := { i printString. source. coverage. entities }.
            Transcript show: 'Adding row for line ', i printString, ': ', row printString; cr.
            data add: row ] ].
    Transcript show: 'Table data built, rows: ', data size printString; cr.
    ^ data
]

{ #category : 'initialization' }
CoverageUIBuilder >> connectPresenters [
	filterDropList whenSelectedItemChangedDo: [ :item |
		table items: (self buildTableDataForFilter: item) ].
	
	table whenSelectedItemChangedDo: [ :row |
		row ifNotNil: [
			| lineNumber entities |
			lineNumber := row first asNumber.
			entities := analyzer entitiesForLine: lineNumber.
			detailsText text: (self detailsForLine: lineNumber entities: entities) ] ].
]

{ #category : 'initialization' }
CoverageUIBuilder >> defaultLayout [
	^ SpBoxLayout newVertical
		add: summaryLabel expand: false;
		add: (SpBoxLayout newHorizontal
			add: filterDropList expand: false;
			add: uncoverButton expand: false;
			yourself) expand: false;
		add: (SpPanedLayout newTopToBottom
			add: table;
			add: detailsText;
			yourself);
		yourself
]

{ #category : 'accessing' }
CoverageUIBuilder >> detailsFor: entity [
    ^ String streamContents: [ :stream |
        stream << 'Entity: ' << (entity name ifNil: [ 'Unknown' ]) << String cr.
        stream << 'Type: ' << (entity className ifNil: [ 'Unknown' ]) << String cr.
        stream << 'Source Location: '.
        stream << (entity sourceAnchor ifNil: [ 'N/A' ] ifNotNil: [ :anchor | anchor mooseDescription ifNil: [ 'Not available' ] ]) << String cr ]
]

{ #category : 'private' }
CoverageUIBuilder >> detailsForLine: lineNumber entities: entities [
	^ String streamContents: [ :stream |
		stream << 'Line: ' << lineNumber printString << String cr.
		entities
			ifEmpty: [ stream << 'No entities associated with this line.' ]
			ifNotEmpty: [
				stream << 'Entities:' << String cr.
				entities do: [ :info |
					stream
						<< '- Name: ' << ((info at: #entity) name ifNil: [ 'Unknown' ]) << String cr
						<< '  Type: ' << (info at: #className) << String cr
						<< '  Range: ' << (info at: #startPos) printString << '-' << (info at: #endPos) printString << String cr ] ] ]
]

{ #category : 'private' }
CoverageUIBuilder >> entityTypesForLine: lineNumber [
	| entities result |
	entities := analyzer entitiesForLine: lineNumber.
	result := String streamContents: [ :stream |
		entities do: [ :info |
			| className |
			className := info at: #className.
			stream nextPutAll: className ] separatedBy: [ stream nextPutAll: ', ' ] ].
	^ result isEmpty ifTrue: [ '-' ] ifFalse: [ result ]
]

{ #category : 'initialization' }
CoverageUIBuilder >> initialize [
	super initialize.
]

{ #category : 'initialization' }
CoverageUIBuilder >> initializePresenters [
	analyzer ifNil: [ 
		table := self newTable
			addColumn: (SpStringTableColumn title: 'Line #' evaluated: [ :row | '' ]);
			addColumn: (SpStringTableColumn title: 'Source' evaluated: [ :row | '' ]);
			addColumn: (SpStringTableColumn title: 'Coverage' evaluated: [ :row | '' ]);
			addColumn: (SpStringTableColumn title: 'Entity Types' evaluated: [ :row | '' ]);
			items: #();
			yourself.
		detailsText := self newText
			editable: false;
			yourself.
		summaryLabel := self newLabel
			label: 'Coverage: N/A (Analyzer not initialized)';
			yourself.
		filterDropList := self newDropList
			items: #('All');
			selectItem: 'All';
			yourself.
		uncoverButton := self newButton
			label: 'Show Uncovered';
			action: [ detailsText text: 'Analyzer not initialized' ];
			yourself.
		self windowTitle: 'Code Coverage - Not Initialized'.
		^ self ].

	table := self newTable
		addColumn: (SpStringTableColumn title: 'Line #' evaluated: [ :row | row first ]);
		addColumn: (SpStringTableColumn title: 'Source' evaluated: [ :row | row second ]);
		addColumn: (SpStringTableColumn title: 'Coverage' evaluated: [ :row | row third ]);
		addColumn: (SpStringTableColumn title: 'Entity Types' evaluated: [ :row | row fourth ]);
		items: (self buildTableDataForFilter: 'All');
		yourself.
	
	detailsText := self newText
		editable: false;
		yourself.
	
	summaryLabel := self newLabel
		label: ('Coverage: {1}% ({2}/{3} lines)' format: { 
			analyzer coveragePercentage ifNil: [ '0.00' ]. 
			analyzer coveredLines size printString. 
			analyzer totalLines printString });
		yourself.
	
	filterDropList := self newDropList
		items: ((OrderedCollection new add: 'All'; add: 'Uncovered'; addAll: (analyzer entityTypes ifNil: [ #() ]); yourself));
		selectItem: 'All';
		whenSelectedItemChangedDo: [ :item | 
			table items: (self buildTableDataForFilter: item).
			table refresh ];
		yourself.
	
	uncoverButton := self newButton
		label: 'Show Uncovered';
		action: [ self showUncoveredLines ];
		yourself.
	
	self windowTitle: ('Code Coverage: ', (analyzer fileName ifNil: ['Unknown'] ifNotNil: [ :fn | fn asFileReference basename ])).
]

{ #category : 'initialization' }
CoverageUIBuilder >> initializeWithAnalyzer: aCodeCoverageAnalyzer [
	(aCodeCoverageAnalyzer isNil or: [ aCodeCoverageAnalyzer totalLines isNil ])
		ifTrue: [ self error: 'Analyzer must be initialized with a model and file' ].
	analyzer := aCodeCoverageAnalyzer.
	self initializePresenters.
]

{ #category : 'initialization' }
CoverageUIBuilder >> open [
	Transcript show: 'Starting open'; cr.
	[ 
		Transcript show: 'Setting up UI components'; cr.
		self initializePresenters.
		Transcript show: 'Opening window'; cr.
		^ super open
	] on: Error do: [ :error |
		Transcript show: 'Error in open: ', error messageText; cr.
		Transcript show: 'Error details: ', error printString; cr.
		^ nil ]
]

{ #category : 'actions' }
CoverageUIBuilder >> showEntityDetails: entity [
    detailsText text: (String streamContents: [ :stream |
        stream nextPutAll: 'Name: '.
        stream nextPutAll: (entity name ifNil: [ 'Unknown' ]).
        stream cr.
        stream nextPutAll: 'Type: '.
        stream nextPutAll: (entity class name ifNil: [ 'Unknown' ]).
        stream cr.
        stream nextPutAll: 'Lines: '.
        stream nextPutAll: (analyzer linesForEntity: entity) printString ])
]

{ #category : 'private' }
CoverageUIBuilder >> showUncoveredLines [
	| uncovered |
	uncovered := analyzer uncoveredLines.
	detailsText text: (String streamContents: [ :stream |
		stream << 'Uncovered Lines: ' << uncovered size printString << String cr.
		uncovered do: [ :i |
			stream
				<< i printString <<'thresh: ' << (analyzer sourceLines at: i ifAbsent: [ '<missing>' ]) << String cr ] ])
]

{ #category : 'initialization' }
CoverageUIBuilder >> windowTitle: aString [
	self withWindowDo: [ :window | window title: aString ]
]
