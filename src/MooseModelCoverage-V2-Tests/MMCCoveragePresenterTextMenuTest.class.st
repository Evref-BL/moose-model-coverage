"
Tests of the context menu of the text of MMCCoveragePresenter (Inspect from the text): entityAtTextPosition:, textContextMenuAt:, textPositionAtGlobalPoint:, mouseTextPosition, with the API and in a real window. The inspect action is always replaced by a recorder: no inspector is ever opened.

Fixture text (24 characters, LF at 10 and 20): 'aaaa bbbb' LF 'cccc dddd' LF 'eeee'. Foo is the region 1-19, its method bar the region 6-14; 20-24 is in no region.
"
Class {
	#name : 'MMCCoveragePresenterTextMenuTest',
	#superclass : 'TestCase',
	#instVars : [
		'foo',
		'bar',
		'model',
		'text'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers - window' }
MMCCoveragePresenterTextMenuTest >> globalPointOfCharacter: anIndex in: aPresenter [
	"Center of the character anIndex, in world coordinates."

	| area block |
	area := self textAreaOf: aPresenter.
	block := area paragraph characterBlockForIndex: anIndex.
	^ area localPointToGlobal:
		  block left + block right / 2 @ (block top + block bottom / 2)
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> isEnabled: anItem [
	"isEnabled answers a boolean or a block answering a boolean."

	| enabled |
	enabled := anItem isEnabled.
	^ enabled isBlock
		  ifTrue: [ enabled value ]
		  ifFalse: [ enabled ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> itemNamed: aString in: aMenu [

	| items |
	items := (self itemsOf: aMenu) select: [ :each | each name = aString ].
	self assert: items size equals: 1.
	^ items first
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> itemsOf: aMenu [
	"All the items of all the groups of an SpMenuPresenter."

	^ aMenu menuGroups
		  inject: OrderedCollection new
		  into: [ :all :group |
				  all
					  addAll: group menuItems;
					  yourself ]
]

{ #category : 'helpers - window' }
MMCCoveragePresenterTextMenuTest >> menuItemsOfMorph: aMenuMorph [

	^ aMenuMorph submorphs select: [ :each |
		  each isKindOf: MenuItemMorph ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> newCoverage [

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: text
			   regions: {
					   (self regionOf: foo from: 1 to: 19).
					   (self regionOf: bar from: 6 to: 14) }
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> newPresenter [
	"Not opened presenter on the fixture coverage and model (the default inspect action is still there: tests replace it with recordInspectionsOf:)."

	^ MMCCoveragePresenter on: self newCoverage model: model
]

{ #category : 'helpers - window' }
MMCCoveragePresenterTextMenuTest >> putHandOnCharacter: anIndex in: aPresenter [

	World activeHand position:
		(self globalPointOfCharacter: anIndex in: aPresenter)
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> recordInspectionsOf: aPresenter [
	"Replace the inspect action of aPresenter by a recorder; answer the collection of the entities received (no inspector is opened)."

	| calls |
	calls := OrderedCollection new.
	aPresenter inspectAction: [ :entity | calls add: entity ].
	^ calls
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> regionOf: anEntity from: start to: end [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (start to: end)
		  text: (text copyFrom: start to: end)
]

{ #category : 'helpers - window' }
MMCCoveragePresenterTextMenuTest >> rubricMenuIn: aPresenter [
	"The menu Rubric builds for a right click at the position of the hand (answered, not popped up; the caller deletes it)."

	^ (self textAreaOf: aPresenter) getMenu: false
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> runItem: anItem [

	anItem action cull: anItem
]

{ #category : 'helpers' }
MMCCoveragePresenterTextMenuTest >> setUp [
	"Throwaway model (never added to MooseModel root): class Foo with its method bar."

	super setUp.
	foo := FamixJavaClass new
		       name: 'Foo';
		       yourself.
	bar := FamixJavaMethod new
		       name: 'bar';
		       yourself.
	foo addMethod: bar.
	model := FamixJavaModel new.
	model add: foo.
	model add: bar.
	text := String streamContents: [ :s |
			        s
				        nextPutAll: 'aaaa bbbb';
				        nextPut: Character lf;
				        nextPutAll: 'cccc dddd';
				        nextPut: Character lf;
				        nextPutAll: 'eeee' ]
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testCopyIsDisabledWithoutTextSelection [
	"Not opened: no widget, so no selection."

	| presenter |
	presenter := self newPresenter.
	self deny: presenter textHasSelection.
	self deny: (self isEnabled:
			 (self itemNamed: 'Copy' in: (presenter textContextMenuAt: 7)))
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testCopyWithoutWidgetDoesNothing [

	| presenter before |
	presenter := self newPresenter.
	before := Clipboard clipboardText.
	presenter copyTextSelection.
	self assert: Clipboard clipboardText equals: before
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testDisabledInspectCallsNothingEvenIfRun [

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	self runItem:
		(self itemNamed: 'Inspect' in: (presenter textContextMenuAt: 22)).
	self runItem:
		(self itemNamed: 'Inspect' in: (presenter textContextMenuAt: nil)).
	self assert: calls isEmpty
]

{ #category : 'tests - entity at position' }
MMCCoveragePresenterTextMenuTest >> testEntityAtTextPositionDoesNotMoveTheSelectionNorTheTree [

	| presenter before |
	presenter := self newPresenter.
	before := presenter textPresenter selectionInterval.
	presenter entityAtTextPosition: 7.
	self assert: presenter textPresenter selectionInterval equals: before.
	self assert: presenter selectedEntityInTree isNil.
	self deny: presenter isSynchronizing
]

{ #category : 'tests - entity at position' }
MMCCoveragePresenterTextMenuTest >> testEntityAtTextPositionIsNilForANonIntegerPosition [

	| presenter |
	presenter := self newPresenter.
	{
		nil.
		1.5.
		(3 / 2).
		'a'.
		#foo.
		(2 @ 3).
		(1 to: 3) } do: [ :each |
		self assert: (presenter entityAtTextPosition: each) isNil ]
]

{ #category : 'tests - entity at position' }
MMCCoveragePresenterTextMenuTest >> testEntityAtTextPositionIsNilOutsideAnyRegion [
	"20 to 24 are in the text but in no region."

	| presenter |
	presenter := self newPresenter.
	20 to: 24 do: [ :each |
	self assert: (presenter entityAtTextPosition: each) isNil ]
]

{ #category : 'tests - entity at position' }
MMCCoveragePresenterTextMenuTest >> testEntityAtTextPositionIsNilOutsideTheText [

	| presenter |
	presenter := self newPresenter.
	#( 0 -1 25 26 99999 ) do: [ :each |
		self assert: (presenter entityAtTextPosition: each) isNil ]
]

{ #category : 'tests - entity at position' }
MMCCoveragePresenterTextMenuTest >> testEntityAtTextPositionIsNilWithoutReadableFile [

	| presenter |
	presenter := MMCCoveragePresenter
		             on: MMCCoveragePresenter emptyCoverage
		             model: model.
	self deny: presenter fileCoverage isReadable.
	#( 0 1 6 ) do: [ :each |
		self assert: (presenter entityAtTextPosition: each) isNil ]
]

{ #category : 'tests - entity at position' }
MMCCoveragePresenterTextMenuTest >> testEntityAtTextPositionIsTheDeepestEntity [

	| presenter |
	presenter := self newPresenter.
	#( 1 2 5 15 19 ) do: [ :each |
		self assert: (presenter entityAtTextPosition: each) identicalTo: foo ].
	#( 6 7 10 14 ) do: [ :each |
		self assert: (presenter entityAtTextPosition: each) identicalTo: bar ]
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testInspectActionReceivesTheEntityAtThePosition [

	| presenter calls menu |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	menu := presenter textContextMenuAt: 7.
	self runItem: (self itemNamed: 'Inspect' in: menu).
	self assert: calls size equals: 1.
	self assert: calls first identicalTo: bar.
	self runItem:
		(self itemNamed: 'Inspect' in: (presenter textContextMenuAt: 2)).
	self assert: calls size equals: 2.
	self assert: calls last identicalTo: foo
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testInspectDoesNotMoveTheTextSelection [

	| presenter before menu calls |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	presenter textPresenter selectionInterval: (3 to: 5).
	before := presenter textPresenter selectionInterval.
	menu := presenter textContextMenuAt: 12.
	self runItem: (self itemNamed: 'Inspect' in: menu).
	self assert: calls size equals: 1.
	self assert: presenter textPresenter selectionInterval equals: before.
	self deny: presenter isSynchronizing
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testInspectIsEnabledOnlyWhenAnEntityIsFound [

	| presenter |
	presenter := self newPresenter.
	self assert: (self isEnabled:
			 (self itemNamed: 'Inspect' in: (presenter textContextMenuAt: 7))).
	self assert: (self isEnabled:
			 (self itemNamed: 'Inspect' in: (presenter textContextMenuAt: 2))).
	self deny: (self isEnabled:
			 (self itemNamed: 'Inspect' in: (presenter textContextMenuAt: 22))).
	self deny: (self isEnabled:
			 (self itemNamed: 'Inspect' in: (presenter textContextMenuAt: 0))).
	self deny: (self isEnabled:
			 (self
				  itemNamed: 'Inspect'
				  in: (presenter textContextMenuAt: 99999))).
	self deny: (self isEnabled:
			 (self itemNamed: 'Inspect' in: (presenter textContextMenuAt: nil)))
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testInspectedEntityIsTheOneOfTheMenuPositionNotTheTreeSelection [
	"The entity is fixed when the menu is built: the tree selection (Foo) is not used."

	| presenter calls menu |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	presenter selectEntityInTree: foo.
	menu := presenter textContextMenuAt: 7.
	self runItem: (self itemNamed: 'Inspect' in: menu).
	self assert: calls first identicalTo: bar.
	self assert: presenter selectedEntityInTree identicalTo: foo
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testMenuIsAMenuPresenterWithInspectFirstThenCopy [

	| menu |
	menu := self newPresenter textContextMenuAt: 7.
	self assert: (menu isKindOf: SpMenuPresenter).
	self
		assert:
		((self itemsOf: menu) collect: [ :each | each name ]) asArray
		equals: #( 'Inspect' 'Copy' )
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testMenuIsBuiltAnewAtEveryCall [

	| presenter first second |
	presenter := self newPresenter.
	first := presenter textContextMenuAt: 7.
	second := presenter textContextMenuAt: 7.
	self deny: first == second
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowBelowTheLastLineIsNil [

	| presenter widgetBounds point |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			widgetBounds := presenter textPresenter adapter widget bounds.
			point := self globalPointOfCharacter: 22 in: presenter.
			self
				assert: (presenter textPositionAtGlobalPoint: point)
				equals: 22.
			self assert:
				(presenter textPositionAtGlobalPoint: point x @ (point y + 100))
					isNil.
			self assert: (presenter textPositionAtGlobalPoint:
					 point x @ (widgetBounds bottom - 5)) isNil ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowBlankRightOfALineIsNil [

	| presenter widgetBounds y |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			widgetBounds := presenter textPresenter adapter widget bounds.
			y := (self globalPointOfCharacter: 1 in: presenter) y.
			self assert:
				(presenter textPositionAtGlobalPoint: widgetBounds right - 30 @ y)
					isNil.
			y := (self globalPointOfCharacter: 11 in: presenter) y.
			self assert:
				(presenter textPositionAtGlobalPoint: widgetBounds right - 30 @ y)
					isNil ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowMouseTextPositionFollowsTheHand [

	| presenter widgetBounds |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			self putHandOnCharacter: 7 in: presenter.
			self assert: presenter mouseTextPosition equals: 7.
			self putHandOnCharacter: 12 in: presenter.
			self assert: presenter mouseTextPosition equals: 12.
			widgetBounds := presenter textPresenter adapter widget bounds.
			World activeHand position: widgetBounds right - 30
				@ (self globalPointOfCharacter: 1 in: presenter) y.
			self assert: presenter mouseTextPosition isNil.
			World activeHand position: -50 @ -50.
			self assert: presenter mouseTextPosition isNil ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowOutsideTheTextWidgetIsNil [

	| presenter widgetBounds point |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			widgetBounds := presenter textPresenter adapter widget bounds.
			point := self globalPointOfCharacter: 2 in: presenter.
			self assert: (presenter textPositionAtGlobalPoint: point) equals: 2.
			self assert:
				(presenter textPositionAtGlobalPoint:
					 point x @ (widgetBounds top - 5)) isNil.
			self assert:
				(presenter textPositionAtGlobalPoint:
					 widgetBounds left - 5 @ point y) isNil.
			self assert:
				(presenter textPositionAtGlobalPoint:
					 widgetBounds right + 5 @ point y) isNil.
			self assert:
				(presenter textPositionAtGlobalPoint: -1000 @ -1000) isNil ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowRightClickOnAnEntityOffersInspect [
	"The hand is on the character 7 (method bar): Rubric builds the menu with Inspect enabled and Copy disabled (no selection); Inspect gives bar to the (recorded) inspect action, once, and does not move the text selection."

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			| menu items before |
			before := presenter textPresenter selectionInterval.
			self putHandOnCharacter: 7 in: presenter.
			menu := self rubricMenuIn: presenter.
			[
				items := self menuItemsOfMorph: menu.
				self
					assert:
					(items collect: [ :each | each contents asString ]) asArray
					equals: #( 'Inspect' 'Copy' ).
				self assert: items first isEnabled.
				self deny: items last isEnabled.
				items first doButtonAction.
				self assert: calls size equals: 1.
				self assert: calls first identicalTo: bar.
				self
					assert: presenter textPresenter selectionInterval
					equals: before ] ensure: [ menu delete ] ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowRightClickOutsideAnyRegionDisablesInspect [
	"The hand is on the character 22 (in no region), then on the blank right of the first line."

	| presenter calls |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			| menu |
			self putHandOnCharacter: 22 in: presenter.
			menu := self rubricMenuIn: presenter.
			[ self deny: (self menuItemsOfMorph: menu) first isEnabled ]
				ensure: [ menu delete ].
			World activeHand position:
				presenter textPresenter adapter widget bounds right - 30
				@ (self globalPointOfCharacter: 1 in: presenter) y.
			menu := self rubricMenuIn: presenter.
			[ self deny: (self menuItemsOfMorph: menu) first isEnabled ]
				ensure: [ menu delete ].
			self assert: calls isEmpty ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowRightClickWithASelectionEnablesCopyAndKeepsTheEntityOfThePosition [
	"Selection 1-4 ('aaaa', Foo at its start) and the hand on the character 7 (bar): Copy is enabled and puts the selected text in the clipboard; Inspect gives bar (the entity under the mouse, not that of the selection) and the selection is unchanged. The clipboard of the image is restored."

	| presenter calls clipboardBefore |
	presenter := self newPresenter.
	calls := self recordInspectionsOf: presenter.
	clipboardBefore := Clipboard clipboardText.
	self withOpenWindowOf: presenter do: [ :window |
			| menu items |
			[
				presenter textPresenter selectionInterval: (1 to: 4).
				self assert: presenter textHasSelection.
				self putHandOnCharacter: 7 in: presenter.
				menu := self rubricMenuIn: presenter.
				[
					items := self menuItemsOfMorph: menu.
					self assert: items first isEnabled.
					self assert: items last isEnabled.
					items last doButtonAction.
					self assert: Clipboard clipboardText asString equals: 'aaaa'.
					items first doButtonAction.
					self assert: calls size equals: 1.
					self assert: calls first identicalTo: bar.
					self
						assert: presenter textPresenter selectionInterval
						equals: (1 to: 4) ] ensure: [ menu ifNotNil: [ menu delete ] ] ]
				ensure: [ Clipboard clipboardText: clipboardBefore ] ]
]

{ #category : 'tests - real window' }
MMCCoveragePresenterTextMenuTest >> testRealWindowTextPositionAtTheCenterOfEachCharacter [
	"Real window: the center of every character gives its index; the line breaks (10 and 20) give nil."

	| presenter |
	presenter := self newPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			1 to: 24 do: [ :each |
					| expected |
					expected := (#( 10 20 ) includes: each)
						            ifTrue: [ nil ]
						            ifFalse: [ each ].
					self
						assert: (presenter textPositionAtGlobalPoint:
								 (self globalPointOfCharacter: each in: presenter))
						equals: expected ] ]
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testTextPresenterContextMenuIsABlockAnsweringAMenu [
	"Not opened: the mouse is over no character, Inspect is disabled."

	| presenter menu |
	presenter := self newPresenter.
	self assert: presenter textPresenter contextMenu isBlock.
	menu := presenter textPresenter contextMenu value.
	self assert: (menu isKindOf: SpMenuPresenter).
	self deny: (self isEnabled: (self itemNamed: 'Inspect' in: menu))
]

{ #category : 'tests - menu' }
MMCCoveragePresenterTextMenuTest >> testWithoutWidgetThereIsNoMouseTextPosition [

	| presenter |
	presenter := self newPresenter.
	self assert: (presenter textPositionAtGlobalPoint: 5 @ 5) isNil.
	self assert: (presenter textPositionAtGlobalPoint: 0 @ 0) isNil.
	self assert: presenter mouseTextPosition isNil
]

{ #category : 'helpers - window' }
MMCCoveragePresenterTextMenuTest >> textAreaOf: aPresenter [

	^ aPresenter textPresenter adapter widget textArea
]

{ #category : 'helpers - window' }
MMCCoveragePresenterTextMenuTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Skipped without World. Open aPresenter in a forked process (15 s limit: #waitTimeoutSeconds: answers TRUE on timeout), let Morphic lay it out (500 ms), evaluate aBlock with the window, and always close it, restore the position of the hand and check that no SpWindow is left."

	| window semaphore timedOut openError windowsBefore handPosition |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isKindOf: SpWindow ].
	handPosition := World activeHand position.
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
		(Delay forMilliseconds: 500) wait.
		aBlock value: window ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ].
			World activeHand position: handPosition.
			self
				assert:
				(World submorphs count: [ :each | each isKindOf: SpWindow ])
				equals: windowsBefore ]
]
