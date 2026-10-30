"
Tests of the memoization of MMCColorPalette colors: unchanged values (frozen references), speed of repeated calls, independence between palettes and out-of-range arguments.
Note on mutability: Color is mutable in Pharo, so a cache that shares instances is only safe because the callers in MooseModelCoverage-V2 never mutate the colors (the only sender of colorForSegment: is MMCCoveragePresenter>>buildDecorators, which only passes the color to highlightColor:; colorForType:depth: has no sender outside the palette).
"
Class {
	#name : 'MMCColorPaletteCacheTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> buildLargeEntities [
	"50 packages x 20 classes x 9 methods = 10 050 entities, in creation order (copy of MMCCoveragePresenterTreeTest)."

	| all |
	all := OrderedCollection new: 10100.
	1 to: 50 do: [ :p |
			| pkg |
			pkg := self named: FamixJavaPackage name: 'pkg' , p printString.
			all add: pkg.
			1 to: 20 do: [ :c |
					| cls |
					cls := self
						       named: FamixJavaClass
						       name: 'Cls' , p printString , '_' , c printString.
					pkg addType: cls.
					all add: cls.
					1 to: 9 do: [ :m |
							| method |
							method := self named: FamixJavaMethod name: 'm' , m printString.
							cls addMethod: method.
							all add: method ] ] ].
	^ all
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> buildLargeModelAndCoverages [
	"Answer { model. coverage A. coverage B } on 10 050 entities (700 covered classes each, 7 000 regions each). Heavy: only called by the performance tests, never in setUp."

	| entities aModel |
	entities := self buildLargeEntities.
	aModel := FamixJavaModel new.
	entities do: [ :each | aModel add: each ].
	^ {
		  aModel.
		  (self largeCoverageOf: entities coveredWhen: [ :c | c \\ 10 < 7 ]).
		  (self largeCoverageOf: entities coveredWhen: [ :c | c \\ 10 >= 3 ]) }
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> coverageOfSize: aSize regions: aCollection [
	"Coverage without file. Regions must be sorted by start, then by decreasing size."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: (String new: aSize withAll: $x)
			   regions: aCollection asOrderedCollection
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> durationOf: aBlock [
	"Milliseconds taken by aBlock."

	^ aBlock timeToRun asMilliSeconds
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> largeCoverageOf: entities coveredWhen: aBlock [
	"Coverage on 200 000 characters. Class number c (0-based, 1000 classes) owns the block c*200+1 to c*200+200; when aBlock answers true for c, its region is b+1 to b+190 (b = c*200) and its 9 methods get b+1+k*20 to b+1+k*20+14: 10 regions per covered class (copy of MMCCoveragePresenterTreeTest)."

	| regions classIndex |
	regions := OrderedCollection new: 7000.
	classIndex := 0.
	entities do: [ :each |
			(each isKindOf: FamixJavaClass) ifTrue: [
					| base |
					base := classIndex * 200.
					(aBlock value: classIndex) ifTrue: [
							regions add:
								(self regionFor: each from: base + 1 to: base + 190).
							(each methods asSortedCollection: [ :a :b | a name <= b name ])
								doWithIndex: [ :method :k |
										| start |
										start := base + 1 + (k - 1 * 20).
										regions add:
											(self regionFor: method from: start to: start + 14) ] ].
					classIndex := classIndex + 1 ] ].
	^ self coverageOfSize: 200000 regions: regions
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> named: aFamixClass name: aString [

	^ aFamixClass new
		  name: aString;
		  yourself
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> newSegmentOfType: aTypeName depth: anInteger [

	| entity |
	entity := aTypeName = 'Class'
		          ifTrue: [ FamixJavaClass new ]
		          ifFalse: [
				          aTypeName = 'Method'
					          ifTrue: [ FamixJavaMethod new ]
					          ifFalse: [ FamixJavaAttribute new ] ].
	^ MMCHighlightSegment
		  interval: (1 to: 3)
		  region: (MMCEntityRegion
				   entity: entity
				   anchor: nil
				   interval: (1 to: 3)
				   text: 'xxx')
		  depth: anInteger
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> referenceHexes [
	"Colors computed in the image BEFORE any optimization (palette of Attribute, Class, Method). Key: theme, type, depth."

	| pairs |
	pairs := #( 'dark Attribute 0' '5A4824' 'dark Attribute 1'
	            '69542A' 'dark Attribute 2' '786030' 'dark Attribute 3'
	            '886D36' 'dark Class 0' '215252' 'dark Class 1'
	            '265F5F' 'dark Class 2' '2B6D6D' 'dark Class 3'
	            '317C7C' 'dark Method 0' '793060' 'dark Method 1'
	            '8C3870' 'dark Method 2' '9F3F7F' 'dark Method 3'
	            'B54891' 'light Attribute 0' 'EEDEBE' 'light Attribute 1'
	            'DEC697' 'light Attribute 2' 'C9AC71' 'light Attribute 3'
	            'B4934F' 'light Class 0' 'BAE9E9' 'light Class 1'
	            '90D5D5' 'light Class 2' '6ABDBD' 'light Class 3'
	            '48A5A5' 'light Method 0' 'FFCCEE' 'light Method 1'
	            'FFAEE4' 'light Method 2' 'F88BD4' 'light Method 3'
	            'EB67BF' ).
	^ Dictionary newFromPairs: pairs
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> regionFor: anEntity from: aStart to: anEnd [

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (aStart to: anEnd)
		  text: (String new: anEnd - aStart + 1 withAll: $x)
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testBuildDecoratorsOnThirteenThousandSegmentsTakesLessThan150Milliseconds [
	"Measured before the optimization: about 689 ms for 13 301 segments (about 95 % in colorForSegment:). Threshold 150 ms."

	| data elapsed presenter |
	data := self buildLargeModelAndCoverages.
	presenter := MMCCoveragePresenter
		             on: (data at: 2)
		             model: (data at: 1).
	elapsed := self durationOf: [ presenter buildDecorators ].
	self
		assert: presenter decorators size
		equals: presenter plan segments size.
	self
		assert: elapsed < 150
		description: 'buildDecorators took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testColorIsEqualAtEveryCallForOneToTwelveTypes [
	"For 1, 3, 8 and 12 types, depths 0..3 and both themes: two successive calls answer equal colors."

	#( 1 3 8 12 ) do: [ :count |
			#( #light #dark ) do: [ :theme |
					| names palette |
					names := self typeNamesOfSize: count.
					palette := MMCColorPalette forTypeNames: names theme: theme.
					names do: [ :name |
							0 to: 3 do: [ :depth |
									| first |
									first := palette colorForType: name depth: depth.
									self
										assert: (palette colorForType: name depth: depth)
										equals: first.
									self
										assert: (palette colorForType: name depth: depth)
										equals: first ] ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testColorsAreOpaque [
	"All colors of the palette are opaque. Color is mutable in Pharo, but no sender in MooseModelCoverage-V2 mutates a color answered by the palette (buildDecorators only passes it to highlightColor:), so a cache may share instances."

	#( #light #dark ) do: [ :theme |
			| palette |
			palette := self threeTypePalette: theme.
			#( 'Attribute' 'Class' 'Method' 'Zzz' ) do: [ :type |
					0 to: 3 do: [ :depth |
							self
								assert: (palette colorForType: type depth: depth) alpha
								equals: 1.0 ] ].
			self assert: palette uncoveredColor alpha equals: 1.0.
			self assert: palette textColor alpha equals: 1.0 ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testColorsOfDistinctTypesAndDepthsAreDistinct [
	"The cache key must include type and depth: 3 types x 4 depths give 12 distinct colors per theme."

	#( #light #dark ) do: [ :theme |
			| palette colors |
			palette := self threeTypePalette: theme.
			colors := Set new.
			#( 'Attribute' 'Class' 'Method' ) do: [ :type |
					0 to: 3 do: [ :depth |
					colors add: (palette colorForType: type depth: depth) ] ].
			self assert: colors size equals: 12 ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testDarkThemeColorsMatchTheFrozenReferences [
	"Non-regression of the formula: 12 colors (3 types x 4 depths) in #dark."

	| palette references |
	palette := self threeTypePalette: #dark.
	references := self referenceHexes.
	#( 'Attribute' 'Class' 'Method' ) do: [ :type |
			0 to: 3 do: [ :depth |
					self
						assert: (palette colorForType: type depth: depth) asHexString
						equals:
						(references at: 'dark ' , type , ' ' , depth printString) ] ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testDepthAboveThreeIsCappedAtEveryCall [
	"Depth 7 and 99 behave as depth 3: dark Class 3 = 317C7C; unknown type light grey 3 = 808080."

	| dark light |
	dark := self threeTypePalette: #dark.
	light := self threeTypePalette: #light.
	3 timesRepeat: [
			self
				assert: (dark colorForType: 'Class' depth: 7) asHexString
				equals: '317C7C'.
			self
				assert: (dark colorForType: 'Class' depth: 99) asHexString
				equals: '317C7C'.
			self
				assert: (light colorForType: 'Zzz' depth: 7) asHexString
				equals: '808080' ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testFiftyThousandSegmentColorsTakeLessThan150Milliseconds [
	"Measured before the optimization: about 2700 ms (54 us per call, a 40-step bisection each). Threshold 150 ms."

	| palette segments elapsed |
	palette := self threeTypePalette: #dark.
	segments := {
		            (self newSegmentOfType: 'Class' depth: 0).
		            (self newSegmentOfType: 'Method' depth: 1).
		            (self newSegmentOfType: 'Attribute' depth: 2).
		            (self newSegmentOfType: 'Class' depth: 3) }.
	elapsed := self durationOf: [
			           1 to: 50000 do: [ :i |
			           palette colorForSegment: (segments at: i - 1 \\ 4 + 1) ] ].
	self
		assert: elapsed < 150
		description:
		'colorForSegment: x 50000 took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testFrozenReferencesAreStillRightOnTheSecondCall [
	"A cache must not alter the value returned by the second call."

	| palette references |
	palette := self threeTypePalette: #dark.
	references := self referenceHexes.
	2 timesRepeat: [
			#( 'Attribute' 'Class' 'Method' ) do: [ :type |
					0 to: 3 do: [ :depth |
							self
								assert: (palette colorForType: type depth: depth) asHexString
								equals:
								(references at: 'dark ' , type , ' ' , depth printString) ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testHundredThousandTextColorsTakeLessThan50Milliseconds [
	"Measured before: about 3 ms. Must stay fast."

	| palette elapsed |
	palette := self threeTypePalette: #light.
	elapsed := self durationOf: [
		           100000 timesRepeat: [ palette textColor ] ].
	self
		assert: elapsed < 50
		description:
		'textColor x 100000 took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testHundredThousandTypeColorsTakeLessThan100Milliseconds [
	"Measured before the optimization: about 5400 ms for 100000 calls. Threshold 100 ms."

	| palette elapsed |
	palette := self threeTypePalette: #light.
	elapsed := self durationOf: [
		           1 to: 100000 do: [ :i |
		           palette colorForType: 'Class' depth: i \\ 4 ] ].
	self
		assert: elapsed < 100
		description:
		'colorForType:depth: x 100000 took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testHundredThousandUncoveredColorsTakeLessThan50Milliseconds [
	"Measured before: about 13 ms. Must stay fast."

	| palette elapsed |
	palette := self threeTypePalette: #dark.
	elapsed := self durationOf: [
		           100000 timesRepeat: [ palette uncoveredColor ] ].
	self
		assert: elapsed < 50
		description:
		'uncoveredColor x 100000 took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testHundredThousandUnknownTypeGreysTakeLessThan50Milliseconds [
	"Measured before: about 21 ms. Must stay fast."

	| palette elapsed |
	palette := self threeTypePalette: #dark.
	elapsed := self durationOf: [
		           1 to: 100000 do: [ :i |
		           palette colorForType: 'Zzz' depth: i \\ 4 ] ].
	self
		assert: elapsed < 50
		description: 'grey x 100000 took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testLightThemeColorsMatchTheFrozenReferences [
	"Non-regression of the formula: 12 colors (3 types x 4 depths) in #light."

	| palette references |
	palette := self threeTypePalette: #light.
	references := self referenceHexes.
	#( 'Attribute' 'Class' 'Method' ) do: [ :type |
			0 to: 3 do: [ :depth |
					self
						assert: (palette colorForType: type depth: depth) asHexString
						equals:
						(references at: 'light ' , type , ' ' , depth printString) ] ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testNegativeAndNilDepthsAreTreatedAsZero [
	"Depth -1, -50 and nil behave as depth 0: dark Class 0 = 215252; dark unknown grey 0 = 4F4F4F."

	| palette |
	palette := self threeTypePalette: #dark.
	3 timesRepeat: [
			self
				assert: (palette colorForType: 'Class' depth: -1) asHexString
				equals: '215252'.
			self
				assert: (palette colorForType: 'Class' depth: -50) asHexString
				equals: '215252'.
			self
				assert: (palette colorForType: 'Class' depth: nil) asHexString
				equals: '215252'.
			self
				assert: (palette colorForType: 'Zzz' depth: -1) asHexString
				equals: '4F4F4F' ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testNilTypeGivesTheGreyOfTheLevelAtEveryCall [
	"nil type: grey. Dark level 1 = 595959."

	| palette |
	palette := self threeTypePalette: #dark.
	3 timesRepeat: [
			self
				assert: (palette colorForType: nil depth: 1) asHexString
				equals: '595959' ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testOutOfRangeCallsDoNotPoisonTheValidOnes [
	"Calling with invalid arguments first must not freeze a wrong value for the valid depths."

	| palette |
	palette := self threeTypePalette: #dark.
	palette colorForType: 'Class' depth: 99.
	palette colorForType: 'Class' depth: -3.
	palette colorForType: nil depth: 2.
	self
		assert: (palette colorForType: 'Class' depth: 3) asHexString
		equals: '317C7C'.
	self
		assert: (palette colorForType: 'Class' depth: 0) asHexString
		equals: '215252'.
	self
		assert: (palette colorForType: 'Class' depth: 2) asHexString
		equals: '2B6D6D'.
	self
		assert: (palette colorForType: nil depth: 2) asHexString
		equals: '636363'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testPalettesWithDifferentThemesDoNotShareTheirColors [
	"Same types, different themes: dark Class 2 = 2B6D6D, light Class 2 = 6ABDBD, in any order of calls."

	| dark light |
	dark := self threeTypePalette: #dark.
	light := self threeTypePalette: #light.
	self
		assert: (light colorForType: 'Class' depth: 2) asHexString
		equals: '6ABDBD'.
	self
		assert: (dark colorForType: 'Class' depth: 2) asHexString
		equals: '2B6D6D'.
	self
		assert: (light colorForType: 'Class' depth: 2) asHexString
		equals: '6ABDBD'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testPalettesWithDifferentTypesDoNotShareTheirColors [
	"Palette A has 3 types (Class is the 2nd: hue 180), palette B only Class (hue 40). Creating B must not change A, and vice versa."

	| a before b |
	a := self threeTypePalette: #dark.
	before := a colorForType: 'Class' depth: 1.
	self assert: before asHexString equals: '265F5F'.
	b := MMCColorPalette forTypeNames: #( 'Class' ) theme: #dark.
	self
		assert: (b colorForType: 'Class' depth: 1) asHexString
		equals: '69542A'.
	self assert: (a colorForType: 'Class' depth: 1) equals: before.
	self
		assert: (b colorForType: 'Class' depth: 1) asHexString
		equals: '69542A'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testPresenterConstructionOnTenThousandEntitiesTakesLessThan300Milliseconds [
	"Large fixture (10 050 entities, 13 301 segments). Measured before the optimization: about 786 ms. Threshold 300 ms."

	| data elapsed presenter |
	data := self buildLargeModelAndCoverages.
	elapsed := self durationOf: [
		           presenter := MMCCoveragePresenter
			                        on: (data at: 2)
			                        model: (data at: 1) ].
	self assert: presenter treePresenter roots size equals: 50.
	self
		assert: elapsed < 300
		description: 'on:model: took ' , elapsed printString , ' ms'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testRebuiltPaletteGivesEqualColorsForOneToTwelveTypes [
	"A new palette built with the same types answers the same colors as the first one."

	#( 1 3 8 12 ) do: [ :count |
			#( #light #dark ) do: [ :theme |
					| names first second |
					names := self typeNamesOfSize: count.
					first := MMCColorPalette forTypeNames: names theme: theme.
					names do: [ :name |
						0 to: 3 do: [ :depth | first colorForType: name depth: depth ] ].
					second := MMCColorPalette
						          forTypeNames: names reverse
						          theme: theme.
					names do: [ :name |
							0 to: 3 do: [ :depth |
									self
										assert: (second colorForType: name depth: depth)
										equals: (first colorForType: name depth: depth) ] ] ] ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testSegmentColorEqualsTheColorOfItsTypeAndDepth [
	"colorForSegment: of a covered segment is colorForType:depth:; of an uncovered one it is uncoveredColor."

	| palette |
	palette := self threeTypePalette: #dark.
	2 timesRepeat: [
			self
				assert:
					(palette colorForSegment:
						 (self newSegmentOfType: 'Method' depth: 2)) asHexString
				equals: '9F3F7F'.
			self
				assert: (palette colorForSegment:
						 (MMCHighlightSegment uncoveredInterval: (1 to: 2))) asHexString
				equals: 'E60000' ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testSingleTypePaletteMatchesTheFrozenReferences [
	"With one type the hue is 40: dark Only 0..3 = 5A4824 69542A 786030 886D36; light = EEDEBE DEC697 C9AC71 B4934F (same as Attribute, which is the first of three types so hue 40)."

	| dark light |
	dark := MMCColorPalette forTypeNames: #( 'Only' ) theme: #dark.
	light := MMCColorPalette forTypeNames: #( 'Only' ) theme: #light.
	self
		assert: ((0 to: 3) collect: [ :d |
				 (dark colorForType: 'Only' depth: d) asHexString ])
		equals: #( '5A4824' '69542A' '786030' '886D36' ).
	self
		assert: ((0 to: 3) collect: [ :d |
				 (light colorForType: 'Only' depth: d) asHexString ])
		equals: #( 'EEDEBE' 'DEC697' 'C9AC71' 'B4934F' )
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testTypeNamesAnswersACopy [
	"Mutating the answer of typeNames changes neither typeNames nor the colors."

	| palette names |
	palette := self threeTypePalette: #dark.
	names := palette typeNames.
	self assert: names equals: #( 'Attribute' 'Class' 'Method' ).
	names at: 1 put: 'Zorro'.
	self
		assert: palette typeNames
		equals: #( 'Attribute' 'Class' 'Method' ).
	self
		assert: (palette colorForType: 'Attribute' depth: 0) asHexString
		equals: '5A4824'.
	self
		assert: (palette colorForType: 'Zorro' depth: 0) asHexString
		equals: '4F4F4F'
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testUnknownTypeGreysMatchTheFrozenReferences [
	"Unknown type: grey per level. Dark 4F4F4F 595959 636363 6E6E6E; light D9D9D9 B8B8B8 999999 808080."

	| dark light |
	dark := self threeTypePalette: #dark.
	light := self threeTypePalette: #light.
	2 timesRepeat: [
			self
				assert: ((0 to: 3) collect: [ :d |
						 (dark colorForType: 'Zzz' depth: d) asHexString ])
				equals: #( '4F4F4F' '595959' '636363' '6E6E6E' ).
			self
				assert: ((0 to: 3) collect: [ :d |
						 (light colorForType: 'Zzz' depth: d) asHexString ])
				equals: #( 'D9D9D9' 'B8B8B8' '999999' '808080' ) ]
]

{ #category : 'tests' }
MMCColorPaletteCacheTest >> testUpdateFileCoverageOnTenThousandEntitiesTakesLessThan300Milliseconds [
	"Measured before the optimization: about 767 ms. Threshold 300 ms. The presenter is built outside the measure."

	| data elapsed presenter |
	data := self buildLargeModelAndCoverages.
	presenter := MMCCoveragePresenter
		             on: (data at: 2)
		             model: (data at: 1).
	elapsed := self durationOf: [
		           presenter updateFileCoverage: (data at: 3) ].
	self assert: presenter treePresenter roots size equals: 50.
	self
		assert: elapsed < 300
		description:
		'updateFileCoverage: took ' , elapsed printString , ' ms'
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> threeTypePalette: aTheme [

	^ MMCColorPalette
		  forTypeNames: #( 'Class' 'Method' 'Attribute' )
		  theme: aTheme
]

{ #category : 'helpers' }
MMCColorPaletteCacheTest >> typeNamesOfSize: anInteger [
	"Answer anInteger distinct type names."

	^ (1 to: anInteger) collect: [ :i | 'Type' , i printString , 'x' ]
]
