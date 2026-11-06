"
I keep in the image the MMCColorScheme of each Moose model (for: creates it on demand). The models are held weakly, so a deleted model does not stay alive because of me, as long as its scheme has no subscriber referencing it (views must unsubscribe when closed). Schemes are lost when the image is not saved or when the model is discarded; there is no file persistence.
"
Class {
	#name : 'MMCColorSchemeRegistry',
	#superclass : 'Object',
	#classVars : [
		'Schemes'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'accessing' }
MMCColorSchemeRegistry class >> for: aModel [
	"Answer the color scheme of aModel, created empty when absent."

	^ self schemes at: aModel ifAbsentPut: [ MMCColorScheme new ]
]

{ #category : 'accessing' }
MMCColorSchemeRegistry class >> removeFor: aModel [
	"Forget the scheme of aModel, if any."

	self schemes removeKey: aModel ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MMCColorSchemeRegistry class >> reset [
	"Forget all the schemes."

	Schemes := nil
]

{ #category : 'accessing' }
MMCColorSchemeRegistry class >> schemes [

	^ Schemes ifNil: [ Schemes := WeakIdentityKeyDictionary new ]
]

{ #category : 'accessing' }
MMCColorSchemeRegistry class >> size [
	"Answer the number of models having a scheme."

	^ self schemes size
]
