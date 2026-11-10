"
Tests of MMCColorScheme: overrides of the base color of Famix types (forced opaque), equality and copy ignoring the subscribers, and the notifications (one per real change, none when nothing changes).
"
Class {
	#name : 'MMCColorSchemeTest',
	#superclass : 'TestCase',
	#instVars : [
		'scheme',
		'notifications'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'tests' }
MMCColorSchemeTest >> countingBlock [
	"A subscriber counting its notifications in notifications."

	^ [ notifications := notifications + 1 ]
]

{ #category : 'tests' }
MMCColorSchemeTest >> setUp [

	super setUp.
	scheme := MMCColorScheme new.
	notifications := 0
]

{ #category : 'tests' }
MMCColorSchemeTest >> testCopyHasTheOverridesButNoSubscriber [

	| copy |
	scheme overrideAt: 'Class' put: Color red.
	scheme whenChangedDo: self countingBlock.
	copy := scheme copy.
	self assert: copy equals: scheme.
	self deny: copy == scheme.
	self assert: copy subscriberCount equals: 0.
	self assert: scheme subscriberCount equals: 1
]

{ #category : 'tests' }
MMCColorSchemeTest >> testCopyIsIndependent [

	| copy |
	scheme overrideAt: 'Class' put: Color red.
	scheme whenChangedDo: self countingBlock.
	copy := scheme copy.
	copy overrideAt: 'Method' put: Color green.
	self assert: notifications equals: 0.
	self assert: (scheme overrideFor: 'Method') isNil.
	scheme removeOverrideFor: 'Class'.
	self assert: (copy overrideFor: 'Class') equals: Color red
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testEachRealChangeNotifiesOnce [

	scheme whenChangedDo: self countingBlock.
	scheme overrideAt: 'Class' put: Color red.
	self assert: notifications equals: 1.
	scheme overrideAt: 'Class' put: Color blue.
	self assert: notifications equals: 2.
	scheme overrideAt: 'Method' put: Color green.
	self assert: notifications equals: 3.
	scheme removeOverrideFor: 'Method'.
	self assert: notifications equals: 4.
	scheme reset.
	self assert: notifications equals: 5
]

{ #category : 'tests' }
MMCColorSchemeTest >> testEqualityComparesTheOverrides [

	| other |
	other := MMCColorScheme new.
	self assert: scheme equals: other.
	scheme overrideAt: 'Class' put: Color red.
	self deny: scheme = other.
	other overrideAt: 'Class' put: Color red.
	self assert: scheme equals: other.
	self assert: scheme hash equals: other hash.
	other overrideAt: 'Class' put: Color blue.
	self deny: scheme = other.
	self deny: scheme = 42
]

{ #category : 'tests' }
MMCColorSchemeTest >> testEqualityIgnoresTheSubscribers [

	| other |
	other := MMCColorScheme new.
	scheme whenChangedDo: self countingBlock.
	scheme whenChangedDo: self countingBlock.
	self assert: scheme equals: other.
	self assert: scheme hash equals: other hash
]

{ #category : 'tests' }
MMCColorSchemeTest >> testNewSchemeIsEmpty [

	self assert: scheme isEmpty.
	self deny: scheme hasOverrides.
	self assert: scheme typeNamesOverridden isEmpty.
	self assert: scheme subscriberCount equals: 0.
	self assert: (scheme overrideFor: 'Class') isNil
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testNotifySubscribersNotifiesWithoutChange [

	scheme whenChangedDo: self countingBlock.
	scheme notifySubscribers.
	self assert: notifications equals: 1
]

{ #category : 'tests' }
MMCColorSchemeTest >> testOverrideIsForcedOpaque [

	scheme overrideAt: 'Class' put: (Color red alpha: 0.3).
	self assert: (scheme overrideFor: 'Class') alpha equals: 1.
	self assert: (scheme overrideFor: 'Class') equals: Color red
]

{ #category : 'tests' }
MMCColorSchemeTest >> testOverrideIsStoredAndAnswered [

	scheme overrideAt: 'Class' put: Color red.
	self assert: (scheme overrideFor: 'Class') equals: Color red.
	self assert: (scheme overrideFor: 'Method') isNil.
	self deny: scheme isEmpty.
	self assert: scheme hasOverrides
]

{ #category : 'tests' }
MMCColorSchemeTest >> testOverridingAgainReplacesTheColor [

	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Class' put: Color blue.
	self assert: (scheme overrideFor: 'Class') equals: Color blue.
	self assert: scheme typeNamesOverridden size equals: 1
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testRemoveAllSubscribers [

	scheme whenChangedDo: self countingBlock.
	scheme whenChangedDo: self countingBlock.
	scheme removeAllSubscribers.
	self assert: scheme subscriberCount equals: 0.
	scheme overrideAt: 'Class' put: Color red.
	self assert: notifications equals: 0
]

{ #category : 'tests' }
MMCColorSchemeTest >> testRemoveOverrideForgetsOnlyThatType [

	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Method' put: Color green.
	scheme removeOverrideFor: 'Class'.
	self assert: (scheme overrideFor: 'Class') isNil.
	self assert: (scheme overrideFor: 'Method') equals: Color green
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testRemoveSubscriberStopsTheNotifications [

	| block |
	block := self countingBlock.
	scheme whenChangedDo: block.
	scheme overrideAt: 'Class' put: Color red.
	scheme removeSubscriber: block.
	scheme overrideAt: 'Class' put: Color blue.
	self assert: notifications equals: 1.
	self assert: scheme subscriberCount equals: 0
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testRemoveUnknownSubscriberDoesNothing [

	scheme whenChangedDo: self countingBlock.
	scheme removeSubscriber: [ nil ].
	self assert: scheme subscriberCount equals: 1
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testRemovingAnAbsentTypeDoesNotNotify [

	scheme overrideAt: 'Class' put: Color red.
	scheme whenChangedDo: self countingBlock.
	scheme removeOverrideFor: 'Method'.
	self assert: notifications equals: 0
]

{ #category : 'tests' }
MMCColorSchemeTest >> testResetForgetsEveryOverride [

	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Method' put: Color green.
	scheme reset.
	self assert: scheme isEmpty.
	self deny: scheme hasOverrides.
	self assert: scheme typeNamesOverridden isEmpty
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testResetNotifiesOnceWhateverTheNumberOfOverrides [

	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Method' put: Color green.
	scheme overrideAt: 'Access' put: Color blue.
	scheme whenChangedDo: self countingBlock.
	scheme reset.
	self assert: notifications equals: 1
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testResetOfAnEmptySchemeDoesNotNotify [

	scheme whenChangedDo: self countingBlock.
	scheme reset.
	self assert: notifications equals: 0.
	scheme overrideAt: 'Class' put: Color red.
	scheme reset.
	scheme reset.
	self assert: notifications equals: 2
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testSameColorDoesNotNotify [

	scheme overrideAt: 'Class' put: Color red.
	scheme whenChangedDo: self countingBlock.
	scheme overrideAt: 'Class' put: Color red.
	self assert: notifications equals: 0
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testSameColorWithAnotherAlphaDoesNotNotify [
	"The alpha is forced to 1, so the stored color does not change."

	scheme overrideAt: 'Class' put: Color red.
	scheme whenChangedDo: self countingBlock.
	scheme overrideAt: 'Class' put: (Color red alpha: 0.5).
	self assert: notifications equals: 0
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testSeveralSubscribersAreAllNotified [

	| a b |
	a := 0.
	b := 0.
	scheme whenChangedDo: [ a := a + 1 ].
	scheme whenChangedDo: [ b := b + 10 ].
	self assert: scheme subscriberCount equals: 2.
	scheme overrideAt: 'Class' put: Color red.
	self assert: a equals: 1.
	self assert: b equals: 10
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testSubscriberCanUnsubscribeWhileNotified [

	| block other |
	other := 0.
	block := nil.
	block := [
		         notifications := notifications + 1.
		         scheme removeSubscriber: block ].
	scheme whenChangedDo: block.
	scheme whenChangedDo: [ other := other + 1 ].
	scheme overrideAt: 'Class' put: Color red.
	scheme overrideAt: 'Class' put: Color blue.
	self assert: notifications equals: 1.
	self assert: other equals: 2
]

{ #category : 'tests - notifications' }
MMCColorSchemeTest >> testSubscriberSeesTheNewStateWhenNotified [

	| seen |
	scheme whenChangedDo: [ seen := scheme overrideFor: 'Class' ].
	scheme overrideAt: 'Class' put: Color red.
	self assert: seen equals: Color red.
	scheme whenChangedDo: [ seen := scheme isEmpty ].
	scheme reset.
	self assert: seen
]

{ #category : 'tests' }
MMCColorSchemeTest >> testTypeNamesOverriddenAreSorted [

	scheme overrideAt: 'Method' put: Color red.
	scheme overrideAt: 'Access' put: Color green.
	scheme overrideAt: 'Class' put: Color blue.
	self
		assert: scheme typeNamesOverridden
		equals: #( 'Access' 'Class' 'Method' )
]
