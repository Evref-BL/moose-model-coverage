"
I compute the Famix type name of an entity class: the class name without the Famix prefix and without the metamodel prefix (FamixJavaMethod gives Method). The metamodel prefix is the name of the topmost Famix<Metamodel>Entity class of the superclass chain. I am shared by MMCEntityRegion, MMCModelNavigator and MMCModelFiles.
"
Class {
	#name : 'MMCTypeName',
	#superclass : 'Object',
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'accessing' }
MMCTypeName class >> metamodelPrefixOf: aClass [
	"Answer the prefix shared by the entity classes of the metamodel of aClass, or 'Famix'. The root entity class is the topmost class of the superclass chain named Famix<Metamodel>Entity."

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
MMCTypeName class >> ofClass: aClass [
	"Answer the name of aClass without the metamodel prefix, else without the Famix prefix (FamixJavaMethod gives Method)."

	| className prefix |
	className := aClass name.
	prefix := self metamodelPrefixOf: aClass.
	(className beginsWith: prefix) ifTrue: [
		^ className allButFirst: prefix size ].
	^ (className beginsWith: 'Famix')
		  ifTrue: [ className allButFirst: 5 ]
		  ifFalse: [ className ]
]
