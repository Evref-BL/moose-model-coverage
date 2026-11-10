"
I hold the user color choices of one Moose model: a base color (always opaque) per Famix type name (the key is the type name as MMCEntityRegion>>typeName answers, for example 'Method'). A type without override keeps its default palette color. Subscribers registered with whenChangedDo: are notified after each change, so that views can refresh; they are not copied by copy. See MMCColorSchemeRegistry for the scheme of a model and MMCColorPalette>>colorScheme: for its use.
"
Class {
	#name : 'MMCColorScheme',
	#superclass : 'Object',
	#instVars : [
		'overrides',
		'subscribers',
		'hiddenTypeNames'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'comparing' }
MMCColorScheme >> = anObject [
	"Two schemes are equal when they have the same overrides and the same hidden types (subscribers are ignored)."

	^ self == anObject or: [
			  self class == anObject class and: [
					  overrides = anObject overrides and: [
						  hiddenTypeNames = anObject hiddenTypeNames ] ] ]
]

{ #category : 'accessing' }
MMCColorScheme >> hasHiddenTypes [

	^ hiddenTypeNames isNotEmpty
]

{ #category : 'accessing' }
MMCColorScheme >> hasOverrides [

	^ overrides isNotEmpty
]

{ #category : 'comparing' }
MMCColorScheme >> hash [

	^ overrides hash bitXor: hiddenTypeNames hash
]

{ #category : 'accessing' }
MMCColorScheme >> hiddenTypeNames [
	"Answer a copy of the set of the hidden type names."

	^ hiddenTypeNames copy
]

{ #category : 'accessing' }
MMCColorScheme >> hideAll: aTypeNameCollection [
	"Hide the types, in addition to those already hidden, with one single notification, and only when one of them was visible."

	| before |
	before := hiddenTypeNames size.
	hiddenTypeNames addAll: aTypeNameCollection.
	hiddenTypeNames size = before ifTrue: [ ^ self ].
	self notifySubscribers
]

{ #category : 'accessing' }
MMCColorScheme >> hideType: aTypeName [
	"Hide the type and notify; nothing happens when it is already hidden."

	(hiddenTypeNames includes: aTypeName) ifTrue: [ ^ self ].
	hiddenTypeNames add: aTypeName.
	self notifySubscribers
]

{ #category : 'initialization' }
MMCColorScheme >> initialize [

	super initialize.
	overrides := Dictionary new.
	hiddenTypeNames := Set new.
	subscribers := OrderedCollection new
]

{ #category : 'accessing' }
MMCColorScheme >> isDefault [
	"Answer true when there is no color override and no hidden type."

	^ overrides isEmpty and: [ hiddenTypeNames isEmpty ]
]

{ #category : 'accessing' }
MMCColorScheme >> isEmpty [

	^ overrides isEmpty
]

{ #category : 'accessing' }
MMCColorScheme >> isTypeVisible: aTypeName [
	"A type is visible unless it was hidden; an unknown type is visible."

	^ (hiddenTypeNames includes: aTypeName) not
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
	"The copy has its own overrides and hidden types and no subscriber."

	super postCopy.
	overrides := overrides copy.
	hiddenTypeNames := hiddenTypeNames copy.
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

{ #category : 'accessing' }
MMCColorScheme >> setHiddenTypeNames: aTypeNameCollection [
	"Replace the hidden types by aTypeNameCollection with one single notification, and only when the set changes."

	| new |
	new := Set withAll: aTypeNameCollection.
	new = hiddenTypeNames ifTrue: [ ^ self ].
	hiddenTypeNames := new.
	self notifySubscribers
]

{ #category : 'accessing' }
MMCColorScheme >> setType: aTypeName visible: aBoolean [

	aBoolean
		ifTrue: [ self showType: aTypeName ]
		ifFalse: [ self hideType: aTypeName ]
]

{ #category : 'accessing' }
MMCColorScheme >> showAll [
	"Show every type and notify when some type was hidden."

	hiddenTypeNames isEmpty ifTrue: [ ^ self ].
	hiddenTypeNames := Set new.
	self notifySubscribers
]

{ #category : 'accessing' }
MMCColorScheme >> showType: aTypeName [
	"Show the type and notify; nothing happens when it is already visible."

	(hiddenTypeNames includes: aTypeName) ifFalse: [ ^ self ].
	hiddenTypeNames remove: aTypeName.
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
