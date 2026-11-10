"
Tests of MMCTypeName: the name of an entity class without the metamodel prefix (FamixJavaMethod gives Method), and of the delegations of MMCEntityRegion>>typeName and MMCModelNavigator>>typeNameOf: that must answer the same names as before the extraction.
"
Class {
	#name : 'MMCTypeNameTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'tests' }
MMCTypeNameTest >> testClassWithoutFamixPrefixKeepsItsName [

	self assert: (MMCTypeName ofClass: Object) asString equals: 'Object'.
	self
		assert: (MMCTypeName ofClass: OrderedCollection) asString
		equals: 'OrderedCollection'.
	self assert: (MMCTypeName metamodelPrefixOf: Object) equals: 'Famix'
]

{ #category : 'tests' }
MMCTypeNameTest >> testEntityRegionTypeNameDelegates [

	| region |
	region := MMCEntityRegion
		          entity: FamixJavaMethod new
		          anchor: nil
		          interval: (1 to: 2)
		          text: 'x'.
	self assert: region typeName asString equals: 'Method'.
	self
		assert: region typeName
		equals: (MMCTypeName ofClass: FamixJavaMethod).
	region := MMCEntityRegion
		          entity: FamixJavaClass new
		          anchor: nil
		          interval: (1 to: 2)
		          text: 'x'.
	self assert: region typeName asString equals: 'Class'
]

{ #category : 'tests' }
MMCTypeNameTest >> testFamixClassOutsideAnEntityHierarchyOnlyLosesFamix [
	"A Famix class that is not under a Famix<Metamodel>Entity (the model class) only loses the Famix prefix."

	self
		assert: (MMCTypeName metamodelPrefixOf: FamixJavaModel)
		equals: 'Famix'.
	self
		assert: (MMCTypeName ofClass: FamixJavaModel) asString
		equals: 'JavaModel'
]

{ #category : 'tests' }
MMCTypeNameTest >> testJavaClassGivesClass [

	self
		assert: (MMCTypeName ofClass: FamixJavaClass) asString
		equals: 'Class'
]

{ #category : 'tests' }
MMCTypeNameTest >> testJavaMethodGivesMethod [

	self
		assert: (MMCTypeName ofClass: FamixJavaMethod) asString
		equals: 'Method'
]

{ #category : 'tests' }
MMCTypeNameTest >> testMetamodelPrefixOfAnEntityClass [

	self
		assert: (MMCTypeName metamodelPrefixOf: FamixJavaMethod)
		equals: 'FamixJava'.
	self
		assert: (MMCTypeName metamodelPrefixOf: FamixStClass)
		equals: 'FamixSt'
]

{ #category : 'tests' }
MMCTypeNameTest >> testNavigatorTypeNameOfDelegates [

	| navigator |
	navigator := MMCModelNavigator basicNew.
	self
		assert: (navigator typeNameOf: FamixJavaMethod new) asString
		equals: 'Method'.
	self
		assert: (navigator typeNameOf: FamixJavaClass new) asString
		equals: 'Class'.
	self
		assert: (navigator typeNameOf: FamixJavaAccess new)
		equals: (MMCTypeName ofClass: FamixJavaAccess)
]

{ #category : 'tests' }
MMCTypeNameTest >> testOtherMetamodelsLoseTheirOwnPrefix [

	self
		assert: (MMCTypeName ofClass: FamixStClass) asString
		equals: 'Class'.
	self
		assert: (MMCTypeName ofClass: FamixJavaIndexedFileAnchor) asString
		equals: 'IndexedFileAnchor'.
	self
		assert: (MMCTypeName ofClass: FamixJavaAccess) asString
		equals: 'Access'
]

{ #category : 'tests' }
MMCTypeNameTest >> testRegionAndNavigatorAnswerTheSameName [

	| navigator entity region |
	navigator := MMCModelNavigator basicNew.
	{
		FamixJavaMethod.
		FamixJavaClass.
		FamixJavaAttribute.
		FamixJavaPackage } do: [ :each |
			entity := each new.
			region := MMCEntityRegion
				          entity: entity
				          anchor: nil
				          interval: (1 to: 1)
				          text: ''.
			self assert: region typeName equals: (navigator typeNameOf: entity) ]
]

{ #category : 'tests' }
MMCTypeNameTest >> testRootEntityClassOfAMetamodelGivesEntity [

	self
		assert: (MMCTypeName ofClass: FamixJavaEntity) asString
		equals: 'Entity'
]
