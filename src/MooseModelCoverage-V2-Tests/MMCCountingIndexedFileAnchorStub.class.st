"
Test stub: an indexed file anchor counting the calls to completeText (all instances share the counter), used to check that V2 reads a file only once.
"
Class {
	#name : 'MMCCountingIndexedFileAnchorStub',
	#superclass : 'FamixJavaIndexedFileAnchor',
	#classInstVars : [
		'completeTextCalls'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'counting' }
MMCCountingIndexedFileAnchorStub class >> completeTextCalls [
	^ completeTextCalls ifNil: [ 0 ]
]

{ #category : 'counting' }
MMCCountingIndexedFileAnchorStub class >> noteCompleteTextCall [
	completeTextCalls := self completeTextCalls + 1
]

{ #category : 'counting' }
MMCCountingIndexedFileAnchorStub class >> resetCompleteTextCalls [
	completeTextCalls := 0
]

{ #category : 'accessing' }
MMCCountingIndexedFileAnchorStub >> completeText [
	self class noteCompleteTextCall.
	^ super completeText
]
