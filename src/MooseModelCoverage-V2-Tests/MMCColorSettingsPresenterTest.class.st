"
Tests of MMCColorSettingsPresenter and of the Colors button of MMCCoveragePresenter, without any window (no graphical picker is opened).
"
Class {
	#name : 'MMCColorSettingsPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'scheme',
		'presenter'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> assertColor: aColor isCloseTo: anotherColor [
	"Equal up to the rounding of a 8 bit channel."

	self assert: (aColor red - anotherColor red) abs <= 0.01.
	self assert: (aColor green - anotherColor green) abs <= 0.01.
	self assert: (aColor blue - anotherColor blue) abs <= 0.01
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> colorOfSwatchOf: aTypeName in: aPresenter [
	"The color of the pixel of the swatch form shown in the Color column for the type."

	| form |
	form := aPresenter typeTable columns first readObject: aTypeName.
	self assert: form extent equals: 16 @ 16.
	^ form colorAt: 8 @ 8
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> countNotificationsOfScheme [
	"Subscribe a counter to the scheme of the test and answer a block answering the count."

	| count |
	count := 0.
	scheme whenChangedDo: [ count := count + 1 ].
	^ [ count ]
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> debounceProcessesCount [
	"Number of live debounce processes of the image."

	^ Process allInstances count: [ :each |
		  each name = 'MMCColorSettings debounce' and: [
			  each isTerminated not ] ]
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> guarded: aBlock [
	"Evaluate aBlock; a watchdog process raises an error in the test process after 30 s, and is always terminated."

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

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> presenterWithCounts: aDictionary do: aBlock [
	"Evaluate aBlock with a presenter on a new scheme and aDictionary; it is always closed afterwards."

	| other |
	other := MMCColorSettingsPresenter
		         on: MMCColorScheme new
		         counts: aDictionary.
	^ [ aBlock value: other ] ensure: [ other windowClosed ]
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> setUp [

	super setUp.
	scheme := MMCColorScheme new.
	presenter := MMCColorSettingsPresenter
		             on: scheme
		             counts: (OrderedDictionary new
				              at: 'Class' put: 3;
				              at: 'Method' put: 10;
				              at: 'Access' put: 10;
				              yourself)
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> systemWindowCount [

	^ World submorphs count: [ :each | each isSystemWindow ]
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> tearDown [

	presenter windowClosed.
	super tearDown
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testBlankFilterShowsEveryType [

	presenter filterField text: 'cla'.
	presenter filterField text: '   '.
	self
		assert: presenter displayedTypeNames
		equals: #( 'Access' 'Method' 'Class' ).
	presenter filterField text: ''.
	self
		assert: presenter displayedTypeNames
		equals: #( 'Access' 'Method' 'Class' )
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testChangingSelectionAppliesThePendingColor [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter selectTypeNamed: 'Method'.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self deny: presenter hasPendingColor
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testChangingSelectionAppliesThePendingColorOnceAndStopsTheDebounce [

	| count before |
	count := self countNotificationsOfScheme.
	before := self debounceProcessesCount.
	presenter debounceMilliseconds: 60000.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	self assert: self debounceProcessesCount equals: before + 1.
	presenter selectTypeNamed: 'Method'.
	self assert: count value equals: 1.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self assert: (scheme overrideFor: 'Method') isNil.
	self assert: self debounceProcessesCount equals: before
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testChoicesOnTwoTypesApplyBoth [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter selectTypeNamed: 'Method'.
	presenter chooseColor: Color blue.
	presenter flushPendingColor.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self assert: (scheme overrideFor: 'Method') equals: Color blue.
	self assert: scheme typeNamesOverridden equals: #( 'Class' 'Method' )
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testChooseColorShowsTheColorInTheEditorAtOnce [

	presenter selectTypeNamed: 'Class'.
	self assert: (presenter chooseColor: Color blue).
	self assert: presenter pendingColor equals: Color blue.
	self assert: presenter hexField text equals: '#0000FF'.
	self assert: presenter hasPendingColor.
	self assert: scheme isEmpty
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testChooseColorWithoutSelectionDoesNothing [

	self deny: (presenter chooseColor: Color red).
	self assert: scheme isEmpty
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testChooseColorWithoutSelectionShowsAMessage [

	self deny: (presenter chooseColor: Color red).
	self
		assert: presenter messageLabel label
		equals: 'Select a type first'.
	self deny: presenter hasPendingColor.
	self assert: presenter pendingColor isNil
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testChoosingTheSameColorAgainDoesNotNotify [

	| count |
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter flushPendingColor.
	count := self countNotificationsOfScheme.
	presenter chooseColor: Color red.
	presenter flushPendingColor.
	self assert: count value equals: 0
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testChosenColorIsMadeOpaque [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: (Color red alpha: 0.3).
	self assert: presenter pendingColor alpha equals: 1.
	presenter flushPendingColor.
	self assert: (scheme overrideFor: 'Class') alpha equals: 1
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testClosingAppliesPendingColorAndUnsubscribes [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter windowClosed.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self deny: presenter hasPendingColor.
	self assert: (presenter instVarNamed: 'subscription') isNil
]

{ #category : 'tests - real window' }
MMCColorSettingsPresenterTest >> testClosingTheRealWindowAppliesThePendingColorAndUnsubscribes [

	World ifNil: [ self skip: 'no world' ].
	self withExamplePresenterDo: [ :coverage |
			| window settings before |
			before := Process allInstances count: [ :each |
				          each name = 'MMCColorSettings debounce' and: [
					          each isTerminated not ] ].
			self guarded: [
					[
						window := MMCColorSettingsPresenter openOn: coverage.
						settings := window presenter.
						self assert: coverage colorScheme subscriberCount equals: 2.
						settings debounceMilliseconds: 60000.
						settings selectTypeNamed: 'Class'.
						settings chooseColor: Color red.
						self assert: settings hasPendingColor ] ensure: [
							window ifNotNil: [
									[ window close ]
										on: Error
										do: [ :e | e return ] ] ] ].
			self
				assert: (coverage colorScheme overrideFor: 'Class')
				equals: Color red.
			self deny: settings hasPendingColor.
			self assert: coverage colorScheme subscriberCount equals: 1.
			self assert: settings coveragePresenter isNil.
			self
				assert: (Process allInstances count: [ :each |
						 each name = 'MMCColorSettings debounce' and: [
							 each isTerminated not ] ])
				equals: before ]
]

{ #category : 'tests - coverage presenter' }
MMCColorSettingsPresenterTest >> testClosingTheSettingsReleasesTheReferenceOnTheCoveragePresenter [

	self withExamplePresenterDo: [ :coverage |
			| settings |
			settings := MMCColorSettingsPresenter forCoveragePresenter:
				            coverage.
			self assert: settings coveragePresenter == coverage.
			settings windowClosed.
			self assert: settings coveragePresenter isNil.
			self assert: coverage colorScheme subscriberCount equals: 1 ]
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testColorSourceColumnIsAutoThenCustom [

	| column |
	column := presenter typeTable columns last.
	self assert: column title equals: 'Color source'.
	self assert: (column readObject: 'Class') equals: 'auto'.
	scheme overrideAt: 'Class' put: Color red.
	self assert: (column readObject: 'Class') equals: 'custom'.
	self assert: (column readObject: 'Method') equals: 'auto'.
	scheme removeOverrideFor: 'Class'.
	self assert: (column readObject: 'Class') equals: 'auto'
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testColorSourceIsCustomWhileAColorIsPending [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color blue.
	self
		assert: (presenter typeTable columns last readObject: 'Class')
		equals: 'custom'.
	self assert: (presenter isCustom: 'Class').
	self deny: (presenter isCustom: 'Method')
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testColorsButtonIsBelowSetRootFolderButton [

	| coverage box |
	coverage := MMCCoveragePresenter newMultiFileExample.
	box := coverage rootAndColorButtonsLayout.
	self assert: box children asArray equals: {
			coverage setRootFolderButton.
			coverage colorsButton }
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testColorsButtonOnExampleAndOpenerHook [

	| coverage calls |
	coverage := MMCCoveragePresenter newMultiFileExample.
	calls := OrderedCollection new.
	coverage colorSettingsOpener: [ :each |
			calls add: each.
			nil ].
	self assert: coverage colorsButton isEnabled.
	coverage openColorSettings.
	self assert: calls asArray equals: { coverage }.
	self assert: coverage colorSettingsWindow isNil
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testColumnTitlesAndKinds [

	self
		assert: (presenter typeTable columns collect: #title) asArray
		equals: #( 'Color' 'Type' 'Entities' 'Color source' ).
	self
		assert: presenter typeTable columns first class
		equals: SpImageTableColumn.
	self
		assert: (presenter typeTable columns second readObject: 'Class')
		equals: 'Class'
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testDebounceDoesNotApplyBeforeItsDelay [

	| count |
	count := self countNotificationsOfScheme.
	presenter debounceMilliseconds: 60000.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	(Delay forMilliseconds: 100) wait.
	self assert: presenter hasPendingColor.
	self assert: count value equals: 0.
	self assert: scheme isEmpty
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testDefaultChooserIsAnInjectableBlockOfOneArgumentAndIsNotEvaluated [
	"Only reads the default chooser (its evaluation would open the modal graphical picker)."

	| fresh |
	fresh := MMCColorSettingsPresenter
		         on: MMCColorScheme new
		         counts: Dictionary new.
	[ self assert: fresh colorChooser numArgs equals: 1 ] ensure: [
		fresh windowClosed ]
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testDeferredApplicationOfAnObsoleteChoiceIsIgnored [
	"The debounce process defers the application with the generation of its choice: a flush made meanwhile makes it obsolete."

	| count |
	count := self countNotificationsOfScheme.
	presenter debounceMilliseconds: 20.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter flushPendingColor.
	presenter chooseColor: Color blue.
	presenter debounceMilliseconds: 60000.
	presenter chooseColor: Color green.
	(Delay forMilliseconds: 200) wait.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self assert: count value equals: 1.
	self assert: presenter hasPendingColor
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testEachChoiceReplacesThePreviousDebounceProcess [

	| before |
	before := self debounceProcessesCount.
	presenter debounceMilliseconds: 60000.
	presenter selectTypeNamed: 'Class'.
	5 timesRepeat: [ presenter chooseColor: Color random ].
	self assert: self debounceProcessesCount equals: before + 1.
	presenter flushPendingColor.
	self assert: self debounceProcessesCount equals: before
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testEmptyCountsKeepTheNoTypeMessageWhenFiltering [

	self presenterWithCounts: Dictionary new do: [ :other |
			other filterField text: 'abc'.
			self
				assert: other messageLabel label
				equals: 'No Famix type with source anchors in this model.' ]
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testEmptyCountsShowAMessage [

	| empty |
	empty := MMCColorSettingsPresenter
		         on: MMCColorScheme new
		         counts: Dictionary new.
	self assert: empty displayedTypeNames isEmpty.
	self assert:
		(empty messageLabel label includesSubstring: 'No Famix type').
	empty windowClosed
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testEmptyCountsShowTheNoTypeMessageAndSelectNothing [

	self presenterWithCounts: Dictionary new do: [ :other |
			self assert: other displayedTypeNames isEmpty.
			self
				assert: other messageLabel label
				equals: 'No Famix type with source anchors in this model.'.
			self assert: other selectedType isNil.
			self deny: (other chooseColor: Color red).
			self assert: other messageLabel label equals: 'Select a type first'.
			self assert: other colorScheme isEmpty ]
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testEntitiesColumnShowsTheCounts [

	| column |
	column := presenter typeTable columns third.
	self assert: column title equals: 'Entities'.
	self assert: (column readObject: 'Method') equals: '10'.
	self assert: (column readObject: 'Class') equals: '3'
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testFilterIsCaseInsensitiveAndKeepsTheOrder [

	presenter filterField text: 'CLA'.
	self assert: presenter displayedTypeNames equals: #( 'Class' ).
	presenter filterField text: 'S'.
	self
		assert: presenter displayedTypeNames
		equals: #( 'Access' 'Class' )
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testFilterKeepsMatchingTypes [

	presenter filterField text: 'ac'.
	self assert: presenter displayedTypeNames equals: #( 'Access' )
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testFilterKeepsTheSelectionWhenTheTypeIsStillThere [

	presenter selectTypeNamed: 'Class'.
	presenter filterField text: 'cl'.
	self assert: presenter selectedType equals: 'Class'.
	self
		assert: presenter typeTable selection selectedItem
		equals: 'Class'
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testFilterWithoutMatchShowsAMessage [

	presenter filterField text: 'zzz'.
	self assert: presenter displayedTypeNames isEmpty.
	self
		assert: presenter messageLabel label
		equals: 'No type matches the filter.'.
	presenter filterField text: ''.
	self assert: presenter messageLabel label equals: ''
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testFlushAppliesOnceAndTheDebounceThenDoesNothing [

	| count |
	count := self countNotificationsOfScheme.
	presenter debounceMilliseconds: 40.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter chooseColor: Color blue.
	self assert: presenter flushPendingColor.
	self assert: count value equals: 1.
	self assert: (scheme overrideFor: 'Class') equals: Color blue.
	(Delay forMilliseconds: 300) wait.
	self assert: count value equals: 1
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testFlushWithoutPendingColorAnswersFalseAndDoesNotNotify [

	| count |
	count := self countNotificationsOfScheme.
	self deny: presenter flushPendingColor.
	self assert: count value equals: 0
]

{ #category : 'tests - coverage presenter' }
MMCColorSettingsPresenterTest >> testForCoveragePresenterEditsTheSchemeOfTheCoverageWindow [

	self withExamplePresenterDo: [ :coverage |
			| settings before |
			settings := MMCColorSettingsPresenter forCoveragePresenter:
				            coverage.
			[
				before := coverage palette colorForType: 'Class' depth: 0.
				settings selectTypeNamed: 'Class'.
				settings chooseColor: Color red.
				settings flushPendingColor.
				self
					assert: (coverage colorScheme overrideFor: 'Class')
					equals: Color red.
				self deny:
					(coverage palette colorForType: 'Class' depth: 0) = before.
				settings resetAll.
				self
					assert: (coverage palette colorForType: 'Class' depth: 0)
					equals: before ] ensure: [ settings windowClosed ] ]
]

{ #category : 'tests - coverage presenter' }
MMCColorSettingsPresenterTest >> testForCoveragePresenterFollowsTheThemeOfTheCoveragePresenter [

	self withExamplePresenterDo: [ :coverage |
			| settings dark |
			dark := coverage palette defaultColorForType: 'Class' depth: 0.
			coverage applyTheme: #light.
			settings := MMCColorSettingsPresenter forCoveragePresenter:
				            coverage.
			[
				self deny: (settings effectiveColorOf: 'Class') = dark.
				self
					assert: (settings effectiveColorOf: 'Class')
					equals: (coverage palette defaultColorForType: 'Class' depth: 0) ]
				ensure: [ settings windowClosed ] ]
]

{ #category : 'tests - coverage presenter' }
MMCColorSettingsPresenterTest >> testForCoveragePresenterListsTheTypesOfTheInventory [

	self withExamplePresenterDo: [ :coverage |
			| settings |
			settings := MMCColorSettingsPresenter forCoveragePresenter:
				            coverage.
			[
				self assert: settings colorScheme == coverage colorScheme.
				self assert: settings coveragePresenter == coverage.
				self
					assert: settings displayedTypeNames asSet
					equals: coverage modelFiles typeNames asSet.
				self
					assert: settings windowTitleText
					equals: 'Colors - ' , coverage modelName ] ensure: [
				settings windowClosed ] ]
]

{ #category : 'tests - coverage presenter' }
MMCColorSettingsPresenterTest >> testForCoveragePresenterShowsThePaletteDefaultColors [

	self withExamplePresenterDo: [ :coverage |
			| settings |
			settings := MMCColorSettingsPresenter forCoveragePresenter:
				            coverage.
			[
				coverage modelFiles typeNames do: [ :type |
						self
							assert: (settings effectiveColorOf: type)
							equals: (coverage palette defaultColorForType: type depth: 0) ] ]
				ensure: [ settings windowClosed ] ]
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testHexColorIsAppliedOnFlush [

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: '#FF0000'.
	self assert: presenter hasPendingColor.
	self assert: (presenter effectiveColorOf: 'Method') equals: Color red.
	self assert: (scheme overrideFor: 'Method') isNil.
	self assert: presenter flushPendingColor.
	self assert: (scheme overrideFor: 'Method') equals: Color red.
	self deny: presenter hasPendingColor.
	self assert: (presenter isCustom: 'Method')
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testHexParsing [

	self
		assert: (MMCColorSettingsPresenter colorFromHex: '#00ff00')
		equals: Color green.
	self
		assert: (MMCColorSettingsPresenter colorFromHex: '0000FF')
		equals: Color blue.
	self assert: (MMCColorSettingsPresenter colorFromHex: '#12') isNil.
	self
		assert: (MMCColorSettingsPresenter hexOf: Color red)
		equals: '#FF0000'
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testHexWithSurroundingBlanksIsAccepted [

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: '  #FF8800 '.
	presenter flushPendingColor.
	self
		assert: (scheme overrideFor: 'Method')
		equals: (MMCColorSettingsPresenter colorFromHex: '#FF8800')
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testHexWithoutHashIsAccepted [
	"Documents the behavior: the # is optional (the field is then rewritten with the # on the next display)."

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: 'ff8800'.
	self assert: presenter hasPendingColor.
	presenter flushPendingColor.
	self
		assert: (scheme overrideFor: 'Method')
		equals: (MMCColorSettingsPresenter colorFromHex: '#FF8800')
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testInvalidHexIsReportedWithoutException [

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: 'nope'.
	self assert:
		(presenter messageLabel label includesSubstring: 'Invalid').
	self deny: presenter hasPendingColor.
	self assert: scheme isEmpty
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testInvalidHexValuesAreReportedWithoutExceptionOrOverride [

	presenter selectTypeNamed: 'Method'.
	#( 'nope' '#12' '#GGGGGG' '#FF880' '#FF88000' '' '#' '12 34 56' )
		do: [ :each |
				self shouldnt: [ presenter hexField text: each ] raise: Error.
				self
					assert: presenter messageLabel label
					equals: 'Invalid color: expected #RRGGBB'.
				self deny: presenter hasPendingColor.
				presenter flushPendingColor.
				self assert: scheme isEmpty ]
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testLastColorWinsAfterDebounce [

	presenter debounceMilliseconds: 30.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter chooseColor: Color blue.
	(Delay forMilliseconds: 300) wait.
	self assert: (scheme overrideFor: 'Class') equals: Color blue
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testLoadingTheEditorDoesNotMakeAColorPending [

	presenter selectTypeNamed: 'Class'.
	presenter selectTypeNamed: 'Method'.
	self deny: presenter hasPendingColor.
	self assert: presenter flushPendingColor equals: false.
	self assert: scheme isEmpty
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testLowerCaseHexIsAccepted [
	"Documents the behavior: lower case digits are accepted, like the upper case ones."

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: '#ff8800'.
	self assert: presenter hasPendingColor.
	presenter flushPendingColor.
	self
		assert: (scheme overrideFor: 'Method')
		equals: (MMCColorSettingsPresenter colorFromHex: '#FF8800')
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testModelWithoutTypesInTheCoveragePresenterGivesAnEmptyTable [
	"A presenter without inventory has no type counts."

	| coverage coveragePresenter settings |
	coveragePresenter := MMCCoveragePresenter newMultiFileExample.
	coverage := coveragePresenter model.
	[
		coveragePresenter := MMCCoveragePresenter
			                     on:
				                     (coveragePresenter modelFiles coverageFor:
					                      coveragePresenter currentFile)
			                     model: coverage.
		settings := MMCColorSettingsPresenter forCoveragePresenter:
			            coveragePresenter.
		[
			self assert: settings displayedTypeNames isEmpty.
			self assert:
				(settings messageLabel label includesSubstring: 'No Famix type') ]
			ensure: [ settings windowClosed ] ] ensure: [
			MMCColorSchemeRegistry removeFor: coverage.
			coverage rootFolder asFileReference ensureDeleteAll ]
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testNoZombieProcessAfterManyChoicesAndAClose [

	| before |
	before := self debounceProcessesCount.
	presenter debounceMilliseconds: 60000.
	presenter selectTypeNamed: 'Class'.
	10 timesRepeat: [ presenter chooseColor: Color random ].
	presenter selectTypeNamed: 'Method'.
	10 timesRepeat: [ presenter chooseColor: Color random ].
	presenter windowClosed.
	self assert: self debounceProcessesCount equals: before
]

{ #category : 'tests - real window' }
MMCColorSettingsPresenterTest >> testOpenOnOpensANonModalWindowWithTheExpectedTitleAndExtent [
	"Real window: openOn: returns at once (non modal) with the open window; it is always closed in ensure: and the number of windows is checked."

	World ifNil: [ self skip: 'no world' ].
	self withExamplePresenterDo: [ :coverage |
			| windowsBefore window |
			windowsBefore := self systemWindowCount.
			self guarded: [
					[
						window := MMCColorSettingsPresenter openOn: coverage.
						self assert: (window isKindOf: SpWindowPresenter).
						self assert: window isOpen.
						self
							assert: window title
							equals: 'Colors - ' , coverage modelName.
						self assert: window presenter initialExtent equals: 560 @ 420.
						self assert: window initialExtent equals: 560 @ 420.
						self assert: self systemWindowCount equals: windowsBefore + 1 ]
						ensure: [
								window ifNotNil: [
										[ window close ]
											on: Error
											do: [ :e | e return ] ] ] ].
			self assert: self systemWindowCount equals: windowsBefore.
			self assert: coverage colorScheme subscriberCount equals: 1 ]
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testPickButtonActionUsesTheInjectedChooser [

	presenter selectTypeNamed: 'Method'.
	presenter colorChooser: [ :current | Color blue ].
	presenter pickButton click.
	self assert: presenter pendingColor equals: Color blue
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testPickButtonLabelEndsWithAnEllipsis [

	self
		assert: presenter pickButton label
		equals: 'Pick' , (String with: (Character value: 16r2026))
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testPickChooserAnsweringNilChangesNothing [

	| calls |
	calls := 0.
	presenter selectTypeNamed: 'Class'.
	presenter colorChooser: [ :current |
			calls := calls + 1.
			nil ].
	presenter pickColor.
	self assert: calls equals: 1.
	self deny: presenter hasPendingColor.
	self assert: scheme isEmpty
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testPickChooserReceivesTheEffectiveColorAndItsColorIsChosen [

	| received |
	presenter selectTypeNamed: 'Class'.
	scheme overrideAt: 'Class' put: Color green.
	presenter colorChooser: [ :current |
			received := current.
			Color red ].
	presenter pickColor.
	self assert: received equals: Color green.
	self assert: presenter pendingColor equals: Color red.
	self assert: presenter hexField text equals: '#FF0000'.
	presenter flushPendingColor.
	self assert: (scheme overrideFor: 'Class') equals: Color red
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testPickColorUsesTheInjectedChooser [

	presenter selectTypeNamed: 'Class'.
	presenter colorChooser: [ :current | Color red ].
	presenter pickColor.
	presenter flushPendingColor.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	presenter colorChooser: [ :current | nil ].
	presenter pickColor.
	self deny: presenter hasPendingColor
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testPickWithoutSelectionDoesNotCallTheChooser [

	| calls |
	calls := 0.
	presenter colorChooser: [ :current |
			calls := calls + 1.
			Color red ].
	presenter pickColor.
	self assert: calls equals: 0.
	self
		assert: presenter messageLabel label
		equals: 'Select a type first'.
	self assert: scheme isEmpty
]

{ #category : 'tests - pick and coverage' }
MMCColorSettingsPresenterTest >> testPickedColorIsDebouncedLikeAnyChoice [

	presenter debounceMilliseconds: 30.
	presenter selectTypeNamed: 'Method'.
	presenter colorChooser: [ :current | Color blue ].
	presenter pickColor.
	self assert:
		(self
			 waitUpTo: 3000
			 until: [ (scheme overrideFor: 'Method') notNil ]).
	self assert: (scheme overrideFor: 'Method') equals: Color blue
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testResetAllDropsThePendingColor [

	| count |
	count := self countNotificationsOfScheme.
	presenter debounceMilliseconds: 40.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter resetAll.
	self deny: presenter hasPendingColor.
	(Delay forMilliseconds: 250) wait.
	self assert: count value equals: 0.
	self assert: scheme isEmpty
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testResetAllOnAnEmptySchemeDoesNotNotify [

	| count |
	count := self countNotificationsOfScheme.
	presenter resetAll.
	self assert: count value equals: 0
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testResetAllRemovesEveryOverrideAndNotifiesOnce [

	| count |
	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Method' put: Color green.
	count := self countNotificationsOfScheme.
	presenter resetAll.
	self assert: count value equals: 1.
	self assert: scheme isEmpty.
	self deny: (presenter isCustom: 'Class')
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testResetTypeAndResetAll [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter flushPendingColor.
	scheme overrideAt: 'Method' put: Color green.
	presenter resetSelectedType.
	self assert: (scheme overrideFor: 'Class') isNil.
	self assert: (scheme overrideFor: 'Method') equals: Color green.
	presenter resetAll.
	self assert: scheme isEmpty
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testResetTypeDropsThePendingColor [

	| count |
	count := self countNotificationsOfScheme.
	presenter debounceMilliseconds: 40.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter resetSelectedType.
	self deny: presenter hasPendingColor.
	(Delay forMilliseconds: 250) wait.
	self assert: count value equals: 0.
	self assert: scheme isEmpty
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testResetTypeRemovesOnlyThatOverrideAndNotifiesOnce [

	| count |
	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Method' put: Color green.
	count := self countNotificationsOfScheme.
	presenter selectTypeNamed: 'Class'.
	presenter resetSelectedType.
	self assert: count value equals: 1.
	self assert: (scheme overrideFor: 'Class') isNil.
	self assert: (scheme overrideFor: 'Method') equals: Color green.
	self deny: (presenter isCustom: 'Class').
	self
		assert: presenter hexField text
		equals: (MMCColorSettingsPresenter hexOf:
				 (presenter effectiveColorOf: 'Class'))
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testResetTypeWithoutSelectionDoesNothing [

	scheme overrideAt: 'Class' put: Color red.
	self shouldnt: [ presenter resetSelectedType ] raise: Error.
	self assert: (scheme overrideFor: 'Class') equals: Color red
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testSchemeChangedElsewhereIsShownInTheTable [

	scheme overrideAt: 'Method' put: Color green.
	self assert: (presenter isCustom: 'Method').
	self
		assertColor: (self colorOfSwatchOf: 'Method' in: presenter)
		isCloseTo: Color green.
	scheme reset.
	self deny: (presenter isCustom: 'Method')
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testSchemeChangedElsewhereReloadsTheEditorOfTheSelectedType [

	presenter selectTypeNamed: 'Class'.
	scheme overrideAt: 'Class' put: Color red.
	self assert: presenter hexField text equals: '#FF0000'.
	self deny: presenter hasPendingColor
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testSelectingATypeThatIsNotDisplayedDoesNothing [

	presenter selectTypeNamed: 'Class'.
	presenter selectTypeNamed: 'Nope'.
	self assert: presenter selectedType equals: 'Class'
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testSelectingAnotherTypeChangesTheEditor [

	presenter selectTypeNamed: 'Class'.
	presenter selectTypeNamed: 'Method'.
	self assert: presenter selectedType equals: 'Method'.
	self
		assert: presenter hexField text
		equals: (MMCColorSettingsPresenter hexOf:
				 (presenter effectiveColorOf: 'Method')).
	self assert: scheme isEmpty
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testSelectionLoadsTheEditorWithTheDefaultColor [

	| default |
	self assert: presenter hexField text equals: ''.
	presenter selectTypeNamed: 'Class'.
	default := presenter effectiveColorOf: 'Class'.
	self assert: presenter selectedType equals: 'Class'.
	self
		assert: presenter hexField text
		equals: (MMCColorSettingsPresenter hexOf: default).
	self assert: presenter previewPresenter image notNil.
	self deny: presenter hasPendingColor.
	self assert: scheme isEmpty
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testSelectionLoadsTheEditorWithTheOverride [

	scheme overrideAt: 'Method' put: (Color r: 1 g: 136 / 255.0 b: 0).
	presenter selectTypeNamed: 'Method'.
	self assert: presenter hexField text equals: '#FF8800'
]

{ #category : 'tests - real window' }
MMCColorSettingsPresenterTest >> testSettingsWindowSurvivesTheCloseOfTheCoverageWindow [
	"The coverage window is closed first: choosing, flushing and closing the settings window raise no error."

	World ifNil: [ self skip: 'no world' ].
	self withExamplePresenterDo: [ :coverage |
			| coverageWindow window settings |
			self guarded: [
					[
						coverageWindow := coverage open.
						coverage openColorSettings.
						window := coverage colorSettingsWindow.
						settings := window presenter.
						coverageWindow close.
						self
							shouldnt: [
									settings selectTypeNamed: 'Class'.
									settings chooseColor: Color red.
									settings flushPendingColor.
									settings resetAll.
									settings chooseColor: Color blue ]
							raise: Error ] ensure: [
							window ifNotNil: [
									[ window close ]
										on: Error
										do: [ :e | e return ] ].
							[ coverageWindow close ]
								on: Error
								do: [ :e | e return ] ] ].
			self
				assert: (coverage colorScheme overrideFor: 'Class')
				equals: Color blue ]
]

{ #category : 'tests - debounce' }
MMCColorSettingsPresenterTest >> testSeveralQuickChoicesGiveOneOverrideOfTheLastColor [

	| count |
	count := self countNotificationsOfScheme.
	presenter debounceMilliseconds: 40.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter chooseColor: Color green.
	presenter chooseColor: Color blue.
	self assert: presenter hasPendingColor.
	self assert: count value equals: 0.
	self assert:
		(self waitUpTo: 3000 until: [ presenter hasPendingColor not ]).
	(Delay forMilliseconds: 150) wait.
	self assert: count value equals: 1.
	self assert: (scheme overrideFor: 'Class') equals: Color blue
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testSwatchColumnShowsTheDefaultColorWithoutOverride [

	| default |
	default := (MMCColorPalette
		            forTypeNames: #( 'Access' 'Class' 'Method' )
		            theme: #dark) defaultColorForType: 'Class' depth: 0.
	self assert: (presenter effectiveColorOf: 'Class') equals: default.
	self
		assertColor: (self colorOfSwatchOf: 'Class' in: presenter)
		isCloseTo: default
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testSwatchColumnShowsTheOverride [

	scheme overrideAt: 'Class' put: Color red.
	self
		assertColor: (self colorOfSwatchOf: 'Class' in: presenter)
		isCloseTo: Color red.
	self assert: (presenter effectiveColorOf: 'Class') equals: Color red.
	self assert: (presenter effectiveColorOf: 'Method') ~= Color red
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testSwatchColumnShowsThePendingColor [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color blue.
	self
		assertColor: (self colorOfSwatchOf: 'Class' in: presenter)
		isCloseTo: Color blue.
	self assert: (scheme overrideFor: 'Class') isNil
]

{ #category : 'tests - table' }
MMCColorSettingsPresenterTest >> testTiesInCountsAreSortedByName [

	self
		presenterWithCounts: (OrderedDictionary new
				 at: 'Beta' put: 5;
				 at: 'Alpha' put: 5;
				 at: 'Gamma' put: 9;
				 at: 'Delta' put: 1;
				 yourself)
		do: [ :other |
				self
					assert: other displayedTypeNames
					equals: #( 'Gamma' 'Alpha' 'Beta' 'Delta' ).
				self
					assert: other typeTable items asArray
					equals: #( 'Gamma' 'Alpha' 'Beta' 'Delta' ) ]
]

{ #category : 'tests' }
MMCColorSettingsPresenterTest >> testTypesAreSortedByDecreasingCountThenName [

	self
		assert: presenter displayedTypeNames
		equals: #( 'Access' 'Method' 'Class' )
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testValidHexAfterAnInvalidOneClearsTheMessage [

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: 'nope'.
	presenter hexField text: '#00FF00'.
	self assert: presenter messageLabel label equals: ''.
	self assert: presenter hasPendingColor
]

{ #category : 'tests - editor' }
MMCColorSettingsPresenterTest >> testValidHexColorBecomesAnOverrideAfterFlush [

	presenter selectTypeNamed: 'Method'.
	presenter hexField text: '#FF8800'.
	self assert: presenter hasPendingColor.
	self assert: (scheme overrideFor: 'Method') isNil.
	presenter flushPendingColor.
	self
		assert: (scheme overrideFor: 'Method')
		equals: (MMCColorSettingsPresenter colorFromHex: '#FF8800').
	self assert: (scheme overrideFor: 'Method') alpha equals: 1.
	self assert: presenter hexField text equals: '#FF8800'
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testWindowClosedAppliesThePendingColorAndUnsubscribes [

	| count before |
	before := self debounceProcessesCount.
	presenter debounceMilliseconds: 60000.
	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	self assert: scheme subscriberCount equals: 1.
	count := self countNotificationsOfScheme.
	presenter windowClosed.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self assert: count value equals: 1.
	self assert: scheme subscriberCount equals: 1.
	self assert: self debounceProcessesCount equals: before.
	scheme overrideAt: 'Class' put: Color blue.
	self assert: count value equals: 2
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testWindowClosedLeavesNoSubscriberOfThePresenter [

	self assert: scheme subscriberCount equals: 1.
	presenter windowClosed.
	self assert: scheme subscriberCount equals: 0
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testWindowClosedTwiceIsHarmless [

	presenter selectTypeNamed: 'Class'.
	presenter chooseColor: Color red.
	presenter windowClosed.
	self shouldnt: [ presenter windowClosed ] raise: Error.
	self assert: (scheme overrideFor: 'Class') equals: Color red
]

{ #category : 'tests - reset and close' }
MMCColorSettingsPresenterTest >> testWindowClosedWithoutCoveragePresenterDoesNotFail [

	self assert: presenter coveragePresenter isNil.
	self shouldnt: [ presenter windowClosed ] raise: Error
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> waitUpTo: someMilliseconds until: aBlock [
	"Poll aBlock every 20 ms, letting the UI process run its deferred actions."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 20) wait.
			waited := waited + 20 ].
	^ aBlock value
]

{ #category : 'helpers' }
MMCColorSettingsPresenterTest >> withExamplePresenterDo: aBlock [
	"Evaluate aBlock with a not opened multi file example coverage presenter, then close its window, forget the scheme of its model and delete its temporary folder."

	| coverage |
	coverage := MMCCoveragePresenter newMultiFileExample.
	^ [ aBlock value: coverage ] ensure: [
			  [ coverage window ifNotNil: [ :aWindow | aWindow close ] ]
				  on: Error
				  do: [ :e | e return ].
			  MMCColorSchemeRegistry removeFor: coverage model.
			  coverage model rootFolder asFileReference ensureDeleteAll ]
]
