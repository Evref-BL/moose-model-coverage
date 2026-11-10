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

{ #category : 'accessing' }
MMCEntityRegion >> metamodelPrefixOf: aClass [
	"Answer the prefix shared by the entity classes of the metamodel of aClass, or 'Famix'."

	^ MMCTypeName metamodelPrefixOf: aClass
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
	"Answer the entity class name without the Famix prefix and the metamodel prefix (FamixJavaMethod gives Method). See MMCTypeName."

	^ MMCTypeName ofClass: entity class
]
