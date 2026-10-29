"
Tests of MMCCoveragePresenter (Spec2 presenter showing an MMCFileCoverage: highlighted text, summary, uncovered zones list, details under the cursor). Unit tests never open a window (no Spec adapter is built before open: decorations are held by the presenter and deferred); only testSmokeOpenWithRealWindowDecoratesTheText opens a real Morphic window.
"
Class {
	#name : 'MMCCoveragePresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterTest >> assertDecoratorsMatchPlanOf: aPresenter [
	"Every decorator has the interval of its segment and the opaque color of the palette for it."

	| decorators segments |
	decorators := aPresenter decorators.
	segments := aPresenter plan segments.
	self assert: decorators size equals: segments size.
	segments withIndexDo: [ :segment :i |
			| decorator |
			decorator := decorators at: i.
			self
				assert: decorator interval asArray
				equals: segment interval asArray.
			self
				assert: decorator highlightColor
				equals: (aPresenter palette colorForSegment: segment).
			self assert: decorator highlightColor alpha equals: 1.0 ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> attributeNamed: aName on: aFileName from: start to: end [

	^ self
		  newEntity: (FamixJavaAttribute new
				   name: aName;
				   yourself)
		  on: aFileName
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> attributeRegionNamed: aName from: start to: end [

	^ self
		  newRegionOf: (FamixJavaAttribute new
				   name: aName;
				   yourself)
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> classNamed: aName on: aFileName from: start to: end [

	^ self
		  newEntity: (FamixJavaClass new
				   name: aName;
				   yourself)
		  on: aFileName
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> classRegionNamed: aName from: start to: end [

	^ self
		  newRegionOf: (FamixJavaClass new
				   name: aName;
				   yourself)
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> detailsLinesAt: aPosition of: aPresenter [

	^ (aPresenter detailsTextAt: aPosition) lines asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> largeCoverageFilledWith: aCharacter [
	"7 000 regions on 500 000 characters (no file): 1000 classes of 500 characters, each with a class region (base+1 to base+450), 3 methods (base+11+100m, 60 characters) and one attribute (16 characters) in each method. The last 50 characters of each block stay uncovered: 1000 uncovered zones."

	| regions |
	regions := OrderedCollection new.
	0 to: 999 do: [ :c |
			| base |
			base := c * 500.
			regions add: (self
					 classRegionNamed: 'C' , c printString
					 from: base + 1
					 to: base + 450).
			0 to: 2 do: [ :m |
					| start |
					start := base + 11 + (m * 100).
					regions add: (self
							 methodRegionNamed: 'm' , m printString
							 from: start
							 to: start + 59).
					regions add: (self
							 attributeRegionNamed: 'a' , m printString
							 from: start + 5
							 to: start + 20) ] ].
	^ self
		  newCoverageFor: (String new: 500000 withAll: aCharacter)
		  regions: regions
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> lastLinesUncoveredCoverage [
	"14 lines 'ab' LF (42 characters, line n = 3n-2 to 3n); class 1-33 covers lines 1-11. The uncovered run 34-42 is trimmed to 34-41 (lines 12 to 14, 8 characters)."

	| text |
	text := String streamContents: [ :s |
			        14 timesRepeat: [
					        s
						        nextPutAll: 'ab';
						        nextPut: Character lf ] ].
	^ self
		  newCoverageFor: text
		  regions: { (self classRegionNamed: 'K' from: 1 to: 33) }
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> methodNamed: aName on: aFileName from: start to: end [

	^ self
		  newEntity: (FamixJavaMethod new
				   name: aName;
				   yourself)
		  on: aFileName
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> methodRegionNamed: aName from: start to: end [

	^ self
		  newRegionOf: (FamixJavaMethod new
				   name: aName;
				   yourself)
		  from: start
		  to: end
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> mockApplication [
	"Answer an application with the Mock backend: no Morphic adapter, no window."

	^ SpApplication new
		  useBackend: #Mock;
		  yourself
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> multiLineText [
	"'aaa' LF 'bbb' LF 'ccc' (11 characters): aaa 1-3, LF 4, bbb 5-7, LF 8, ccc 9-11. Lines: 1 = 1-4, 2 = 5-8, 3 = 9-11."

	^ 'aaa' , String lf , 'bbb' , String lf , 'ccc'
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> nestedCoverage [
	"Text 'aaaa bbbb cccc dddd eeee' (24 characters), class Foo 1-24 containing method bar 6-19.
	Segments: Class 1-5 (depth 0), Method 6-19 (depth 1), Class 20-24 (depth 0). No uncovered zone."

	^ self newCoverageFor: 'aaaa bbbb cccc dddd eeee' regions: {
			  (self classRegionNamed: 'Foo' from: 1 to: 24).
			  (self methodRegionNamed: 'bar' from: 6 to: 19) }
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newCoverageFor: aText regions: aCollection [
	"Answer a readable coverage of aText with the given regions (no ignored, no other file anchor)."

	^ self
		  newCoverageFor: aText
		  regions: aCollection
		  ignored: #(  )
		  otherFileAnchors: 0
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newCoverageFor: aText regions: aCollection ignored: ignoredCollection otherFileAnchors: anInteger [

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: aText
			   regions: aCollection
			   ignoredAnchors: ignoredCollection
			   otherFileAnchorCount: anInteger)
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newEntity: anEntity on: aFileName from: start to: end [
	"Add anEntity and an indexed anchor on aFileName (start to: end) to the model."

	| anchor |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anEntity.
	model add: anchor.
	anEntity sourceAnchor: anchor.
	^ anEntity
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newPresenterOn: aCoverage [
	"Answer a not opened presenter on aCoverage (default theme)."

	^ self presenterClass on: aCoverage
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newPresenterOn: aCoverage theme: aSymbol [
	"Answer a not opened presenter on aCoverage with the forced theme aSymbol."

	^ self presenterClass on: aCoverage theme: aSymbol
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newRegionOf: anEntity from: start to: end [
	"Answer a region of anEntity on start to: end (placeholder text)."

	^ MMCEntityRegion
		  entity: anEntity
		  anchor: nil
		  interval: (start to: end)
		  text: (String new: (end - start + 1 max: 0) withAll: $x)
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> newUnreadableCoverage [
	"No file reference, no text."

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: nil
			   text: ''
			   regions: #(  )
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> presenterClass [
	"The only place of the tests referencing the production class."

	^ MMCCoveragePresenter
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-v2-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> sixZonesCoverage [
	"twelveWordsText with a Class region on each odd word (1, 3, ... 11): 6 covered words, 6 uncovered zones (the even words, k = 2j: 10j-4 to 10j-1: 6-9, 16-19, 26-29, 36-39, 46-49, 56-59).
	Covered 24 of 59 characters (40.7 percent), 24 of 48 significant (50.0 percent). Ignored anchors: 9, other file anchors: 31."

	| regions ignored |
	regions := (1 to: 11 by: 2) collect: [ :k |
			           self
				           classRegionNamed: 'C' , k printString
				           from: 5 * k - 4
				           to: 5 * k - 1 ].
	ignored := (1 to: 9) collect: [ :i |
		           MMCIgnoredAnchor anchor: nil reason: #test ].
	^ self
		  newCoverageFor: self twelveWordsText
		  regions: regions
		  ignored: ignored
		  otherFileAnchors: 31
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> sourceText [
	"Lines (LF terminated): 1 'class A {' (1-9, LF 10), 2 '  int x;' (11-18, LF 19), 3 '  void m() {}' (20-32, LF 33), 4 '}' (34, LF 35). 35 characters."

	^ 'class A {' , String lf , '  int x;' , String lf , '  void m() {}'
	  , String lf , '}' , String lf
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> summaryOf: aPresenter [
	"Answer what the summary widget shows (label or text)."

	| widget |
	widget := aPresenter summaryPresenter.
	^ (widget isKindOf: SpLabelPresenter)
		  ifTrue: [ widget label ]
		  ifFalse: [ widget text ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> tearDown [

	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testApplyInvalidThemeRaisesAndKeepsState [

	| presenter message |
	presenter := self newPresenterOn: self nestedCoverage theme: #dark.
	message := nil.
	[ presenter applyTheme: #sepia ]
		on: Error
		do: [ :e | message := e messageText ].
	self assert: message notNil.
	self assert: (message asLowercase includesSubstring: 'theme').
	self assert: presenter theme equals: #dark.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testApplyThemeDarkAfterLightComesBack [

	| presenter darkColors |
	presenter := self newPresenterOn: self nestedCoverage theme: #dark.
	darkColors := presenter decorators collect: [ :each |
		              each highlightColor ].
	presenter applyTheme: #light.
	presenter applyTheme: #dark.
	self assert: presenter theme equals: #dark.
	self assert: presenter decorators size equals: 3.
	self
		assert:
			(presenter decorators collect: [ :each | each highlightColor ])
				asArray
		equals: darkColors asArray
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testApplyThemeLightRebuildsPaletteAndDecorators [

	| presenter oldColors newColors |
	presenter := self newPresenterOn: self nestedCoverage theme: #dark.
	oldColors := presenter decorators collect: [ :each |
		             each highlightColor ].
	presenter applyTheme: #light.
	self assert: presenter theme equals: #light.
	self assert: presenter palette theme equals: #light.
	self assert: presenter decorators size equals: 3.
	self assertDecoratorsMatchPlanOf: presenter.
	newColors := presenter decorators collect: [ :each |
		             each highlightColor ].
	"The dark and light palettes differ (at least on the Class colour): the decorations follow the new theme."
	self deny: newColors asArray = oldColors asArray
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testBuildingSeveralPresentersOnTheSameCoverageDoesNotAccumulateDecorators [

	| coverage first second |
	coverage := self nestedCoverage.
	first := self newPresenterOn: coverage.
	second := self newPresenterOn: coverage.
	self assert: first decorators size equals: 3.
	self assert: second decorators size equals: 3.
	self assert: first plan size equals: second plan size
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDecoratorColorsAreTheOpaquePaletteColors [
	"Covered segments use palette colorForSegment:, uncovered ones use uncoveredColor; all alpha = 1."

	| presenter uncoveredDecorators |
	presenter := self newPresenterOn: self zonesCoverage.
	self assertDecoratorsMatchPlanOf: presenter.
	uncoveredDecorators := presenter decorators select: [ :each |
		                       each highlightColor
		                       = presenter palette uncoveredColor ].
	"zonesCoverage: segments Class 1-4, blank 5 (uncovered segment with the blank), uncovered 6-9, Class 11-14: the uncovered segments are the ones flagged by the plan."
	self
		assert: uncoveredDecorators size
		equals:
		(presenter plan segments count: [ :each | each isUncovered ])
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDecoratorsAreACopy [
	"Changing the collection answered by decorators does not change the presenter."

	| presenter first second |
	presenter := self newPresenterOn: self nestedCoverage.
	first := presenter decorators.
	second := presenter decorators.
	self deny: first == second.
	[ first removeAll ]
		on: Error
		do: [ :e | e return ].
	self assert: presenter decorators size equals: 3
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDefaultThemeIsDarkBeforeOpening [

	| presenter |
	presenter := self newPresenterOn: self zonesCoverage.
	self assert: presenter theme equals: #dark.
	self assert: presenter palette theme equals: #dark
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsAtFirstAndLastCharacter [

	| presenter |
	presenter := self newPresenterOn: self zonesCoverage.
	self
		assert: (self detailsLinesAt: 1 of: presenter)
		equals: #( 'Position 1 (line 1)' 'Class A' ).
	self
		assert: (self detailsLinesAt: 14 of: presenter)
		equals: #( 'Position 14 (line 1)' 'Class B' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsDoesNotRaiseWhenTheEntityHasNoMooseName [
	"An entity that does not understand mooseName at all (an Object): no error, '<unnamed>' as the name."

	| coverage presenter text |
	coverage := self
		            newCoverageFor: 'aaaa bbbb'
		            regions:
		            { (self newRegionOf: Object new from: 1 to: 4) }.
	presenter := self newPresenterOn: coverage.
	text := presenter detailsTextAt: 2.
	self assert: text lines size equals: 2.
	self assert: (text lines second endsWith: '<unnamed>')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsInClassOutsideTheMethodHasOnlyTheClass [
	"Position 2 is in class Foo only."

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	self
		assert: (self detailsLinesAt: 2 of: presenter)
		equals: #( 'Position 2 (line 1)' 'Class Foo' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsOfBlankBetweenCoveredRegionsSaysNotCovered [
	"Chosen wording: a blank outside any region and outside any uncovered zone is reported with 'not covered' (and never with 'uncovered'). Position 5 of zonesCoverage is the blank between A (1-4) and the zone 6-9."

	| presenter text |
	presenter := self newPresenterOn: self zonesCoverage.
	text := presenter detailsTextAt: 5.
	self assert: text lines first equals: 'Position 5 (line 1)'.
	self assert: (text asLowercase includesSubstring: 'not covered').
	self deny: (text asLowercase includesSubstring: 'uncovered')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsOfBlankBetweenTwoMethodsSaysNotCovered [
	"'aaaa bbbb': method m1 1-4 and method m2 6-9; position 5 is a blank between them (no uncovered zone at all)."

	| coverage presenter |
	coverage := self newCoverageFor: 'aaaa bbbb' regions: {
			            (self methodRegionNamed: 'm1' from: 1 to: 4).
			            (self methodRegionNamed: 'm2' from: 6 to: 9) }.
	self assert: coverage uncoveredRegions isEmpty.
	presenter := self newPresenterOn: coverage.
	self assert:
		((presenter detailsTextAt: 5) asLowercase includesSubstring:
			 'not covered').
	self
		assert: (self detailsLinesAt: 6 of: presenter)
		equals: #( 'Position 6 (line 1)' 'Method m2' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsOfClassContainingMethod [
	"nestedCoverage position 7 is in method bar (6-19) inside class Foo (1-24): Class line at depth 0, Method line indented by 2 spaces (depth 1). Unattached entities: mooseName is the simple name."

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	self
		assert: (self detailsLinesAt: 7 of: presenter)
		equals: #( 'Position 7 (line 1)' 'Class Foo' '  Method bar' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsOfEntitiesWithoutNameUsesUnnamedPlaceholder [
	"FamixJavaClass new / FamixJavaMethod new have an empty mooseName: '<unnamed>'."

	| coverage presenter |
	coverage := self newCoverageFor: 'aaaa bbbb' regions: {
			            (self newRegionOf: FamixJavaClass new from: 1 to: 9).
			            (self newRegionOf: FamixJavaMethod new from: 1 to: 4) }.
	presenter := self newPresenterOn: coverage.
	self
		assert: (self detailsLinesAt: 2 of: presenter)
		equals:
		#( 'Position 2 (line 1)' 'Class <unnamed>' '  Method <unnamed>' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsOfPositionInUncoveredZoneSaysUncovered [
	"zonesCoverage position 7 is in the uncovered zone xxxx (6-9)."

	| presenter text |
	presenter := self newPresenterOn: self zonesCoverage.
	text := presenter detailsTextAt: 7.
	self assert: text lines first equals: 'Position 7 (line 1)'.
	self assert: (text asLowercase includesSubstring: 'uncovered')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsOutsideTheTextIsEmpty [
	"zonesCoverage has 14 characters: 0, negative and 15 are outside."

	| presenter |
	presenter := self newPresenterOn: self zonesCoverage.
	self assert: (presenter detailsTextAt: 0) equals: ''.
	self assert: (presenter detailsTextAt: -3) equals: ''.
	self assert: (presenter detailsTextAt: 15) equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsReportsTheLineOfThePosition [
	"multiLineText: class Foo 1-11, method bar 9-11; position 10 is on line 3, position 4 (the first line feed) on line 1."

	| coverage presenter |
	coverage := self newCoverageFor: self multiLineText regions: {
			            (self classRegionNamed: 'Foo' from: 1 to: 11).
			            (self methodRegionNamed: 'bar' from: 9 to: 11) }.
	presenter := self newPresenterOn: coverage.
	self
		assert: (self detailsLinesAt: 10 of: presenter)
		equals: #( 'Position 10 (line 3)' 'Class Foo' '  Method bar' ).
	self
		assert: (self detailsLinesAt: 4 of: presenter)
		equals: #( 'Position 4 (line 1)' 'Class Foo' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testDetailsUsesQualifiedMooseNameOfAttachedEntities [
	"Method bar added to class Foo: its mooseName is 'Foo.bar'."

	| foo bar coverage presenter |
	foo := FamixJavaClass new
		       name: 'Foo';
		       yourself.
	bar := FamixJavaMethod new
		       name: 'bar';
		       yourself.
	foo addMethod: bar.
	coverage := self newCoverageFor: 'aaaa bbbb' regions: {
			            (self newRegionOf: foo from: 1 to: 9).
			            (self newRegionOf: bar from: 1 to: 4) }.
	presenter := self newPresenterOn: coverage.
	self
		assert: (self detailsLinesAt: 2 of: presenter)
		equals: #( 'Position 2 (line 1)' 'Class Foo' '  Method Foo.bar' )
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testForModelFileAcceptsAPathString [

	| presenter |
	self writeFlatFixture.
	presenter := self presenterClass
		             forModel: model
		             file: (folder / 'A.java') pathString.
	self assert: presenter fileCoverage size equals: 35.
	self assert: presenter fileCoverage regions size equals: 3.
	self assert: (presenter summaryText includesSubstring: '74.3 %')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testForModelFileDetailsOfTheMethod [
	"Position 25 is in method m (22-32); the model entities are attached to the model: mooseName is the simple name of the method here (no parent)."

	| presenter lines |
	self writeFlatFixture.
	presenter := self presenterClass
		             forModel: model
		             file: folder / 'A.java'.
	lines := self detailsLinesAt: 25 of: presenter.
	self assert: lines first equals: 'Position 25 (line 3)'.
	self assert: lines size equals: 2.
	self assert: (lines second beginsWith: 'Method ').
	self assert: (lines second endsWith: 'm')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testForModelFileFromFileReference [
	"A.java: class A 1-9, attribute x 13-18, method m 22-32 (see writeFlatFixture). Covered 26/35 = 74.3 %, significant 21/22 = 95.5 %, 1 uncovered zone ('}'), 2 ignored anchors, 6 anchors of other.java."

	| presenter |
	self writeFlatFixture.
	presenter := self presenterClass
		             forModel: model
		             file: folder / 'A.java'.
	self deny: presenter isDisplayed.
	self assert: presenter fileCoverage size equals: 35.
	self assert: presenter fileCoverage regions size equals: 3.
	self assert: presenter textPresenter text equals: self sourceText.
	self assert: presenter uncoveredListPresenter items size equals: 1.
	self
		assert: presenter uncoveredListPresenter items first interval
		equals: (34 to: 34).
	self assert: (presenter windowTitle includesSubstring: 'A.java').
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testForModelFileOfAFileWithoutAnchorIsUnreadable [
	"b.txt exists but only a.txt has an anchor: unreadable, no error."

	| presenter |
	self writeText: 'abcdef' to: 'a.txt'.
	self writeText: 'uvwxyz' to: 'b.txt'.
	self
		classNamed: 'A'
		on: 'a.txt'
		from: 1
		to: 3.
	presenter := self presenterClass
		             forModel: model
		             file: folder / 'b.txt'.
	self deny: presenter fileCoverage isReadable.
	self assert: presenter decorators isEmpty.
	self assert:
		(presenter summaryText asLowercase includesSubstring: 'unreadable')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testForModelFileSummaryHasTheHandComputedValues [

	| summary |
	self writeFlatFixture.
	summary := (self presenterClass
		            forModel: model
		            file: folder / 'A.java') summaryText.
	self assert: (summary includesSubstring: '74.3 %').
	self assert: (summary includesSubstring: '95.5 %').
	self assert: (summary includesSubstring: '1').
	self assert: (summary includesSubstring: '2').
	self assert: (summary includesSubstring: '6')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testInitialExtentIsAtLeast800By500 [

	| extent |
	extent := (self newPresenterOn: self nestedCoverage) initialExtent.
	self assert: extent isPoint.
	self assert: extent x >= 800.
	self assert: extent y >= 500
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testLabelOfMultiLineRegionHasBothLineNumbers [
	"lastLinesUncoveredCoverage: zone 34-41, lines 12 to 14, 8 characters, preview 'ab ab ab' (line feeds replaced by spaces)."

	| coverage presenter label |
	coverage := self lastLinesUncoveredCoverage.
	presenter := self newPresenterOn: coverage.
	label := presenter labelForUncoveredRegion:
		         coverage uncoveredRegions first.
	self assert: (label includesSubstring: '12').
	self assert: (label includesSubstring: '14').
	self assert: (label includesSubstring: '8').
	self assert: (label includesSubstring: 'ab ab ab')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testLabelOfSingleLineRegionHasOneLineNumberSizeAndPreview [
	"'aaa' LF 'bbbbbb' LF 'ccc': zone 5-10 'bbbbbb' on line 2, 6 characters."

	| coverage presenter label |
	coverage := self
		            newCoverageFor:
		            'aaa' , String lf , 'bbbbbb' , String lf , 'ccc'
		            regions: {
				            (self classRegionNamed: 'A' from: 1 to: 3).
				            (self classRegionNamed: 'B' from: 12 to: 14) }.
	presenter := self newPresenterOn: coverage.
	label := presenter labelForUncoveredRegion:
		         coverage uncoveredRegions first.
	self assert: coverage uncoveredRegions first startLine equals: 2.
	self assert: coverage uncoveredRegions first endLine equals: 2.
	self assert: (label includesSubstring: '2').
	self deny: (label includesSubstring: '2-2').
	self assert: (label includesSubstring: '6').
	self assert: (label includesSubstring: 'bbbbbb')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testLabelPreviewIsTruncatedAfterSixtyCharacters [
	"100 characters '0123456789' x 10: the preview keeps the first 60 characters and ends with the ellipsis; size 100."

	| text coverage presenter label |
	text := String streamContents: [ :s |
		        10 timesRepeat: [ s nextPutAll: '0123456789' ] ].
	coverage := self newCoverageFor: text regions: #(  ).
	presenter := self newPresenterOn: coverage.
	label := presenter labelForUncoveredRegion:
		         coverage uncoveredRegions first.
	self assert:
		(label includesSubstring: (text copyFrom: 1 to: 60) , '…').
	self deny: (label includesSubstring: (text copyFrom: 1 to: 61)).
	self assert: (label includesSubstring: '100')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testLabelPreviewOfExactlySixtyCharactersIsNotTruncated [

	| text coverage presenter label |
	text := String new: 60 withAll: $q.
	coverage := self newCoverageFor: text regions: #(  ).
	presenter := self newPresenterOn: coverage.
	label := presenter labelForUncoveredRegion:
		         coverage uncoveredRegions first.
	self assert: (label includesSubstring: text).
	self deny: (label includesSubstring: '…')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testLabelPreviewReplacesLineEndsWithSpaces [
	"'ab' CR LF 'cd' (5 characters, one zone 1-5, lines 1 to 2): the preview has no CR nor LF and keeps ab and cd separated by blank(s)."

	| coverage presenter label |
	coverage := self
		            newCoverageFor: 'ab' , String crlf , 'cd'
		            regions: #(  ).
	presenter := self newPresenterOn: coverage.
	label := presenter labelForUncoveredRegion:
		         coverage uncoveredRegions first.
	self deny: (label includes: Character cr).
	self deny: (label includes: Character lf).
	self assert: (label includesSubstring: 'ab ').
	self assert: (label includesSubstring: ' cd')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testNestedClassAndMethodGiveThreeDecorators [
	"Class 1-24 containing method 6-19: segments Class 1-5, Method 6-19, Class 20-24."

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	self assert: presenter plan size equals: 3.
	self assert: presenter decorators size equals: 3.
	self
		assert:
			(presenter decorators collect: [ :each | each interval asArray ])
				asArray
		equals: {
				(1 to: 5) asArray.
				(6 to: 19) asArray.
				(20 to: 24) asArray }.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testNewApplicationModelWithMockApplicationBuildsPresenter [
	"Standard Spec2 construction (application + model) with the Mock backend: no adapter, no window."

	| coverage presenter |
	coverage := self zonesCoverage.
	presenter := self presenterClass
		             newApplication: self mockApplication
		             model: coverage.
	self assert: presenter fileCoverage identicalTo: coverage.
	self assert: presenter textPresenter text equals: coverage text.
	self deny: presenter textPresenter hasAdapter.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testOnBuildsClosedPresenterOnTheCoverage [

	| coverage presenter |
	coverage := self zonesCoverage.
	presenter := self newPresenterOn: coverage.
	self assert: presenter fileCoverage identicalTo: coverage.
	self assert: presenter plan class equals: MMCHighlightPlan.
	self assert: presenter palette class equals: MMCColorPalette.
	self deny: presenter isDisplayed.
	self deny: presenter textPresenter hasAdapter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testOnThemeForcesDarkTheme [

	| presenter |
	presenter := self newPresenterOn: self zonesCoverage theme: #dark.
	self assert: presenter theme equals: #dark.
	self assert: presenter palette theme equals: #dark
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testOnThemeForcesLightTheme [

	| presenter |
	presenter := self newPresenterOn: self zonesCoverage theme: #light.
	self assert: presenter theme equals: #light.
	self assert: presenter palette theme equals: #light.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testPaletteTypeNamesAreTheTypeNamesOfTheCoverage [
	"Class and Method regions: the palette knows exactly #('Class' 'Method')."

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	self
		assert: presenter palette typeNames asArray
		equals: #( 'Class' 'Method' ).
	self
		assert: presenter palette typeNames asArray
		equals: presenter fileCoverage typeNames asArray
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testPlainTextWithoutRegionIsOneUncoveredZone [
	"'hello world' (11 characters), no region: one uncovered segment 1-11 painted with the uncovered color, one uncovered zone 1-11, 0 of 11 covered (0.0 percent), 0 of 10 significant (0.0 percent)."

	| coverage presenter |
	coverage := self newCoverageFor: 'hello world' regions: #(  ).
	presenter := self newPresenterOn: coverage.
	self assert: presenter plan size equals: 1.
	self assert: presenter decorators size equals: 1.
	self
		assert: presenter decorators first interval asArray
		equals: (1 to: 11) asArray.
	self
		assert: presenter decorators first highlightColor
		equals: presenter palette uncoveredColor.
	self
		assert: presenter uncoveredListPresenter items asArray
		equals: coverage uncoveredRegions asArray.
	self assert: presenter uncoveredListPresenter items size equals: 1.
	self assert: (presenter summaryText includesSubstring: '0.0 %')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testRefreshHighlightsIsIdempotent [
	"Two refreshes: still one decorator per segment (3), same colors."

	| presenter before |
	presenter := self newPresenterOn: self nestedCoverage.
	before := presenter decorators collect: [ :each |
		          each highlightColor ].
	presenter refreshHighlights.
	presenter refreshHighlights.
	self assert: presenter decorators size equals: presenter plan size.
	self assert: presenter decorators size equals: 3.
	self
		assert:
			(presenter decorators collect: [ :each | each highlightColor ])
				asArray
		equals: before asArray.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testRefreshHighlightsOnLargeCoverageIsFast [
	"Repeated refreshes on 7 000 regions do not accumulate nor slow down."

	| presenter milliseconds |
	presenter := self newPresenterOn: (self largeCoverageFilledWith: $a).
	milliseconds := [ 2 timesRepeat: [ presenter refreshHighlights ] ]
		                timeToRun asMilliSeconds.
	self
		assert: milliseconds < 5000
		description:
		'two refreshes took ' , milliseconds printString , ' ms'.
	self assert: presenter decorators size equals: presenter plan size
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSelectUncoveredRegionSelectsItsIntervalInTheText [
	"Third zone of sixZonesCoverage: 26-29."

	| presenter region |
	presenter := self newPresenterOn: self sixZonesCoverage.
	region := presenter fileCoverage uncoveredRegions third.
	presenter selectUncoveredRegion: region.
	self assert: region interval equals: (26 to: 29).
	self
		assert: presenter textPresenter selectionInterval
		equals: (26 to: 29)
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSelectUncoveredRegionWithoutRegionDoesNotRaise [

	| presenter |
	presenter := self newPresenterOn: self sixZonesCoverage.
	presenter selectUncoveredRegion: nil.
	presenter uncoveredListPresenter unselectAll.
	self assert: presenter decorators size equals: presenter plan size
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSelectingRowInTheTableSelectsTheRegionInTheText [
	"Programmatic selection of row 2 in the table (test adapter: no adapter at all, the selection model of the presenter is used) must select the second zone, 16-19, in the text. If this fails while testSelectUncoveredRegionSelectsItsIntervalInTheText passes, the presenter does not subscribe to the table selection."

	| presenter |
	presenter := self newPresenterOn: self sixZonesCoverage.
	presenter uncoveredListPresenter selectIndex: 2.
	self
		assert: presenter textPresenter selectionInterval
		equals: (16 to: 19)
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testShowDetailsAtPutsTheDetailsInTheDetailsPresenter [

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	presenter showDetailsAt: 7.
	self
		assert: presenter detailsPresenter text
		equals: (presenter detailsTextAt: 7).
	presenter showDetailsAt: 0.
	self assert: presenter detailsPresenter text equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSmokeOpenWithRealWindowDecoratesTheText [
	"Only test opening a real Morphic window. Skipped when there is no World. The presenter is built without theme: at opening the theme is detected from the background of the widget (themeForBackground:). The effective background of the text is the color of the scrolled text morph (textArea backgroundColor is Color transparent with the Morphic backend). The window is closed in ensure:."

	| presenter window semaphore timedOut openError textArea background expectedTheme |
	World ifNil: [ self skip: 'no world' ].
	presenter := self newPresenterOn: self nestedCoverage.
	semaphore := Semaphore new.
	openError := nil.
	[
		[
			[ window := presenter open ]
				on: Error
				do: [ :e | openError := e ] ] ensure: [ semaphore signal ] ] fork.
	[
		timedOut := semaphore waitTimeoutSeconds: 10.
		self
			deny: timedOut
			description: 'the window did not open within 10 seconds'.
		self
			assert: openError isNil
			description: 'open raised ' , openError printString.
		textArea := presenter textPresenter adapter widget textArea.
		self
			assert: textArea segments size
			equals: presenter decorators size.
		self assert: presenter decorators size equals: 3.
		self assert: (#( dark light ) includes: presenter theme).
		background := presenter textPresenter adapter widget color.
		self
			assert: background alpha > 0
			description: 'the background read on the widget is transparent'.
		expectedTheme := MMCColorPalette themeForBackground: background.
		self assert: presenter theme equals: expectedTheme.
		self assertDecoratorsMatchPlanOf: presenter.
		presenter showDetailsAt: 1.
		self
			assert: presenter detailsPresenter text
			equals: (presenter detailsTextAt: 1) ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ]
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSummaryOfSixZonesCoverageShowsAllCounts [
	"sixZonesCoverage: raw 24/59 = 40.7 %, significant 24/48 = 50.0 %, 6 uncovered zones, 9 ignored anchors, 31 other file anchors (digits chosen so that no number is a substring of another one)."

	| presenter summary |
	presenter := self newPresenterOn: self sixZonesCoverage.
	summary := presenter summaryText.
	self assert: (summary includesSubstring: '40.7 %').
	self assert: (summary includesSubstring: '50.0 %').
	self assert: (summary includesSubstring: '6').
	self assert: (summary includesSubstring: '9').
	self assert: (summary includesSubstring: '31')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSummaryOfUnreadableFileSaysUnreadable [

	| presenter |
	presenter := self newPresenterOn: self newUnreadableCoverage.
	self assert:
		(presenter summaryText asLowercase includesSubstring: 'unreadable')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSummaryWidgetShowsSummaryText [

	| presenter |
	presenter := self newPresenterOn: self sixZonesCoverage.
	self
		assert: (self summaryOf: presenter)
		equals: presenter summaryText
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testSummaryWithoutSignificantCharacterSaysNotApplicable [
	"'   ' (blanks only, readable): significantRatio is nil, raw ratio 0 of 3 = 0.0 %."

	| coverage presenter |
	coverage := self newCoverageFor: '   ' regions: #(  ).
	self assert: coverage significantRatio isNil.
	presenter := self newPresenterOn: coverage.
	self assert: (presenter summaryText includesSubstring: 'n/a').
	self assert: (presenter summaryText includesSubstring: '0.0 %')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testTextPresenterShowsTheFileText [

	| coverage presenter |
	coverage := self zonesCoverage.
	presenter := self newPresenterOn: coverage.
	self assert: presenter textPresenter text equals: 'aaaa xxxx bbbb'.
	self assert: presenter textPresenter text equals: coverage text
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUncoveredListItemsAreTheRegionsInOrder [

	| presenter |
	presenter := self newPresenterOn: self sixZonesCoverage.
	self assert: presenter uncoveredListPresenter items size equals: 6.
	self
		assert: presenter uncoveredListPresenter items asArray
		equals: presenter fileCoverage uncoveredRegions asArray.
	"Intervals 6-9, 16-19, 26-29, 36-39, 46-49, 56-59 (computed by hand: word 2j = 10j-4 to 10j-1)."
	self
		assert: (presenter uncoveredListPresenter items collect: [ :each |
				 each interval ]) asArray
		equals: {
				(6 to: 9).
				(16 to: 19).
				(26 to: 29).
				(36 to: 39).
				(46 to: 49).
				(56 to: 59) }
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUnreadableFileGivesAnEmptyPresenter [

	| presenter |
	presenter := self newPresenterOn: self newUnreadableCoverage.
	self assert: presenter textPresenter text equals: ''.
	self assert: presenter uncoveredListPresenter items isEmpty.
	self assert: presenter plan isEmpty.
	self assert: presenter decorators isEmpty.
	self assert: (presenter detailsTextAt: 1) equals: ''.
	presenter showDetailsAt: 1.
	self assert: presenter detailsPresenter text equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUnreadableFileWithAReferenceButNoTextIsAlsoEmpty [
	"a.txt as reference, text '': isReadable is false."

	| coverage presenter |
	coverage := self newCoverageFor: '' regions: #(  ).
	self deny: coverage isReadable.
	presenter := self newPresenterOn: coverage.
	self assert: presenter decorators isEmpty.
	self assert:
		(presenter summaryText asLowercase includesSubstring: 'unreadable')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUpdateFileCoverageBetweenLargeCoveragesIsFast [
	"7 000 regions (1000 classes, 3000 methods, 3000 attributes) on 500 000 characters: removeAllTextSegmentDecorations must be done before changing the text (quadratic otherwise); update well under 5 seconds with the test adapter."

	| first second presenter milliseconds |
	first := self largeCoverageFilledWith: $a.
	second := self largeCoverageFilledWith: $b.
	self assert: first regions size equals: 7000.
	self assert: first size equals: 500000.
	presenter := self newPresenterOn: first.
	self assert: presenter decorators size equals: presenter plan size.
	milliseconds := [ presenter updateFileCoverage: second ] timeToRun
		                asMilliSeconds.
	self
		assert: milliseconds < 5000
		description:
		'updateFileCoverage: took ' , milliseconds printString , ' ms'.
	self assert: presenter decorators size equals: presenter plan size.
	self assert: presenter textPresenter text first equals: $b
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUpdateFileCoverageClearsTheDetails [

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	presenter showDetailsAt: 7.
	presenter updateFileCoverage: self zonesCoverage.
	self assert: presenter detailsPresenter text equals: ''
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUpdateFileCoverageKeepsTheTheme [

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage theme: #light.
	presenter updateFileCoverage: self zonesCoverage.
	self assert: presenter theme equals: #light.
	self assert: presenter palette theme equals: #light.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUpdateFileCoverageOfAnUnreadableThenReadableFileDecoratesAgain [

	| presenter |
	presenter := self newPresenterOn: self newUnreadableCoverage.
	presenter updateFileCoverage: self nestedCoverage.
	self assert: presenter decorators size equals: 3.
	self assertDecoratorsMatchPlanOf: presenter
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUpdateFileCoverageReplacesEverything [
	"From nestedCoverage (3 segments, no uncovered zone) to sixZonesCoverage (6 uncovered zones): coverage, plan, palette, text, list, summary, details and decorations are those of the new coverage; no decorator of the old file stays."

	| presenter old new oldDecorators |
	old := self nestedCoverage.
	new := self sixZonesCoverage.
	presenter := self newPresenterOn: old.
	oldDecorators := presenter decorators.
	presenter updateFileCoverage: new.
	self assert: presenter fileCoverage identicalTo: new.
	self assert: presenter plan fileCoverage identicalTo: new.
	self
		assert: presenter palette typeNames asArray
		equals: new typeNames asArray.
	self assert: presenter textPresenter text equals: new text.
	self
		assert: presenter uncoveredListPresenter items asArray
		equals: new uncoveredRegions asArray.
	self assert: presenter uncoveredListPresenter items size equals: 6.
	self
		assert: presenter summaryText
		equals: (self newPresenterOn: new) summaryText.
	self
		assert: (self summaryOf: presenter)
		equals: presenter summaryText.
	self assertDecoratorsMatchPlanOf: presenter.
	self assert: (presenter decorators noneSatisfy: [ :each |
			 oldDecorators anySatisfy: [ :o | o == each ] ])
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testUpdateFileCoverageToUnreadableRemovesAllDecorators [

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	presenter updateFileCoverage: self newUnreadableCoverage.
	self assert: presenter decorators isEmpty.
	self assert: presenter textPresenter text equals: ''.
	self assert: presenter uncoveredListPresenter items isEmpty.
	self assert:
		(presenter summaryText asLowercase includesSubstring: 'unreadable')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testWidgetsTypesAndReadOnly [

	| presenter |
	presenter := self newPresenterOn: self zonesCoverage.
	self assert: (presenter textPresenter isKindOf: SpTextPresenter).
	self deny: presenter textPresenter isEditable.
	self assert: (presenter detailsPresenter isKindOf: SpTextPresenter).
	self deny: presenter detailsPresenter isEditable.
	self assert:
		((presenter uncoveredListPresenter isKindOf: SpTablePresenter) or: [
			 presenter uncoveredListPresenter isKindOf: SpListPresenter ]).
	self assert:
		((presenter summaryPresenter isKindOf: SpLabelPresenter) or: [
			 presenter summaryPresenter isKindOf: SpTextPresenter ])
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testWindowTitleContainsTheFileName [
	"The coverages of these tests are on a.txt."

	| presenter |
	presenter := self newPresenterOn: self nestedCoverage.
	self assert: (presenter windowTitle includesSubstring: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterTest >> testWindowTitleOfUnreadableFileIsAStringWithoutError [

	| presenter title |
	presenter := self newPresenterOn: self newUnreadableCoverage.
	title := presenter windowTitle.
	self assert: title isString.
	self assert: title isEmpty not
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> twelveWordsText [
	"Twelve words 'abcd' separated by one blank: 12 * 4 + 11 = 59 characters. Word k spans 5k-4 to 5k-1."

	^ String streamContents: [ :s |
		  (1 to: 12)
			  do: [ :i | s nextPutAll: 'abcd' ]
			  separatedBy: [ s space ] ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> writeFlatFixture [
	"A.java with class A 1-9, attribute x 13-18, method m 22-32 (26 of 35 characters covered, 21 of 22 significant), two ignored anchors (end beyond the text) and six anchors on other.java."

	self writeText: self sourceText to: 'A.java'.
	self writeText: 'other file content' to: 'other.java'.
	self
		classNamed: 'A'
		on: 'A.java'
		from: 1
		to: 9.
	self
		attributeNamed: 'x'
		on: 'A.java'
		from: 13
		to: 18.
	self
		methodNamed: 'm'
		on: 'A.java'
		from: 22
		to: 32.
	self
		classNamed: 'Bad1'
		on: 'A.java'
		from: 33
		to: 99.
	self
		classNamed: 'Bad2'
		on: 'A.java'
		from: 34
		to: 99.
	1 to: 6 do: [ :i |
			self
				classNamed: 'O' , i printString
				on: 'other.java'
				from: 1
				to: 5 ]
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> writeText: aString to: aFileName [
	"Write aString encoded in UTF-8 (no BOM) in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]

{ #category : 'helpers' }
MMCCoveragePresenterTest >> zonesCoverage [
	"'aaaa xxxx bbbb' (14 characters): class A 1-4 and class B 11-14; blanks at 5 and 10; one uncovered zone 'xxxx' (6-9)."

	^ self newCoverageFor: 'aaaa xxxx bbbb' regions: {
			  (self classRegionNamed: 'A' from: 1 to: 4).
			  (self classRegionNamed: 'B' from: 11 to: 14) }
]
