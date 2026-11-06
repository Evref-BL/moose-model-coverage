"
I hold the user color choices of one Moose model: a base color (always opaque) per Famix type name (the key is the type name as MMCEntityRegion>>typeName answers, for example 'Method'). A type without override keeps its default palette color. Subscribers registered with whenChangedDo: are notified after each change, so that views can refresh; they are not copied by copy. See MMCColorSchemeRegistry for the scheme of a model and MMCColorPalette>>colorScheme: for its use.
"
Class {
	#name : 'MMCColorScheme',
	#superclass : 'Object',
	#instVars : [
		'overrides',
		'subscribers'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'comparing' }
MMCColorScheme >> = anObject [
	"Two schemes are equal when they have the same overrides (subscribers are ignored)."

	^ self == anObject or: [
		  self class == anObject class and: [
			  overrides = anObject overrides ] ]
]

{ #category : 'accessing' }
MMCColorScheme >> hasOverrides [

	^ overrides isNotEmpty
]

{ #category : 'comparing' }
MMCColorScheme >> hash [

	^ overrides hash
]

{ #category : 'initialization' }
MMCColorScheme >> initialize [

	super initialize.
	overrides := Dictionary new.
	subscribers := OrderedCollection new
]

{ #category : 'accessing' }
MMCColorScheme >> isEmpty [

	^ overrides isEmpty
]

{ #category : 'notification' }
MMCColorScheme >> notifySubscribers [
	"Notify the subscribers; a copy of the list is used so that a subscriber can unsubscribe while notified."

	subscribers copy do: [ :each | each value ]
]

{ #category : 'accessing' }
MMCColorScheme >> overrideAt: aTypeName put: aColor [
	"Set the base color of the type (forced opaque) and notify. Nothing happens, no notification, when the color is already the one of the type."

	| opaque |
	opaque := Color
		          r: aColor red
		          g: aColor green
		          b: aColor blue
		          alpha: 1.
	(overrides at: aTypeName ifAbsent: [ nil ]) = opaque ifTrue: [
		^ self ].
	overrides at: aTypeName put: opaque.
	self notifySubscribers
]

{ #category : 'accessing' }
MMCColorScheme >> overrideFor: aTypeName [
	"Answer the base color of the type, nil without override."

	^ overrides at: aTypeName ifAbsent: [ nil ]
]

{ #category : 'comparing' }
MMCColorScheme >> overrides [

	^ overrides
]

{ #category : 'initialization' }
MMCColorScheme >> postCopy [
	"The copy has its own overrides and no subscriber."

	super postCopy.
	overrides := overrides copy.
	subscribers := OrderedCollection new
]

{ #category : 'notification' }
MMCColorScheme >> removeAllSubscribers [

	subscribers := OrderedCollection new
]

{ #category : 'accessing' }
MMCColorScheme >> removeOverrideFor: aTypeName [
	"Forget the override of the type and notify; nothing happens without override."

	(overrides includesKey: aTypeName) ifFalse: [ ^ self ].
	overrides removeKey: aTypeName.
	self notifySubscribers
]

{ #category : 'notification' }
MMCColorScheme >> removeSubscriber: aBlock [
	"Stop notifying aBlock, the very block given to whenChangedDo:."

	subscribers remove: aBlock ifAbsent: [ ]
]

{ #category : 'accessing' }
MMCColorScheme >> reset [
	"Forget all the overrides and notify when there was one."

	overrides isEmpty ifTrue: [ ^ self ].
	overrides := Dictionary new.
	self notifySubscribers
]

{ #category : 'notification' }
MMCColorScheme >> subscriberCount [

	^ subscribers size
]

{ #category : 'accessing' }
MMCColorScheme >> typeNamesOverridden [
	"Answer the sorted type names having an override."

	^ overrides keys asArray sorted
]

{ #category : 'notification' }
MMCColorScheme >> whenChangedDo: aBlock [
	"Evaluate aBlock (without argument) after each change of the scheme."

	subscribers add: aBlock
]
