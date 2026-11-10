Class {
	#name : 'MMCColorSchemeVisibilityTest',
	#superclass : 'TestCase',
	#instVars : [
		'scheme',
		'notifications'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'running' }
MMCColorSchemeVisibilityTest >> setUp [

	super setUp.
	scheme := MMCColorScheme new.
	notifications := 0.
	scheme whenChangedDo: [ notifications := notifications + 1 ]
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testCopyHasItsOwnHiddenTypesAndNoSubscriber [

	| copy copyNotifications |
	scheme hideType: 'Class'.
	copy := scheme copy.
	self assert: copy equals: scheme.
	self assert: copy subscriberCount equals: 0.
	self assert: scheme subscriberCount equals: 1.
	copyNotifications := 0.
	copy whenChangedDo: [ copyNotifications := copyNotifications + 1 ].
	notifications := 0.
	copy hideType: 'Method'.
	self assert: (scheme isTypeVisible: 'Method').
	self deny: (copy isTypeVisible: 'Method').
	self assert: notifications equals: 0.
	self assert: copyNotifications equals: 1.
	scheme showType: 'Class'.
	self deny: (copy isTypeVisible: 'Class').
	self deny: copy = scheme
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testEqualityAndHashIncludeTheVisibility [

	| other |
	other := MMCColorScheme new.
	self assert: scheme equals: other.
	self assert: scheme hash equals: other hash.
	other hideType: 'Class'.
	self deny: scheme = other.
	scheme hideType: 'Class'.
	self assert: scheme equals: other.
	self assert: scheme hash equals: other hash.
	scheme hideType: 'Method'.
	self deny: scheme = other.
	scheme showType: 'Method'.
	scheme overrideAt: 'Class' put: Color red.
	self deny: scheme = other.
	other overrideAt: 'Class' put: Color red.
	self assert: scheme equals: other
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testEveryTypeIsVisibleByDefault [

	self assert: (scheme isTypeVisible: 'Class').
	self assert: (scheme isTypeVisible: 'Unknown').
	self deny: scheme hasHiddenTypes.
	self assert: scheme hiddenTypeNames isEmpty.
	self assert: scheme isDefault
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testHasOverridesConcernsTheColorsOnly [

	scheme hideType: 'Class'.
	self deny: scheme hasOverrides.
	scheme overrideAt: 'Method' put: Color blue.
	self assert: scheme hasOverrides.
	self assert: scheme isEmpty equals: false
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testHiddenTypeNamesIsACopy [

	| names |
	scheme hideType: 'Class'.
	names := scheme hiddenTypeNames.
	names add: 'Method'.
	names remove: 'Class'.
	self deny: (scheme isTypeVisible: 'Class').
	self assert: (scheme isTypeVisible: 'Method').
	self assert: scheme hiddenTypeNames equals: #( 'Class' ) asSet.
	self deny: scheme hiddenTypeNames == scheme hiddenTypeNames
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testHideAllIsAdditiveWithOneNotification [

	scheme hideType: 'Access'.
	notifications := 0.
	scheme hideAll: #( 'Class' 'Method' ).
	self
		assert: scheme hiddenTypeNames
		equals: #( 'Access' 'Class' 'Method' ) asSet.
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testHideAllWithNothingNewDoesNotNotify [

	scheme hideAll: #( 'Class' 'Method' ).
	notifications := 0.
	scheme hideAll: #( 'Class' ).
	scheme hideAll: #(  ).
	self assert: notifications equals: 0.
	self
		assert: scheme hiddenTypeNames
		equals: #( 'Class' 'Method' ) asSet
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testHideTypeHidesAndNotifiesOnce [

	scheme hideType: 'Class'.
	self deny: (scheme isTypeVisible: 'Class').
	self assert: (scheme isTypeVisible: 'Method').
	self assert: scheme hasHiddenTypes.
	self assert: notifications equals: 1.
	self deny: scheme isDefault
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testHidingAnAlreadyHiddenTypeDoesNotNotify [

	scheme hideType: 'Class'.
	scheme hideType: 'Class'.
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testIsDefaultNeedsNoColorAndNoHiddenType [

	self assert: scheme isDefault.
	scheme overrideAt: 'Class' put: Color red.
	self deny: scheme isDefault.
	scheme hideType: 'Method'.
	scheme removeOverrideFor: 'Class'.
	self deny: scheme isDefault.
	scheme showAll.
	self assert: scheme isDefault
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testMutatingTheSetGivenToSetHiddenTypeNamesDoesNotAffectTheScheme [

	| given |
	given := Set withAll: #( 'Class' ).
	scheme setHiddenTypeNames: given.
	given add: 'Method'.
	given remove: 'Class'.
	self assert: scheme hiddenTypeNames equals: #( 'Class' ) asSet.
	self deny: (scheme isTypeVisible: 'Class').
	self assert: (scheme isTypeVisible: 'Method')
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testResetKeepsTheHiddenTypesAndDropsTheColors [

	scheme overrideAt: 'Class' put: Color red.
	scheme hideType: 'Method'.
	notifications := 0.
	scheme reset.
	self deny: scheme hasOverrides.
	self assert: scheme hasHiddenTypes.
	self deny: (scheme isTypeVisible: 'Method').
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testResetWithOnlyHiddenTypesDoesNotNotify [

	scheme hideType: 'Method'.
	notifications := 0.
	scheme reset.
	self assert: notifications equals: 0.
	self deny: (scheme isTypeVisible: 'Method')
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testSetHiddenTypeNamesReplacesAtomicallyWithOneNotification [

	scheme hideAll: #( 'Class' 'Method' ).
	notifications := 0.
	scheme setHiddenTypeNames: #( 'Method' 'Access' ).
	self
		assert: scheme hiddenTypeNames
		equals: #( 'Method' 'Access' ) asSet.
	self assert: (scheme isTypeVisible: 'Class').
	self deny: (scheme isTypeVisible: 'Access').
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testSetHiddenTypeNamesWithTheSameSetDoesNotNotify [

	scheme hideAll: #( 'Class' 'Method' ).
	notifications := 0.
	scheme setHiddenTypeNames: #( 'Method' 'Class' ).
	scheme setHiddenTypeNames:
		#( 'Method' 'Class' 'Class' ) asOrderedCollection.
	self assert: notifications equals: 0.
	scheme setHiddenTypeNames: Set new.
	self assert: notifications equals: 1.
	scheme setHiddenTypeNames: #(  ).
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testSetTypeVisibleDelegatesToHideAndShow [

	scheme setType: 'Class' visible: false.
	self deny: (scheme isTypeVisible: 'Class').
	self assert: notifications equals: 1.
	scheme setType: 'Class' visible: false.
	self assert: notifications equals: 1.
	scheme setType: 'Class' visible: true.
	self assert: (scheme isTypeVisible: 'Class').
	self assert: notifications equals: 2.
	scheme setType: 'Class' visible: true.
	self assert: notifications equals: 2
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testShowAllShowsEverythingWithOneNotification [

	scheme hideAll: #( 'Class' 'Method' ).
	notifications := 0.
	scheme showAll.
	self deny: scheme hasHiddenTypes.
	self assert: (scheme isTypeVisible: 'Class').
	self assert: notifications equals: 1.
	scheme showAll.
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testShowTypeShowsAndNotifiesOnce [

	scheme hideType: 'Class'.
	scheme showType: 'Class'.
	self assert: (scheme isTypeVisible: 'Class').
	self deny: scheme hasHiddenTypes.
	self assert: notifications equals: 2.
	self assert: scheme isDefault
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testShowingAVisibleTypeDoesNotNotify [

	scheme showType: 'Class'.
	scheme showType: 'Unknown'.
	self assert: notifications equals: 0
]

{ #category : 'tests' }
MMCColorSchemeVisibilityTest >> testSubscriberCanUnsubscribeWhileNotifiedOfAVisibilityChange [

	| block calls |
	calls := 0.
	block := nil.
	block := [
		         calls := calls + 1.
		         scheme removeSubscriber: block ].
	scheme whenChangedDo: block.
	scheme hideType: 'Class'.
	scheme hideType: 'Method'.
	self assert: calls equals: 1.
	self assert: notifications equals: 2
]
