"
Tests of MMCColorSchemeRegistry, the color schemes by Moose model. The global state (class variable Schemes) is saved and replaced by a fresh registry in setUp and restored in tearDown, so that the schemes of the models of the image are never touched.
"
Class {
	#name : 'MMCColorSchemeRegistryTest',
	#superclass : 'TestCase',
	#instVars : [
		'savedSchemes'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> setUp [
	"Save the global registry and start from a fresh one."

	super setUp.
	savedSchemes := MMCColorSchemeRegistry classPool at: #Schemes.
	MMCColorSchemeRegistry classPool at: #Schemes put: nil
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> tearDown [

	MMCColorSchemeRegistry classPool at: #Schemes put: savedSchemes.
	super tearDown
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testForAnswersTheSameSchemeEachTime [

	| model |
	model := Object new.
	self assert: (MMCColorSchemeRegistry for: model)
		== (MMCColorSchemeRegistry for: model).
	self assert: MMCColorSchemeRegistry size equals: 1
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testForCreatesAnEmptyScheme [

	| model scheme |
	model := Object new.
	scheme := MMCColorSchemeRegistry for: model.
	self assert: scheme class equals: MMCColorScheme.
	self assert: scheme isEmpty
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testKeysAreComparedByIdentity [
	"Two equal models are two keys."

	| a b |
	a := 'model' copy.
	b := 'model' copy.
	self assert: a equals: b.
	self deny:
		(MMCColorSchemeRegistry for: a) == (MMCColorSchemeRegistry for: b)
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testRegistryDoesNotRetainAModelWhoseOnlyReferenceIsTheKey [
	"The entries are weak: once nobody else refers to a model, its scheme goes (the finalization process must run after the garbage collection, hence the short waits). The test retries a few times, as a collection is not guaranteed to be total, and keeps another model (still referenced) as a control."

	| kept gone |
	kept := Object new.
	MMCColorSchemeRegistry for: kept.
	[ MMCColorSchemeRegistry for: Object new ] value.
	gone := false.
	10 timesRepeat: [
			gone ifFalse: [
					Smalltalk garbageCollect.
					(Delay forMilliseconds: 100) wait.
					gone := MMCColorSchemeRegistry size = 1 ] ].
	self assert: gone.
	self assert: (MMCColorSchemeRegistry schemes includesKey: kept)
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testRemoveForAnUnknownModelDoesNothing [

	MMCColorSchemeRegistry for: Object new.
	MMCColorSchemeRegistry removeFor: Object new.
	self assert: MMCColorSchemeRegistry size equals: 1
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testRemoveForForgetsTheSchemeOfThatModelOnly [

	| a b schemeA schemeB |
	a := Object new.
	b := Object new.
	schemeA := MMCColorSchemeRegistry for: a.
	schemeB := MMCColorSchemeRegistry for: b.
	MMCColorSchemeRegistry removeFor: a.
	self assert: MMCColorSchemeRegistry size equals: 1.
	self assert: (MMCColorSchemeRegistry for: b) == schemeB.
	self deny: (MMCColorSchemeRegistry for: a) == schemeA
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testResetForgetsEveryScheme [

	| model scheme |
	model := Object new.
	scheme := MMCColorSchemeRegistry for: model.
	scheme overrideAt: 'Class' put: Color red.
	MMCColorSchemeRegistry for: Object new.
	MMCColorSchemeRegistry reset.
	self assert: MMCColorSchemeRegistry size equals: 0.
	self deny: (MMCColorSchemeRegistry for: model) == scheme.
	self assert: (MMCColorSchemeRegistry for: model) isEmpty
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testSchemesIsCreatedAfterReset [

	MMCColorSchemeRegistry reset.
	self assert: MMCColorSchemeRegistry schemes isEmpty.
	self assert:
		MMCColorSchemeRegistry schemes == MMCColorSchemeRegistry schemes
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testSchemesIsTheDictionaryOfTheModelsSchemes [

	| model scheme |
	model := Object new.
	scheme := MMCColorSchemeRegistry for: model.
	self assert: (MMCColorSchemeRegistry schemes at: model) == scheme.
	self
		assert: MMCColorSchemeRegistry schemes size
		equals: MMCColorSchemeRegistry size
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testSetUpIsolatesTheGlobalState [

	self assert: MMCColorSchemeRegistry size equals: 0.
	self deny: MMCColorSchemeRegistry schemes == savedSchemes
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testSizeCountsTheModelsHavingAScheme [

	| keep |
	self assert: MMCColorSchemeRegistry size equals: 0.
	keep := (1 to: 3) collect: [ :i | Object new ].
	keep do: [ :each | MMCColorSchemeRegistry for: each ].
	self assert: MMCColorSchemeRegistry size equals: 3.
	self assert: keep size equals: 3
]

{ #category : 'tests' }
MMCColorSchemeRegistryTest >> testTwoModelsHaveTwoSchemes [

	| a b |
	a := Object new.
	b := Object new.
	self deny:
		(MMCColorSchemeRegistry for: a) == (MMCColorSchemeRegistry for: b).
	(MMCColorSchemeRegistry for: a) overrideAt: 'Class' put: Color red.
	self assert: (MMCColorSchemeRegistry for: b) isEmpty.
	self assert: MMCColorSchemeRegistry size equals: 2
]
