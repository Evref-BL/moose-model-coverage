"
Tests of the nil guard of MMCCoveragePresenter>>textSelectionChangedTo: and of the 'Inspect' context menu of the tree (treeContextMenu, inspectAction, inspectAction:, inspectTreeEntity). The inspection action is injectable and replaced by a recorder: no real inspector is ever opened. API facts (Pharo 13 Spec2): treePresenter contextMenu answers the block set by contextMenu: (evaluated at each popup); SpMenuPresenter menuGroups -> groups, SpMenuGroupPresenter menuItems -> items; SpMenuItemPresenter name, isEnabled (boolean or block), action (cull: item).
"
Class {
	#name : 'MMCCoveragePresenterInspectTest',
	#superclass : 'TestCase',
	#instVars : [
		'fixture'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> buildSmallFixture [
	"Text of 100 characters. Hierarchy: pkgA(Alpha(run, count), Aardvark), pkgB(Beta(stop), Gamma(abort)), pkgC(Delta). Regions: Alpha 1-50, run 10-30, count 35-45, Beta 60-90, stop 70-80. Never covered: pkgC, Delta, Aardvark, Gamma, abort (copy of MMCCoveragePresenterTreeTest)."

	| d |
	d := Dictionary new.
	d at: #pkgA put: (self named: FamixJavaPackage name: 'pkgA').
	d at: #pkgB put: (self named: FamixJavaPackage name: 'pkgB').
	d at: #pkgC put: (self named: FamixJavaPackage name: 'pkgC').
	d at: #alpha put: (self named: FamixJavaClass name: 'Alpha').
	d at: #aardvark put: (self named: FamixJavaClass name: 'Aardvark').
	d at: #beta put: (self named: FamixJavaClass name: 'Beta').
	d at: #gamma put: (self named: FamixJavaClass name: 'Gamma').
	d at: #delta put: (self named: FamixJavaClass name: 'Delta').
	d at: #run put: (self named: FamixJavaMethod name: 'run').
	d at: #count put: (self named: FamixJavaAttribute name: 'count').
	d at: #stop put: (self named: FamixJavaMethod name: 'stop').
	d at: #abort put: (self named: FamixJavaMethod name: 'abort').
	(d at: #pkgA)
		addType: (d at: #alpha);
		addType: (d at: #aardvark).
	(d at: #pkgB)
		addType: (d at: #beta);
		addType: (d at: #gamma).
	(d at: #pkgC) addType: (d at: #delta).
	(d at: #alpha)
		addMethod: (d at: #run);
		addAttribute: (d at: #count).
	(d at: #beta) addMethod: (d at: #stop).
	(d at: #gamma) addMethod: (d at: #abort).
	d at: #model put: (self modelWith:
			 (d select: [ :each | each isKindOf: FamixJavaEntity ]) values).
	d at: #coverage put: (self coverageOfSize: 100 regions: {
				 (self regionFor: (d at: #alpha) from: 1 to: 50).
				 (self regionFor: (d at: #run) from: 10 to: 30).
				 (self regionFor: (d at: #count) from: 35 to: 45).
				 (self regionFor: (d at: #beta) from: 60 to: 90).
				 (self regionFor: (d at: #stop) from: 70 to: 80) }).
	^ d
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> coverageOfSize: aSize regions: aCollection [
	"Coverage without file. Regions must be sorted by start, then by decreasing size."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: (String new: aSize withAll: $x)
			   regions: aCollection asOrderedCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> fixtureAt: aKey [
	"Named element of the small fixture (entities, #model, #coverage)."

	fixture ifNil: [ fixture := self buildSmallFixture ].
	^ fixture at: aKey
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> inspectItemOf: aMenu [
	"The only item of the menu (checks there is exactly one, named Inspect)."

	| items |
	items := self menuItemsOf: aMenu.
	self assert: items size equals: 1.
	self assert: items first name equals: 'Inspect'.
	^ items first
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> isEnabledItem: anItem [
	"isEnabled answers a boolean or a block answering a boolean (Spec2 accepts both)."

	| enabled |
	enabled := anItem isEnabled.
	^ enabled isBlock
		  ifTrue: [ enabled value ]
		  ifFalse: [ enabled ]
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> isInspectEnabledIn: aPresenter [
	"Builds a menu now and answers whether its Inspect item is enabled."

	^ self isEnabledItem:
		  (self inspectItemOf: aPresenter treeContextMenu)
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> menuItemsOf: aMenu [
	"All the items of all the groups of an SpMenuPresenter."

	^ aMenu menuGroups
		  inject: OrderedCollection new
		  into: [ :all :group |
				  all
					  addAll: group menuItems;
					  yourself ]
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> modelWith: aCollection [

	| aModel |
	aModel := FamixJavaModel new.
	aCollection do: [ :each | aModel add: each ].
	^ aModel
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> named: aFamixClass name: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> newPresenter [
	"Not opened presenter (null application) on the small fixture: coverage and Moose model."

	^ MMCCoveragePresenter
		  on: (self fixtureAt: #coverage)
		  model: (self fixtureAt: #model)
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> newPresenterWithoutModel [
	"Presenter whose tree is empty (nil Moose model)."

	^ MMCCoveragePresenter on: (self fixtureAt: #coverage) model: nil
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> recordInspectionsOf: aPresenter [
	"Replace the inspect action of aPresenter by a recorder; answer the collection of the entities received (no inspector is opened)."

	| calls |
	calls := OrderedCollection new.
	aPresenter inspectAction: [ :entity | calls add: entity ].
	^ calls
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> regionFor: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> selectName: aName in: aPresenter [
	"Select in the tree the entity of the fixture with that key."

	aPresenter selectEntityInTree: (self fixtureAt: aName)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectActionDefaultIsAOneArgumentBlock [
	"The default action is a block with one argument (it does anEntity inspect: never evaluated here)."

	| action |
	action := self newPresenter inspectAction.
	self assert: action isBlock.
	self assert: action numArgs equals: 1
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectActionSetterStoresTheBlock [

	| presenter action |
	presenter := self newPresenter.
	action := [ :entity | entity ].
	presenter inspectAction: action.
	self assert: presenter inspectAction == action
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemActionCallsTheActionOnceWithTheSelectedEntity [
	"Run the action of the Inspect item of a menu built after selecting Beta."

	| presenter calls item |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	self selectName: #beta in: presenter.
	item := self inspectItemOf: presenter treeContextMenu.
	item action cull: item.
	self assert: calls size equals: 1.
	self assert: calls first == (self fixtureAt: #beta)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemActionWithoutSelectionCallsNothing [
	"The action itself (not only the disabled state of the item) does nothing without selection."

	| presenter calls item |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	item := self inspectItemOf: presenter treeContextMenu.
	item action cull: item.
	self assert: calls isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemIsDisabledForAnEntityNotInTheTree [
	"Object new is not visible: selectEntityInTree: clears the selection (even after a real selection), so the item is disabled."

	| presenter |
	presenter := self newPresenter.
	self selectName: #alpha in: presenter.
	presenter selectEntityInTree: Object new.
	self assert: presenter selectedEntityInTree isNil.
	self deny: (self isInspectEnabledIn: presenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemIsDisabledWithoutModel [
	"No Moose model: the tree is empty, nothing can be selected: the item stays disabled."

	| presenter |
	presenter := self newPresenterWithoutModel.
	self assert: presenter treePresenter roots isEmpty.
	self deny: (self isInspectEnabledIn: presenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemIsDisabledWithoutSelection [

	| presenter |
	presenter := self newPresenter.
	self assert: presenter selectedEntityInTree isNil.
	self deny: (self isInspectEnabledIn: presenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemIsEnabledInWholeModelModeForAnEntityWithoutRegion [
	"The menu does not depend on the Whole model check box: Aardvark (no region, greyed) selected in #all mode gives an enabled item."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	self selectName: #aardvark in: presenter.
	self assert:
		presenter selectedEntityInTree == (self fixtureAt: #aardvark).
	self assert: (self isInspectEnabledIn: presenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectItemIsEnabledWithASelectedEntity [

	| presenter |
	presenter := self newPresenter.
	self selectName: #alpha in: presenter.
	self assert: (self isInspectEnabledIn: presenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectTreeEntityCallsTheActionOnceWithTheSelectedEntity [

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	self selectName: #run in: presenter.
	presenter inspectTreeEntity.
	self assert: calls size equals: 1.
	self assert: calls first == (self fixtureAt: #run)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectTreeEntityInWholeModelModeInspectsTheGreyedEntity [

	| presenter calls |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	calls := self recordInspectionsOf: presenter.
	self selectName: #aardvark in: presenter.
	presenter inspectTreeEntity.
	self assert: calls size equals: 1.
	self assert: calls first == (self fixtureAt: #aardvark)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectTreeEntityWithoutModelCallsNothing [

	| presenter calls |
	presenter := self newPresenterWithoutModel.
	calls := self recordInspectionsOf: presenter.
	presenter inspectTreeEntity.
	self assert: calls isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectTreeEntityWithoutSelectionCallsNothing [

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	presenter inspectTreeEntity.
	self assert: calls isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectionDoesNotChangeTheTextSelection [

	| presenter before |
	presenter := self newPresenter.
	self recordInspectionsOf: presenter.
	self selectName: #run in: presenter.
	before := presenter textPresenter selectionInterval.
	presenter inspectTreeEntity.
	self assert: presenter textPresenter selectionInterval equals: before.
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testInspectionDoesNotChangeTheTreeSelection [

	| presenter |
	presenter := self newPresenter.
	self recordInspectionsOf: presenter.
	self selectName: #run in: presenter.
	presenter inspectTreeEntity.
	self assert: presenter selectedEntityInTree == (self fixtureAt: #run)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testMenuIsRebuiltAfterTheSelectionChanges [
	"Select Alpha: enabled; clear the selection: disabled; select run: enabled again. Each time the menu is asked anew."

	| presenter |
	presenter := self newPresenter.
	self selectName: #alpha in: presenter.
	self assert: (self isInspectEnabledIn: presenter).
	presenter selectEntityInTree: nil.
	self deny: (self isInspectEnabledIn: presenter).
	self selectName: #run in: presenter.
	self assert: (self isInspectEnabledIn: presenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testPresenterStaysUsableAfterTheInspectActionRaises [
	"DECISION: whether the exception is propagated or swallowed is left to the implementation (both accepted); in both cases the tree selection is unchanged, isSynchronizing is false and the presenter still selects and inspects."

	| presenter calls |
	presenter := self newPresenter.
	self selectName: #run in: presenter.
	presenter inspectAction: [ :entity | Error signal: 'inspect failed' ].
	[ presenter inspectTreeEntity ]
		on: Error
		do: [ :e | e return ].
	self assert: presenter selectedEntityInTree == (self fixtureAt: #run).
	self deny: presenter isSynchronizing.
	calls := self recordInspectionsOf: presenter.
	self selectName: #beta in: presenter.
	presenter inspectTreeEntity.
	self assert: calls size equals: 1.
	self assert: calls first == (self fixtureAt: #beta)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testSmokeContextMenuInspectsTheSelectedEntity [
	"Real window on newExample (deposit is the third child of Account in the tree). treePresenter contextMenu value gives a menu whose Inspect item is enabled; its action, with the inspection replaced by a recorder, inspects deposit once. No inspector is opened."

	| presenter deposit calls |
	presenter := MMCCoveragePresenter newExample.
	deposit := presenter navigator visibleEntities detect: [ :each |
		           each name = 'deposit' ].
	self withOpenWindowOf: presenter do: [ :window |
			| menu item |
			calls := self recordInspectionsOf: presenter.
			presenter selectEntityInTree: deposit.
			self assert: presenter selectedEntityInTree == deposit.
			menu := presenter treePresenter contextMenu value.
			item := self inspectItemOf: menu.
			self assert: (self isEnabledItem: item).
			item action cull: item.
			self assert: calls size equals: 1.
			self assert: calls first == deposit ]
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testSmokeRightClickSelectsTheRowUnderTheMouse [
	"Spike result (FastTable): FTTableMorph>>mouseDown: selects the row under the cursor whatever the button, and FTTableMorph>>showMenuForIndex: selects it again when it is not selected, BEFORE asking the data source for the menu (menuColumn:row:); so when the context menu block runs, selectedEntityInTree is the clicked row. Here a synthetic yellow button press and release is dispatched by the hand on row 2 (Account) while deposit is selected; a popped up menu (once the menu exists) is removed afterwards. The Inspect action is never run."

	| presenter deposit account hand menusBefore |
	presenter := MMCCoveragePresenter newExample.
	deposit := presenter navigator visibleEntities detect: [ :each |
		           each name = 'deposit' ].
	account := presenter navigator visibleEntities detect: [ :each |
		           each name = 'Account' ].
	menusBefore := World submorphs select: [ :each | each isMenuMorph ].
	self withOpenWindowOf: presenter do: [ :window |
			| table row point |
			[
				presenter selectEntityInTree: deposit.
				table := presenter treePresenter adapter widget.
				self waitUpTo: 600 until: [
						table container exposedRows notNil and: [
							table container exposedRows size >= 2 ] ].
				row := table container exposedRows at: 2.
				point := row bounds center.
				hand := World activeHand.
				hand handleEvent: (MouseButtonEvent new
						 setType: #mouseDown
						 position: point
						 which: 2
						 buttons: 2
						 hand: hand
						 stamp: Time millisecondClockValue).
				hand handleEvent: (MouseButtonEvent new
						 setType: #mouseUp
						 position: point
						 which: 2
						 buttons: 0
						 hand: hand
						 stamp: Time millisecondClockValue).
				self waitUpTo: 200 until: [ false ].
				self assert: presenter selectedEntityInTree == account ] ensure: [
					(World submorphs select: [ :each |
						 each isMenuMorph and: [ (menusBefore includes: each) not ] ])
						do: [ :each | each delete ] ] ]

]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTextSelectionChangedToNegativeStepIntervalDoesNotFail [
	"An Interval with a negative step (30 to: 10 by: -1, first 30) is treated like its first position: no error and the presenter is not left synchronizing."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: (30 to: 10 by: -1).
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTextSelectionChangedToNilDoesNotFail [
	"A nil interval is ignored: no MessageNotUnderstood (nil first)."

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: nil
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTextSelectionChangedToNilKeepsTheTextAndTheDetails [
	"Neither the text nor the details nor the text selection change."

	| presenter text details selection |
	presenter := self newPresenter.
	self selectName: #alpha in: presenter.
	text := presenter textPresenter text asString.
	details := presenter detailsPresenter text asString.
	selection := presenter textPresenter selectionInterval.
	presenter textSelectionChangedTo: nil.
	self assert: presenter textPresenter text asString equals: text.
	self assert: presenter detailsPresenter text asString equals: details.
	self assert: presenter textPresenter selectionInterval equals: selection
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTextSelectionChangedToNilKeepsTheTreeSelection [
	"Alpha selected in the tree stays selected after a nil text selection."

	| presenter |
	presenter := self newPresenter.
	self selectName: #alpha in: presenter.
	presenter textSelectionChangedTo: nil.
	self assert: presenter selectedEntityInTree == (self fixtureAt: #alpha)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTextSelectionChangedToNilLeavesIsSynchronizingFalse [

	| presenter |
	presenter := self newPresenter.
	presenter textSelectionChangedTo: nil.
	self deny: presenter isSynchronizing
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTreeContextMenuHasExactlyOneItemNamedInspect [
	"One group at least, one item in all: named Inspect (checked by inspectItemOf:)."

	| menu |
	menu := self newPresenter treeContextMenu.
	self assert: (self menuItemsOf: menu) size equals: 1.
	self assert: (self inspectItemOf: menu) name equals: 'Inspect'
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTreeContextMenuIsAMenuPresenter [

	self assert:
		(self newPresenter treeContextMenu isKindOf: SpMenuPresenter)
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTreeContextMenuIsBuiltAnewAtEveryCall [
	"Two calls answer two different menus (a stale menu would keep a stale enabled state)."

	| presenter first second |
	presenter := self newPresenter.
	first := presenter treeContextMenu.
	second := presenter treeContextMenu.
	self deny: first == second.
	self deny:
		(self menuItemsOf: first) first == (self menuItemsOf: second) first
]

{ #category : 'tests' }
MMCCoveragePresenterInspectTest >> testTreePresenterContextMenuIsABlockAnsweringTheCurrentMenu [
	"The tree context menu is dynamic: a block (evaluated at each popup) answering a fresh SpMenuPresenter with the Inspect item."

	| presenter first second |
	presenter := self newPresenter.
	self assert: presenter treePresenter contextMenu isBlock.
	first := presenter treePresenter contextMenu value.
	second := presenter treePresenter contextMenu value.
	self assert: (first isKindOf: SpMenuPresenter).
	self deny: first == second.
	self assert: (self inspectItemOf: first) name equals: 'Inspect'
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> waitUpTo: someMilliseconds until: aBlock [
	"Let Morphic run (200 ms steps) until aBlock is true or someMilliseconds elapsed. Answer the final value of aBlock."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 200) wait.
			World doOneCycle.
			waited := waited + 200 ].
	^ aBlock value
]

{ #category : 'helpers' }
MMCCoveragePresenterInspectTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Open aPresenter in a forked process (15 s limit: #waitTimeoutSeconds: answers TRUE on timeout), evaluate aBlock with the window, and always close it, then check that no SpWindow is left. Skipped without World."

	| window semaphore timedOut openError windowsBefore |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isKindOf: SpWindow ].
	semaphore := Semaphore new.
	openError := nil.
	[
		[
			[ window := aPresenter open ]
				on: Error
				do: [ :e | openError := e ] ] ensure: [ semaphore signal ] ] fork.
	[
		timedOut := semaphore waitTimeoutSeconds: 15.
		self
			deny: timedOut
			description: 'the window did not open within 15 seconds'.
		self
			assert: openError isNil
			description: 'open raised ' , openError class name.
		aBlock value: window ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ].
			self
				assert:
				(World submorphs count: [ :each | each isKindOf: SpWindow ])
				equals: windowsBefore ]
]
