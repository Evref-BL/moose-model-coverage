"
TDD tests of the file-by-file navigation of MMCCoveragePresenter: file selector (fileListPresenter, filter), labels ('?' until computed, percentage, unreadable marker), previous/next/next uncovered navigation with their enabled states, compute all, and non regression of the presenters built without inventory (on:, on:model:, forModel:file:). Fixture (files of a temporary folder, cleaned in tearDown): a.txt (100 chars, ClassA 1-50: 50.0 percent, uncovered zone), b.txt (100 chars, ClassB 1-100: 100.0 percent, no uncovered zone), c.txt ('xxx', ClassC 1-1: 33.3 percent, uncovered zone), gone.txt (missing on disk: unreadable). Expected API of MMCCoveragePresenter: forModel: (not opened, first sorted file), openOn:, openOn:file:, modelFiles, currentFile, showFile:, fileListPresenter, fileFilterPresenter, visibleFiles, fileLabelFor:, previousFile, nextFile, nextUncoveredFile, computeAllFiles, previousFileButton, nextFileButton, nextUncoveredFileButton, computeAllButton, globalSummaryText, filesSummaryPresenter, windowTitleText.
"
Class {
	#name : 'MMCCoveragePresenterFilesTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'entities',
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> addClass: aName on: aFileName from: start to: end [
	"Add to the model the class aName (kept under aName in entities) with an indexed file anchor."

	| entity anchor |
	entity := FamixJavaClass new.
	entity name: aName.
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: start.
	anchor endPos: end.
	model add: anchor.
	entity sourceAnchor: anchor.
	entities at: aName put: entity.
	^ entity
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> buildFullyCoveredFixture [
	"p.txt and q.txt, 10 chars each, entirely covered (no uncovered zone)."

	self writeText: (String new: 10 withAll: $x) to: 'p.txt'.
	self writeText: (String new: 10 withAll: $x) to: 'q.txt'.
	self
		addClass: 'ClassP'
		on: 'p.txt'
		from: 1
		to: 10.
	self
		addClass: 'ClassQ'
		on: 'q.txt'
		from: 1
		to: 10
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> buildStandardFixture [
	"a.txt: 100 chars, ClassA 1-50 (50.0 %, one uncovered zone). b.txt: 100 chars, ClassB 1-100 (100.0 %, no uncovered zone). c.txt: 3 chars, ClassC 1-1 (33.3 %, one uncovered zone). gone.txt: missing on disk (unreadable), ClassG. Orphan: class without anchor. Sorted relative names: a.txt b.txt c.txt gone.txt."

	self writeText: (String new: 100 withAll: $x) to: 'a.txt'.
	self writeText: (String new: 100 withAll: $x) to: 'b.txt'.
	self writeText: 'xxx' to: 'c.txt'.
	self
		addClass: 'ClassA'
		on: 'a.txt'
		from: 1
		to: 50.
	self
		addClass: 'ClassB'
		on: 'b.txt'
		from: 1
		to: 100.
	self
		addClass: 'ClassC'
		on: 'c.txt'
		from: 1
		to: 1.
	self
		addClass: 'ClassG'
		on: 'gone.txt'
		from: 1
		to: 2.
	entities at: 'Orphan' put: (FamixJavaClass new
			 name: 'Orphan';
			 yourself).
	model add: (entities at: 'Orphan')
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> entity: aName [

	^ entities at: aName
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> file: aFileName [
	"The canonical FileReference expected in MMCModelFiles>>files."

	^ (folder / aFileName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> isInactive: aWidget [
	"A file widget of a presenter without inventory is disabled or hidden."

	^ aWidget isEnabled not or: [ aWidget isVisible not ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> labelsOf: aPresenter [
	"Labels of the items of the file list, in order."

	^ aPresenter fileListPresenter items collect: [ :each |
		  aPresenter fileLabelFor: each ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> namesOfFiles: aCollection [
	"Relative names of the given files, as an Array."

	^ (aCollection collect: [ :each | each basename ]) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> newPresenter [
	"Not opened presenter on the inventory of the model (current file: the first sorted file). Registered to be closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> setUp [

	super setUp.
	folder := FileLocator temp / ('mmc-files-ui-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testClickingComputeAllComputesEveryFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter computeAllButton click.
	self assert:
		(presenter modelFiles summaryFor: (self file: 'c.txt')) notNil.
	self
		assert: (presenter fileLabelFor: (self file: 'c.txt'))
		equals: 'c.txt  33.3%'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testClickingTheNavigationButtonsMovesBetweenFiles [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter nextFileButton click.
	self assert: presenter currentFile equals: (self file: 'b.txt').
	presenter previousFileButton click.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testComputeAllFilesComputesEveryFileAndRefreshesTheLabels [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter computeAllFiles.
	self assert: (self labelsOf: presenter) equals: {
			'a.txt  50.0%'.
			'b.txt  100.0%'.
			'c.txt  33.3%'.
			(self unreadableLabelOf: 'gone.txt') }.
	self assert:
		(presenter modelFiles summaryFor: (self file: 'b.txt')) notNil
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testComputeAllFilesDoesNotRecomputeComputedFiles [

	| presenter first |
	self buildStandardFixture.
	presenter := self newPresenter.
	first := presenter modelFiles coverageFor: (self file: 'a.txt').
	presenter computeAllFiles.
	self assert:
		(presenter modelFiles coverageFor: (self file: 'a.txt')) == first.
	self assert: presenter fileCoverage == first
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testComputeAllFilesKeepsTheCurrentFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'b.txt').
	presenter computeAllFiles.
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (self file: 'b.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testEmptyFilterShowsAllFilesAgain [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'b'.
	presenter fileFilterPresenter text: ''.
	self assert: presenter visibleFiles size equals: 4.
	self assert: presenter fileListPresenter items size equals: 4
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testExistingSubPresentersAreStillThere [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	#( textPresenter uncoveredListPresenter detailsPresenter
	   summaryPresenter treePresenter wholeModelTogglePresenter
	   treeStatusPresenter fileListPresenter fileFilterPresenter
	   filesSummaryPresenter previousFileButton nextFileButton
	   nextUncoveredFileButton computeAllButton ) do: [ :each |
		self assert: (presenter perform: each) notNil description: each ]
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFileListItemsAreTheInventoryFilesInOrder [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self
		assert: presenter fileListPresenter items asArray
		equals: presenter modelFiles files asArray.
	self
		assert: (self namesOfFiles: presenter fileListPresenter items)
		equals: #( 'a.txt' 'b.txt' 'c.txt' 'gone.txt' )
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFileNavigationIsHarmlessWithoutInventory [

	| presenter coverage text |
	self buildStandardFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	text := presenter textPresenter text.
	presenter nextFile.
	presenter previousFile.
	presenter nextUncoveredFile.
	presenter computeAllFiles.
	presenter showFile: (self file: 'b.txt').
	self assert: presenter fileCoverage == coverage.
	self assert: presenter textPresenter text equals: text.
	self assert: presenter currentFile isNil
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFileWidgetsAreDisabledOrHiddenWithoutInventory [

	| presenter coverage |
	self buildStandardFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self assert: (self isInactive: presenter fileListPresenter).
	self assert: (self isInactive: presenter fileFilterPresenter).
	self assert: (self isInactive: presenter previousFileButton).
	self assert: (self isInactive: presenter nextFileButton).
	self assert: (self isInactive: presenter nextUncoveredFileButton).
	self assert: (self isInactive: presenter computeAllButton)
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFilterDoesNotChangeTheCurrentFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	presenter fileFilterPresenter text: 'a.txt'.
	self assert: presenter currentFile equals: (self file: 'c.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFilterKeepsFilesOfSubfoldersByRelativePath [

	| presenter |
	self writeText: 'xxxx' to: 'src/Foo.txt'.
	self writeText: 'xxxx' to: 'test/Bar.txt'.
	self
		addClass: 'Foo'
		on: 'src/Foo.txt'
		from: 1
		to: 2.
	self
		addClass: 'Bar'
		on: 'test/Bar.txt'
		from: 1
		to: 2.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'SRC/'.
	self
		assert: (presenter visibleFiles collect: [ :each |
				 presenter modelFiles relativeNameOf: each ]) asArray
		equals: #( 'src/Foo.txt' )
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFilterKeepsFilesWhoseRelativeNameContainsTheTextIgnoringCase [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'B.TXT'.
	self
		assert: (self namesOfFiles: presenter visibleFiles)
		equals: #( 'b.txt' ).
	self
		assert: (self namesOfFiles: presenter fileListPresenter items)
		equals: #( 'b.txt' )
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFilterOnlyLooksAtTheRelativeNameNotTheAbsolutePath [
	"The temporary folder name contains 'mmc-files-ui': it is not part of the relative names."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'mmc-files-ui'.
	self assert: presenter visibleFiles isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFilterWithoutMatchEmptiesTheListButKeepsTheCurrentFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'zzz'.
	self assert: presenter visibleFiles isEmpty.
	self assert: presenter fileListPresenter items isEmpty.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testFirstFileIsComputedOnOpeningAndOthersStayUncomputed [
	"Coverage per file on demand: only the shown file is read."

	| presenter files |
	self buildStandardFixture.
	presenter := self newPresenter.
	files := presenter modelFiles.
	self assert: (files summaryFor: (self file: 'a.txt')) notNil.
	self assert: (files summaryFor: (self file: 'b.txt')) isNil.
	self assert: (files summaryFor: (self file: 'c.txt')) isNil
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testForModelFileKeepsItsBehaviorWithoutInventory [
	"Compatibility: forModel:file: still answers a single-file presenter without selector."

	| presenter |
	self buildStandardFixture.
	presenter := presenters add:
		             (MMCCoveragePresenter forModel: model file: 'b.txt').
	self assert: presenter modelFiles isNil.
	self assert: presenter currentFile isNil.
	self assert: presenter model == model.
	self assert: presenter textPresenter text size equals: 100.
	self assert: (presenter windowTitle includesSubstring: 'b.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testForModelOpensOnTheFirstSortedFileOfTheModel [
	"forModel: (new, not opened) is the unopened counterpart of openOn:."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self assert: presenter model == model.
	self
		assert: presenter windowTitleText
		equals: 'Coverage - a.txt (1/4)'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testLabelOfUnreadableFileHasTheMarkerBeforeAndAfterShowingIt [

	| presenter file |
	self buildStandardFixture.
	presenter := self newPresenter.
	file := self file: 'gone.txt'.
	self
		assert: (presenter fileLabelFor: file)
		equals: (self unreadableLabelOf: 'gone.txt').
	presenter showFile: file.
	self
		assert: (presenter fileLabelFor: file)
		equals: (self unreadableLabelOf: 'gone.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testLabelShowsSignificantPercentageWithOneDecimalOnceComputed [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	self
		assert: (presenter fileLabelFor: (self file: 'c.txt'))
		equals: 'c.txt  33.3%'.
	self
		assert: (presenter fileLabelFor: (self file: 'b.txt'))
		equals: 'b.txt  ?'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testLabelsAreSortedByRelativePathAndShowQuestionMarkUntilComputed [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self assert: (self labelsOf: presenter) equals: {
			'a.txt  50.0%'.
			'b.txt  ?'.
			'c.txt  ?'.
			(self unreadableLabelOf: 'gone.txt') }
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testListDisplaysTheLabels [
	"The display block of the list is fileLabelFor:."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileListPresenter items do: [ :each |
			self
				assert: (presenter fileListPresenter display value: each)
				equals: (presenter fileLabelFor: each) ]
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testModelFilesIsTheInventoryOfTheModel [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self assert: presenter modelFiles notNil.
	self assert: presenter modelFiles fileCount equals: 4
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNavigationButtonsStatesOnAMiddleAndOnTheLastFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'b.txt').
	self assert: presenter previousFileButton isEnabled.
	self assert: presenter nextFileButton isEnabled.
	presenter showFile: (self file: 'gone.txt').
	self assert: presenter previousFileButton isEnabled.
	self deny: presenter nextFileButton isEnabled
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNavigationButtonsStatesOnTheFirstFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self deny: presenter previousFileButton isEnabled.
	self assert: presenter nextFileButton isEnabled.
	self assert: presenter nextUncoveredFileButton isEnabled.
	self assert: presenter computeAllButton isEnabled
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNextFileGoesToTheFollowingFileInSortedOrder [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter nextFile.
	self assert: presenter currentFile equals: (self file: 'b.txt').
	presenter nextFile.
	self assert: presenter currentFile equals: (self file: 'c.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNextFileOnTheLastFileDoesNothingAndDoesNotLoop [
	"The last file in sorted order is gone.txt (unreadable files are part of the navigation)."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'gone.txt').
	presenter nextFile.
	self assert: presenter currentFile equals: (self file: 'gone.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNextUncoveredFileSkipsFullyCoveredFilesAndComputesThemOnDemand [
	"From a.txt: b.txt is fully covered (computed on the way, label 100.0%), c.txt has an uncovered zone."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self assert:
		(presenter modelFiles summaryFor: (self file: 'b.txt')) isNil.
	presenter nextUncoveredFile.
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self
		assert: (presenter fileLabelFor: (self file: 'b.txt'))
		equals: 'b.txt  100.0%'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNextUncoveredFileUsesAnAlreadyComputedFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	presenter showFile: (self file: 'a.txt').
	presenter nextUncoveredFile.
	self assert: presenter currentFile equals: (self file: 'c.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNextUncoveredFileWithoutCandidateDoesNothing [
	"p.txt and q.txt are fully covered: no move, but the encountered file q.txt has been computed."

	| presenter |
	self buildFullyCoveredFixture.
	presenter := self newPresenter.
	presenter nextUncoveredFile.
	self assert: presenter currentFile equals: (self file: 'p.txt').
	self
		assert: (presenter fileLabelFor: (self file: 'q.txt'))
		equals: 'q.txt  100.0%'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testNextUncoveredFileWrapsAroundAndSkipsUnreadableFiles [
	"From c.txt: gone.txt is unreadable (no uncovered zone), then wrap to a.txt."

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	presenter nextUncoveredFile.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testOnCoverageOnlyWithoutInventoryKeepsItsBehavior [

	| presenter coverage |
	self buildStandardFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	presenter := presenters add: (MMCCoveragePresenter on: coverage).
	self assert: presenter modelFiles isNil.
	self assert: presenter model isNil.
	self assert: presenter windowTitleText equals: 'Coverage'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testOnModelWithoutInventoryKeepsItsBehavior [

	| presenter coverage |
	self buildStandardFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self file: 'a.txt').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self assert: presenter modelFiles isNil.
	self assert: presenter currentFile isNil.
	self assert: presenter fileCoverage == coverage.
	self assert: presenter textPresenter text size equals: 100.
	self assert: presenter treePresenter roots size equals: 1
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testOpensOnTheFirstSortedFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testPreviousFileGoesBack [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	presenter previousFile.
	self assert: presenter currentFile equals: (self file: 'b.txt').
	presenter previousFile.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testPreviousFileOnTheFirstFileDoesNothing [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter previousFile.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testSelectingAnItemInTheListShowsTheFile [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter fileListPresenter selectItem: (self file: 'c.txt').
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self assert: presenter textPresenter text equals: 'xxx'.
	self
		assert: (presenter fileLabelFor: (self file: 'c.txt'))
		equals: 'c.txt  33.3%'
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testShowFileDoesNotRecomputeAnAlreadyComputedFile [
	"The coverage shown is the cached one of the inventory (same object)."

	| presenter first |
	self buildStandardFixture.
	presenter := self newPresenter.
	first := presenter modelFiles coverageFor: (self file: 'a.txt').
	presenter showFile: (self file: 'b.txt').
	presenter showFile: (self file: 'a.txt').
	self assert: presenter fileCoverage == first.
	self assert:
		(presenter modelFiles coverageFor: (self file: 'a.txt')) == first
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testShowFileOfAnUnknownFileDoesNothing [

	| presenter before |
	self buildStandardFixture.
	presenter := self newPresenter.
	before := presenter textPresenter text.
	presenter showFile: (folder / 'unknown.txt') asFileReference.
	self assert: presenter currentFile equals: (self file: 'a.txt').
	self assert: presenter textPresenter text equals: before.
	presenter showFile: nil.
	self assert: presenter currentFile equals: (self file: 'a.txt')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testShowFileSelectsTheFileInTheListWithoutBouncing [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'b.txt').
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (self file: 'b.txt').
	self assert: presenter currentFile equals: (self file: 'b.txt').
	self assert: presenter textPresenter text size equals: 100
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testShowFileUpdatesTextUncoveredZonesAndSummary [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'c.txt').
	self assert: presenter currentFile equals: (self file: 'c.txt').
	self assert: presenter textPresenter text equals: 'xxx'.
	self assert: presenter uncoveredListPresenter items size equals: 1.
	self
		assert: presenter uncoveredListPresenter items first interval
		equals: (2 to: 3).
	self assert:
		(presenter summaryPresenter label includesSubstring: '1/3')
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testShowingAnUnreadableFileShowsTheUnreadableSummary [

	| presenter |
	self buildStandardFixture.
	presenter := self newPresenter.
	presenter showFile: (self file: 'gone.txt').
	self assert: presenter currentFile equals: (self file: 'gone.txt').
	self assert:
		(presenter summaryPresenter label includesSubstring: 'Unreadable').
	self assert: presenter textPresenter text isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterFilesTest >> testSingleFileModelHasOneItemAndNoNavigation [

	| presenter |
	self writeText: (String new: 10 withAll: $x) to: 'only.txt'.
	self
		addClass: 'Only'
		on: 'only.txt'
		from: 1
		to: 5.
	presenter := self newPresenter.
	self assert: presenter fileListPresenter items size equals: 1.
	self assert: presenter currentFile equals: (self file: 'only.txt').
	self deny: presenter previousFileButton isEnabled.
	self deny: presenter nextFileButton isEnabled.
	presenter nextFile.
	presenter previousFile.
	self assert: presenter currentFile equals: (self file: 'only.txt')
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> unreadableLabelOf: aRelativeName [
	"Expected label of an unreadable file: '<relative>  (warning sign) unreadable'."

	^ aRelativeName , '  ' , (String with: (Character value: 16r26A0))
	  , ' unreadable'
]

{ #category : 'helpers' }
MMCCoveragePresenterFilesTest >> writeText: aString to: aFileName [
	"UTF-8 text file in the fixture folder."

	| ref |
	ref := folder resolve: aFileName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
