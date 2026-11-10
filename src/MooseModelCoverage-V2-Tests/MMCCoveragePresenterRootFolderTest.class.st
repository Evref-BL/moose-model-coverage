"
Tests (TDD, written before the production code) of the ""Set root folder"" button of MMCCoveragePresenter, at the top right of the line of the 'Whole model' check box. It does what the Moose Models Browser does (MiSetRootFolderCommand, menu 'Set Root Folder': a StOpenDirectoryPresenter modal dialog, then model rootFolder: <folder fullName>).
Expected API: setRootFolderButton (SpButtonPresenter, label 'Set root folder' with an ellipsis, help 'Root folder: <path>' or 'Root folder: (none)', enabled only with an inventory); rootFolderChooser / rootFolderChooser: (block WITHOUT argument answering a FileReference folder or nil when cancelled; the default opens the real dialog and is never evaluated by the tests, which inject a fake chooser); chooseRootFolder (nil changes nothing, else setRootFolder:; the button click does chooseRootFolder); setRootFolder: (FileReference or path String of an existing folder: model rootFolder:, new MMCModelFiles inventory, current file kept when still in the inventory else the first sorted file, every widget refreshed, tree selection, tree filter and file filter kept; anything else, or no inventory: nothing, no error).
Fixtures: a temporary folder (the right root) and an empty temporary folder (the wrong root), both deleted in tearDown; the models are created by the tests so model rootFolder is never restored. Windows are closed in tearDown. The real dialog is NEVER opened. Performance: setRootFolder: on 2000 fictive files must take less than 2 s.
"
Class {
	#name : 'MMCCoveragePresenterRootFolderTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'wrongFolder',
		'model',
		'entities',
		'presenters',
		'chooserCalls'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'fixture' }
MMCCoveragePresenterRootFolderTest >> addClass: aName on: aFileName from: start to: end [
	"Add to the model the class aName (kept in entities) with an indexed file anchor on aFileName (relative or absolute)."

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
MMCCoveragePresenterRootFolderTest >> assertChooserAnswering: anAnswer ignoredBy: aPresenter [
	"chooseRootFolder with a fake chooser answering anAnswer changes nothing."

	| rootBefore filesBefore labelsBefore currentBefore |
	rootBefore := model rootFolder.
	filesBefore := aPresenter modelFiles.
	labelsBefore := self labelsOf: aPresenter.
	currentBefore := aPresenter currentFile.
	self install: anAnswer on: aPresenter.
	self chooseOn: aPresenter.
	self assert: chooserCalls equals: 1.
	self assert: model rootFolder == rootBefore.
	self assert: aPresenter modelFiles == filesBefore.
	self assert: (self labelsOf: aPresenter) equals: labelsBefore.
	self assert: aPresenter currentFile equals: currentBefore
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> assertSetRootFolderIgnores: anArgument [
	"Nothing changes, no error: model rootFolder (same object), inventory (same instance), labels, current file, title."

	| presenter rootBefore filesBefore labelsBefore currentBefore titleBefore |
	self buildRelativeFixture.
	presenter := self newPresenter.
	rootBefore := model rootFolder.
	filesBefore := presenter modelFiles.
	labelsBefore := self labelsOf: presenter.
	currentBefore := presenter currentFile.
	titleBefore := presenter windowTitleText.
	self setRoot: anArgument on: presenter.
	self assert: model rootFolder == rootBefore.
	self assert: presenter modelFiles == filesBefore.
	self assert: (self labelsOf: presenter) equals: labelsBefore.
	self assert: presenter currentFile equals: currentBefore.
	self assert: presenter windowTitleText equals: titleBefore
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> boundsOf: aPresenter [
	"Bounds in the world of the widget of a Spec presenter."

	^ aPresenter adapter widget bounds
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> buildAbsoluteFixture [
	"Anchors with ABSOLUTE names, model rootFolder = the right folder. a.txt (100 chars, ClassA 1-50), b.txt (100, ClassB 1-100), c.txt (3, ClassC 1-1). An existing sub folder 'sub' is available as another root. Sorted: a, b, c."

	model rootFolder: folder asFileReference.
	(folder / 'sub') ensureCreateDirectory.
	#( 'a.txt' 'b.txt' 'c.txt' )
		with: #( 100 100 3 )
		do: [ :name :size |
			self writeText: (String new: size withAll: $x) to: name ].
	self
		addClass: 'ClassA'
		on: (folder / 'a.txt') fullName
		from: 1
		to: 50.
	self
		addClass: 'ClassB'
		on: (folder / 'b.txt') fullName
		from: 1
		to: 100.
	self
		addClass: 'ClassC'
		on: (folder / 'c.txt') fullName
		from: 1
		to: 1
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> buildFileTreeOf: aPresenter [
	"Build the widget of the file tree without opening a window: the selection of a SpTreeTablePresenter is only applied once its adapter exists (see selectPathByItems:)."

	aPresenter fileListPresenter build
]

{ #category : 'fixture' }
MMCCoveragePresenterRootFolderTest >> buildRelativeFixture [
	"Anchors with RELATIVE names, model rootFolder = the wrong empty folder: every file is unreadable. Sources in the right folder: src/a/Alpha.java (100 chars, ClassAlpha 1-50 = 50 %), src/b/Beta.java (10 chars, ClassBeta 1-10 = 100 %). src/b/Delta.java (ClassDelta) exists nowhere. Sorted: Alpha, Beta, Delta."

	self writeText: (String new: 100 withAll: $x) to: 'src/a/Alpha.java'.
	self writeText: (String new: 10 withAll: $y) to: 'src/b/Beta.java'.
	self
		addClass: 'ClassAlpha'
		on: 'src/a/Alpha.java'
		from: 1
		to: 50.
	self
		addClass: 'ClassBeta'
		on: 'src/b/Beta.java'
		from: 1
		to: 10.
	self
		addClass: 'ClassDelta'
		on: 'src/b/Delta.java'
		from: 1
		to: 5
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> buttonOf: aPresenter [
	"The new button (perform: so that the test compiles before the production code)."

	^ aPresenter perform: #setRootFolderButton
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> canonical: aFolderOrString [
	"Canonical FileReference of a path (FileReference or String)."

	^ aFolderOrString asFileReference canonicalize
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> chooseOn: aPresenter [

	aPresenter perform: #chooseRootFolder
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> fileItemsOf: aPresenter [
	"Files of the leaves of the file tree, flattened in the order of the tree (folders first, then alphabetical)."

	| result pending |
	result := OrderedCollection new.
	pending := OrderedCollection withAll:
		           aPresenter fileListPresenter roots.
	[ pending isEmpty ] whileFalse: [
			| node |
			node := pending removeFirst.
			node isFile
				ifTrue: [ result add: node file ]
				ifFalse: [ pending addAllFirst: node children ] ].
	^ result
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> fileNamed: aRelativeName [
	"Canonical file of the right folder."

	^ (folder resolve: aRelativeName) asFileReference canonicalize
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> install: anAnswer on: aPresenter [
	"Fake chooser without argument: counts its calls and answers anAnswer (a FileReference, a String, nil...). The real dialog is never opened."

	aPresenter perform: #rootFolderChooser: with: [
			chooserCalls := chooserCalls + 1.
			anAnswer ]
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> labelsOf: aPresenter [
	"Full labels (see fileLabelFor:) of the files of the file tree, the leaves flattened in the order of the tree."

	^ ((self fileItemsOf: aPresenter) collect: [ :each |
		   aPresenter fileLabelFor: each ]) asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> modelRoot [
	"Canonical root folder of the model, whatever its type (String as Moose stores it, or FileReference)."

	^ self canonical: model rootFolder
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> newPresenter [
	"Not opened presenter on the inventory of the model, closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> newWindowPresenter [
	"Presenter in Whole model mode (the covered tree is empty with the wrong root, and the window waits for exposed rows)."

	| presenter |
	presenter := self newPresenter.
	presenter treeFilter: #all.
	^ presenter
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> selectedFileOf: aPresenter [
	"File of the leaf selected in the file tree, nil when nothing (or a folder) is selected."

	^ aPresenter fileListPresenter selection selectedItem ifNotNil: [
		  :node | node file ]
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> setRoot: aFolder on: aPresenter [

	aPresenter perform: #setRootFolder: with: aFolder
]

{ #category : 'fixture' }
MMCCoveragePresenterRootFolderTest >> setUp [
	"Right root folder (folder, holds the sources), wrong root folder (wrongFolder, empty, existing), and a model whose rootFolder is the wrong one."

	super setUp.
	folder := FileLocator temp / ('mmc-rootfolder-' , UUID new asString).
	folder ensureCreateDirectory.
	wrongFolder := FileLocator temp
	               / ('mmc-rootfolder-wrong-' , UUID new asString).
	wrongFolder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: wrongFolder asFileReference.
	entities := Dictionary new.
	presenters := OrderedCollection new.
	chooserCalls := 0
]

{ #category : 'fixture' }
MMCCoveragePresenterRootFolderTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folders."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	wrongFolder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonExistsAndIsAButtonPresenter [

	self buildRelativeFixture.
	self assert:
		((self buttonOf: self newPresenter) isKindOf: SpButtonPresenter)
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonHelpFollowsTheNewRootFolder [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self assert: ((self buttonOf: presenter) help includesSubstring:
			 folder asFileReference pathString).
	self deny: ((self buttonOf: presenter) help includesSubstring:
			 wrongFolder asFileReference pathString)
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonHelpSaysNoneWithoutRootFolder [
	"No inventory and a model without rootFolder: 'Root folder: (none)' (the inventory cannot be built without root)."

	| presenter coverage |
	self buildRelativeFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'src/a/Alpha.java').
	model rootFolder: nil.
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self
		assert: (self buttonOf: presenter) help
		equals: 'Root folder: (none)'
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonHelpShowsTheCurrentRootFolder [

	| presenter help |
	self buildRelativeFixture.
	presenter := self newPresenter.
	help := (self buttonOf: presenter) help.
	self assert: help notNil.
	self assert: (help includesSubstring: 'Root folder: ').
	self assert:
		(help includesSubstring: wrongFolder asFileReference pathString)
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> testButtonIsAtTheTopRightOfTheWholeModelLineInARealWindow [
	"Real window (1300@700): the button is visible, inside the window, on the same line as the 'Whole model' check box, on its right, aligned with the right edge of the left column (the tree panel)."

	| presenter |
	self buildRelativeFixture.
	presenter := self newWindowPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			| button toggle tree windowBounds |
			button := self boundsOf: (self buttonOf: presenter).
			toggle := self boundsOf: presenter wholeModelTogglePresenter.
			tree := self boundsOf: presenter treePresenter.
			windowBounds := (self buttonOf: presenter) adapter widget window
				                bounds.
			self assert: (self buttonOf: presenter) adapter widget visible.
			self assert: (windowBounds containsRect: button).
			self assert: button width > 10.
			self assert: button left > toggle left.
			self assert: button center x > toggle center x.
			self assert:
				(button center y between: toggle top and: toggle bottom).
			self assert: (button right - tree right) abs <= 24.
			self assert: button bottom <= tree top ]
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonIsDisabledWithForModelFile [
	"forModel:file: builds a single file presenter without inventory."

	| presenter |
	self buildRelativeFixture.
	presenter := presenters add:
		             (MMCCoveragePresenter
			              forModel: model
			              file: 'src/a/Alpha.java').
	self assert: presenter modelFiles isNil.
	self deny: (self buttonOf: presenter) isEnabled
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonIsDisabledWithoutInventoryOnModel [
	"on:model: builds a presenter without inventory (modelFiles nil)."

	| presenter coverage |
	self buildRelativeFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'src/a/Alpha.java').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	self assert: presenter modelFiles isNil.
	self deny: (self buttonOf: presenter) isEnabled
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonIsEnabledWithInventory [

	self buildRelativeFixture.
	self assert: (self buttonOf: self newPresenter) isEnabled
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> testButtonKeepsItsPlaceAfterSetRootFolderInARealWindow [

	| presenter |
	self buildRelativeFixture.
	presenter := self newWindowPresenter.
	self withOpenWindowOf: presenter do: [ :window |
			| before after |
			before := self boundsOf: (self buttonOf: presenter).
			self setRoot: folder on: presenter.
			self waitUpTo: 1000 until: [ false ].
			after := self boundsOf: (self buttonOf: presenter).
			self assert: after equals: before.
			self assert: window title equals: presenter windowTitleText ]
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testButtonLabelMentionsTheRootFolder [
	"'Set root folder' followed by an ellipsis, or an equivalent short label."

	self buildRelativeFixture.
	self assert:
		((self buttonOf: self newPresenter) label asString asLowercase
			 includesSubstring: 'root')
]

{ #category : 'tests - chooser' }
MMCCoveragePresenterRootFolderTest >> testCancelledChooserChangesNothing [
	"Cancel (nil): same labels, same current file, same model rootFolder, same MMCModelFiles instance."

	self buildRelativeFixture.
	self assertChooserAnswering: nil ignoredBy: self newPresenter
]

{ #category : 'tests - chooser' }
MMCCoveragePresenterRootFolderTest >> testChooseRootFolderWithAPathStringSetsIt [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self install: folder asFileReference pathString on: presenter.
	self chooseOn: presenter.
	self assert: self modelRoot equals: (self canonical: folder)
]

{ #category : 'tests - chooser' }
MMCCoveragePresenterRootFolderTest >> testChooseRootFolderWithAValidFolderSetsIt [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self install: folder asFileReference on: presenter.
	self chooseOn: presenter.
	self assert: chooserCalls equals: 1.
	self assert: self modelRoot equals: (self canonical: folder).
	self deny:
		((self labelsOf: presenter) first endsWith: self unreadableSuffix)
]

{ #category : 'tests - chooser' }
MMCCoveragePresenterRootFolderTest >> testChooserAnsweringAFileChangesNothing [

	self buildRelativeFixture.
	self
		assertChooserAnswering: (self writeText: 'x' to: 'plain.txt')
		ignoredBy: self newPresenter
]

{ #category : 'tests - chooser' }
MMCCoveragePresenterRootFolderTest >> testChooserAnsweringAMissingFolderChangesNothing [

	self buildRelativeFixture.
	self
		assertChooserAnswering: folder / 'does-not-exist'
		ignoredBy: self newPresenter
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testChooserIsInjectable [

	| presenter fake |
	self buildRelativeFixture.
	presenter := self newPresenter.
	fake := [ nil ].
	presenter perform: #rootFolderChooser: with: fake.
	self assert: (presenter perform: #rootFolderChooser) == fake
]

{ #category : 'tests - click and performance' }
MMCCoveragePresenterRootFolderTest >> testClickingTheButtonChoosesAndSetsTheRootFolder [
	"A real click on the button (fake chooser, no dialog)."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self install: folder asFileReference on: presenter.
	(self buttonOf: presenter) click.
	self assert: chooserCalls equals: 1.
	self assert: self modelRoot equals: (self canonical: folder).
	self assert: presenter textPresenter text size equals: 100.
	self assert: ((self buttonOf: presenter) help includesSubstring:
			 folder asFileReference pathString)
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> testClickingTheButtonInARealWindowSetsTheRootFolder [
	"Open window, click (fake chooser): the widgets of the open window are refreshed."

	| presenter |
	self buildRelativeFixture.
	presenter := self newWindowPresenter.
	self install: folder asFileReference on: presenter.
	self withOpenWindowOf: presenter do: [ :window |
			(self buttonOf: presenter) click.
			self waitUpTo: 1000 until: [ false ].
			self assert: self modelRoot equals: (self canonical: folder).
			self assert: presenter textPresenter text size equals: 100.
			self assert: window title equals: presenter windowTitleText ]
]

{ #category : 'tests - click and performance' }
MMCCoveragePresenterRootFolderTest >> testClickingTheButtonWithACancellingChooserChangesNothing [

	| presenter filesBefore |
	self buildRelativeFixture.
	presenter := self newPresenter.
	filesBefore := presenter modelFiles.
	self install: nil on: presenter.
	(self buttonOf: presenter) click.
	self assert: chooserCalls equals: 1.
	self assert: presenter modelFiles == filesBefore.
	self assert: self modelRoot equals: (self canonical: wrongFolder)
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testCoveredModeIsKept [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self assert: presenter treeFilter equals: #covered.
	self deny: presenter wholeModelTogglePresenter state
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testCurrentFileIsKeptWhenStillInTheNewInventory [
	"Absolute anchors: the canonical files do not change, only their names (outside the new root: absolute path)."

	| presenter |
	self buildAbsoluteFixture.
	presenter := self newPresenter.
	self buildFileTreeOf: presenter.
	presenter showFile: (self fileNamed: 'b.txt').
	self setRoot: folder / 'sub' on: presenter.
	self assert: presenter currentFile equals: (self fileNamed: 'b.txt').
	self
		assert: presenter windowTitleText
		equals:
		'Coverage - ' , (self fileNamed: 'b.txt') pathString , ' (2/3)'.
	self
		assert: (self selectedFileOf: presenter)
		equals: (self fileNamed: 'b.txt').
	self assert: presenter textPresenter text size equals: 100
]

{ #category : 'tests - button' }
MMCCoveragePresenterRootFolderTest >> testDefaultChooserIsANonNilBlockNeverEvaluated [
	"The default is the real dialog (StOpenDirectoryPresenter modal, as in MiSetRootFolderCommand): only checked, never evaluated."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self assert: (presenter perform: #rootFolderChooser) isBlock
]

{ #category : 'tests - click and performance' }
MMCCoveragePresenterRootFolderTest >> testExpandFileTreeChangesNeitherTheFileNorTheCoverage [
	"Non regression: unfolding the file tree (widget built, no window) keeps the current file and does not recompute the coverage (same plan and same decorator objects), and the leaf of the current file stays selected."

	| presenter file plan decorators |
	1 to: 30 do: [ :i |
			self
				addClass: 'C' , i printString
				on: 'd' , (i \\ 5) printString , '/f' , i printString , '.txt'
				from: 1
				to: 5 ].
	presenter := self newPresenter.
	self buildFileTreeOf: presenter.
	file := presenter currentFile.
	plan := presenter plan.
	decorators := presenter decorators.
	presenter expandFileTree.
	self assert: presenter currentFile equals: file.
	self assert: presenter plan == plan.
	self assert: presenter decorators size equals: decorators size.
	presenter decorators
		with: decorators
		do: [ :after :before | self assert: after == before ].
	self
		assert:
		presenter fileListPresenter adapter widget dataSource numberOfRows
		equals: 35.
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (presenter fileNodeOf: file)
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testFileFilterIsKept [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	presenter fileFilterPresenter text: 'src/b'.
	self setRoot: folder on: presenter.
	self assert: presenter fileFilterPresenter text equals: 'src/b'.
	self assert: (self fileItemsOf: presenter) size equals: 2.
	self
		assert: (self labelsOf: presenter) first
		equals:
		(presenter fileLabelFor: (self fileNamed: 'src/b/Beta.java'))
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testFilesOutsideTheNewRootAreNamedByAbsolutePath [

	| presenter |
	self buildAbsoluteFixture.
	presenter := self newPresenter.
	self assert: ((self labelsOf: presenter) first beginsWith: 'a.txt  ').
	self setRoot: folder / 'sub' on: presenter.
	(self labelsOf: presenter)
		with: #( 'a.txt' 'b.txt' 'c.txt' )
		do: [ :label :name |
				self assert:
					(label beginsWith: (self fileNamed: name) pathString , '  ') ]
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> testLayoutRatiosAreUnchanged [
	"Same bounds as MMCCoveragePresenterTreeWidthTest."

	| layout |
	self buildRelativeFixture.
	layout := self newPresenter defaultLayout.
	self assert: layout children last positionOfSlider >= 0.25.
	self assert: layout children last positionOfSlider <= 0.32
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testNoEchoLoopAfterTheChange [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self deny: presenter isSynchronizing
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testOnlyTheCurrentFileIsComputedAfterTheChange [
	"Coverage stays on demand: Beta is readable but not computed (?)."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self assert: ((self labelsOf: presenter) second endsWith: '  ?').
	self assert:
		(presenter globalSummaryText includesSubstring: 'computed 1/3')
]

{ #category : 'tests - click and performance' }
MMCCoveragePresenterRootFolderTest >> testOpenOnTwoThousandFilesInARealWindowIsFastAndExpandsTheTree [
	"Non regression (freeze of about 149 s at the opening): 2000 fictive files in 20 folders, real window. A watchdog process raises an error in the test process after 30 s (the test runner is never blocked longer). The opening must take less than 3 s (wide threshold) and leave the tree unfolded (2000 files and 20 folders) with the leaf of the current file selected. The window is closed in ensure:."

	| presenter window watchdog testProcess milliseconds node |
	World ifNil: [ self skip: 'no world' ].
	1 to: 2000 do: [ :i |
			self
				addClass: 'C' , i printString
				on: 'd' , (i \\ 20) printString , '/f' , i printString , '.txt'
				from: 1
				to: 5 ].
	presenter := self newPresenter.
	testProcess := Processor activeProcess.
	watchdog := [
		            (Delay forSeconds: 30) wait.
		            testProcess signalException:
			            (Error new messageText:
				             'open did not return within 30 s (freeze)') ]
		            forkAt: Processor userInterruptPriority.
	[
		milliseconds := Time millisecondsToRun: [ window := presenter open ].
		watchdog terminate.
		self
			assert: milliseconds < 3000
			description: 'open took ' , milliseconds printString , ' ms'.
		self
			assert:
			presenter fileListPresenter adapter widget dataSource numberOfRows
			equals: 2020.
		node := presenter fileNodeOf: presenter currentFile.
		self assert: node notNil.
		self
			assert: presenter fileListPresenter selection selectedItem
			equals: node ] ensure: [
			watchdog terminate.
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ]
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> testPanelTitlesAreUnchanged [

	self buildRelativeFixture.
	self
		assert: self newPresenter panelTitles
		equals:
			#( 'Summary' 'Files' 'Model' 'Source text' 'Uncovered zones'
			   'Details' )
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testRelativeAnchorsAreUnreadableWithTheWrongRootFolder [
	"Precondition of the key use case."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self assert: (self labelsOf: presenter) size equals: 3.
	(self labelsOf: presenter) do: [ :each |
		self assert: (each endsWith: self unreadableSuffix) ]
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testRootFolderWhereTheCurrentFileIsGoneKeepsWorkingWithoutError [
	"Inverse case: right root, then the wrong root. The current file is no longer in the inventory: first sorted file, unreadable, no error."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self setRoot: wrongFolder on: presenter.
	self
		assert: presenter currentFile
		equals: presenter modelFiles files first.
	(self labelsOf: presenter) do: [ :each |
		self assert: (each endsWith: self unreadableSuffix) ].
	self
		assert: presenter windowTitleText
		equals: 'Coverage - src/a/Alpha.java (1/3)'.
	self assert: self modelRoot equals: (self canonical: wrongFolder).
	self deny: presenter isSynchronizing
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderAcceptsAPathString [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder asFileReference pathString on: presenter.
	self assert: self modelRoot equals: (self canonical: folder).
	self deny:
		((self labelsOf: presenter) first endsWith: self unreadableSuffix)
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderBuildsANewInventory [

	| presenter before |
	self buildRelativeFixture.
	presenter := self newPresenter.
	before := presenter modelFiles.
	self setRoot: folder on: presenter.
	self deny: presenter modelFiles == before.
	self assert: presenter modelFiles notNil
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderMakesRelativeFilesReadable [
	"Key use case: wrong root -> every file unreadable; right root -> readable, current file read, coverage computed, label with percentage, text shown."

	| presenter labels |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	labels := self labelsOf: presenter.
	self assert: labels size equals: 3.
	self assert: (labels first beginsWith: 'src/a/Alpha.java  ').
	self assert: (labels first includesSubstring: '%').
	self deny: (labels first endsWith: self unreadableSuffix).
	self assert: (labels second beginsWith: 'src/b/Beta.java  ').
	self deny: (labels second endsWith: self unreadableSuffix).
	self
		assert: labels third
		equals: 'src/b/Delta.java' , self unreadableSuffix.
	self
		assert: presenter currentFile
		equals: (self fileNamed: 'src/a/Alpha.java').
	self assert: presenter fileCoverage notNil.
	self assert: presenter textPresenter text size equals: 100
]

{ #category : 'tests - click and performance' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderOnTwoThousandFilesTakesLessThanTwoSeconds [
	"Performance: 2000 fictive files (relative names, absent from the disk, wrong root): the new inventory and the refresh of the widgets must take less than 2 s."

	| presenter milliseconds |
	1 to: 2000 do: [ :i |
			self
				addClass: 'C' , i printString
				on: 'd' , (i \\ 20) printString , '/f' , i printString , '.txt'
				from: 1
				to: 5 ].
	presenter := self newPresenter.
	self assert: presenter modelFiles fileCount equals: 2000.
	milliseconds := Time millisecondsToRun: [
		                self setRoot: folder on: presenter ].
	self assert: self modelRoot equals: (self canonical: folder).
	self assert: presenter modelFiles fileCount equals: 2000.
	self
		assert: milliseconds < 2000
		description:
		'setRootFolder: took ' , milliseconds printString , ' ms'
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderRefreshesNavigationButtons [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self buildFileTreeOf: presenter.
	self setRoot: folder on: presenter.
	self deny: presenter previousFileButton isEnabled.
	self assert: presenter nextFileButton isEnabled.
	self
		assert: (self selectedFileOf: presenter)
		equals: presenter currentFile
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderRefreshesTextUncoveredZonesSummaryAndTitle [

	| presenter summaryBefore |
	self buildRelativeFixture.
	presenter := self newPresenter.
	summaryBefore := presenter summaryPresenter label.
	self setRoot: folder on: presenter.
	self assert: presenter uncoveredListPresenter items size equals: 1.
	self deny: presenter summaryPresenter label = summaryBefore.
	self
		assert: presenter windowTitleText
		equals: 'Coverage - src/a/Alpha.java (1/3)'.
	self assert:
		(presenter globalSummaryText includesSubstring: 'covered 50').
	self
		assert: presenter filesSummaryPresenter label
		equals: presenter globalSummaryText
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderRefreshesTheTree [
	"Covered mode: ClassAlpha only becomes visible once its file is readable."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self assert: (presenter navigator visibleEntities includes:
			 (entities at: 'ClassAlpha')).
	self deny: presenter treePresenter roots isEmpty
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderUpdatesTheModelRootFolder [
	"The root folder is the one of the MODEL; compared canonically, since Moose stores a String."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self assert: self modelRoot equals: (self canonical: folder)
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithACollectionDoesNothing [

	self assertSetRootFolderIgnores: #( 1 2 )
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithAFileDoesNothing [

	self buildRelativeFixture.
	self assertSetRootFolderIgnores:
		(self writeText: 'x' to: 'plain.txt')
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithAMissingFolderDoesNothing [

	self buildRelativeFixture.
	self assertSetRootFolderIgnores: folder / 'does-not-exist'
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithAMissingPathStringDoesNothing [

	self buildRelativeFixture.
	self assertSetRootFolderIgnores: (folder / 'does-not-exist') fullName
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithANumberDoesNothing [

	self assertSetRootFolderIgnores: 42
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithAnIncongruousObjectDoesNothing [

	self assertSetRootFolderIgnores: Object new
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithNilDoesNothing [

	self buildRelativeFixture.
	self assertSetRootFolderIgnores: nil
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithoutInventoryDoesNothing [
	"on:model: (no inventory): no error, the model rootFolder is not touched."

	| presenter coverage rootBefore |
	self buildRelativeFixture.
	self writeText: 'x' to: 'plain.txt'.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'src/a/Alpha.java').
	presenter := presenters add:
		             (MMCCoveragePresenter on: coverage model: model).
	rootBefore := model rootFolder.
	self setRoot: folder on: presenter.
	self assert: model rootFolder == rootBefore.
	self assert: presenter modelFiles isNil.
	self assert: presenter windowTitleText equals: 'Coverage'
]

{ #category : 'tests - invalid arguments' }
MMCCoveragePresenterRootFolderTest >> testSetRootFolderWithoutModelDoesNothing [
	"Coverage without Moose model: nothing, no error, button disabled."

	| presenter coverage |
	self buildRelativeFixture.
	coverage := (MMCModelFiles on: model) coverageFor:
		            (self fileNamed: 'src/a/Alpha.java').
	presenter := presenters add: (MMCCoveragePresenter on: coverage).
	self setRoot: folder on: presenter.
	self assert: presenter model isNil.
	self deny: (self buttonOf: presenter) isEnabled
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testSeveralSuccessiveChanges [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	self setRoot: folder on: presenter.
	self setRoot: wrongFolder on: presenter.
	self setRoot: folder on: presenter.
	self assert: self modelRoot equals: (self canonical: folder).
	self deny:
		((self labelsOf: presenter) first endsWith: self unreadableSuffix).
	self assert: presenter textPresenter text size equals: 100.
	self assert: presenter modelFiles fileCount equals: 3.
	self deny: presenter isSynchronizing
]

{ #category : 'tests - window and layout' }
MMCCoveragePresenterRootFolderTest >> testTreeAndFileListKeepTheirHeightsAtInitialExtentInARealWindow [
	"Non regression of the dimensions at 1300@700 (the new button must not steal the room): tree at least 200 px, file list at least 100 px, before and after setRootFolder:."

	| presenter |
	self buildRelativeFixture.
	presenter := self newWindowPresenter.
	self assert: presenter initialExtent equals: 1300 @ 700.
	self withOpenWindowOf: presenter do: [ :window |
			self assert: (self boundsOf: presenter treePresenter) height >= 200.
			self assert:
				(self boundsOf: presenter fileListPresenter) height >= 100.
			self setRoot: folder on: presenter.
			self waitUpTo: 1000 until: [ false ].
			self assert: (self boundsOf: presenter treePresenter) height >= 200.
			self assert:
				(self boundsOf: presenter fileListPresenter) height >= 100 ]
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testTreeSelectionIsKeptWhenTheEntityStaysVisible [
	"Whole model mode: ClassBeta stays visible after the change."

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	presenter treeFilter: #all.
	presenter selectEntityInTree: (entities at: 'ClassBeta').
	self assert:
		presenter selectedEntityInTree == (entities at: 'ClassBeta').
	self setRoot: folder on: presenter.
	self assert:
		presenter selectedEntityInTree == (entities at: 'ClassBeta')
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testTwoPresentersOnTheSameModelSeeTheSameRootFolder [

	| first second |
	self buildRelativeFixture.
	first := self newPresenter.
	second := self newPresenter.
	self setRoot: folder on: first.
	self
		assert: (self canonical: first model rootFolder)
		equals: (self canonical: second model rootFolder).
	self assert: first model == second model.
	self assert: self modelRoot equals: (self canonical: folder)
]

{ #category : 'tests - setRootFolder' }
MMCCoveragePresenterRootFolderTest >> testWholeModelModeIsKept [

	| presenter |
	self buildRelativeFixture.
	presenter := self newPresenter.
	presenter treeFilter: #all.
	self setRoot: folder on: presenter.
	self assert: presenter treeFilter equals: #all.
	self assert: presenter wholeModelTogglePresenter state.
	self assert: (presenter navigator visibleEntities includes:
			 (entities at: 'ClassDelta'))
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> unreadableSuffix [
	"'  (warning sign) unreadable'."

	^ '  ' , (String with: (Character value: 16r26A0)) , ' unreadable'
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> waitUpTo: someMilliseconds until: aBlock [
	"Let Morphic run (100 ms steps) until aBlock is true or someMilliseconds elapsed. Answer the final value of aBlock."

	| waited |
	waited := 0.
	[ aBlock value or: [ waited >= someMilliseconds ] ] whileFalse: [
			(Delay forMilliseconds: 100) wait.
			World doOneCycle.
			waited := waited + 100 ].
	^ aBlock value
]

{ #category : 'helpers' }
MMCCoveragePresenterRootFolderTest >> withOpenWindowOf: aPresenter do: aBlock [
	"Skipped without World. Open aPresenter, wait for the tree rows and the layout (1 s), evaluate aBlock with the window, then always close it and check that the number of windows is the same as before."

	| window windowsBefore |
	World ifNil: [ self skip: 'no world' ].
	windowsBefore := World submorphs count: [ :each |
		                 each isSystemWindow ].
	[
		window := aPresenter open.
		self
			assert: (self waitUpTo: 3000 until: [
						 aPresenter treePresenter adapter widget container exposedRows
							 notNil and: [
							 aPresenter treePresenter adapter widget container exposedRows
								 notEmpty ] ])
			description: 'the tree rows were not exposed'.
		self waitUpTo: 1000 until: [ false ].
		aBlock value: window ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ].
	self
		assert: (World submorphs count: [ :each | each isSystemWindow ])
		equals: windowsBefore
]

{ #category : 'fixture' }
MMCCoveragePresenterRootFolderTest >> writeText: aString to: aRelativeName [
	"UTF-8 text file in the right folder."

	| ref |
	ref := folder resolve: aRelativeName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
	^ ref
]
