"
Tests of the color management of MMCCoveragePresenter: palette built on the types of the whole model (stable default colors from a file to another), color scheme of the model or of the presenter (colorScheme, colorScheme:, applyColorScheme:), survival of the scheme through the theme, file and model changes, the Colors button (state, opener hook, one window, layout under Set root folder in a real window). The temporary folders are deleted and the windows closed in tearDown; the real picker is never opened.
"
Class {
	#name : 'MMCCoveragePresenterColorsTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'entities',
		'presenters',
		'windows'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> add: anEntityClass named: aName on: aFileName from: start to: end [
	"Add to the model an entity (kept in entities) with an indexed file anchor on aFileName."

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

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> assertDecoratorsOf: aPresenter matchPalette: aPalette [
	"Without selection: every decorator has exactly the color that aPalette gives to its segment."

	aPresenter plan segments
		with: aPresenter decorators asArray
		do: [ :segment :decorator |
				self
					assert: decorator highlightColor
					equals: (aPalette colorForSegment: segment) ]
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> assertOverrideSurvivesIn: aPresenter theme: aTheme [
	"The scheme is the one of the model, still overriding Method, and the palette (theme aTheme) applies it."

	| reference |
	self assert:
		aPresenter colorScheme == (MMCColorSchemeRegistry for: model).
	self
		assert: (aPresenter colorScheme overrideFor: 'Method')
		equals: Color red.
	reference := self referencePaletteTheme: aTheme.
	reference colorScheme: aPresenter colorScheme.
	self assert: aPresenter palette colorScheme == aPresenter colorScheme.
	self assertDecoratorsOf: aPresenter matchPalette: reference
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> boundsOf: aPresenter [

	^ aPresenter adapter widget bounds
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> buildTwoFileFixture [
	"a/A.java holds only a method (type Method), b/B.java a class (1-90) holding a method (10-40) (types Class and Method). Sorted: A then B. The types of the model are Class and Method, those of A alone are Method."

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

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> colorsOfTypeNamed: aTypeName in: aPresenter [
	"The highlight colors of the covered segments of the type in the current file, in order."

	^ (aPresenter plan segments
		   with: aPresenter decorators asArray
		   collect: [ :segment :decorator |
				   (segment isUncovered not and: [
					    segment typeName asString = aTypeName ])
					   ifTrue: [ decorator highlightColor ]
					   ifFalse: [ nil ] ]) reject: #isNil
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> fileNamed: aBaseName of: aPresenter [

	^ aPresenter modelFiles files detect: [ :each |
		  each basename = aBaseName ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> guarded: aBlock [
	"Evaluate aBlock; a watchdog process raises an error in the test process after 30 s (a real window must never block the test runner), and is always terminated."

	| watchdog testProcess |
	testProcess := Processor activeProcess.
	watchdog := [
		            (Delay forSeconds: 30) wait.
		            testProcess signalException:
			            (Error new messageText:
				             'real window test did not finish within 30 s') ]
		            forkAt: Processor userInterruptPriority.
	^ [ aBlock value ] ensure: [ watchdog terminate ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> isTitle: aTitle visibleIn: aWindowMorph [
	"True when a short text or label morph of the window shows aTitle, visible and inside the window."

	^ (aWindowMorph allMorphs select: [ :each |
			   (self stringOfMorph: each)
				   ifNil: [ false ]
				   ifNotNil: [ :string |
						   string size <= (aTitle size + 4) and: [
							   string includesSubstring: aTitle ] ] ]) anySatisfy: [ :each |
			  | area |
			  area := (each respondsTo: #headerHeight)
				          ifTrue: [
						          each bounds topLeft corner:
							          each bounds right
							          @ (each bounds top + each headerHeight) ]
				          ifFalse: [ each bounds ].
			  each visible and: [
					  each isInWorld and: [
							  area width > 0 and: [
								  area height > 0 and: [
									  aWindowMorph bounds containsRect: area ] ] ] ] ]
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> newPresenter [
	"Not opened presenter on the inventory of the model, closed (and its model forgotten) in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> referencePaletteTheme: aTheme [
	"The palette that the presenter must build on the types of the two files fixture: Class and Method of the whole model."

	^ MMCColorPalette forTypeNames: #( 'Class' 'Method' ) theme: aTheme
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> setUp [
	"A temporary folder, an empty FamixJava model rooted in it, no presenter and no window."

	super setUp.
	folder := FileLocator temp / ('mmc-colors-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new.
	windows := OrderedCollection new
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> stringOfMorph: aMorph [
	"The text shown by a text or label morph, nil for the other morphs."

	#( #contents #text #label ) do: [ :selector |
			(aMorph respondsTo: selector) ifTrue: [
					| value |
					value := [ aMorph perform: selector ]
						         on: Error
						         do: [ :e | e return: nil ].
					((value isKindOf: String) or: [ value isKindOf: Text ]) ifTrue: [
						^ value asString ] ] ].
	^ nil
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> systemWindowCount [

	^ World submorphs count: [ :each | each isSystemWindow ]
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> tearDown [
	"Close the windows, forget the schemes of the models of the test and delete the temporary folders (the one of the test and those of the example presenters)."

	windows do: [ :each |
			[ each close ]
				on: Error
				do: [ :e | e return ] ].
	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ].
			[
				each model ifNotNil: [ :aModel |
						| root |
						MMCColorSchemeRegistry removeFor: aModel.
						root := aModel rootFolder ifNotNil: [ :r | r asFileReference ].
						(root notNil and: [
								 root isDirectory and: [
										 root parent = FileLocator temp asFileReference and: [
											 root basename beginsWith: 'mmc-' ] ] ]) ifTrue: [
							root ensureDeleteAll ] ] ]
				on: Error
				do: [ :e | e return ] ].
	MMCColorSchemeRegistry removeFor: model.
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testApplyColorSchemeChangesOnlyTheTargetedType [

	| presenter classBefore methodBefore uncoveredBefore |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	classBefore := (self colorsOfTypeNamed: 'Class' in: presenter)
		               asArray.
	methodBefore := (self colorsOfTypeNamed: 'Method' in: presenter)
		                asArray.
	uncoveredBefore := (self uncoveredColorsIn: presenter) asArray.
	self assert: classBefore isNotEmpty.
	self assert: methodBefore isNotEmpty.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	self
		assert: (self colorsOfTypeNamed: 'Class' in: presenter) asArray
		equals: classBefore.
	self
		assert: (self uncoveredColorsIn: presenter) asArray
		equals: uncoveredBefore.
	self deny: (self colorsOfTypeNamed: 'Method' in: presenter) asArray
		= methodBefore.
	(self colorsOfTypeNamed: 'Method' in: presenter) do: [ :each |
		self assert: (each hue - Color red hue) abs < 2 ]
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testApplyColorSchemeDirectlyRebuildsThePalette [

	| presenter oldPalette |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	oldPalette := presenter palette.
	presenter applyColorScheme: presenter colorScheme.
	self deny: presenter palette == oldPalette.
	self assert: presenter palette colorScheme == presenter colorScheme
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testApplyColorSchemeForAnotherSchemeDoesNothing [

	| presenter palette decorators other |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	palette := presenter palette.
	decorators := presenter decorators.
	other := MMCColorScheme new.
	other overrideAt: 'Method' put: Color red.
	presenter applyColorScheme: other.
	presenter applyColorScheme: nil.
	self assert: presenter palette == palette.
	self assert: presenter decorators equals: decorators
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testApplyColorSchemeIsIgnoredWhileApplying [

	| presenter palette |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	palette := presenter palette.
	presenter instVarNamed: 'isApplyingColorScheme' put: true.
	presenter applyColorScheme: presenter colorScheme.
	self assert: presenter palette == palette.
	presenter instVarNamed: 'isApplyingColorScheme' put: false.
	presenter applyColorScheme: presenter colorScheme.
	self deny: presenter palette == palette
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testApplyColorSchemeWithoutCoverageOrWidgetDoesNothing [

	| bare |
	bare := MMCCoveragePresenter basicNew.
	self shouldnt: [ bare applyColorScheme: nil ] raise: Error.
	bare := MMCCoveragePresenter basicNew.
	bare colorScheme: MMCColorScheme new.
	self
		shouldnt: [ bare applyColorScheme: bare colorScheme ]
		raise: Error.
	self assert: bare palette isNil
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testApplyingFlagIsResetAfterwards [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter applyColorScheme: presenter colorScheme.
	self deny: (presenter instVarNamed: 'isApplyingColorScheme') == true
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testChangingTheSchemeOfTheModelRefreshesThePresenter [

	| presenter before |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	before := (self colorsOfTypeNamed: 'Method' in: presenter) asArray.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	self deny:
		(self colorsOfTypeNamed: 'Method' in: presenter) asArray = before.
	self assert:
		(self colorsOfTypeNamed: 'Method' in: presenter) isNotEmpty
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testClickingColorsOpensOneWindowAndTheSecondClickRaisesIt [

	| presenter first count |
	presenter := presenters add: MMCCoveragePresenter newMultiFileExample.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: presenter colorSettingsWindow isNil.
			count := self systemWindowCount.
			presenter colorsButton click.
			self waitUpTo: 1000 until: [ false ].
			first := presenter colorSettingsWindow.
			self assert: first notNil.
			self assert: first isOpen.
			self assert: first title equals: 'Colors - ' , presenter modelName.
			self assert: self systemWindowCount equals: count + 1.
			presenter colorsButton click.
			self waitUpTo: 1000 until: [ false ].
			self assert: presenter colorSettingsWindow == first.
			self assert: self systemWindowCount equals: count + 1 ]
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testClickingTheButtonCallsTheOpenerHook [

	| presenter calls |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	calls := OrderedCollection new.
	presenter colorSettingsOpener: [ :each |
			calls add: each.
			nil ].
	presenter colorsButton click.
	self assert: calls size equals: 1
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testClosingTheColorsWindowForgetsItAndAllowsANewOne [

	| presenter first second |
	presenter := presenters add: MMCCoveragePresenter newMultiFileExample.
	self withOpenWindowOf: presenter do: [ :window |
			presenter openColorSettings.
			first := presenter colorSettingsWindow.
			self assert: first notNil.
			first close.
			self assert: presenter colorSettingsWindow isNil.
			self assert: presenter colorScheme subscriberCount equals: 1.
			presenter openColorSettings.
			second := presenter colorSettingsWindow.
			self assert: second notNil.
			self deny: second == first.
			self assert: second isOpen ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testClosingTheCoverageWindowUnsubscribesFromTheScheme [

	| presenter scheme |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	scheme := presenter colorScheme.
	self assert: scheme subscriberCount equals: 1.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: scheme subscriberCount equals: 1.
			scheme overrideAt: 'Method' put: Color red.
			self assert: scheme subscriberCount equals: 1 ].
	self assert: scheme subscriberCount equals: 0
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testColorChosenInTheColorsWindowIsShownInTheCoverageWindow [
	"The editor of the opened Colors window changes the scheme of the coverage window (the debounce is flushed, no wait)."

	| presenter before |
	presenter := presenters add: MMCCoveragePresenter newMultiFileExample.
	self withOpenWindowOf: presenter do: [ :window |
			before := (self colorsOfTypeNamed: 'Class' in: presenter) asArray.
			presenter openColorSettings.
			presenter colorSettingsWindow presenter selectTypeNamed: 'Class'.
			presenter colorSettingsWindow presenter chooseColor: Color red.
			presenter colorSettingsWindow presenter flushPendingColor.
			self
				assert: (presenter colorScheme overrideFor: 'Class')
				equals: Color red.
			self deny:
				(self colorsOfTypeNamed: 'Class' in: presenter) asArray = before ]
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorSettingsClosedForgetsTheWindow [

	| presenter window |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	window := Object new.
	presenter instVarNamed: 'colorSettingsWindow' put: window.
	self assert: presenter colorSettingsWindow == window.
	presenter colorSettingsClosed: window.
	self assert: presenter colorSettingsWindow isNil
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorSettingsClosedIgnoresAnotherWindow [

	| presenter window |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	window := Object new.
	presenter instVarNamed: 'colorSettingsWindow' put: window.
	presenter colorSettingsClosed: Object new.
	self assert: presenter colorSettingsWindow == window
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorsButtonExistsWithItsLabel [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	self assert: presenter colorsButton notNil.
	self
		assert: presenter colorsButton label
		equals: 'Colors' , (String with: (Character value: 16r2026))
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testColorsButtonIsBelowSetRootFolderInARealWindow [
	"Real window of the multi file example: same column (left and right edges within 2 px), the Colors button starts under the bottom of Set root folder and is not wider."

	| presenter |
	presenter := presenters add: MMCCoveragePresenter newMultiFileExample.
	self withOpenWindowOf: presenter do: [ :window |
			| root colors |
			root := self boundsOf: presenter setRootFolderButton.
			colors := self boundsOf: presenter colorsButton.
			self assert: presenter colorsButton adapter widget visible.
			self assert: colors width > 10.
			self assert: (colors left - root left) abs <= 2.
			self assert: (colors right - root right) abs <= 2.
			self assert: colors top >= (root bottom - 2).
			self assert: colors width <= root width.
			self assert: (window adapter widget bounds containsRect: colors) ]
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorsButtonIsDisabledWithoutInventory [

	| presenter coverage |
	self buildTwoFileFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'A.java' of: self newPresenter).
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self assert: presenter modelFiles isNil.
	self deny: presenter colorsButton isEnabled
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorsButtonIsDisabledWithoutModel [

	| presenter coverage |
	self buildTwoFileFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'A.java' of: self newPresenter).
	presenter := presenters add: (MMCCoveragePresenter on: coverage).
	self deny: presenter colorsButton isEnabled
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorsButtonIsEnabledWithInventory [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	self assert: presenter colorsButton isEnabled
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testColorsButtonStaysEnabledAfterSetRootFolder [

	| presenter wrong |
	self buildTwoFileFixture.
	wrong := folder / 'wrong'.
	wrong ensureCreateDirectory.
	model rootFolder: wrong asFileReference.
	presenter := self newPresenter.
	self assert: presenter colorsButton isEnabled.
	presenter perform: #setRootFolder: with: folder asFileReference.
	self assert: presenter colorsButton isEnabled
]

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> testDefaultColorOfATypeIsTheSameInTwoFiles [
	"A.java holds only methods, B.java a class and a method: the color of Method used to depend on the types of the file, now it does not."

	| presenter inA inB perFile |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	self assert: presenter currentFile basename equals: 'A.java'.
	inA := presenter palette defaultColorForType: 'Method' depth: 0.
	self assert:
		(self colorsOfTypeNamed: 'Method' in: presenter) isNotEmpty.
	self
		assertDecoratorsOf: presenter
		matchPalette: (self referencePaletteTheme: presenter theme).
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	inB := presenter palette defaultColorForType: 'Method' depth: 0.
	self assert: inA equals: inB.
	self
		assertDecoratorsOf: presenter
		matchPalette: (self referencePaletteTheme: presenter theme).
	perFile := (MMCColorPalette
		            forTypeNames: #( 'Method' )
		            theme: presenter theme)
		           defaultColorForType: 'Method'
		           depth: 0.
	self deny: inA = perFile
]

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> testDefaultColorsAreStableBackToTheFirstFile [

	| presenter before |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	before := (self colorsOfTypeNamed: 'Method' in: presenter) asArray.
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	presenter showFile: (self fileNamed: 'A.java' of: presenter).
	self
		assert: (self colorsOfTypeNamed: 'Method' in: presenter) asArray
		equals: before
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testDefaultOpenerIsABlockOfOneArgument [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	self assert: presenter colorSettingsOpener numArgs equals: 1.
	self assert: presenter defaultColorSettingsOpener numArgs equals: 1
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testDefaultSchemeIsTheOneOfTheModelInTheRegistry [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	self assert:
		presenter colorScheme == (MMCColorSchemeRegistry for: model).
	self assert: presenter colorScheme isEmpty
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> testEmphasisAlphaIsKeptOnTheOtherEntitiesAfterAnOverride [

	| presenter dimmed full |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	presenter treeFilter: #all.
	presenter selectEntityInTree: (entities at: 'methodB').
	presenter colorScheme overrideAt: 'Class' put: Color red.
	dimmed := 0.
	full := 0.
	presenter plan segments
		with: presenter decorators asArray
		do: [ :segment :decorator |
				(segment isUncovered not and: [
					 segment region entity == (entities at: 'methodB') ])
					ifTrue: [
							full := full + 1.
							self assert: decorator highlightColor alpha equals: 1 ]
					ifFalse: [
							dimmed := dimmed + 1.
							self assert:
								(decorator highlightColor alpha - presenter dimmedAlpha) abs
								< 0.01 ] ].
	self assert: full equals: 1.
	self assert: dimmed > 0
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> testEmphasisKeepsTheNewColorOfTheSelectedEntity [

	| presenter reference selectedColors |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	presenter treeFilter: #all.
	presenter selectEntityInTree: (entities at: 'methodB').
	presenter colorScheme overrideAt: 'Method' put: Color red.
	reference := self referencePaletteTheme: presenter theme.
	reference colorScheme: presenter colorScheme.
	selectedColors := self colorsOfTypeNamed: 'Method' in: presenter.
	self assert: selectedColors size equals: 1.
	self
		assert: selectedColors first
		equals: (reference colorForType: 'Method' depth: 1)
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testExplicitSchemeAffectsThePresenterOnly [

	| first second mine |
	self buildTwoFileFixture.
	first := self newPresenter.
	second := self newPresenter.
	mine := MMCColorScheme new.
	first colorScheme: mine.
	mine overrideAt: 'Method' put: Color red.
	self deny: (first palette colorForType: 'Method' depth: 0)
		= (second palette colorForType: 'Method' depth: 0)
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testExplicitSchemeColorsThePalette [

	| presenter mine expected |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	mine := MMCColorScheme new.
	mine overrideAt: 'Method' put: Color red.
	presenter colorScheme: mine.
	expected := self referencePaletteTheme: presenter theme.
	expected colorScheme: mine.
	self assertDecoratorsOf: presenter matchPalette: expected.
	self deny: (presenter palette colorForType: 'Method' depth: 0)
		= (presenter palette defaultColorForType: 'Method' depth: 0)
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testExplicitSchemeIsUsed [

	| presenter mine |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	mine := MMCColorScheme new.
	presenter colorScheme: mine.
	self assert: presenter colorScheme == mine.
	self assert: mine subscriberCount equals: 1.
	self
		assert: (MMCColorSchemeRegistry for: model) subscriberCount
		equals: 0
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testModelNameIsTheNameOfTheModel [

	| presenter |
	self buildTwoFileFixture.
	model name: 'my-model'.
	presenter := self newPresenter.
	self assert: presenter modelName equals: 'my-model'
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testModelNameWithoutModelIsNil [

	| presenter coverage |
	self buildTwoFileFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'A.java' of: self newPresenter).
	presenter := presenters add: (MMCCoveragePresenter on: coverage).
	self assert: presenter modelName isNil
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testNilSchemeGoesBackToTheSchemeOfTheModel [

	| presenter mine |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	mine := MMCColorScheme new.
	mine overrideAt: 'Method' put: Color red.
	presenter colorScheme: mine.
	presenter colorScheme: nil.
	self assert:
		presenter colorScheme == (MMCColorSchemeRegistry for: model).
	self assert: mine subscriberCount equals: 0.
	self assert: presenter colorScheme subscriberCount equals: 1.
	self
		assertDecoratorsOf: presenter
		matchPalette: (self referencePaletteTheme: presenter theme)
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testOpenColorSettingsCallsTheOpenerAgainWhenItAnsweredNoWindow [

	| presenter calls |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	calls := 0.
	presenter colorSettingsOpener: [ :each |
			calls := calls + 1.
			nil ].
	presenter openColorSettings.
	presenter openColorSettings.
	self assert: calls equals: 2
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testOpenColorSettingsCallsTheOpenerWithThePresenter [

	| presenter calls |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	calls := OrderedCollection new.
	presenter colorSettingsOpener: [ :each |
			calls add: each.
			nil ].
	presenter openColorSettings.
	self assert: calls size equals: 1.
	self assert: calls first == presenter.
	self assert: presenter colorSettingsWindow isNil
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testOpenerHookIsReadBack [

	| presenter hook |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	hook := [ :each | nil ].
	presenter colorSettingsOpener: hook.
	self assert: presenter colorSettingsOpener == hook
]

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> testPaletteIsBuiltOnTheTypesOfTheWholeModel [

	| presenter reference |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	self
		assert: presenter modelFiles typeNames
		equals: #( 'Class' 'Method' ).
	reference := self referencePaletteTheme: presenter theme.
	(0 to: 3) do: [ :level |
			self
				assert:
				(presenter palette defaultColorForType: 'Class' depth: level)
				equals: (reference defaultColorForType: 'Class' depth: level).
			self
				assert:
				(presenter palette defaultColorForType: 'Method' depth: level)
				equals: (reference defaultColorForType: 'Method' depth: level) ]
]

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> testPaletteWithoutInventoryUsesTheTypesOfTheFile [

	| coverage presenter reference |
	self buildTwoFileFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'B.java' of: self newPresenter).
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self assert: presenter modelFiles isNil.
	reference := MMCColorPalette
		             forTypeNames: coverage typeNames
		             theme: presenter theme.
	self assertDecoratorsOf: presenter matchPalette: reference
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testPresenterWithoutModelHasItsOwnScheme [

	| coverage first second sizeBefore |
	self buildTwoFileFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'A.java' of: self newPresenter).
	sizeBefore := MMCColorSchemeRegistry size.
	first := presenters add: (MMCCoveragePresenter on: coverage).
	second := presenters add: (MMCCoveragePresenter on: coverage).
	self assert: first model isNil.
	self assert: first colorScheme isEmpty.
	self deny: first colorScheme == second colorScheme.
	self assert: MMCColorSchemeRegistry size equals: sizeBefore
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testResetOfTheSchemeGivesTheDefaultColorsBack [

	| presenter before |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	before := (self colorsOfTypeNamed: 'Method' in: presenter) asArray.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	presenter colorScheme reset.
	self
		assert: (self colorsOfTypeNamed: 'Method' in: presenter) asArray
		equals: before
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testSchemeChangeWhileApplyingDoesNotLoop [
	"A subscriber changing the scheme again from the notification of the presenter must not make the presenter recurse."

	| presenter count |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	count := 0.
	presenter colorScheme whenChangedDo: [
			count := count + 1.
			count < 3 ifTrue: [
					presenter colorScheme
						overrideAt: 'Class'
						put: (Color r: count / 10 g: 0.5 b: 0.5) ] ].
	self
		shouldnt: [
		presenter colorScheme overrideAt: 'Method' put: Color red ]
		raise: Error.
	self assert: count equals: 3
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> testSchemeStaysSubscribedAfterTheChanges [

	| presenter before |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter applyTheme: #light.
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	presenter updateFileCoverage:
		(presenter modelFiles coverageFor: presenter currentFile).
	self assert: presenter colorScheme subscriberCount equals: 1.
	before := (self colorsOfTypeNamed: 'Method' in: presenter) asArray.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	self deny:
		(self colorsOfTypeNamed: 'Method' in: presenter) asArray = before
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> testSchemeSurvivesAFileChange [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	presenter showFile: (self fileNamed: 'B.java' of: presenter).
	self assertOverrideSurvivesIn: presenter theme: presenter theme.
	presenter showFile: (self fileNamed: 'A.java' of: presenter).
	self assertOverrideSurvivesIn: presenter theme: presenter theme
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> testSchemeSurvivesApplyTheme [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	presenter applyTheme: #light.
	self assertOverrideSurvivesIn: presenter theme: #light.
	presenter applyTheme: #dark.
	self assertOverrideSurvivesIn: presenter theme: #dark
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testSchemeSurvivesSetRootFolder [
	"The model first points to an empty folder (all the files are unreadable), then to the right one: the new inventory, palette and decorators still use the scheme, which stays subscribed."

	| presenter wrong scheme reference before |
	self buildTwoFileFixture.
	wrong := folder / 'wrong'.
	wrong ensureCreateDirectory.
	model rootFolder: wrong asFileReference.
	presenter := self newPresenter.
	scheme := presenter colorScheme.
	scheme overrideAt: 'Method' put: Color red.
	presenter perform: #setRootFolder: with: folder asFileReference.
	self
		assert: presenter modelFiles typeNames
		equals: #( 'Class' 'Method' ).
	self assert: presenter colorScheme == scheme.
	self assert: scheme subscriberCount equals: 1.
	reference := self referencePaletteTheme: presenter theme.
	reference colorScheme: scheme.
	self assert: presenter palette colorScheme == scheme.
	self assertDecoratorsOf: presenter matchPalette: reference.
	before := (self colorsOfTypeNamed: 'Method' in: presenter) asArray.
	scheme overrideAt: 'Method' put: Color green.
	self deny:
		(self colorsOfTypeNamed: 'Method' in: presenter) asArray = before
]

{ #category : 'tests - emphasis and survival' }
MMCCoveragePresenterColorsTest >> testSchemeSurvivesUpdateFileCoverage [

	| presenter |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	presenter colorScheme overrideAt: 'Method' put: Color red.
	presenter updateFileCoverage:
		(presenter modelFiles coverageFor: presenter currentFile).
	self assertOverrideSurvivesIn: presenter theme: presenter theme
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testSixTitlesAreStillVisibleWithTheColorsButtonInARealWindow [

	| presenter |
	presenter := presenters add: MMCCoveragePresenter newMultiFileExample.
	self withOpenWindowOf: presenter do: [ :window |
			#( 'Summary' 'Files' 'Model' 'Source text' 'Uncovered zones'
			   'Details' ) do: [ :title |
					self
						assert: (self isTitle: title visibleIn: window adapter widget)
						description: title , ' is not visible in the window' ] ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterColorsTest >> testTreeAndFileListKeepTheirHeightsWithTheColorsButtonInARealWindow [
	"At 1300@700 the second button must not steal the room: tree at least 200 px, file list at least 100 px."

	| presenter |
	presenter := presenters add: MMCCoveragePresenter newMultiFileExample.
	self assert: presenter initialExtent equals: 1300 @ 700.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: (self boundsOf: presenter treePresenter) height >= 200.
			self assert:
				(self boundsOf: presenter fileListPresenter) height >= 100 ]
]

{ #category : 'tests - scheme' }
MMCCoveragePresenterColorsTest >> testTwoPresentersOfTheSameModelShareTheScheme [

	| first second |
	self buildTwoFileFixture.
	first := self newPresenter.
	second := self newPresenter.
	self assert: first colorScheme == second colorScheme.
	self assert: first colorScheme subscriberCount equals: 2
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testUpdateFileCoverageWithAnotherModelKeepsAnExplicitScheme [

	| presenter mine other |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	mine := MMCColorScheme new.
	mine overrideAt: 'Method' put: Color red.
	presenter colorScheme: mine.
	other := FamixJavaModel new.
	[
		presenter
			updateFileCoverage:
			(presenter modelFiles coverageFor: presenter currentFile)
			model: other.
		self assert: presenter colorScheme == mine.
		self assert: mine subscriberCount equals: 1.
		self deny: (presenter palette colorForType: 'Method' depth: 0)
			= (presenter palette defaultColorForType: 'Method' depth: 0) ]
		ensure: [ MMCColorSchemeRegistry removeFor: other ]
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testUpdateFileCoverageWithAnotherModelReleasesTheDefaultScheme [

	| presenter other oldScheme |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	oldScheme := presenter colorScheme.
	oldScheme overrideAt: 'Method' put: Color red.
	other := FamixJavaModel new.
	[
		presenter
			updateFileCoverage:
			(presenter modelFiles coverageFor: presenter currentFile)
			model: other.
		self assert:
			presenter colorScheme == (MMCColorSchemeRegistry for: other).
		self assert: presenter colorScheme isEmpty.
		self assert: oldScheme subscriberCount equals: 0.
		self
			assertDecoratorsOf: presenter
			matchPalette: (self referencePaletteTheme: presenter theme) ]
		ensure: [ MMCColorSchemeRegistry removeFor: other ]
]

{ #category : 'tests - scheme lifecycle' }
MMCCoveragePresenterColorsTest >> testUpdateFileCoverageWithTheSameModelKeepsTheDefaultScheme [

	| presenter oldScheme |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	oldScheme := presenter colorScheme.
	oldScheme overrideAt: 'Method' put: Color red.
	presenter
		updateFileCoverage:
		(presenter modelFiles coverageFor: presenter currentFile)
		model: model.
	self assert: presenter colorScheme == oldScheme.
	self assert: oldScheme subscriberCount equals: 1
]

{ #category : 'tests - button' }
MMCCoveragePresenterColorsTest >> testWholeModelLineHoldsTheTwoButtonsInOneColumn [

	| presenter column |
	self buildTwoFileFixture.
	presenter := self newPresenter.
	column := presenter wholeModelLineLayout children last.
	self assert: column children asArray equals: {
			presenter setRootFolderButton.
			presenter colorsButton }
]

{ #category : 'helpers' }
MMCCoveragePresenterColorsTest >> uncoveredColorsIn: aPresenter [

	^ (aPresenter plan segments
		   with: aPresenter decorators asArray
		   collect: [ :segment :decorator |
				   segment isUncovered
					   ifTrue: [ decorator highlightColor ]
					   ifFalse: [ nil ] ]) reject: #isNil
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> waitUpTo: someMilliseconds until: aBlock [
	"Let Morphic run (100 ms steps) until aBlock is true or someMilliseconds elapsed. Answer the final value of aBlock."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 100) wait.
			World doOneCycle.
			waited := waited + 100 ].
	^ aBlock value
]

{ #category : 'helpers - window' }
MMCCoveragePresenterColorsTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Skipped without World. Open aPresenter at its initialExtent (1300@700), wait for the tree rows and for the layout to be stable, evaluate aBlock with the window presenter, then always close the window and the color settings window (if any) and check that the number of windows is the same as before."

	| window windowsBefore previous |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := self systemWindowCount.
	self guarded: [
			[
				window := aPresenter open.
				window adapter widget extent: aPresenter initialExtent.
				self waitUpTo: 3000 until: [
						| rows |
						rows := aPresenter treePresenter adapter widget container
							        exposedRows.
						rows notNil and: [ rows notEmpty ] ].
				self waitUpTo: 3000 until: [
						| now |
						now := {
							       aPresenter treePresenter adapter widget bounds.
							       aPresenter textPresenter adapter widget bounds.
							       aPresenter colorsButton adapter widget bounds.
							       aPresenter setRootFolderButton adapter widget bounds }.
						previous = now or: [
								previous := now.
								false ] ].
				self waitUpTo: 1000 until: [ false ].
				aBlock value: window ] ensure: [
					aPresenter colorSettingsWindow ifNotNil: [ :colors |
							[ colors close ]
								on: Error
								do: [ :e | e return ] ].
					window ifNotNil: [
							[ window close ]
								on: Error
								do: [ :e | e return ] ] ] ].
	self assert: self systemWindowCount equals: windowsBefore
]

{ #category : 'fixture' }
MMCCoveragePresenterColorsTest >> writeText: aString to: aRelativeName [
	"UTF-8 text file in the temporary folder."

	| ref |
	ref := folder resolve: aRelativeName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
