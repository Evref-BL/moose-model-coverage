"
I am the text region (1-based, inclusive interval in characters) of an entity inside a file text.
"
Class {
	#name : 'MMCEntityRegion',
	#superclass : 'Object',
	#instVars : [
		'entity',
		'anchor',
		'interval',
		'text'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCEntityRegion class >> entity: anEntity anchor: anAnchor interval: anInterval text: aString [

	^ self new
		  setEntity: anEntity
		  anchor: anAnchor
		  interval: anInterval
		  text: aString;
		  yourself
]

{ #category : 'accessing' }
MMCEntityRegion >> anchor [

	^ anchor
]

{ #category : 'accessing' }
MMCEntityRegion >> entity [

	^ entity
]

{ #category : 'accessing' }
MMCEntityRegion >> interval [
	"Answer the 1-based inclusive interval of characters in the file text."

	^ interval
]

{ #category : 'private' }
MMCEntityRegion >> metamodelPrefixOf: aClass [
	"Answer the prefix shared by the entity classes of the metamodel of aClass, or 'Famix'.
	The root entity class is the topmost class of the superclass chain named Famix<Metamodel>Entity."

	| rootEntity |
	rootEntity := aClass withAllSuperclasses reversed
		              detect: [ :each |
				              (each name beginsWith: 'Famix') and: [
					              (each name endsWith: 'Entity') and: [
						              each name size > 11 ] ] ]
		              ifNone: [ ^ 'Famix' ].
	^ rootEntity name allButLast: 6
]

{ #category : 'accessing' }
MMCEntityRegion >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: self typeName;
		nextPutAll: ' ';
		print: interval first;
		nextPut: $-;
		print: interval last;
		nextPut: $)
]

{ #category : 'accessing' }
MMCEntityRegion >> setEntity: anEntity anchor: anAnchor interval: anInterval text: aString [

	entity := anEntity.
	anchor := anAnchor.
	interval := anInterval.
	text := aString
]

{ #category : 'accessing' }
MMCEntityRegion >> size [
	"Answer the number of characters of the region."

	^ interval size
]

{ #category : 'accessing' }
MMCEntityRegion >> text [
	"Answer the text of the region."

	^ text
]

{ #category : 'accessing' }
MMCEntityRegion >> typeName [
	"Answer the entity class name without the Famix prefix and the metamodel prefix.
	The metamodel prefix is the name of the root entity class of the metamodel, found in the superclass chain as a class named Famix<Metamodel>Entity (FamixJavaEntity gives FamixJava), so FamixJavaMethod gives Method. Without such a class only the Famix prefix is removed."

	| name prefix |
	name := entity class name.
	prefix := self metamodelPrefixOf: entity class.
	(name beginsWith: prefix) ifTrue: [ ^ name allButFirst: prefix size ].
	^ (name beginsWith: 'Famix')
		  ifTrue: [ name allButFirst: 5 ]
		  ifFalse: [ name ]
]
