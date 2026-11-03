"
Tests of the file tree (Files panel, a SpTreeTablePresenter of MMCFileTreeNode) of MMCCoveragePresenter on the multi file example (src/a/Alpha.java, src/a/Beta.java, src/b/Delta.java unreadable, src/b/Gamma.java): structure, labels, unfolding, selection of the current file, click on a folder, filter, Compute all, Previous / Next. The selection of a SpTreeTablePresenter is only applied once its widget exists: most tests build the widget (no window, #builtPresenter); one test opens a real window and closes it.
"
Class {
	#name : 'MMCCoveragePresenterFileTreeTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> builtPresenter [
	"The example presenter whose file tree widget is built (no window) and unfolded."

	| presenter |
	presenter := self examplePresenter.
	presenter fileListPresenter build.
	presenter expandFileTree.
	^ presenter
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> displayedLabelsOf: aPresenter [
	"Texts displayed by the column of the file tree, depth first, without indentation."

	| labels walk |
	labels := OrderedCollection new.
	walk := nil.
	walk := [ :nodes |
		        nodes do: [ :each |
				        labels add: (self labelOf: each in: aPresenter).
				        walk value: each children ] ].
	walk value: aPresenter fileListPresenter roots.
	^ labels asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> examplePresenter [
	"Not opened presenter on the multi file example (current file: Alpha.java), closed and cleaned in tearDown."

	^ presenters add: MMCCoveragePresenter newMultiFileExample
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> fileNamed: aBasename of: aPresenter [
	"The file of the inventory named aBasename."

	^ aPresenter modelFiles files detect: [ :each |
		  each basename = aBasename ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> labelOf: aNode in: aPresenter [
	"Text displayed by the column of the file tree for aNode."

	^ aPresenter fileListPresenter columns first evaluation value: aNode
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> outlineOf: aPresenter [
	"Names of the nodes of the file tree, depth first, indented by two spaces per level."

	| lines walk |
	lines := OrderedCollection new.
	walk := nil.
	walk := [ :nodes :depth |
		        nodes do: [ :each |
				        lines add:
					        (String new: depth * 2 withAll: Character space)
					        , each name.
				        walk value: each children value: depth + 1 ] ].
	walk value: aPresenter fileListPresenter roots value: 0.
	^ lines asArray
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> rowCountOf: aPresenter [
	"Number of rows of the FastTable of the (built) file tree: the unfolded nodes."

	^ aPresenter fileListPresenter adapter widget dataSource numberOfRows
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> selectFile: aFile in: aPresenter [
	"Select the leaf of aFile in the file tree, as a click on it."

	aPresenter fileListPresenter selectPathByItems:
		(aPresenter fileNodeOf: aFile) pathFromRoot
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> selectedNodeOf: aPresenter [

	^ aPresenter fileListPresenter selection selectedItem
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> setUp [

	super setUp.
	presenters := OrderedCollection new
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> tearDown [
	"Close every window, then delete the temporary folder of the example presenters (only when under the system temporary directory)."

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

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testClickingAFolderDoesNotReloadTheCoverageNorTheText [

	| presenter coverage text b |
	presenter := self builtPresenter.
	coverage := presenter fileCoverage.
	text := presenter textPresenter text.
	b := (presenter fileNodeOf:
		      (self fileNamed: 'Beta.java' of: presenter)) parent.
	presenter fileListPresenter selectPathByItems: b pathFromRoot.
	self assert: presenter fileCoverage == coverage.
	self assert: presenter textPresenter text equals: text.
	self
		assert: (presenter modelFiles summaryFor:
				 (self fileNamed: 'Beta.java' of: presenter)) isNil
		description: 'no other file was computed'
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testClickingAFolderKeepsTheCurrentFile [

	| presenter folder file |
	presenter := self builtPresenter.
	file := presenter currentFile.
	folder := presenter fileListPresenter roots first.
	presenter fileListPresenter selectPathByItems: folder pathFromRoot.
	self assert: (self selectedNodeOf: presenter) == folder.
	self assert: presenter currentFile equals: file
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testClickingAFolderThenALeafStillShowsTheLeaf [

	| presenter beta |
	presenter := self builtPresenter.
	presenter fileListPresenter selectPathByItems:
		presenter fileListPresenter roots first pathFromRoot.
	beta := self fileNamed: 'Beta.java' of: presenter.
	self selectFile: beta in: presenter.
	self assert: presenter currentFile equals: beta
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testComputeAllKeepsTheCurrentFileSelectedAndTheTreeUnfolded [

	| presenter file |
	presenter := self builtPresenter.
	file := presenter currentFile.
	presenter computeAllFiles.
	self assert: presenter currentFile equals: file.
	self assert: (self selectedNodeOf: presenter) file equals: file.
	self assert: (self rowCountOf: presenter) equals: 7
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testComputeAllKeepsTheFilterOfTheTree [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'src/b'.
	presenter computeAllFiles.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  b' '    Delta.java' '    Gamma.java' )
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testComputeAllUpdatesTheLabels [

	| presenter labels |
	presenter := self builtPresenter.
	presenter computeAllFiles.
	labels := self displayedLabelsOf: presenter.
	self assert: labels first equals: 'src'.
	self assert: (labels at: 3) equals: 'Alpha.java  100.0%'.
	self assert: ((labels at: 4) endsWith: '%').
	self deny: ((labels at: 4) endsWith: '?').
	self
		assert: (labels at: 6)
		equals: 'Delta.java  ' , self unreadableLabel.
	self assert: ((labels at: 7) endsWith: '%')
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testCurrentFileLeafIsSelectedAtTheOpening [

	| presenter node |
	presenter := self builtPresenter.
	node := self selectedNodeOf: presenter.
	self assert: node isFile.
	self assert: node file equals: presenter currentFile.
	self assert: node name equals: 'Alpha.java'.
	self assert: node == (presenter fileNodeOf: presenter currentFile)
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testEmptyFilterRestoresTheWholeTree [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'gamma'.
	presenter fileFilterPresenter text: ''.
	self
		assert: (self outlineOf: presenter)
		equals:
			#( 'src' '  a' '    Alpha.java' '    Beta.java' '  b' '    Delta.java'
			   '    Gamma.java' ).
	self assert: (self rowCountOf: presenter) equals: 7
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testEmptyFilterSelectsTheCurrentFileAgain [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'gamma'.
	presenter fileFilterPresenter text: ''.
	self assert: (self selectedNodeOf: presenter)
		== (presenter fileNodeOf: presenter currentFile).
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileCoverageInfoIsQuestionMarkPercentOrUnreadable [

	| presenter |
	presenter := self examplePresenter.
	self
		assert: (presenter fileCoverageInfoFor:
				 (self fileNamed: 'Alpha.java' of: presenter))
		equals: '100.0%'.
	self
		assert: (presenter fileCoverageInfoFor:
				 (self fileNamed: 'Beta.java' of: presenter))
		equals: '?'.
	self
		assert: (presenter fileCoverageInfoFor:
				 (self fileNamed: 'Delta.java' of: presenter))
		equals: self unreadableLabel
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileLabelForKeepsTheRelativePathAndTheInfo [

	| presenter |
	presenter := self examplePresenter.
	self
		assert:
		(presenter fileLabelFor:
			 (self fileNamed: 'Alpha.java' of: presenter))
		equals: 'src/a/Alpha.java  100.0%'.
	self
		assert:
		(presenter fileLabelFor:
			 (self fileNamed: 'Gamma.java' of: presenter))
		equals: 'src/b/Gamma.java  ?'
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileLabelIsTheNameAndTheCoverageWithoutPath [
	"Only the current file is computed at the opening: the others show a question mark."

	self
		assert: (self displayedLabelsOf: self examplePresenter)
		equals: {
				'src'.
				'a'.
				'Alpha.java  100.0%'.
				'Beta.java  ?'.
				'b'.
				('Delta.java  ' , self unreadableLabel).
				'Gamma.java  ?' }
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileListIsATreeTablePresenter [

	self
		assert: self examplePresenter fileListPresenter class
		equals: SpTreeTablePresenter
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileNodeLabelIsTheFileLabelWithoutTheFolders [

	| presenter |
	presenter := self examplePresenter.
	presenter modelFiles files do: [ :each |
			| full short |
			full := presenter fileLabelFor: each.
			short := presenter fileNodeLabelFor: (presenter fileNodeOf: each).
			self assert: (full endsWith: short).
			self deny: (short includes: $/).
			self assert: (full includesSubstring: 'src/') ]
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileNodeOfAnUnknownFileIsNil [

	| presenter |
	presenter := self examplePresenter.
	self assert: (presenter fileNodeOf:
			 (FileLocator temp / 'nowhere.txt') asFileReference) isNil.
	self assert: (presenter fileNodeOf: nil) isNil
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFileNodeOfAnswersTheLeafOfEachFile [

	| presenter |
	presenter := self examplePresenter.
	presenter modelFiles files do: [ :each |
			| leaf |
			leaf := presenter fileNodeOf: each.
			self assert: leaf notNil.
			self assert: leaf file equals: each.
			self assert: leaf name equals: each basename ]
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterHidingTheCurrentFileLeavesNothingSelectedButKeepsTheFile [
	"CURRENT BEHAVIOUR (documented, not endorsed): when the filter hides the current file, no node of the tree is selected (refreshFileList unselects) while the text still shows the current file. The user sees no selected row; nothing is reselected until the filter shows the file again."

	| presenter alpha text |
	presenter := self builtPresenter.
	alpha := presenter currentFile.
	text := presenter textPresenter text.
	presenter fileFilterPresenter text: 'gamma'.
	self assert: presenter currentFile equals: alpha.
	self assert: presenter textPresenter text equals: text.
	self assert: (presenter fileNodeOf: alpha) isNil.
	self assert: (self selectedNodeOf: presenter) isNil
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterHidingTheCurrentFileThenNavigatingToAVisibleFileSelectsIt [
	"CURRENT BEHAVIOUR: once the shown file is visible again (here by clicking Next twice up to Delta then Gamma with the filter on gamma) its leaf is selected."

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'gamma'.
	3 timesRepeat: [ presenter nextFile ].
	self assert: presenter currentFile basename equals: 'Gamma.java'.
	self assert: (self selectedNodeOf: presenter) notNil.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterHidingTheCurrentFileThenNextUsesTheCompleteList [
	"CURRENT BEHAVIOUR: Next ignores the filter (documented by nextFile): it shows Beta, which the filter also hides, so the tree still has no selection."

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'gamma'.
	presenter nextFile.
	self assert: presenter currentFile basename equals: 'Beta.java'.
	self assert: (self selectedNodeOf: presenter) isNil.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  b' '    Gamma.java' )
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterKeepingTheCurrentFileKeepsItSelected [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'alpha'.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  a' '    Alpha.java' ).
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterKeepsTheAncestorsOfTheMatchingFiles [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'gamma'.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  b' '    Gamma.java' )
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterKeepsTheTreeUnfolded [
	"src, b, Gamma.java."

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'gamma'.
	self assert: (self rowCountOf: presenter) equals: 3
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterMatchesTheRelativePathNotOnlyTheName [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'SRC/A/'.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  a' '    Alpha.java' '    Beta.java' )
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterTextIsKeptWhenSelectingAnotherVisibleFile [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'a/'.
	self
		selectFile: (self fileNamed: 'Beta.java' of: presenter)
		in: presenter.
	self assert: presenter fileFilterPresenter text equals: 'a/'.
	self assert: presenter currentFile basename equals: 'Beta.java'
]

{ #category : 'tests - filter' }
MMCCoveragePresenterFileTreeTest >> testFilterWithoutMatchEmptiesTheTree [

	| presenter |
	presenter := self builtPresenter.
	presenter fileFilterPresenter text: 'zzz'.
	self assert: presenter fileListPresenter roots isEmpty.
	self assert: (self rowCountOf: presenter) equals: 0
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testFolderLabelIsTheFolderName [

	| presenter |
	presenter := self examplePresenter.
	self
		assert:
		(presenter fileNodeLabelFor: presenter fileListPresenter roots first)
		equals: 'src'.
	self
		assert:
		(self labelOf: presenter fileListPresenter roots first in: presenter)
		equals: 'src'
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testNavigationButtonsMoveTheSelection [

	| presenter |
	presenter := self builtPresenter.
	presenter nextFileButton click.
	self
		assert: (self selectedNodeOf: presenter) file basename
		equals: 'Beta.java'.
	presenter previousFileButton click.
	self
		assert: (self selectedNodeOf: presenter) file basename
		equals: 'Alpha.java'
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testNextFileCrossesFoldersInTheOrderOfTheTree [

	| presenter |
	presenter := self builtPresenter.
	#( 'Beta.java' 'Delta.java' 'Gamma.java' ) do: [ :each |
			presenter nextFile.
			self assert: presenter currentFile basename equals: each.
			self
				assert: (self selectedNodeOf: presenter) file
				equals: presenter currentFile ]
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testNextFileMovesTheSelectionToTheNextLeaf [

	| presenter |
	presenter := self builtPresenter.
	presenter nextFile.
	self assert: presenter currentFile basename equals: 'Beta.java'.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testNextUncoveredFileSelectsItsLeaf [

	| presenter |
	presenter := self builtPresenter.
	presenter nextUncoveredFile.
	self assert: (self selectedNodeOf: presenter) notNil.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testOnlyTheLeavesAreFiles [

	| presenter |
	presenter := self examplePresenter.
	self assert: presenter fileListPresenter roots size equals: 1.
	self assert: presenter fileListPresenter roots first isFolder.
	(presenter fileNodeOf: (self fileNamed: 'Beta.java' of: presenter))
		in: [ :leaf |
				self assert: leaf isFile.
				self assert: leaf children isEmpty ]
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testPreviousAndNextStayOnTheEndsOfTheList [

	| presenter |
	presenter := self builtPresenter.
	presenter previousFile.
	self assert: presenter currentFile basename equals: 'Alpha.java'.
	self deny: presenter previousFileButton isEnabled.
	presenter showFile: (self fileNamed: 'Gamma.java' of: presenter).
	presenter nextFile.
	self assert: presenter currentFile basename equals: 'Gamma.java'.
	self deny: presenter nextFileButton isEnabled
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeTest >> testPreviousFileMovesTheSelectionToThePreviousLeaf [

	| presenter |
	presenter := self builtPresenter.
	presenter showFile: (self fileNamed: 'Gamma.java' of: presenter).
	presenter previousFile.
	self assert: presenter currentFile basename equals: 'Delta.java'.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile.
	presenter previousFile.
	self assert: presenter currentFile basename equals: 'Beta.java'.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile
]

{ #category : 'tests - real window' }
MMCCoveragePresenterFileTreeTest >> testRealWindowShowsTheUnfoldedTreeAndFolderClickKeepsTheFile [
	"Real Morphic window (closed at the end): seven rows, the row of Alpha.java selected at the opening; a click on the folder row src (index 1) does not change the file, a click on the leaf Gamma.java (index 7) shows it."

	| presenter window table alpha text |
	presenter := self examplePresenter.
	alpha := presenter currentFile.
	text := presenter textPresenter text.
	[
		window := presenter open.
		table := presenter fileListPresenter adapter widget.
		self assert: table dataSource numberOfRows equals: 7.
		self assert: table selectedIndex equals: 3.
		table selectIndex: 1.
		self assert: (self selectedNodeOf: presenter) name equals: 'src'.
		self assert: presenter currentFile equals: alpha.
		self assert: presenter textPresenter text equals: text.
		table selectIndex: 7.
		self assert: presenter currentFile basename equals: 'Gamma.java'.
		self
			assert: (self selectedNodeOf: presenter) file
			equals: presenter currentFile ] ensure: [
		window ifNotNil: [ window close ] ]
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testRealigningTheSelectionPutsTheCurrentFileLeafBack [
	"After a click on a folder, the realignment (deferred in a real window) selects the leaf of the current file again."

	| presenter |
	presenter := self builtPresenter.
	presenter fileListPresenter selectPathByItems:
		presenter fileListPresenter roots first pathFromRoot.
	presenter realignFileTreeSelection.
	self assert: (self selectedNodeOf: presenter)
		== (presenter fileNodeOf: presenter currentFile).
	self deny: presenter isSynchronizing
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testRefreshingTheFileListKeepsTheTreeUnfolded [

	| presenter |
	presenter := self builtPresenter.
	presenter refreshFileList.
	self assert: (self rowCountOf: presenter) equals: 7
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testSelectingALeafComputesItAndUpdatesItsLabel [

	| presenter gamma leaf |
	presenter := self builtPresenter.
	gamma := self fileNamed: 'Gamma.java' of: presenter.
	leaf := presenter fileNodeOf: gamma.
	self
		assert: (self labelOf: leaf in: presenter)
		equals: 'Gamma.java  ?'.
	self selectFile: gamma in: presenter.
	self deny: (presenter fileNodeOf: gamma) isNil.
	self
		assert:
			((self labelOf: (presenter fileNodeOf: gamma) in: presenter)
				 endsWith: '%')
		description: 'the label of the shown file is computed'
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testSelectingALeafShowsItsFile [

	| presenter gamma |
	presenter := self builtPresenter.
	gamma := self fileNamed: 'Gamma.java' of: presenter.
	self selectFile: gamma in: presenter.
	self assert: presenter currentFile equals: gamma.
	self assert:
		presenter fileCoverage == (presenter modelFiles coverageFor: gamma).
	self assert: (self selectedNodeOf: presenter) file equals: gamma.
	self deny: presenter isSynchronizing
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testSelectingAnUnreadableLeafDoesNotRaise [

	| presenter delta |
	presenter := self builtPresenter.
	delta := self fileNamed: 'Delta.java' of: presenter.
	self shouldnt: [ self selectFile: delta in: presenter ] raise: Error.
	self assert: presenter currentFile equals: delta
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testSelectionPathGoesThroughTheFolders [

	| presenter |
	presenter := self builtPresenter.
	self
		assert:
			(presenter fileListPresenter selection selectedItemsInPath
				 collect: [ :each | each name ]) asArray
		equals: #( 'src' 'a' 'Alpha.java' )
]

{ #category : 'tests - selection' }
MMCCoveragePresenterFileTreeTest >> testShowFileSelectsTheLeafOfTheFileInANestedFolder [

	| presenter gamma |
	presenter := self builtPresenter.
	gamma := self fileNamed: 'Gamma.java' of: presenter.
	presenter showFile: gamma.
	self assert:
		(self selectedNodeOf: presenter) == (presenter fileNodeOf: gamma).
	self assert: (self selectedNodeOf: presenter) file equals: gamma
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testTreeIsFullyUnfoldedOnceDisplayed [
	"src, a, Alpha, Beta, b, Delta, Gamma: seven rows."

	| presenter |
	presenter := self examplePresenter.
	presenter fileListPresenter build.
	presenter expandFileTree.
	self assert: (self rowCountOf: presenter) equals: 7
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testTreeStructureFollowsTheRelativeNames [
	"Folders then files, alphabetical, nothing compacted (src has the only children a and b)."

	self
		assert: (self outlineOf: self examplePresenter)
		equals:
			#( 'src' '  a' '    Alpha.java' '    Beta.java' '  b' '    Delta.java'
			   '    Gamma.java' )
]

{ #category : 'tests - structure' }
MMCCoveragePresenterFileTreeTest >> testUnfoldingWithoutWidgetIsHarmless [

	| presenter |
	presenter := self examplePresenter.
	self deny: presenter fileListPresenter hasAdapter.
	self shouldnt: [ presenter expandFileTree ] raise: Error.
	self shouldnt: [ presenter deferFileTreeRealignment ] raise: Error.
	self shouldnt: [ presenter realignFileTreeSelection ] raise: Error
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeTest >> unreadableLabel [

	^ (String with: (Character value: 16r26A0)) , ' unreadable'
]
