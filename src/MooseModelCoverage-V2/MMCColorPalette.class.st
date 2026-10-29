"
Opaque colors per entity type name and nesting depth (0 to 3) for a light or dark theme, readable with the theme text color. Hues avoid red, which is reserved for uncovered zones.
"
Class {
	#name : 'MMCColorPalette',
	#superclass : 'Object',
	#instVars : [
		'theme',
		'typeNames'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCColorPalette class >> forTypeNames: aCollection theme: aSymbol [
	"Answer a palette for the given type names (order and duplicates do not matter) and theme (#light or #dark)."

	^ self new setTypeNames: aCollection theme: aSymbol
]

{ #category : 'instance creation' }
MMCColorPalette class >> themeForBackground: aColor [
	"Answer #dark for a dark background color, #light otherwise."

	^ aColor luminance < 0.4
		  ifTrue: [ #dark ]
		  ifFalse: [ #light ]
]

{ #category : 'accessing' }
MMCColorPalette >> colorForSegment: aSegment [

	^ aSegment isUncovered
		  ifTrue: [ self uncoveredColor ]
		  ifFalse: [
		  self colorForType: aSegment typeName depth: aSegment depth ]
]

{ #category : 'accessing' }
MMCColorPalette >> colorForType: aTypeName depth: anInteger [
	"Answer the opaque color of the type at the depth (capped between 0 and 3); a neutral grey when the type is unknown."

	| level index |
	level := ((anInteger ifNil: [ 0 ]) max: 0) min: 3.
	index := aTypeName
		         ifNil: [ 0 ]
		         ifNotNil: [ typeNames indexOf: aTypeName ].
	index = 0 ifTrue: [ ^ self greyAtLevel: level ].
	^ self colorOfHue: (self hueOfIndex: index) level: level
]

{ #category : 'private' }
MMCColorPalette >> colorOfHue: aHue level: aLevel [
	"Saturation is fixed per theme; the value is searched so that the relative luminance hits a target per level. Dark: L in [0.07, 0.165] (>= 1.5 contrast against 2B2B2B, >= 4.5 with white text). Light: L in [0.38, 0.74] (>= 1.15 against F5F5F5, >= 4.5 with black text)."

	| saturation target low high |
	theme == #light
		ifTrue: [
				saturation := 0.2 + (0.12 * aLevel).
				target := #( 0.74 0.58 0.43 0.31 ) at: aLevel + 1 ]
		ifFalse: [
				saturation := 0.6.
				target := #( 0.07 0.095 0.125 0.165 ) at: aLevel + 1 ].
	low := 0.
	high := 1.
	40 timesRepeat: [
			| middle |
			middle := low + high / 2.
			(self relativeLuminanceOf: (Color h: aHue s: saturation v: middle))
			< target
				ifTrue: [ low := middle ]
				ifFalse: [ high := middle ] ].
	^ Color h: aHue s: saturation v: high
]

{ #category : 'private' }
MMCColorPalette >> greyAtLevel: aLevel [
	"Unknown types: dark grey with L in [0.078, 0.15] (white text, >= 1.5 against 2B2B2B); light grey with L from 0.69 down to 0.30 (black text, >= 1.15 against F5F5F5)."

	^ Color gray: (theme == #light
			   ifTrue: [ #( 0.85 0.72 0.60 0.50 ) at: aLevel + 1 ]
			   ifFalse: [ #( 0.31 0.35 0.39 0.43 ) at: aLevel + 1 ])
]

{ #category : 'private' }
MMCColorPalette >> hueOfIndex: anIndex [
	"Hues span 40 to 320 degrees: no red, reserved for uncovered zones."

	typeNames size = 1 ifTrue: [ ^ 40 ].
	^ 40 + (anIndex - 1 * 280 / (typeNames size - 1))
]

{ #category : 'private' }
MMCColorPalette >> relativeLuminanceOf: aColor [
	"WCAG relative luminance."

	| linear |
	linear := [ :component |
		          component <= 0.03928
			          ifTrue: [ component / 12.92 ]
			          ifFalse: [ component + 0.055 / 1.055 raisedTo: 2.4 ] ].
	^ 0.2126 * (linear value: aColor red)
	  + (0.7152 * (linear value: aColor green))
	  + (0.0722 * (linear value: aColor blue))
]

{ #category : 'initialization' }
MMCColorPalette >> setTypeNames: aCollection theme: aSymbol [

	(aSymbol == #light or: [ aSymbol == #dark ]) ifFalse: [
			^ Error signal:
				  'Invalid theme ' , aSymbol printString
				  , ' (expected #light or #dark)' ].
	theme := aSymbol.
	typeNames := (aCollection reject: [ :each | each isNil ]) asSet
		             asSortedCollection asArray
]

{ #category : 'accessing' }
MMCColorPalette >> textColor [
	"Answer the color to draw text over the palette colors."

	^ theme == #light
		  ifTrue: [ Color black ]
		  ifFalse: [ Color white ]
]

{ #category : 'accessing' }
MMCColorPalette >> theme [

	^ theme
]

{ #category : 'accessing' }
MMCColorPalette >> typeNames [
	"Answer the sorted type names without duplicate."

	^ typeNames copy
]

{ #category : 'accessing' }
MMCColorPalette >> uncoveredColor [
	"Answer the color of the uncovered zones, whatever the types. Dark: vivid red (L about 0.15, readable with white text, far from the dark backgrounds); light: salmon."

	^ theme == #light
		  ifTrue: [ Color r: 1 g: 0.4 b: 0.4 ]
		  ifFalse: [ Color r: 0.9 g: 0 b: 0 ]
]
