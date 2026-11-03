"
Checks that MMCColorPalette colors are visible against the widget backgrounds (dark and light themes) and that the existing text-contrast and distinctness requirements still hold on the same grid of type counts and depths.
"
Class {
	#name : 'MMCColorPaletteBackgroundTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertDepthDistancesInTheme: aTheme [

	self typeCounts do: [ :count |
			| names palette |
			names := self typeNamesOfCount: count.
			palette := self newPaletteForTypes: names theme: aTheme.
			names do: [ :name |
					self depths allButLast do: [ :depth |
							| distance |
							distance := self
								            distanceBetween:
								            (palette colorForType: name depth: depth)
								            and: (palette colorForType: name depth: depth + 1).
							self assert: distance >= 0.05 description: [
									aTheme , ' count ' , count printString , ' ' , name
									, ' depths ' , depth printString , '/'
									, (depth + 1) printString , ' distance '
									, (distance printShowingDecimalPlaces: 3) ] ] ] ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertEntries: entries haveContrastAtLeast: aThreshold against: aBackground [

	| violations lowest |
	violations := entries select: [ :entry |
		              (self
			               contrastRatioBetween: entry last
			               and: aBackground) < aThreshold ].
	lowest := entries inject: SmallInteger maxVal into: [ :min :entry |
		          min min:
			          (self contrastRatioBetween: entry last and: aBackground) ].
	self assert: violations isEmpty description: [
			'Background ' , aBackground asHexString , ', threshold '
			, aThreshold printString , ', lowest ratio '
			, (lowest printShowingDecimalPlaces: 3) , ', '
			, violations size printString , ' of ' , entries size printString
			, ' below. First: '
			, ((violations first: (3 min: violations size))
					 inject: ''
					 into: [ :text :entry |
							 text , entry first , ' color ' , entry last asHexString
							 , ' ratio '
							 , ((self contrastRatioBetween: entry last and: aBackground)
									  printShowingDecimalPlaces: 3) , '; ' ]) ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertOpaqueColorsInTheme: aTheme [

	| entries |
	entries := (self typeEntriesInTheme: aTheme)
	           , (self uncoveredEntriesInTheme: aTheme)
	           , (self unknownTypeEntriesInTheme: aTheme).
	entries do: [ :entry |
			self
				assert: entry last alpha = 1
				description: [ aTheme , ' ' , entry first , ' is not opaque' ] ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertTextContrastInTheme: aTheme [

	self typeCounts do: [ :count |
			| names palette |
			names := self typeNamesOfCount: count.
			palette := self newPaletteForTypes: names theme: aTheme.
			names do: [ :name |
					self depths do: [ :depth |
							| ratio |
							ratio := self
								         contrastRatioBetween:
								         (palette colorForType: name depth: depth)
								         and: palette textColor.
							self assert: ratio >= 4.5 description: [
									aTheme , ' count ' , count printString , ' ' , name
									, ' depth ' , depth printString , ' text ratio '
									, (ratio printShowingDecimalPlaces: 3) ] ] ] ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertTheme: aTheme types: kind haveContrastAtLeast: aThreshold againstBackgroundHex: aHex [

	| entries |
	entries := kind == #types
		           ifTrue: [ self typeEntriesInTheme: aTheme ]
		           ifFalse: [
				           kind == #uncovered
					           ifTrue: [ self uncoveredEntriesInTheme: aTheme ]
					           ifFalse: [ self unknownTypeEntriesInTheme: aTheme ] ].
	self
		assertEntries: entries
		haveContrastAtLeast: aThreshold
		against: (Color fromHexString: aHex)
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertTypeDistancesInTheme: aTheme [

	(self typeCounts select: [ :count | count <= 8 ]) do: [ :count |
			| names palette |
			names := self typeNamesOfCount: count.
			palette := self newPaletteForTypes: names theme: aTheme.
			self depths do: [ :depth |
					names do: [ :first |
							names do: [ :second |
									first < second ifTrue: [
											| distance |
											distance := self
												            distanceBetween:
												            (palette colorForType: first depth: depth)
												            and:
												            (palette colorForType: second depth: depth).
											self assert: distance >= 0.08 description: [
													aTheme , ' count ' , count printString , ' depth '
													, depth printString , ' ' , first , ' vs ' , second
													, ' distance ' , (distance printShowingDecimalPlaces: 3) ] ] ] ] ] ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> assertUncoveredDistancesInTheme: aTheme [

	self typeCounts do: [ :count |
			| names palette |
			names := self typeNamesOfCount: count.
			palette := self newPaletteForTypes: names theme: aTheme.
			names do: [ :name |
					self depths do: [ :depth |
							| distance |
							distance := self
								            distanceBetween:
								            (palette colorForType: name depth: depth)
								            and: palette uncoveredColor.
							self assert: distance >= 0.15 description: [
									aTheme , ' count ' , count printString , ' ' , name
									, ' depth ' , depth printString , ' uncovered distance '
									, (distance printShowingDecimalPlaces: 3) ] ] ] ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> backgrounds [
	"All backgrounds, both themes."

	^ self darkBackgrounds , self lightBackgrounds
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> contrastRatioBetween: firstColor and: secondColor [
	"WCAG contrast ratio (L1 + 0.05) / (L2 + 0.05), L1 being the lighter."

	| first second |
	first := self relativeLuminanceOf: firstColor.
	second := self relativeLuminanceOf: secondColor.
	^ (first max: second) + 0.05 / ((first min: second) + 0.05)
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> darkBackgrounds [
	"Backgrounds the dark widget can sit on: image default theme, editor dark, black, grey."

	^ #( '1D2535' '1E1E1E' '000000' '2B2B2B' ) collect: [ :hex |
		  Color fromHexString: hex ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> depths [

	^ #( 0 1 2 3 )
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> distanceBetween: firstColor and: secondColor [
	"Euclidean RGB distance, components between 0 and 1."

	^ ((firstColor red - secondColor red) squared
	   + (firstColor green - secondColor green) squared
	   + (firstColor blue - secondColor blue) squared) sqrt
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> lightBackgrounds [

	^ #( 'FFFFFF' 'F5F5F5' 'FAFAFA' ) collect: [ :hex |
		  Color fromHexString: hex ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> linearized: aComponent [
	"WCAG linearization of an sRGB component between 0 and 1."

	^ aComponent <= 0.03928
		  ifTrue: [ aComponent / 12.92 ]
		  ifFalse: [ aComponent + 0.055 / 1.055 raisedTo: 2.4 ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> newPaletteForTypes: aCollection theme: aTheme [

	^ MMCColorPalette forTypeNames: aCollection theme: aTheme
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> relativeLuminanceOf: aColor [
	"WCAG relative luminance (Color>>luminance is not linearized: not used)."

	^ 0.2126 * (self linearized: aColor red)
	  + (0.7152 * (self linearized: aColor green))
	  + (0.0722 * (self linearized: aColor blue))
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkColorsAreOpaque [
	"Type, uncovered and unknown-type colors all have alpha 1."
	self assertOpaqueColorsInTheme: #dark
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkDepthDistanceAtLeast0Point05 [
	"RGB distance between consecutive depths of one type is at least 0.05."
	self assertDepthDistancesInTheme: #dark
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkFirstAndLastDepthDifferLocally [
	"B4: depth 0 and depth 3 of a type differ by at least 0.05 (already implied by the consecutive-depth distance check, kept as a direct visibility check)."
	| palette |
	palette := self newPaletteForTypes: (self typeNamesOfCount: 8) theme: #dark.
	(self typeNamesOfCount: 8) do: [ :name |
		self assert: (self distanceBetween: (palette colorForType: name depth: 0) and: (palette colorForType: name depth: 3)) >= 0.05 description: [ name , ' depth 0 and 3 too close' ] ]
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkTextContrastAtLeast4Point5 [
	"Contrast with the palette text color is at least 4.5 (WCAG AA), for every type, count and depth."
	self assertTextContrastInTheme: #dark
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkTypeColorsContrastAtLeast1Point5WithBackground000000 [
	"Dark theme against background 000000 (L = 0 so a ratio >= 1.5 needs L >= 1.5 * 0.05 - 0.05 = 0.025). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #types haveContrastAtLeast: 1.5 againstBackgroundHex: '000000'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkTypeColorsContrastAtLeast1Point5WithBackground1D2535 [
	"Dark theme against background 1D2535 (L = 0.0183 so a ratio >= 1.5 needs L >= 1.5 * (0.0183 + 0.05) - 0.05 = 0.0525). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #types haveContrastAtLeast: 1.5 againstBackgroundHex: '1D2535'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkTypeColorsContrastAtLeast1Point5WithBackground1E1E1E [
	"Dark theme against background 1E1E1E (L = 0.0129 so a ratio >= 1.5 needs L >= 0.0444). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #types haveContrastAtLeast: 1.5 againstBackgroundHex: '1E1E1E'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkTypeColorsContrastAtLeast1Point5WithBackground2B2B2B [
	"Dark theme against background 2B2B2B (L = 0.0243 so a ratio >= 1.5 needs L >= 0.0614). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #types haveContrastAtLeast: 1.5 againstBackgroundHex: '2B2B2B'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkTypeDistanceAtLeast0Point08 [
	"RGB distance between two types at the same depth is at least 0.08 for up to 8 types."
	self assertTypeDistancesInTheme: #dark
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUncoveredColorContrastAtLeast1Point5WithBackground000000 [
	"Dark theme against background 000000 (L = 0 so a ratio >= 1.5 needs L >= 1.5 * 0.05 - 0.05 = 0.025). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #uncovered haveContrastAtLeast: 1.5 againstBackgroundHex: '000000'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUncoveredColorContrastAtLeast1Point5WithBackground1D2535 [
	"Dark theme against background 1D2535 (L = 0.0183 so a ratio >= 1.5 needs L >= 1.5 * (0.0183 + 0.05) - 0.05 = 0.0525). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #uncovered haveContrastAtLeast: 1.5 againstBackgroundHex: '1D2535'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUncoveredColorContrastAtLeast1Point5WithBackground1E1E1E [
	"Dark theme against background 1E1E1E (L = 0.0129 so a ratio >= 1.5 needs L >= 0.0444). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #uncovered haveContrastAtLeast: 1.5 againstBackgroundHex: '1E1E1E'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUncoveredColorContrastAtLeast1Point5WithBackground2B2B2B [
	"Dark theme against background 2B2B2B (L = 0.0243 so a ratio >= 1.5 needs L >= 0.0614). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #uncovered haveContrastAtLeast: 1.5 againstBackgroundHex: '2B2B2B'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUncoveredDistanceAtLeast0Point15 [
	"RGB distance between uncoveredColor and every type color is at least 0.15."
	self assertUncoveredDistancesInTheme: #dark
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUnknownTypeGreyContrastAtLeast1Point5WithBackground000000 [
	"Dark theme against background 000000 (L = 0 so a ratio >= 1.5 needs L >= 1.5 * 0.05 - 0.05 = 0.025). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #unknown haveContrastAtLeast: 1.5 againstBackgroundHex: '000000'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUnknownTypeGreyContrastAtLeast1Point5WithBackground1D2535 [
	"Dark theme against background 1D2535 (L = 0.0183 so a ratio >= 1.5 needs L >= 1.5 * (0.0183 + 0.05) - 0.05 = 0.0525). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #unknown haveContrastAtLeast: 1.5 againstBackgroundHex: '1D2535'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUnknownTypeGreyContrastAtLeast1Point5WithBackground1E1E1E [
	"Dark theme against background 1E1E1E (L = 0.0129 so a ratio >= 1.5 needs L >= 0.0444). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #unknown haveContrastAtLeast: 1.5 againstBackgroundHex: '1E1E1E'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testDarkUnknownTypeGreyContrastAtLeast1Point5WithBackground2B2B2B [
	"Dark theme against background 2B2B2B (L = 0.0243 so a ratio >= 1.5 needs L >= 0.0614). With white text (ratio >= 4.5 needs L <= 0.183)."
	self assertTheme: #dark types: #unknown haveContrastAtLeast: 1.5 againstBackgroundHex: '2B2B2B'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightColorsAreOpaque [
	"Type, uncovered and unknown-type colors all have alpha 1."
	self assertOpaqueColorsInTheme: #light
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightDepthDistanceAtLeast0Point05 [
	"RGB distance between consecutive depths of one type is at least 0.05."
	self assertDepthDistancesInTheme: #light
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightTextContrastAtLeast4Point5 [
	"Contrast with the palette text color is at least 4.5 (WCAG AA), for every type, count and depth."
	self assertTextContrastInTheme: #light
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightTypeColorsContrastAtLeast1Point15WithBackgroundF5F5F5 [
	"Light theme against background F5F5F5 (L = 0.9133 so a ratio >= 1.15 needs L <= 0.7877)."
	self assertTheme: #light types: #types haveContrastAtLeast: 1.15 againstBackgroundHex: 'F5F5F5'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightTypeColorsContrastAtLeast1Point15WithBackgroundFAFAFA [
	"Light theme against background FAFAFA (L = 0.9561 so a ratio >= 1.15 needs L <= 0.8249)."
	self assertTheme: #light types: #types haveContrastAtLeast: 1.15 againstBackgroundHex: 'FAFAFA'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightTypeColorsContrastAtLeast1Point15WithBackgroundFFFFFF [
	"Light theme against background FFFFFF (L = 1 so a ratio >= 1.15 needs L <= 1.05 / 1.15 - 0.05 = 0.863)."
	self assertTheme: #light types: #types haveContrastAtLeast: 1.15 againstBackgroundHex: 'FFFFFF'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightTypeDistanceAtLeast0Point08 [
	"RGB distance between two types at the same depth is at least 0.08 for up to 8 types."
	self assertTypeDistancesInTheme: #light
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUncoveredColorContrastAtLeast1Point15WithBackgroundF5F5F5 [
	"Light theme against background F5F5F5 (L = 0.9133 so a ratio >= 1.15 needs L <= 0.7877)."
	self assertTheme: #light types: #uncovered haveContrastAtLeast: 1.15 againstBackgroundHex: 'F5F5F5'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUncoveredColorContrastAtLeast1Point15WithBackgroundFAFAFA [
	"Light theme against background FAFAFA (L = 0.9561 so a ratio >= 1.15 needs L <= 0.8249)."
	self assertTheme: #light types: #uncovered haveContrastAtLeast: 1.15 againstBackgroundHex: 'FAFAFA'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUncoveredColorContrastAtLeast1Point15WithBackgroundFFFFFF [
	"Light theme against background FFFFFF (L = 1 so a ratio >= 1.15 needs L <= 1.05 / 1.15 - 0.05 = 0.863)."
	self assertTheme: #light types: #uncovered haveContrastAtLeast: 1.15 againstBackgroundHex: 'FFFFFF'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUncoveredDistanceAtLeast0Point15 [
	"RGB distance between uncoveredColor and every type color is at least 0.15."
	self assertUncoveredDistancesInTheme: #light
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUnknownTypeGreyContrastAtLeast1Point15WithBackgroundF5F5F5 [
	"Light theme against background F5F5F5 (L = 0.9133 so a ratio >= 1.15 needs L <= 0.7877)."
	self assertTheme: #light types: #unknown haveContrastAtLeast: 1.15 againstBackgroundHex: 'F5F5F5'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUnknownTypeGreyContrastAtLeast1Point15WithBackgroundFAFAFA [
	"Light theme against background FAFAFA (L = 0.9561 so a ratio >= 1.15 needs L <= 0.8249)."
	self assertTheme: #light types: #unknown haveContrastAtLeast: 1.15 againstBackgroundHex: 'FAFAFA'
]

{ #category : 'tests' }
MMCColorPaletteBackgroundTest >> testLightUnknownTypeGreyContrastAtLeast1Point15WithBackgroundFFFFFF [
	"Light theme against background FFFFFF (L = 1 so a ratio >= 1.15 needs L <= 1.05 / 1.15 - 0.05 = 0.863)."
	self assertTheme: #light types: #unknown haveContrastAtLeast: 1.15 againstBackgroundHex: 'FFFFFF'
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> typeCounts [
	"Sizes of type sets exercised (1 to 12 types supported)."

	^ #( 1 2 3 5 8 12 )
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> typeEntriesInTheme: aTheme [
	"Answer {label. color} for every type of every set of typeCounts at every depth."

	| entries |
	entries := OrderedCollection new.
	self typeCounts do: [ :count |
			| names palette |
			names := self typeNamesOfCount: count.
			palette := self newPaletteForTypes: names theme: aTheme.
			names do: [ :name |
					self depths do: [ :depth |
							entries add: {
									('count ' , count printString , ' type ' , name , ' depth '
									 , depth printString).
									(palette colorForType: name depth: depth) } ] ] ].
	^ entries
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> typeNamesOfCount: anInteger [

	^ (1 to: anInteger) collect: [ :each |
		  'Type' , (each printPaddedWith: $0 to: 2) ]
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> uncoveredEntriesInTheme: aTheme [

	| palette |
	palette := self
		           newPaletteForTypes: (self typeNamesOfCount: 3)
		           theme: aTheme.
	^ { {
		  'uncoveredColor'.
		  palette uncoveredColor } }
]

{ #category : 'helpers' }
MMCColorPaletteBackgroundTest >> unknownTypeEntriesInTheme: aTheme [
	"Grey used for unknown types, depths 0 to 3."

	| palette |
	palette := self
		           newPaletteForTypes: (self typeNamesOfCount: 3)
		           theme: aTheme.
	^ self depths collect: [ :depth |
			  {
				  ('type Inconnu depth ' , depth printString).
				  (palette colorForType: 'Inconnu' depth: depth) } ]
]
