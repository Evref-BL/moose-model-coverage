"
Tests of the class-side multi-file example of MMCCoveragePresenter. Expected API: MMCCoveragePresenter class>>newMultiFileExample builds and answers, WITHOUT opening it, a presenter with the inventory of the files (modelFiles) on a FamixJavaModel whose rootFolder is a temporary folder created by the example (several sources, some in sub folders). The model has at least 4 files of the inventory, one referenced by an anchor but absent from the disk (unreadable), at least one fully covered file and one partially covered file, classes and methods with FamixJavaIndexedFileAnchor, a class without anchor (warning icon) and a package without anchor. MMCCoveragePresenter class>>multiFileExample (pragma <example>) opens it and answers the presenter, like #example. Each call builds an independent presenter. The temporary folders of the presenters created by the tests are deleted in tearDown (only when they are under the system temporary directory).
"
Class {
	#name : 'MMCCoveragePresenterMultiFileExampleTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterMultiFileExampleTest >> newExamplePresenter [
	"A new, not opened presenter of the example (sent by perform: the method is not there before the implementation). Registered for the cleanup of tearDown."

	^ presenters add:
		  (MMCCoveragePresenter perform: #newMultiFileExample)
]

{ #category : 'helpers' }
MMCCoveragePresenterMultiFileExampleTest >> readableCoveragesOf: aPresenter [
	"After computeAllFiles: the coverages of the readable files of the inventory."

	aPresenter computeAllFiles.
	^ (aPresenter modelFiles files select: [ :each |
		   aPresenter modelFiles isReadable: each ]) collect: [ :each |
		  aPresenter modelFiles coverageFor: each ]
]

{ #category : 'fixture' }
MMCCoveragePresenterMultiFileExampleTest >> setUp [

	super setUp.
	presenters := OrderedCollection new
]

{ #category : 'helpers' }
MMCCoveragePresenterMultiFileExampleTest >> systemWindowCount [

	^ World submorphs count: [ :each | each isSystemWindow ]
]

{ #category : 'fixture' }
MMCCoveragePresenterMultiFileExampleTest >> tearDown [
	"Close every window, then delete the root folder of the example presenters, only when it is under the system temporary directory."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ].
			[
				each model rootFolder ifNotNil: [ :root |
						| ref |
						ref := root asFileReference.
						(ref isDirectory and: [
							 ref pathString beginsWith:
								 FileLocator temp asFileReference pathString ]) ifTrue: [
							ref ensureDeleteAll ] ] ]
				on: Error
				do: [ :e | e return ] ].
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testAfterComputeAllThereIsAFullyCoveredFileAndAPartiallyCoveredFile [
	"Fully covered: no uncovered zone and a positive coverage. Partial: at least one uncovered zone and some covered text (a class whose methods are not all covered)."

	| presenter coverages |
	presenter := self newExamplePresenter.
	coverages := self readableCoveragesOf: presenter.
	self assert: coverages isNotEmpty.
	self
		assert: (coverages anySatisfy: [ :each |
				 each uncoveredRegions isEmpty and: [ each coveredPercentage > 0 ] ])
		description: 'no fully covered file'.
	self
		assert: (coverages anySatisfy: [ :each |
				 each uncoveredRegions isNotEmpty and: [
					 each coveredPercentage > 0 ] ])
		description: 'no partially covered file'.
	self assert: presenter modelFiles globalSummary fileCount >= 4
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testAtLeastOneFileIsUnreadableAndAtLeastThreeAreReadable [
	"A file referenced by an anchor but absent from the disk: unreadable (warning sign in the list label)."

	| presenter unreadable |
	presenter := self newExamplePresenter.
	unreadable := presenter modelFiles unreadableFiles.
	self assert: unreadable isNotEmpty.
	self assert: presenter modelFiles fileCount - unreadable size >= 3.
	self assert: ((presenter fileLabelFor: unreadable first) includes:
			 (Character value: 16r26A0))
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testCurrentFileIsTheFirstSortedFile [

	| presenter modelFiles |
	presenter := self newExamplePresenter.
	modelFiles := presenter modelFiles.
	self assert: presenter currentFile equals: modelFiles files first.
	self
		assert:
		(modelFiles relativeNameOf: presenter currentFile) asLowercase
		equals: ((modelFiles files collect: [ :each |
				  (modelFiles relativeNameOf: each) asLowercase ]) detectMin: [
				 :each | each ])
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testExampleHasAtLeastFourFilesInTheInventory [

	| presenter |
	presenter := self newExamplePresenter.
	self assert: presenter modelFiles fileCount >= 4.
	self
		assert: presenter modelFiles files size
		equals: presenter modelFiles fileCount
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testModelHasClassesAndMethodsWithIndexedFileAnchors [

	| presenter |
	presenter := self newExamplePresenter.
	self assert:
		((presenter model allWithType: FamixJavaClass) count: [ :each |
			 each sourceAnchor isKindOf: FamixJavaIndexedFileAnchor ]) >= 3.
	self assert:
		((presenter model allWithType: FamixJavaMethod) count: [ :each |
			 each sourceAnchor isKindOf: FamixJavaIndexedFileAnchor ]) >= 3
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testModelIsAFamixJavaModelWithAnExistingRootFolderAndSubFolders [
	"The rootFolder is a folder created by the example (its place is the choice of the implementation, documented in the example comment); at least one source of the inventory is in a sub folder of it (relative name with a /)."

	| presenter root |
	presenter := self newExamplePresenter.
	self assert: (presenter model isKindOf: FamixJavaModel).
	root := presenter model rootFolder.
	self assert: root isNotNil.
	self assert: root asFileReference isDirectory.
	self
		assert: (presenter modelFiles files anySatisfy: [ :each |
				 (presenter modelFiles relativeNameOf: each) includes: $/ ])
		description: 'no file in a sub folder'.
	self assert: ((presenter modelFiles files select: [ :each |
			  presenter modelFiles isReadable: each ]) allSatisfy: [ :each |
			 each isFile ])
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testMultiFileExampleCalledTwiceRaisesNoError [
	"Two successive real windows (skipped without World), each closed in ensure:."

	| windowsBefore |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := self systemWindowCount.
	2 timesRepeat: [
			| presenter |
			[
				presenter := MMCCoveragePresenter perform: #multiFileExample.
				presenters add: presenter.
				self assert: presenter window isOpen ] ensure: [
					presenter ifNotNil: [
							[ presenter window ifNotNil: [ :aWindow | aWindow close ] ]
								on: Error
								do: [ :e | e return ] ] ] ].
	self assert: self systemWindowCount equals: windowsBefore
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testMultiFileExampleIsAnnotatedWithTheExamplePragma [
	"Class side method multiFileExample carries <example> and is in the examples protocol."

	| method |
	method := MMCCoveragePresenter class
		          compiledMethodAt: #multiFileExample
		          ifAbsent: [ nil ].
	self
		assert: method isNotNil
		description: 'multiFileExample is missing'.
	self assert: (method hasPragmaNamed: #example).
	self assert: method protocolName equals: #examples
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testMultiFileExampleOpensARealWindowAndLeavesNoWindowAfterClose [
	"Smoke test with a real window (skipped without World): multiFileExample opens the presenter of newMultiFileExample and answers it; the window is closed in ensure: and the number of windows is the same as before."

	| presenter windowsBefore |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := self systemWindowCount.
	[
		presenter := MMCCoveragePresenter perform: #multiFileExample.
		presenters add: presenter.
		self assert: (presenter isKindOf: MMCCoveragePresenter).
		self assert: presenter window isOpen.
		self assert: presenter modelFiles fileCount >= 4.
		self assert: presenter treePresenter adapter isNotNil.
		self assert:
			presenter treePresenter adapter widget dataSource numberOfRows > 0 ]
		ensure: [
				presenter ifNotNil: [
						[ presenter window ifNotNil: [ :aWindow | aWindow close ] ]
							on: Error
							do: [ :e | e return ] ] ].
	self assert: self systemWindowCount equals: windowsBefore
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testNewMultiFileExampleAnswersAPresenterWithInventoryAndDoesNotOpenIt [

	| presenter windowsBefore |
	windowsBefore := World ifNotNil: [ self systemWindowCount ].
	presenter := self newExamplePresenter.
	self assert: (presenter isKindOf: MMCCoveragePresenter).
	self assert: presenter modelFiles isNotNil.
	self assert: presenter model isNotNil.
	self
		assert: presenter window isNil
		description: 'newMultiFileExample must not open the presenter'.
	World ifNotNil: [
		self assert: self systemWindowCount equals: windowsBefore ]
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testTwoCallsAnswerTwoIndependentPresenters [
	"No error at the second call; the presenters, models and inventories are distinct objects and a change in one (file, filter) does not reach the other. The root folders are distinct or the same folder is reused without error: both are accepted."

	| first second other |
	first := self newExamplePresenter.
	second := self newExamplePresenter.
	self deny: first == second.
	self deny: first modelFiles == second modelFiles.
	self deny: first model == second model.
	other := first modelFiles files last.
	first showFile: other.
	first treeFilter: #all.
	self assert: first currentFile equals: other.
	self assert: second currentFile equals: second modelFiles files first.
	self assert: second treeFilter equals: #covered.
	self
		assert: second modelFiles fileCount
		equals: first modelFiles fileCount
]

{ #category : 'tests' }
MMCCoveragePresenterMultiFileExampleTest >> testWholeModelShowsAnEntityWithoutAnchorAndTheModelHasAPackageWithoutAnchor [
	"A class without anchor (warning icon) visible in #all mode, and a parent package without anchor holding a class."

	| presenter visible |
	presenter := self newExamplePresenter.
	presenter treeFilter: #all.
	visible := presenter navigator visibleEntities.
	self
		assert: (visible anySatisfy: [ :each | each sourceAnchor isNil ])
		description: 'no visible entity without anchor'.
	self
		assert:
			((presenter model allWithType: FamixJavaClass) anySatisfy: [ :each |
					 each sourceAnchor isNil and: [
						 (presenter perform: #warningIconFor: with: each) isNotNil ] ])
		description: 'no class without anchor with a warning icon'.
	self
		assert:
			((presenter model allWithType: FamixJavaClass) anySatisfy: [ :each |
					 each parentPackage isNotNil and: [
						 each parentPackage sourceAnchor isNil ] ])
		description: 'no package without anchor holding a class'
]
