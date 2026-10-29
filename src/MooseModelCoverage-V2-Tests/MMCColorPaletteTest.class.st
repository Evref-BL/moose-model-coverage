Class {
	#name : 'MMCColorPaletteTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCColorPaletteTest >> colorsOf: aPalette types: aTypeCollection [
	"Answer every color of the palette for the given types and the depths 0 to 3."
	^ aTypeCollection flatCollect: [ :type | (0 to: 3) collect: [ :depth | aPalette colorForType: type depth: depth ] ]
]

{ #category : 'helpers' }
MMCColorPaletteTest >> contrastRatioBetween: firstColor and: secondColor [
	"WCAG contrast ratio (L1 + 0.05) / (L2 + 0.05), L1 being the lighter."
	| first second |
	first := self relativeLuminanceOf: firstColor.
	second := self relativeLuminanceOf: secondColor.
	^ (first max: second) + 0.05 / ((first min: second) + 0.05)
]

{ #category : 'helpers' }
MMCColorPaletteTest >> distanceBetween: firstColor and: secondColor [
	"Euclidean RGB distance, components between 0 and 1."
	^ (((firstColor red - secondColor red) squared) + ((firstColor green - secondColor green) squared) + ((firstColor blue - secondColor blue) squared)) sqrt
]

{ #category : 'helpers' }
MMCColorPaletteTest >> errorMessageOfPaletteWithTheme: aTheme [
	"Answer the message of the Error raised for an invalid theme, nil when no error. A MessageNotUnderstood is not accepted as a precise error."
	| message |
	message := nil.
	[ self newPaletteForTypes: #( 'Class' ) theme: aTheme ]
		on: Error
		do: [ :error |
			self deny: (error isKindOf: MessageNotUnderstood) description: 'unexpected ' , error printString.
			message := error messageText ].
	^ message
]

{ #category : 'helpers' }
MMCColorPaletteTest >> linearized: aComponent [
	"WCAG linearization of an sRGB component between 0 and 1."
	^ aComponent <= 0.03928
		  ifTrue: [ aComponent / 12.92 ]
		  ifFalse: [ ((aComponent + 0.055) / 1.055) raisedTo: 2.4 ]
]

{ #category : 'helpers' }
MMCColorPaletteTest >> newPaletteForTypes: arg1 theme: arg2 [

	^ MMCColorPalette forTypeNames: arg1 theme: arg2
]

{ #category : 'helpers' }
MMCColorPaletteTest >> newRegionOfEntity: anEntity [
	^ MMCEntityRegion entity: anEntity anchor: nil interval: (1 to: 3) text: 'xxx'
]

{ #category : 'helpers' }
MMCColorPaletteTest >> newSegmentOfType: arg1 depth: arg2 [

	| tmp1 |
	tmp1 := arg1 = 'Class'
		        ifTrue: [ FamixJavaClass new ]
		        ifFalse: [ FamixJavaMethod new ].
	^ MMCHighlightSegment
		  interval: (1 to: 3)
		  region: (self newRegionOfEntity: tmp1)
		  depth: arg2
]

{ #category : 'helpers' }
MMCColorPaletteTest >> newUncoveredSegment [

	^ MMCHighlightSegment uncoveredInterval: (4 to: 6)
]

{ #category : 'helpers' }
MMCColorPaletteTest >> relativeLuminanceOf: aColor [
	"WCAG relative luminance (Color>>luminance is a Rec.601 weighting without linearization: not used)."
	^ (0.2126 * (self linearized: aColor red)) + (0.7152 * (self linearized: aColor green)) + (0.0722 * (self linearized: aColor blue))
]

{ #category : 'tests' }
MMCColorPaletteTest >> testBackgroundThresholdIsAroundLuminanceZeroPointFour [
	"Gray 0.39 has luminance 0.39 (dark), gray 0.41 has 0.41 (light). The exact 0.4 is not tested: the 10 bit rounding of Color makes it fall on either side."
	self assert: (self themeForBackground: (Color gray: 0.39)) equals: #dark.
	self assert: (self themeForBackground: (Color gray: 0.41)) equals: #light
]

{ #category : 'tests' }
MMCColorPaletteTest >> testColorsAreStableForTheSameTypes [
	"E6, two palettes built the same way give the same colors."
	| types |
	types := self typeNamesOfCount: 5.
	self themes do: [ :theme | | first second |
		first := self newPaletteForTypes: types theme: theme.
		second := self newPaletteForTypes: types theme: theme.
		self
			assert: (self colorsOf: first types: types)
			equals: (self colorsOf: second types: types) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testColorsDoNotDependOnTheInputOrder [
	"E5, same typeNames in any order give the same colors."
	| types reference |
	types := self typeNamesOfCount: 8.
	self themes do: [ :theme |
		reference := self newPaletteForTypes: types theme: theme.
		{ types reversed. (types last: 4) , (types first: 4). (types asSortedCollection: [ :a :b | a > b ]) asArray } do: [ :shuffled | | other |
			other := self newPaletteForTypes: shuffled theme: theme.
			types do: [ :type |
				0 to: 3 do: [ :depth |
					self
						assert: (other colorForType: type depth: depth)
						equals: (reference colorForType: type depth: depth) ] ].
			self assert: other uncoveredColor equals: reference uncoveredColor ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testCoveredSegmentGetsTheColorOfItsTypeAndDepth [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' 'Method' ) theme: theme.
		self
			assert: (palette colorForSegment: (self newSegmentOfType: 'Method' depth: 2))
			equals: (palette colorForType: 'Method' depth: 2) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testDarkBackgroundGivesDarkTheme [
	"1D2535: luminance about 0.14, below 0.4."
	self assert: (self themeForBackground: (Color r: 16r1D g: 16r25 b: 16r35 range: 255)) equals: #dark.
	self assert: (self themeForBackground: Color black) equals: #dark
]

{ #category : 'tests' }
MMCColorPaletteTest >> testDepthAboveThreeIsCappedToThree [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' 'Method' ) theme: theme.
		self assert: (palette colorForType: 'Class' depth: 4) equals: (palette colorForType: 'Class' depth: 3).
		self assert: (palette colorForType: 'Class' depth: 99) equals: (palette colorForType: 'Class' depth: 3) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testDepthThreeIsNotCappedBelowThree [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' ) theme: theme.
		self deny: (palette colorForType: 'Class' depth: 3) equals: (palette colorForType: 'Class' depth: 2) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testDifferentDepthsOfTheSameTypeAreDistinct [
	"E2, distance >= 0.05 for every pair of depths 0 to 3."
	self themes do: [ :theme |
		self typeCounts do: [ :count | | palette |
			palette := self newPaletteForTypes: (self typeNamesOfCount: count) theme: theme.
			(self typeNamesOfCount: count) do: [ :type |
				0 to: 3 do: [ :first |
					first + 1 to: 3 do: [ :second |
						self
							assert: (self distanceBetween: (palette colorForType: type depth: first) and: (palette colorForType: type depth: second)) >= 0.05
							description: theme , ' ' , type , ' depths ' , first printString , ' ' , second printString ] ] ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testDifferentTypesAtTheSameDepthAreDistinct [
	"E3, distance >= 0.08 for 2 to 8 types."
	self themes do: [ :theme |
		2 to: 8 do: [ :count | | palette types |
			types := self typeNamesOfCount: count.
			palette := self newPaletteForTypes: types theme: theme.
			0 to: 3 do: [ :depth |
				1 to: count do: [ :i |
					i + 1 to: count do: [ :j |
						self
							assert: (self distanceBetween: (palette colorForType: (types at: i) depth: depth) and: (palette colorForType: (types at: j) depth: depth)) >= 0.08
							description: theme , ' ' , count printString , ' types, depth ' , depth printString , ', ' , i printString , ' vs ' , j printString ] ] ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testDuplicatedTypeNamesDoNotChangeTheColors [
	| types duplicated |
	types := self typeNamesOfCount: 4.
	duplicated := types , types reversed , types.
	self themes do: [ :theme |
		self
			assert: (self colorsOf: (self newPaletteForTypes: duplicated theme: theme) types: types)
			equals: (self colorsOf: (self newPaletteForTypes: types theme: theme) types: types) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testGreyOfUnknownTypeIsReadableWithTheTextColor [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' ) theme: theme.
		self assert: (self contrastRatioBetween: (palette colorForType: 'Unknown' depth: 0) and: palette textColor) >= 4.5 ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testInvalidThemeSymbolRaisesErrorMentioningTheme [
	| message |
	message := self errorMessageOfPaletteWithTheme: #sepia.
	self assert: message notNil.
	self assert: (message includesSubstring: 'theme')
]

{ #category : 'tests' }
MMCColorPaletteTest >> testLightAndDarkThemesGiveDifferentTypeColors [
	| light dark |
	light := self newPaletteForTypes: #( 'Class' ) theme: #light.
	dark := self newPaletteForTypes: #( 'Class' ) theme: #dark.
	self deny: (light colorForType: 'Class' depth: 0) equals: (dark colorForType: 'Class' depth: 0)
]

{ #category : 'tests' }
MMCColorPaletteTest >> testNegativeDepthIsTreatedAsZero [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' 'Method' ) theme: theme.
		self assert: (palette colorForType: 'Method' depth: -1) equals: (palette colorForType: 'Method' depth: 0).
		self assert: (palette colorForType: 'Method' depth: -50) equals: (palette colorForType: 'Method' depth: 0) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testNilThemeRaisesErrorMentioningTheme [
	| message |
	message := self errorMessageOfPaletteWithTheme: nil.
	self assert: message notNil.
	self assert: (message includesSubstring: 'theme')
]

{ #category : 'tests' }
MMCColorPaletteTest >> testNilTypeAnswersTheSameGreyAsAnUnknownType [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' ) theme: theme.
		self assert: (palette colorForType: nil depth: 0) equals: (palette colorForType: 'Unknown' depth: 0) ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testNonSymbolThemeRaisesErrorMentioningTheme [
	| message |
	message := self errorMessageOfPaletteWithTheme: 42.
	self assert: message notNil.
	self assert: (message includesSubstring: 'theme')
]

{ #category : 'tests' }
MMCColorPaletteTest >> testPaletteKeepsItsTheme [
	self assert: (self newPaletteForTypes: #( 'Class' ) theme: #light) theme equals: #light.
	self assert: (self newPaletteForTypes: #( 'Class' ) theme: #dark) theme equals: #dark
]

{ #category : 'tests' }
MMCColorPaletteTest >> testPaletteWithoutTypeAnswersGreyForAnyType [
	"Greys have equal red, green and blue (tolerance 0.01), whatever the theme."
	self themes do: [ :theme | | color |
		color := (self newPaletteForTypes: #(  ) theme: theme) colorForType: 'Class' depth: 0.
		self assert: color notNil.
		self assert: (color red - color green) abs <= 0.01.
		self assert: (color green - color blue) abs <= 0.01 ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testPaletteWithoutTypeHasNoTypeName [
	self assert: (self newPaletteForTypes: #(  ) theme: #light) typeNames isEmpty
]

{ #category : 'tests' }
MMCColorPaletteTest >> testSegmentOfUnknownTypeGetsGrey [
	"Palette knows only Class; the segment is a Method: grey, same as colorForType:depth:."
	| palette color |
	palette := self newPaletteForTypes: #( 'Class' ) theme: #light.
	color := palette colorForSegment: (self newSegmentOfType: 'Method' depth: 1).
	self assert: color equals: (palette colorForType: 'Method' depth: 1).
	self assert: (color red - color blue) abs <= 0.01
]

{ #category : 'tests' }
MMCColorPaletteTest >> testSingleTypeHasHueForty [
	"One type: hue 40 (depth 0), tolerance 3 degrees for the RGB round trip."
	self themes do: [ :theme | | color |
		color := (self newPaletteForTypes: #( 'Class' ) theme: theme) colorForType: 'Class' depth: 0.
		self assert: (color hue - 40) abs <= 3 description: 'hue ' , color hue printString ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTextColorIsBlackInLightThemeAndWhiteInDarkTheme [
	self assert: (self newPaletteForTypes: #( 'Class' ) theme: #light) textColor equals: Color black.
	self assert: (self newPaletteForTypes: #( 'Class' ) theme: #dark) textColor equals: Color white
]

{ #category : 'tests' }
MMCColorPaletteTest >> testThreeTypesHaveHuesFortyOneHundredEightyAndThreeHundredTwenty [
	"n = 3: hue of index i is 40 + i * 280 / 2 for i = 0, 1, 2: 40, 180, 320."
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Attribute' 'Class' 'Method' ) theme: theme.
		#( 'Attribute' 'Class' 'Method' ) with: #( 40 180 320 ) do: [ :type :hue |
			self assert: ((palette colorForType: type depth: 0) hue - hue) abs <= 3 description: type , ' hue' ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTwelveTypesAreAllKnown [
	| palette |
	palette := self newPaletteForTypes: (self typeNamesOfCount: 12) theme: #dark.
	self assert: palette typeNames size equals: 12
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTypeColorsAreOpaque [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: (self typeNamesOfCount: 12) theme: theme.
		(self colorsOf: palette types: (self typeNamesOfCount: 12)) do: [ :each | self assert: each alpha equals: 1 ].
		self assert: palette uncoveredColor alpha equals: 1.
		self assert: (palette colorForType: 'Unknown' depth: 0) alpha equals: 1 ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTypeColorsAvoidRed [
	"With 12 types the hues span 40 to 320: never within 30 degrees of red (0 or 360)."
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: (self typeNamesOfCount: 12) theme: theme.
		(self typeNamesOfCount: 12) do: [ :type | | hue |
			hue := (palette colorForType: type depth: 0) hue.
			self assert: (hue between: 30 and: 330) description: type , ' hue ' , hue printString ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTypeColorsHaveContrastOfAtLeastFourPointFiveWithTheTextColor [
	"E1, WCAG ratio, up to 12 types, depths 0 to 3, both themes."
	self themes do: [ :theme |
		self typeCounts do: [ :count | | palette |
			palette := self newPaletteForTypes: (self typeNamesOfCount: count) theme: theme.
			(self colorsOf: palette types: (self typeNamesOfCount: count)) do: [ :each |
				self
					assert: (self contrastRatioBetween: each and: palette textColor) >= 4.5
					description: theme , ' ' , count printString , ' types: ' , each printString ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTypeNamesAreSortedWithoutDuplicates [
	"Method, Class, Method, Attribute give Attribute, Class, Method."
	| palette |
	palette := self newPaletteForTypes: #( 'Method' 'Class' 'Method' 'Attribute' ) theme: #light.
	self assert: palette typeNames asArray equals: #( 'Attribute' 'Class' 'Method' )
]

{ #category : 'tests' }
MMCColorPaletteTest >> testTypeNamesDoNotDependOnInputOrder [
	| first second |
	first := self newPaletteForTypes: #( 'Method' 'Class' 'Attribute' ) theme: #light.
	second := self newPaletteForTypes: #( 'Attribute' 'Method' 'Class' ) theme: #light.
	self assert: first typeNames asArray equals: second typeNames asArray
]

{ #category : 'tests' }
MMCColorPaletteTest >> testUncoveredColorHasContrastOfAtLeastFourPointFiveWithTheTextColor [
	"E4."
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' ) theme: theme.
		self assert: (self contrastRatioBetween: palette uncoveredColor and: palette textColor) >= 4.5 ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testUncoveredColorIsDistinctFromEveryTypeColor [
	"E4, distance >= 0.15 from all type colors (up to 12 types, depths 0 to 3), both themes."
	self themes do: [ :theme |
		self typeCounts do: [ :count | | palette |
			palette := self newPaletteForTypes: (self typeNamesOfCount: count) theme: theme.
			(self colorsOf: palette types: (self typeNamesOfCount: count)) do: [ :each |
				self
					assert: (self distanceBetween: palette uncoveredColor and: each) >= 0.15
					description: theme , ' ' , count printString , ' types: ' , each printString ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testUncoveredColorIsTheSameWhateverTheTypes [
	self themes do: [ :theme |
		self
			assert: (self newPaletteForTypes: #(  ) theme: theme) uncoveredColor
			equals: (self newPaletteForTypes: (self typeNamesOfCount: 12) theme: theme) uncoveredColor ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testUncoveredSegmentGetsTheUncoveredColor [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' 'Method' ) theme: theme.
		self assert: (palette colorForSegment: self newUncoveredSegment) equals: palette uncoveredColor ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testUnknownTypeAnswersGreyAtEveryDepth [
	self themes do: [ :theme | | palette |
		palette := self newPaletteForTypes: #( 'Class' 'Method' ) theme: theme.
		(-1 to: 5) do: [ :depth | | color |
			color := palette colorForType: 'Unknown' depth: depth.
			self assert: color notNil.
			self assert: (color red - color green) abs <= 0.01.
			self assert: (color green - color blue) abs <= 0.01 ] ]
]

{ #category : 'tests' }
MMCColorPaletteTest >> testWhiteBackgroundGivesLightTheme [
	self assert: (self themeForBackground: Color white) equals: #light
]

{ #category : 'helpers' }
MMCColorPaletteTest >> themeForBackground: arg1 [

	^ MMCColorPalette themeForBackground: arg1
]

{ #category : 'helpers' }
MMCColorPaletteTest >> themes [
	^ #( #light #dark )
]

{ #category : 'helpers' }
MMCColorPaletteTest >> typeCounts [
	^ #( 1 2 3 5 8 12 )
]

{ #category : 'helpers' }
MMCColorPaletteTest >> typeNamesOfCount: anInteger [
	"Type01, Type02, ... already in alphabetical order."
	^ (1 to: anInteger) collect: [ :each | 'Type' , (each printPaddedWith: $0 to: 2) ]
]
