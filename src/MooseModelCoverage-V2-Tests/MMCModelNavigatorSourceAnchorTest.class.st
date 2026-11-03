"
Pure tests of MMCModelNavigator>>hasSourceAnchor: (expected API, called through perform:): true when the entity answers a non nil sourceAnchor, false otherwise (no anchor, nil, object that does not understand #sourceAnchor), without any error, whatever the coverage and the filter. Used by MMCCoveragePresenter to decide whether an entity carries the warning icon (see MMCCoveragePresenterWarningIconTest).
"
Class {
	#name : 'MMCModelNavigatorSourceAnchorTest',
	#superclass : 'TestCase',
	#instVars : [
		'navigator'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> anchoredEntity [

	| entity |
	entity := FamixJavaClass new.
	entity name: 'WithAnchor'.
	entity sourceAnchor: (FamixJavaIndexedFileAnchor new
			 fileName: 'absent.txt';
			 startPos: 1;
			 endPos: 5;
			 yourself).
	^ entity
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> hasAnchor: anObject [

	^ navigator perform: #hasSourceAnchor: with: anObject
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> setUp [

	super setUp.
	navigator := MMCModelNavigator
		             on: nil
		             coverage: MMCCoveragePresenter emptyCoverage
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> testAnchorToAMissingFileCountsAsAnAnchor [
	"Literal meaning: the anchor exists even if its file is absent."

	self assert: (self hasAnchor: self anchoredEntity)
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> testEntityWithSourceAnchorHasOne [

	self assert: (self hasAnchor: self anchoredEntity)
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> testEntityWithoutSourceAnchorHasNone [

	self deny: (self hasAnchor: (FamixJavaClass new
				  name: 'Bare';
				  yourself)).
	self deny: (self hasAnchor: (FamixJavaPackage new
				  name: 'pkg';
				  yourself))
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> testHasSourceAnchorDoesNotChangeTheNavigator [

	| rootsBefore |
	rootsBefore := navigator roots.
	self hasAnchor: self anchoredEntity.
	self hasAnchor: nil.
	self assert: navigator roots equals: rootsBefore.
	self assert: navigator roots isEmpty
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> testNilHasNoSourceAnchorAndRaisesNothing [

	self deny: (self hasAnchor: nil)
]

{ #category : 'tests' }
MMCModelNavigatorSourceAnchorTest >> testObjectsNotUnderstandingSourceAnchorHaveNone [

	self deny: (self hasAnchor: Object new).
	self deny: (self hasAnchor: 'text').
	self deny: (self hasAnchor: 42)
]
