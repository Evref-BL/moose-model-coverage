"
Tests of the alpha emphasis of MMCCoveragePresenter: while an entity is selected in the Model tree and has a covered segment in the current file, its segments keep the alpha of their color and every other segment (uncovered ones included) gets dimmedAlpha; no selection (or an entity without covered segment in the file) leaves every alpha at 1.0. Uses the multi file example (no window, no widget): file Beta.java has the segments uncovered, Beta, used, uncovered; file Alpha.java the segments Alpha, next.
"
Class {
	#name : 'MMCCoveragePresenterEmphasisTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> alphaPresenter [
	"Not opened presenter of the multi file example, showing Alpha.java (segments Alpha, next, Alpha)."

	^ presenters add: MMCCoveragePresenter newMultiFileExample
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> alphasOf: aPresenter [
	"Alpha of the color of each decorator, in the order of the segments."

	^ (aPresenter decorators collect: [ :each |
		   each highlightColor alpha ]) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> assertAllOpaqueIn: aPresenter [

	(self alphasOf: aPresenter) do: [ :each |
		self assert: each equals: 1.0 ]
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> assertAlpha: anAlpha isDimmedFor: aPresenter [
	"Up to the 8 bit rounding of Color (0.25 becomes about 0.247)."

	^ self
		  assert: (anAlpha - aPresenter dimmedAlpha) abs < 0.01
		  description: 'dimmed alpha expected, got ' , anAlpha printString
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> assertAlphas: expectedNames dimmedExcept: fullNames in: aPresenter [
	"The segments named in fullNames have alpha 1.0, every other one has dimmedAlpha (up to the 8 bit rounding of Color)."

	| names alphas |
	names := self namesOfSegmentsOf: aPresenter.
	self assert: names equals: expectedNames.
	alphas := self alphasOf: aPresenter.
	self assert: alphas size equals: names size.
	names with: alphas do: [ :name :alpha |
		(fullNames includes: name)
			ifTrue: [
				self
					assert: alpha = 1.0
					description: name asString , ' must be opaque' ]
			ifFalse: [ self assertAlpha: alpha isDimmedFor: aPresenter ] ]
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> betaPresenter [
	"Presenter showing Beta.java (segments uncovered, Beta, used, uncovered)."

	| presenter |
	presenter := self alphaPresenter.
	presenter showFile: (self fileNamed: 'Beta.java' of: presenter).
	^ presenter
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> entityNamed: aString of: aPresenter [
	"The class or method of the Moose model named aString."

	^ (aPresenter model allWithType: FamixJavaClass)
	  , (aPresenter model allWithType: FamixJavaMethod) detect: [ :each |
		  each name = aString ]
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> fileNamed: aBasename of: aPresenter [

	^ aPresenter modelFiles files detect: [ :each |
		  each basename = aBasename ]
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> namesOfSegmentsOf: aPresenter [
	"Entity name of each segment of the plan, #uncovered for the uncovered ones."

	^ (aPresenter plan segments collect: [ :each |
			   each isUncovered
				   ifTrue: [ #uncovered ]
				   ifFalse: [ each region entity name ] ]) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> sameDecorators: aCollection as: anotherCollection [
	"True when both collections hold the very same decorators (decorators answers a copy of its collection, so == on it means nothing)."

	^ aCollection size = anotherCollection size and: [
		  (1 to: aCollection size) allSatisfy: [ :each |
			  (aCollection at: each) == (anotherCollection at: each) ] ]
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> select: aString in: aPresenter [
	"Select the entity named aString in the Model tree, as a click on it."

	aPresenter selectEntityInTree:
		(self entityNamed: aString of: aPresenter).
	self
		assert: aPresenter treePresenter selection selectedItem name
		equals: aString
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> setUp [

	super setUp.
	presenters := OrderedCollection new
]

{ #category : 'helpers' }
MMCCoveragePresenterEmphasisTest >> tearDown [
	"Close the windows (none expected) and delete the temporary folder of the example presenters (only when under the system temporary directory)."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ].
			[
				each model rootFolder ifNotNil: [ :root |
						| ref |
						ref := root asFileReference.
						(ref isDirectory and: [
							 ref pathString beginsWith:
								 FileLocator temp asFileReference pathString ]) ifTrue: [
							ref ensureDeleteAll ] ] ]
				on: Error
				do: [ :e | e return ] ].
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testAllSegmentsOfTheSelectedEntityStayOpaque [
	"In Alpha.java the class Alpha has two segments around the method next."

	| presenter |
	presenter := self alphaPresenter.
	self select: 'Alpha' in: presenter.
	self
		assertAlphas: #( 'Alpha' 'next' 'Alpha' )
		dimmedExcept: #( 'Alpha' )
		in: presenter.
	self select: 'next' in: presenter.
	self
		assertAlphas: #( 'Alpha' 'next' 'Alpha' )
		dimmedExcept: #( 'next' )
		in: presenter
]

{ #category : 'tests - file change' }
MMCCoveragePresenterEmphasisTest >> testChangingFileClearsAnEntityNotVisibleInTheNewFile [
	"File mode: used is not in the tree of Alpha.java, the selection is cleared and nothing is dimmed."

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter showFile: (self fileNamed: 'Alpha.java' of: presenter).
	self assert: presenter treePresenter selection selectedItem isNil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests - file change' }
MMCCoveragePresenterEmphasisTest >> testChangingFileKeepsTheSelectedEntityButDimsNothingWhenItHasNoSegmentThere [
	"Whole model mode: Beta stays selected when showing Alpha.java, where it has no covered segment, so nothing is dimmed; coming back to Beta.java puts it forward again."

	| presenter |
	presenter := self betaPresenter.
	presenter wholeModelTogglePresenter state: true.
	self select: 'Beta' in: presenter.
	presenter showFile: (self fileNamed: 'Alpha.java' of: presenter).
	self
		assert: presenter treePresenter selection selectedItem name
		equals: 'Beta'.
	self assertAllOpaqueIn: presenter.
	presenter showFile: (self fileNamed: 'Beta.java' of: presenter).
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'Beta' )
		in: presenter
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testChangingTheSelectionDoesNotRecomputeTheCoverage [
	"Only the colors are rebuilt: same coverage and plan objects, no other file computed."

	| presenter coverage plan |
	presenter := self betaPresenter.
	coverage := presenter fileCoverage.
	plan := presenter plan.
	self select: 'used' in: presenter.
	self select: 'Beta' in: presenter.
	presenter treePresenter unselectAll.
	self assert: presenter fileCoverage == coverage.
	self assert: presenter plan == plan.
	self assert:
		(presenter modelFiles coverageFor: presenter currentFile)
		== coverage.
	self assert: (presenter modelFiles summaryFor:
			 (self fileNamed: 'Gamma.java' of: presenter)) isNil
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testChangingTheSelectionKeepsTheText [

	| presenter text |
	presenter := self betaPresenter.
	text := presenter textPresenter text.
	self select: 'used' in: presenter.
	self assert: presenter textPresenter text equals: text
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testChangingTheSelectionRebuildsTheDecorators [
	| presenter before |
	presenter := self betaPresenter.
	before := presenter decorators.
	self select: 'used' in: presenter.
	self deny: (self sameDecorators: presenter decorators as: before)
]

{ #category : 'tests - deselection' }
MMCCoveragePresenterEmphasisTest >> testClickInTheTextOnAnEntityPutsItForward [

	| presenter used position |
	presenter := self betaPresenter.
	used := presenter plan segments detect: [ :each |
		        each isUncovered not and: [
			        each region entity name = 'used' ] ].
	position := used interval first + 4.
	presenter textSelectionChangedTo: (position to: position).
	self
		assert: presenter treePresenter selection selectedItem name
		equals: 'used'.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'used' )
		in: presenter
]

{ #category : 'tests - deselection' }
MMCCoveragePresenterEmphasisTest >> testClickInTheTextOnUncoveredCodeRestoresEveryAlpha [
	"Position 1 of Beta.java (package line) is outside every anchor: the tree selection is cleared."

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter textSelectionChangedTo: (1 to: 1).
	self assert: presenter treePresenter selection selectedItem isNil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testDimmedAlphaIsAQuarter [

	self assert: self alphaPresenter dimmedAlpha equals: 0.25
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testDimmedSegmentsKeepTheHueOfThePaletteColor [

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter plan segments
		with: presenter decorators
		do: [ :segment :decorator |
				| base dimmed |
				base := presenter palette colorForSegment: segment.
				dimmed := decorator highlightColor.
				self assert: (dimmed red closeTo: base red).
				self assert: (dimmed green closeTo: base green).
				self assert: (dimmed blue closeTo: base blue) ]
]

{ #category : 'tests - no covered segment' }
MMCCoveragePresenterEmphasisTest >> testEntityToApplyIsNilWithoutSelectionAndTheSelectedEntityOtherwise [

	| presenter used |
	presenter := self betaPresenter.
	self assert: presenter emphasizedEntityToApply isNil.
	used := self entityNamed: 'used' of: presenter.
	presenter selectEntityInTree: used.
	self assert: presenter emphasizedEntityToApply == used.
	presenter treePresenter unselectAll.
	self assert: presenter emphasizedEntityToApply isNil
]

{ #category : 'tests - no covered segment' }
MMCCoveragePresenterEmphasisTest >> testEntityWithoutAnchorDimsNothing [
	"Whole model mode: the class Orphan has no anchor, hence no covered segment in any file: nothing is dimmed."

	| presenter |
	presenter := self alphaPresenter.
	presenter wholeModelTogglePresenter state: true.
	self select: 'Orphan' in: presenter.
	self assert: presenter emphasizedEntityToApply isNil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests - no covered segment' }
MMCCoveragePresenterEmphasisTest >> testEntityWithoutAnchorDimsNothingInAnotherFileToo [

	| presenter |
	presenter := self betaPresenter.
	presenter wholeModelTogglePresenter state: true.
	self select: 'Orphan' in: presenter.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testExactlyOneEntityIsAtFullAlphaWhileSelected [

	| presenter names |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	names := (self namesOfSegmentsOf: presenter) asArray
		         with: (self alphasOf: presenter)
		         collect: [ :name :alpha |
				         alpha = 1.0
					         ifTrue: [ name ]
					         ifFalse: [ nil ] ].
	self assert: (names reject: #isNil) asSet equals: #( 'used' ) asSet
]

{ #category : 'tests - file change' }
MMCCoveragePresenterEmphasisTest >> testNavigatingThroughTheFilesNeverLeavesStaleDimming [

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter nextFile.
	presenter previousFile.
	presenter previousFile.
	self assert: presenter treePresenter selection selectedItem isNil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testNothingSelectedLeavesEveryAlphaAtOne [

	| presenter |
	presenter := self alphaPresenter.
	self assert: presenter decorators size equals: 3.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testOneDecoratorPerSegmentWhateverTheSelection [

	| presenter |
	presenter := self betaPresenter.
	self
		assert: presenter decorators size
		equals: presenter plan segments size.
	self select: 'used' in: presenter.
	self
		assert: presenter decorators size
		equals: presenter plan segments size.
	self
		assert:
		(presenter decorators collect: [ :each | each interval ]) asArray
		equals: (presenter plan segments collect: [ :each |
				 each interval first to: each interval last ]) asArray
]

{ #category : 'tests - no covered segment' }
MMCCoveragePresenterEmphasisTest >> testPackageWithoutCoveredSegmentDimsNothing [
	"The package demo has no anchor: selecting it (whole model mode) puts nothing forward."

	| presenter |
	presenter := self alphaPresenter.
	presenter wholeModelTogglePresenter state: true.
	presenter selectEntityInTree:
		(presenter model allWithType: FamixJavaPackage) anyOne.
	self
		assert: presenter treePresenter selection selectedItem name
		equals: 'demo'.
	self assert: presenter emphasizedEntityToApply isNil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests - real window' }
MMCCoveragePresenterEmphasisTest >> testRealWindowClickOnAnEntityOfAnotherFileSwitchesTheFileAndPutsItForward [
	"Real Morphic window (closed at the end), whole model mode: a click on the row of the method used (Beta.java) shows Beta.java with only used at full alpha, once the deferred realignment of the tree selection has run (realignTreeSelectionOn: calls refreshEmphasis)."

	| presenter window rows source table |
	presenter := self alphaPresenter.
	[
		window := presenter open.
		presenter wholeModelTogglePresenter state: true.
		presenter treePresenter expandAll.
		table := presenter treePresenter adapter widget.
		source := table dataSource.
		rows := (1 to: source numberOfRows) collect: [ :each |
			        (source elementAt: each) data name ].
		table selectIndex: (rows indexOf: 'used').
		(Delay forMilliseconds: 300) wait.
		self assert: presenter currentFile basename equals: 'Beta.java'.
		self
			assert: presenter treePresenter selection selectedItem name
			equals: 'used'.
		self
			assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
			dimmedExcept: #( 'used' )
			in: presenter ] ensure: [ window ifNotNil: [ window close ] ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterEmphasisTest >> testRealWindowClicksInTheTreeOfTheCurrentFileMoveTheEmphasis [
	"Real Morphic window (closed at the end) on Beta.java: a click on the row used, then on Beta, then the background (deselectAll of the table) put forward used, Beta, then nothing."

	| presenter window rows source table |
	presenter := self betaPresenter.
	[
		window := presenter open.
		presenter treePresenter expandAll.
		table := presenter treePresenter adapter widget.
		source := table dataSource.
		rows := (1 to: source numberOfRows) collect: [ :each |
			        (source elementAt: each) data name ].
		table selectIndex: (rows indexOf: 'used').
		self
			assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
			dimmedExcept: #( 'used' )
			in: presenter.
		table selectIndex: (rows indexOf: 'Beta').
		self
			assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
			dimmedExcept: #( 'Beta' )
			in: presenter.
		table deselectAll.
		self assertAllOpaqueIn: presenter ] ensure: [
		window ifNotNil: [ window close ] ]
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testRefreshEmphasisAfterASilentSelectionChangeAppliesIt [
	"When the selected entity differs from the applied one, refreshEmphasis re-applies the colors (the synchronisation selects without echo)."

	| presenter |
	presenter := self betaPresenter.
	presenter synchronizingDo: [
		presenter selectEntityInTree:
			(self entityNamed: 'used' of: presenter) ].
	self assertAllOpaqueIn: presenter.
	presenter refreshEmphasis.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'used' )
		in: presenter
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testRefreshEmphasisAnswersWithoutErrorWhenNothingIsDisplayed [

	| presenter |
	presenter := self alphaPresenter.
	self shouldnt: [ presenter refreshEmphasis ] raise: Error
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testRefreshEmphasisWithASelectionKeepsTheDecorators [
	| presenter decorators alphas |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	decorators := presenter decorators.
	alphas := self alphasOf: presenter.
	presenter refreshEmphasis.
	presenter refreshEmphasis.
	self assert: (self sameDecorators: presenter decorators as: decorators).
	self assert: (self alphasOf: presenter) equals: alphas
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testRefreshEmphasisWithoutChangeKeepsTheDecorators [
	"Idempotent: nothing to change, the decorators are not rebuilt."

	| presenter decorators |
	presenter := self betaPresenter.
	decorators := presenter decorators.
	presenter refreshEmphasis.
	presenter refreshEmphasis.
	self assert: (self sameDecorators: presenter decorators as: decorators)
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testRefreshHighlightsGivesTheSameAlphasWithASelection [

	| presenter alphas |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	alphas := self alphasOf: presenter.
	presenter refreshHighlights.
	presenter refreshHighlights.
	self assert: (self alphasOf: presenter) equals: alphas.
	self
		assert: presenter decorators size
		equals: presenter plan segments size
]

{ #category : 'tests - file change' }
MMCCoveragePresenterEmphasisTest >> testReloadingTheCurrentFileKeepsTheEmphasis [
	"loadFile: (used after a change of inventory) keeps the visible selection and its emphasis."

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter loadFile: presenter currentFile.
	self
		assert: presenter treePresenter selection selectedItem name
		equals: 'used'.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'used' )
		in: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testSelectedSegmentsKeepExactlyThePaletteColor [

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter plan segments
		with: presenter decorators
		do: [ :segment :decorator |
				(segment isUncovered not and: [
					 segment region entity name = 'used' ]) ifTrue: [
						self
							assert: decorator highlightColor
							equals: (presenter palette colorForSegment: segment) ] ]
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testSelectingAMethodPutsItForwardAndDimsTheRest [
	"Beta.java: uncovered, Beta, used, uncovered; only used keeps the alpha 1.0, the uncovered zones and the class are dimmed."

	| presenter |
	presenter := self betaPresenter.
	self assertAllOpaqueIn: presenter.
	self select: 'used' in: presenter.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'used' )
		in: presenter
]

{ #category : 'tests - deselection' }
MMCCoveragePresenterEmphasisTest >> testSelectingAgainAfterUnselectingDimsAgain [

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter treePresenter unselectAll.
	self select: 'used' in: presenter.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'used' )
		in: presenter
]

{ #category : 'tests - file change' }
MMCCoveragePresenterEmphasisTest >> testSelectingAnEntityOfAnotherFileSwitchesTheFileAndPutsItForward [
	"Whole model mode on Alpha.java, then the method used of Beta.java (notification of the tree selection, as in the file switch tests)."

	| presenter |
	presenter := self alphaPresenter.
	presenter wholeModelTogglePresenter state: true.
	presenter treeSelectionChangedTo: (self entityNamed: 'used' of: presenter).
	self assert: presenter currentFile basename equals: 'Beta.java'.
	self assert: presenter treePresenter selection selectedItem name equals: 'used'.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'used' )
		in: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testSelectingAnotherEntityMovesTheEmphasis [

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	self select: 'Beta' in: presenter.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'Beta' )
		in: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testSelectingTheClassDimsItsMethod [

	| presenter |
	presenter := self betaPresenter.
	self select: 'Beta' in: presenter.
	self
		assertAlphas: #( #uncovered 'Beta' 'used' #uncovered )
		dimmedExcept: #( 'Beta' )
		in: presenter
]

{ #category : 'tests - deselection' }
MMCCoveragePresenterEmphasisTest >> testTreeSelectionChangedToNilRestoresEveryAlpha [
	"The notification of a tree selection change to nothing is what the tree sends on a click on the background."

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter treePresenter unselectAll.
	presenter treeSelectionChangedTo: nil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests - cost' }
MMCCoveragePresenterEmphasisTest >> testTwoUncoveredSegmentsOfTheSameColorGetEqualDimmedColors [
	"Beta.java, 'used' selected: the two uncovered segments have the same palette color and, dimmed, get equal colors (the dimmed colors are memoized by equality, not by identity), at dimmedAlpha."

	| presenter file uncovered |
	presenter := self alphaPresenter.
	file := presenter modelFiles files detect: [ :each |
		        each basename = 'Beta.java' ].
	presenter showFile: file.
	presenter treeFilter: #all.
	presenter selectEntityInTree:
		(presenter plan segments detect: [ :each |
			 each isUncovered not and: [ each region entity name = 'used' ] ])
			region entity.
	uncovered := (presenter plan segments
		              with: presenter decorators asArray
		              collect: [ :segment :decorator |
				              segment isUncovered
					              ifTrue: [ decorator highlightColor ]
					              ifFalse: [ nil ] ]) reject: #isNil.
	self assert: uncovered size equals: 2.
	self assert: uncovered first equals: uncovered last.
	self assertAlpha: uncovered first alpha isDimmedFor: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testUncoveredSegmentsAreDimmedWhileAnEntityIsSelected [
	| presenter alphas |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	alphas := self alphasOf: presenter.
	self assertAlpha: alphas first isDimmedFor: presenter.
	self assertAlpha: alphas last isDimmedFor: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterEmphasisTest >> testUncoveredZonesGetEqualDimmedColors [
	"Both uncovered zones of Beta.java have the same color, so the same dimmed color."

	| presenter decorators |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	decorators := presenter decorators.
	self assert: decorators first highlightColor equals: decorators last highlightColor
]

{ #category : 'tests - deselection' }
MMCCoveragePresenterEmphasisTest >> testUnselectingTheTreeRestoresEveryAlphaToOne [
	"A click on the background of the tree does treePresenter unselectAll."

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter treePresenter unselectAll.
	self assert: presenter treePresenter selection selectedItem isNil.
	self assertAllOpaqueIn: presenter
]

{ #category : 'tests - deselection' }
MMCCoveragePresenterEmphasisTest >> testUnselectingTwiceKeepsEveryAlphaAtOne [

	| presenter |
	presenter := self betaPresenter.
	self select: 'used' in: presenter.
	presenter treePresenter unselectAll.
	presenter treePresenter unselectAll.
	self assertAllOpaqueIn: presenter
]
