"
Tests of the color scheme support of MMCColorPalette: without scheme (or with an empty one) the colors are exactly the default ones, an override gives a color of the same hue whose luminance reaches the target of each level and theme (so the text color keeps its contrast), defaultColorForType:depth: ignores the scheme, and the memos are dropped by colorScheme:.
"
Class {
	#name : 'MMCColorPaletteSchemeTest',
	#superclass : 'TestCase',
	#instVars : [
		'scheme'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> assertGrey: aColor [

	self assert: (aColor red - aColor green) abs < 0.005.
	self assert: (aColor green - aColor blue) abs < 0.005
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> assertLuminancesOfBasesInTheme: aTheme [

	| palette |
	palette := self paletteFor: aTheme.
	self bases do: [ :base |
			(0 to: 3) do: [ :level |
					| color target |
					color := palette colorOfBase: base value level: level.
					target := self targetLuminanceOf: aTheme level: level.
					self
						assert: ((self luminanceOf: color) - target) abs <= 0.02
						description:
							base key , ' ' , aTheme , ' level ' , level printString
							, ' luminance ' , (self luminanceOf: color) printString
							, ' target ' , target printString.
					self assert: color alpha equals: 1 ] ]
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> bases [
	"Named base colors, answered as an Array of associations."

	^ {
		  ('blue' -> Color blue).
		  ('yellow' -> Color yellow).
		  ('red' -> Color red).
		  ('grey' -> Color gray).
		  ('black' -> Color black).
		  ('white' -> Color white) }
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> contrastBetween: aColor and: anotherColor [

	| a b |
	a := self luminanceOf: aColor.
	b := self luminanceOf: anotherColor.
	^ (a max: b) + 0.05 / ((a min: b) + 0.05)
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> luminanceOf: aColor [
	"WCAG relative luminance, computed here independently of the palette."

	| linear |
	linear := [ :c |
		          c <= 0.03928
			          ifTrue: [ c / 12.92 ]
			          ifFalse: [ c + 0.055 / 1.055 raisedTo: 2.4 ] ].
	^ 0.2126 * (linear value: aColor red)
	  + (0.7152 * (linear value: aColor green))
	  + (0.0722 * (linear value: aColor blue))
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> paletteFor: aTheme [

	^ MMCColorPalette forTypeNames: self typeNames theme: aTheme
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> setUp [

	super setUp.
	scheme := MMCColorScheme new
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> targetLuminanceOf: aTheme level: aLevel [
	"The targets measured on the design, written again here."

	^ (aTheme == #light
		   ifTrue: [ #( 0.74 0.58 0.43 0.31 ) ]
		   ifFalse: [ #( 0.07 0.095 0.125 0.165 ) ]) at: aLevel + 1
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testColorSchemeAccessor [

	| palette |
	palette := self paletteFor: #dark.
	self assert: palette colorScheme isNil.
	palette colorScheme: scheme.
	self assert: palette colorScheme == scheme
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testColorSchemeSetterEmptiesTheMemos [

	| palette |
	palette := self paletteFor: #dark.
	palette colorForType: 'Class' depth: 0.
	self deny: (palette instVarNamed: 'colorCache') isEmpty.
	palette colorScheme: scheme.
	self assert: (palette instVarNamed: 'colorCache') isEmpty.
	self assert: (palette instVarNamed: 'classColors') isEmpty
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testDarkLevelsAreLighterAsTheDepthGrows [

	| palette |
	palette := self paletteFor: #dark.
	#( 0 1 2 ) do: [ :level |
			self assert:
				(self luminanceOf: (palette colorOfBase: Color red level: level))
				<
				(self luminanceOf:
					 (palette colorOfBase: Color red level: level + 1)) ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testDefaultColorIgnoresTheScheme [

	self themes do: [ :theme |
			| palette reference |
			palette := self paletteFor: theme.
			reference := self paletteFor: theme.
			palette colorScheme: scheme.
			scheme overrideAt: 'Class' put: Color red.
			scheme overrideAt: 'Method' put: Color blue.
			(0 to: 3) do: [ :level |
					self typeNames , { nil } do: [ :type |
							self
								assert: (palette defaultColorForType: type depth: level)
								equals: (reference defaultColorForType: type depth: level) ] ] ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testDefaultColorIsTheColorOfATypeWithoutOverride [

	| palette |
	palette := self paletteFor: #dark.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color red.
	(0 to: 3) do: [ :level |
			self
				assert: (palette defaultColorForType: 'Method' depth: level)
				equals: (palette colorForType: 'Method' depth: level) ]
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testDefaultColorsAreMemoizedWithAScheme [

	| palette |
	palette := self paletteFor: #light.
	palette colorScheme: scheme.
	self assert: (palette colorForType: 'Class' depth: 1)
		== (palette colorForType: 'Class' depth: 1).
	self assert: (palette defaultColorForType: 'Class' depth: 1)
		== (palette defaultColorForType: 'Class' depth: 1)
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testDefaultSaturationAtLevel [

	| light dark |
	light := self paletteFor: #light.
	dark := self paletteFor: #dark.
	(0 to: 3) do: [ :level |
			self assert:
				((light defaultSaturationAtLevel: level) - (0.2 + (0.12 * level)))
					abs < 0.0001.
			self assert: (dark defaultSaturationAtLevel: level) equals: 0.6 ]
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testDepthIsCappedWithAnOverride [

	| palette |
	palette := self paletteFor: #dark.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color green.
	self
		assert: (palette colorForType: 'Class' depth: 9)
		equals: (palette colorForType: 'Class' depth: 3).
	self
		assert: (palette colorForType: 'Class' depth: -2)
		equals: (palette colorForType: 'Class' depth: 0)
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testGreyBaseGivesGreys [

	self themes do: [ :theme |
			| palette |
			palette := self paletteFor: theme.
			{
				Color gray.
				Color black.
				Color white.
				(Color r: 0.3 g: 0.3 b: 0.3) } do: [ :base |
					(0 to: 3) do: [ :level |
						self assertGrey: (palette colorOfBase: base level: level) ] ] ]
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testLightLevelsAreDarkerAsTheDepthGrows [

	| palette |
	palette := self paletteFor: #light.
	#( 0 1 2 ) do: [ :level |
			self assert:
				(self luminanceOf: (palette colorOfBase: Color blue level: level))
				>
				(self luminanceOf:
					 (palette colorOfBase: Color blue level: level + 1)) ]
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testLightenedSaturationNeverExceedsTheBaseSaturation [

	| palette base |
	palette := self paletteFor: #light.
	base := Color r: 0.2 g: 0.2 b: 1.
	(0 to: 3) do: [ :level |
			self assert: (palette colorOfBase: base level: level) saturation
				<= (base saturation + 0.01) ]
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testLuminanceOfBasesReachesTheTargetsInDarkTheme [

	self assertLuminancesOfBasesInTheme: #dark
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testLuminanceOfBasesReachesTheTargetsInLightTheme [

	self assertLuminancesOfBasesInTheme: #light
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testModifiedOverrideThenColorSchemeGivesTheNewColor [

	| palette first second |
	palette := self paletteFor: #light.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color red.
	first := palette colorForType: 'Class' depth: 0.
	scheme overrideAt: 'Class' put: Color blue.
	palette colorScheme: scheme.
	second := palette colorForType: 'Class' depth: 0.
	self deny: first = second.
	self assert: (second hue - Color blue hue) abs < 2
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testNilDepthIsLevelZeroWithAScheme [

	| palette |
	palette := self paletteFor: #dark.
	palette colorScheme: scheme.
	self
		assert: (palette colorForType: 'Class' depth: nil)
		equals: (palette colorForType: 'Class' depth: 0).
	scheme overrideAt: 'Class' put: Color red.
	self
		assert: (palette colorForType: 'Class' depth: nil)
		equals: (palette colorForType: 'Class' depth: 0)
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testNilTypeIgnoresTheScheme [

	| palette |
	palette := self paletteFor: #dark.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color red.
	self assertGrey: (palette colorForType: nil depth: 0)
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testNoSchemeAndEmptySchemeGiveIdenticalColors [

	self themes do: [ :theme |
			| reference withScheme withoutScheme |
			reference := self paletteFor: theme.
			withScheme := self paletteFor: theme.
			withScheme colorScheme: scheme.
			withoutScheme := self paletteFor: theme.
			withoutScheme colorScheme: nil.
			self typeNames , #( 'Unknown' ) , { nil } do: [ :type |
					(-1 to: 5) do: [ :depth |
							| expected |
							expected := reference colorForType: type depth: depth.
							self
								assert: (withScheme colorForType: type depth: depth)
								equals: expected.
							self
								assert: (withoutScheme colorForType: type depth: depth)
								equals: expected ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testOverrideAppliesToTheFourLevels [

	self themes do: [ :theme |
			| palette default |
			palette := self paletteFor: theme.
			palette colorScheme: scheme.
			scheme overrideAt: 'Class' put: (Color r: 1 g: 0.5 b: 0).
			(0 to: 3) do: [ :level |
					default := palette defaultColorForType: 'Class' depth: level.
					self deny: (palette colorForType: 'Class' depth: level) = default.
					self
						assert: (palette colorForType: 'Class' depth: level) alpha
						equals: 1 ] ]
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testOverrideColorsAreMemoized [

	| palette |
	palette := self paletteFor: #light.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color red.
	self assert: (palette colorForType: 'Class' depth: 1)
		== (palette colorForType: 'Class' depth: 1)
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testOverrideDoesNotChangeTheOtherTypes [

	| palette reference |
	reference := self paletteFor: #light.
	palette := self paletteFor: #light.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color red.
	(0 to: 3) do: [ :level |
			self
				assert: (palette colorForType: 'Method' depth: level)
				equals: (reference colorForType: 'Method' depth: level).
			self
				assert: (palette colorForType: 'Access' depth: level)
				equals: (reference colorForType: 'Access' depth: level) ]
]

{ #category : 'tests' }
MMCColorPaletteSchemeTest >> testOverrideLevelsKeepTheHueOfTheBase [

	| palette base |
	base := Color r: 0.9 g: 0.4 b: 0.1.
	palette := self paletteFor: #dark.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: base.
	(0 to: 3) do: [ :level |
			self assert:
				((palette colorForType: 'Class' depth: level) hue - base hue) abs
				< 2 ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testRemovedOverrideGivesTheDefaultColorBack [

	| palette default |
	palette := self paletteFor: #light.
	default := palette colorForType: 'Class' depth: 2.
	palette colorScheme: scheme.
	scheme overrideAt: 'Class' put: Color red.
	self deny: (palette colorForType: 'Class' depth: 2) = default.
	scheme removeOverrideFor: 'Class'.
	palette colorScheme: scheme.
	self assert: (palette colorForType: 'Class' depth: 2) equals: default
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testSaturatedBaseKeepsItsHueEvenWhenLightened [

	| palette |
	palette := self paletteFor: #light.
	(0 to: 3) do: [ :level |
			self assert:
				((palette colorOfBase: Color blue level: level) hue
				 - Color blue hue) abs < 2.
			self assert:
				((palette colorOfBase: Color red level: level) hue - Color red hue)
					abs < 2 ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testSettingNilSchemeGivesTheDefaultColorsBack [

	| palette default |
	palette := self paletteFor: #dark.
	default := palette colorForType: 'Method' depth: 1.
	palette colorScheme: scheme.
	scheme overrideAt: 'Method' put: Color green.
	self deny: (palette colorForType: 'Method' depth: 1) = default.
	palette colorScheme: nil.
	self
		assert: (palette colorForType: 'Method' depth: 1)
		equals: default
]

{ #category : 'tests - luminance' }
MMCColorPaletteSchemeTest >> testTargetLuminances [

	| light dark |
	light := self paletteFor: #light.
	dark := self paletteFor: #dark.
	(0 to: 3) do: [ :level |
			self assert: ((light targetLuminanceAtLevel: level)
				 - (self targetLuminanceOf: #light level: level)) abs < 0.0001.
			self assert: ((dark targetLuminanceAtLevel: level)
				 - (self targetLuminanceOf: #dark level: level)) abs < 0.0001 ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testTextColorFollowsTheTheme [

	self assert: (self paletteFor: #light) textColor equals: Color black.
	self assert: (self paletteFor: #dark) textColor equals: Color white
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testTextColorKeepsItsContrastOnOverriddenColors [

	self themes do: [ :theme |
			| palette |
			palette := self paletteFor: theme.
			palette colorScheme: scheme.
			self bases do: [ :base |
					scheme overrideAt: 'Class' put: base value.
					(0 to: 3) do: [ :level |
							self
								assert: (self
										 contrastBetween: palette textColor
										 and: (palette colorForType: 'Class' depth: level)) >= 4.5
								description:
								base key , ' ' , theme , ' level ' , level printString ] ] ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testUnknownTypeIsGrey [

	self themes do: [ :theme |
			| palette |
			palette := self paletteFor: theme.
			(0 to: 3) do: [ :level |
					self assertGrey: (palette colorForType: 'Unknown' depth: level).
					self assertGrey: (palette colorForType: nil depth: level).
					self assertGrey:
						(palette defaultColorForType: 'Unknown' depth: level) ].
			palette colorScheme: scheme.
			self assertGrey: (palette colorForType: 'Unknown' depth: 0) ]
]

{ #category : 'tests - scheme' }
MMCColorPaletteSchemeTest >> testUnknownTypeWithAnOverrideTakesTheOverride [
	"An override does not need the type to be in the palette."

	| palette |
	palette := self paletteFor: #dark.
	palette colorScheme: scheme.
	scheme overrideAt: 'Unknown' put: Color red.
	self assert:
		((palette colorForType: 'Unknown' depth: 0) hue - Color red hue) abs
		< 2.
	self assert:
		(palette colorForType: 'Unknown' depth: 0) saturation > 0.3
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> themes [

	^ #( #light #dark )
]

{ #category : 'helpers' }
MMCColorPaletteSchemeTest >> typeNames [

	^ #( 'Access' 'Class' 'Method' )
]
