"
Non regression tests of the scroll position of the file tree (Files panel) of MMCCoveragePresenter. Bug: a click on a file that was not computed yet rebuilt the roots of the tree (refreshFileList: roots:, expandAll, reselection) and FastTable put the scroll back at the top (showIndex 900 -> 1). Now showFile: -> loadFile:keepingFileTree: true -> refreshFileLabels only refreshes the labels of the existing widget, and scrolls (ensureVisibleFirstSelection) only when the selection has to move (navigation) and the row is not fully visible. The tree is still rebuilt by a filter change, by setRootFolder: and when the file is not in the tree.
Fixture: real readable files top/mid/dK/F<i>.java (12 characters, an entity on characters 1-5, so a computed file is 41.7 %) in a temporary folder under FileLocator temp, deleted in tearDown, in a FamixJavaModel created by the tests. The tests with a real window run with a watchdog process (30 s) and close the window in ensure:; windows are also closed in tearDown. Sorted order: by full relative path (d0, d1, d10, ...).
"
Class {
	#name : 'MMCCoveragePresenterFileTreeScrollTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model',
		'presenters'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> assertLabelOf: aFile in: aPresenter equals: aString [
	"The label of the model (fileNodeLabelFor:) of the leaf of aFile."

	self
		assert:
		(aPresenter fileNodeLabelFor: (aPresenter fileNodeOf: aFile))
		equals: aString
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeScrollTest >> assertSelectionFollowsCurrentFileOf: aPresenter at: anIndex [
	"After a navigation step: the current file is the one at anIndex of the sorted list, the selected leaf and the selected FastTable row are those of the current file, nothing else is selected, and the row is fully visible."

	| table node row |
	self waitUpTo: 300 until: [ false ].
	table := self tableOf: aPresenter.
	node := aPresenter fileNodeOf: aPresenter currentFile.
	row := self rowOf: aPresenter currentFile in: aPresenter.
	self assert: aPresenter currentFileIndex equals: anIndex.
	self
		assert: aPresenter currentFile
		equals: (aPresenter modelFiles files at: anIndex).
	self assert:
		aPresenter fileListPresenter selection selectedItem == node.
	self assert: row > 0.
	self assert: table selectedIndex equals: row.
	self assert: table selectedIndexes size equals: 1.
	self assert: (table container isRowIndexFullyVisible: row)
]

{ #category : 'fixture' }
MMCCoveragePresenterFileTreeScrollTest >> buildFixtureOf: aCount [
	"aCount readable files top/mid/dK/F<i>.java (K = i \\ 20, 12 characters), each with one entity on the characters 1-5: a computed file is 41.7 % covered."

	1 to: aCount do: [ :i |
			| relative reference entity anchor |
			relative := 'top/mid/d' , (i \\ 20) printString , '/F'
			            , i printString , '.java'.
			reference := folder resolve: relative.
			reference parent ensureCreateDirectory.
			reference binaryWriteStreamDo: [ :stream |
				stream nextPutAll: 'xxxxxxxxxxxx' utf8Encoded ].
			entity := FamixJavaClass new.
			entity name: 'C' , i printString.
			model add: entity.
			anchor := FamixJavaIndexedFileAnchor new.
			anchor fileName: relative.
			anchor startPos: 1.
			anchor endPos: 5.
			model add: anchor.
			entity sourceAnchor: anchor ]
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> builtPresenterOf: aCount [
	"Presenter on aCount files whose file tree widget is built (no window)."

	| presenter |
	self buildFixtureOf: aCount.
	presenter := self newPresenter.
	presenter fileListPresenter build.
	^ presenter
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> clickFile: aFile in: aPresenter [
	"Click on the row of aFile in the real widget (the way of the user)."

	(self tableOf: aPresenter) selectIndex:
		(self rowOf: aFile in: aPresenter)
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> displayedLabelOf: aFile in: aPresenter [
	"Text really drawn in the row morph of aFile (nil when the row is not exposed)."

	| row morph |
	row := self rowOf: aFile in: aPresenter.
	morph := (self tableOf: aPresenter) container
		         visibleRowMorphAtIndex: row.
	morph ifNil: [ ^ nil ].
	^ (morph allMorphs
		   detect: [ :each | each isKindOf: StringMorph ]
		   ifNone: [ ^ nil ]) contents asString
]

{ #category : 'fixture' }
MMCCoveragePresenterFileTreeScrollTest >> newPresenter [
	"Presenter on the inventory of the model, closed in tearDown."

	^ presenters add: (MMCCoveragePresenter forModel: model)
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> nodesOf: aPresenter [
	"Leaves of the file tree, in the order of the complete sorted list of files."

	^ aPresenter modelFiles files collect: [ :each |
		  aPresenter fileNodeOf: each ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> rowOf: aFile in: aPresenter [
	"Row index of the leaf of aFile in the FastTable of the file tree (0 when it has none)."

	| node source |
	node := aPresenter fileNodeOf: aFile.
	source := (self tableOf: aPresenter) dataSource.
	^ (1 to: source numberOfRows)
		  detect: [ :each | (source elementAt: each) data == node ]
		  ifNone: [ 0 ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> scrollTo: aRow in: aPresenter [
	"Scroll the FastTable so that aRow is the first shown row, and let Morphic settle."

	| table |
	table := self tableOf: aPresenter.
	table verticalScrollBarValue:
		(table rowIndexToVerticalScrollBarValue: aRow).
	self waitUpTo: 300 until: [ false ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> selectedFileOf: aPresenter [
	"File of the selected leaf of the file tree (nil when nothing or a folder is selected)."

	^ aPresenter fileListPresenter selection selectedItem ifNotNil: [
		  :node | node isFolder ifFalse: [ node file ] ]
]

{ #category : 'fixture' }
MMCCoveragePresenterFileTreeScrollTest >> setUp [
	"Temporary folder (the root folder of the model) and an empty model."

	super setUp.
	folder := FileLocator temp / ('mmc-filescroll-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	presenters := OrderedCollection new
]

{ #category : 'tests - real window' }
MMCCoveragePresenterFileTreeScrollTest >> summaryTextFor: aTotal computed: aCount [
	"Expected global summary when every computed file is 41.7 % covered."

	| separator |
	separator := ' ' , (String with: (Character value: 16rB7)) , ' '.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Files: ';
				  print: aTotal;
				  nextPutAll: separator;
				  nextPutAll: 'computed ';
				  print: aCount;
				  nextPut: $/;
				  print: aTotal;
				  nextPutAll: separator;
				  nextPutAll: 'covered 41.7%' ]
]

{ #category : 'helpers' }
MMCCoveragePresenterFileTreeScrollTest >> tableOf: aPresenter [
	"The FastTable of the file tree (the real widget)."

	^ aPresenter fileListPresenter adapter widget
]

{ #category : 'fixture' }
MMCCoveragePresenterFileTreeScrollTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests - real window' }
MMCCoveragePresenterFileTreeScrollTest >> testClickingAnUncomputedFileKeepsTheScrollInARealWindow [
	"Non regression: with 2000 files, scrolled far down (row 900), a click on a visible file not computed yet leaves the scroll where it is (it was put back to row 1), turns its label from ? to 41.7%, updates the global summary, and the selected row is the clicked file (the row of the previous file is not selected any more)."

	| presenter source file before row oldFile oldRow |
	self buildFixtureOf: 2000.
	presenter := self newPresenter.
	oldFile := presenter currentFile.
	self withWindowOf: presenter do: [ :table |
			source := table dataSource.
			oldRow := self rowOf: oldFile in: presenter.
			self scrollTo: 900 in: presenter.
			before := table showIndex.
			self assert: before > 800.
			row := (before + 2 to: before + 8) detect: [ :each |
				       (source elementAt: each) data isFolder not ].
			file := (source elementAt: row) data file.
			self assert: (presenter fileCoverageInfoFor: file) equals: '?'.
			self
				assert: (self displayedLabelOf: file in: presenter)
				equals: (presenter fileNodeOf: file) name , '  ?'.
			self
				assert: presenter filesSummaryPresenter label
				equals: (self summaryTextFor: 2000 computed: 1).

			self clickFile: file in: presenter.
			self waitUpTo: 500 until: [ false ].

			self assert: table showIndex equals: before.
			self assert: presenter currentFile equals: file.
			self assert: (self selectedFileOf: presenter) equals: file.
			self assert: table selectedIndex equals: row.
			self assert: table selectedIndexes size equals: 1.
			self deny: (table isIndexSelected: oldRow).
			self assert: (presenter fileCoverageInfoFor: file) equals: '41.7%'.
			self
				assert: (self displayedLabelOf: file in: presenter)
				equals: (presenter fileNodeOf: file) name , '  41.7%'.
			self
				assert: presenter filesSummaryPresenter label
				equals: (self summaryTextFor: 2000 computed: 2) ]
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeScrollTest >> testComputeAllKeepsTheScrollAndUpdatesEveryLabel [
	"500 files, real window scrolled down: Compute all keeps the scroll, the current file and its selected row, labels every file at 41.7% (model and drawn row) and the summary counts all the files."

	| presenter before current row |
	self buildFixtureOf: 500.
	presenter := self newPresenter.
	self withWindowOf: presenter do: [ :table |
			self scrollTo: 300 in: presenter.
			before := table showIndex.
			self assert: before > 250.
			current := presenter currentFile.
			row := self rowOf: current in: presenter.
			self
				assert: presenter filesSummaryPresenter label
				equals: (self summaryTextFor: 500 computed: 1).

			presenter computeAllFiles.
			self waitUpTo: 300 until: [ false ].

			self assert: table showIndex equals: before.
			self assert: presenter currentFile equals: current.
			self assert: table selectedIndex equals: row.
			self
				assert: presenter fileListPresenter selection selectedItem
				equals: (presenter fileNodeOf: current).
			presenter modelFiles files do: [ :each |
				self assert: (presenter fileCoverageInfoFor: each) equals: '41.7%' ].
			presenter modelFiles files do: [ :each |
					self
						assert:
						(presenter fileNodeLabelFor: (presenter fileNodeOf: each))
						equals: (presenter fileNodeOf: each) name , '  41.7%' ].
			(before to: before + 4) do: [ :index |
					| node |
					node := (table dataSource elementAt: index) data.
					node isFolder ifFalse: [
							self
								assert: (self displayedLabelOf: node file in: presenter)
								equals: node name , '  41.7%' ] ].
			self
				assert: presenter filesSummaryPresenter label
				equals: (self summaryTextFor: 500 computed: 500) ]
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> testFilterChangeRebuildsTheRoots [
	"The roots are rebuilt (new collection, new nodes) after a change of the file filter, as before the fix."

	| presenter roots node |
	presenter := self builtPresenterOf: 300.
	roots := presenter fileListPresenter roots.
	node := presenter fileNodeOf: presenter currentFile.

	presenter fileFilterPresenter text: 'd0/'.

	self deny: presenter fileListPresenter roots == roots.
	self deny: (presenter fileNodeOf: presenter currentFile) == node.
	self assert: (presenter fileNodeOf: presenter currentFile) notNil
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> testLoadFileKeepingTheFileTreeFalseRebuildsTheRoots [
	"loadFile:keepingFileTree: false rebuilds the tree even for a file present in it (what loadFile: does)."

	| presenter roots |
	presenter := self builtPresenterOf: 300.
	roots := presenter fileListPresenter roots.

	presenter
		loadFile: (presenter modelFiles files at: 7)
		keepingFileTree: false.

	self deny: presenter fileListPresenter roots == roots.
	self
		assert: presenter currentFile
		equals: (presenter modelFiles files at: 7).
	self
		assert: presenter fileListPresenter selection selectedItem
		equals: (presenter fileNodeOf: presenter currentFile)
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> testLoadFileOfAFileHiddenByTheFilterRebuildsTheTreeWithoutError [
	"loadFile:keepingFileTree: true with a file absent from the tree (hidden by the filter) falls back to the complete refresh (documented): the roots are rebuilt, the file becomes the current one, nothing is selected in the tree (no leaf), no error, and the summary counts the file."

	| presenter roots target |
	presenter := self builtPresenterOf: 300.
	target := presenter modelFiles files last.
	presenter fileFilterPresenter text: 'd0/'.
	self assert: (presenter fileNodeOf: target) isNil.
	roots := presenter fileListPresenter roots.

	presenter loadFile: target keepingFileTree: true.

	self assert: presenter currentFile equals: target.
	self assert: (presenter fileNodeOf: target) isNil.
	self deny: presenter fileListPresenter roots == roots.
	self assert: presenter fileListPresenter selection selectedItem isNil.
	self
		assert: presenter fileFilterPresenter text asString
		equals: 'd0/'.
	self
		assert: presenter filesSummaryPresenter label
		equals: (self summaryTextFor: 300 computed: 2)
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeScrollTest >> testNavigationSequenceKeepsTheSelectedRowOnTheCurrentFile [
	"300 files, real window: open, next, next, previous, next uncovered, showFile: far away, previous. After each step the current file is the expected one and the selected row is its row, visible."

	| presenter |
	self buildFixtureOf: 300.
	presenter := self newPresenter.
	self withWindowOf: presenter do: [ :table |
			self assertSelectionFollowsCurrentFileOf: presenter at: 1.
			presenter nextFile.
			self assertSelectionFollowsCurrentFileOf: presenter at: 2.
			presenter nextFile.
			self assertSelectionFollowsCurrentFileOf: presenter at: 3.
			presenter previousFile.
			self assertSelectionFollowsCurrentFileOf: presenter at: 2.
			presenter nextUncoveredFile.
			self assertSelectionFollowsCurrentFileOf: presenter at: 3.
			presenter showFile: (presenter modelFiles files at: 250).
			self assertSelectionFollowsCurrentFileOf: presenter at: 250.
			presenter previousFile.
			self assertSelectionFollowsCurrentFileOf: presenter at: 249 ]
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeScrollTest >> testRefreshFileLabelsAndShowFileWithoutWidgetDoNotRaise [
	"No widget (presenter never built nor opened, nothing to refresh): refreshFileLabels and showFile: raise no error, the current file is the shown one, and the labels of the model are right: ? for the files not computed, 41.7% for the computed ones."

	| presenter first second |
	self buildFixtureOf: 50.
	presenter := self newPresenter.
	self deny: presenter fileListPresenter hasAdapter.
	first := presenter currentFile.
	second := presenter modelFiles files at: 7.

	presenter refreshFileLabels.
	self
		assertLabelOf: second
		in: presenter
		equals: (presenter fileNodeOf: second) name , '  ?'.

	presenter showFile: second.

	self assert: presenter currentFile equals: second.
	self
		assertLabelOf: second
		in: presenter
		equals: (presenter fileNodeOf: second) name , '  41.7%'.
	self
		assertLabelOf: first
		in: presenter
		equals: (presenter fileNodeOf: first) name , '  41.7%'.
	self
		assertLabelOf: (presenter modelFiles files at: 20)
		in: presenter
		equals:
			(presenter fileNodeOf: (presenter modelFiles files at: 20)) name
			, '  ?'.
	presenter refreshFileLabels.
	presenter computeAllFiles.
	presenter nextFile.
	self
		assert: presenter currentFile
		equals: (presenter modelFiles files at: 8).
	self
		assert: presenter filesSummaryPresenter label
		equals: (self summaryTextFor: 50 computed: 50)
]

{ #category : 'tests - real window' }
MMCCoveragePresenterFileTreeScrollTest >> testSelectingAFarUncomputedFileThroughTheSelectionShowsItWithoutStaleRow [
	"With 2000 files, selecting by path (the way of the handler) a file far away from the visible rows shows it: current file, selected row and label are the ones of the file, nothing else is selected, and the summary counts it."

	| presenter file oldFile oldRow |
	self buildFixtureOf: 2000.
	presenter := self newPresenter.
	oldFile := presenter currentFile.
	self withWindowOf: presenter do: [ :table |
			oldRow := self rowOf: oldFile in: presenter.
			self scrollTo: 900 in: presenter.
			file := presenter modelFiles files at: 1500.
			self assert: (presenter fileCoverageInfoFor: file) equals: '?'.

			presenter fileListPresenter selectPathByItems:
				(presenter fileNodeOf: file) pathFromRoot.
			self waitUpTo: 500 until: [ false ].

			self assert: presenter currentFile equals: file.
			self assert: (self selectedFileOf: presenter) equals: file.
			self
				assert: table selectedIndex
				equals: (self rowOf: file in: presenter).
			self assert: table selectedIndexes size equals: 1.
			self deny: (table isIndexSelected: oldRow).
			self assert: (presenter fileCoverageInfoFor: file) equals: '41.7%'.
			self
				assert: presenter filesSummaryPresenter label
				equals: (self summaryTextFor: 2000 computed: 2).
			self assert: table showIndex > 1 ]
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> testSetRootFolderRebuildsTheRoots [
	"setRootFolder: always rebuilds the tree (loadFile: does not keep the file tree): new roots collection and new nodes."

	| presenter roots node |
	presenter := self builtPresenterOf: 300.
	roots := presenter fileListPresenter roots.
	node := presenter fileNodeOf: presenter currentFile.

	presenter setRootFolder: folder.

	self deny: presenter fileListPresenter roots == roots.
	self deny: (presenter fileNodeOf: presenter currentFile) == node.
	self assert: (presenter fileNodeOf: presenter currentFile) notNil
]

{ #category : 'tests - roots' }
MMCCoveragePresenterFileTreeScrollTest >> testShowFileKeepsTheSameRootsAndNodes [
	"Proof that the tree is not rebuilt: after showFile: of a file present in the tree (and Next, Previous, Next uncovered), the roots are the very same collection and every leaf is the very same node."

	| presenter roots nodes |
	presenter := self builtPresenterOf: 300.
	roots := presenter fileListPresenter roots.
	nodes := self nodesOf: presenter.
	self assert: (nodes allSatisfy: #notNil).

	presenter showFile: (presenter modelFiles files at: 5).
	presenter nextFile.
	presenter nextUncoveredFile.
	presenter previousFile.

	self
		assert: presenter currentFile
		equals: (presenter modelFiles files at: 6).
	self assert: presenter fileListPresenter roots == roots.
	self assert: nodes size equals: 300.
	nodes
		with: (self nodesOf: presenter)
		do: [ :before :after | self assert: after == before ]
]

{ #category : 'tests - navigation' }
MMCCoveragePresenterFileTreeScrollTest >> testShowFileOfAnOffscreenFileScrollsToMakeItVisible [
	"300 files, real window at the top: showFile: of a far file below scrolls the tree so that its row is fully visible; showFile: of a file above, after scrolling down, scrolls back; showFile: of a file already visible does not scroll."

	| presenter far near visibleFile |
	self buildFixtureOf: 300.
	presenter := self newPresenter.
	self withWindowOf: presenter do: [ :table |
			self assert: table showIndex equals: 1.
			far := presenter modelFiles files at: 250.
			self deny: (table container isRowIndexFullyVisible:
					 (self rowOf: far in: presenter)).

			presenter showFile: far.
			self waitUpTo: 300 until: [ false ].
			self assert: (table container isRowIndexFullyVisible:
					 (self rowOf: far in: presenter)).
			self assert: table showIndex > 1.

			self scrollTo: 300 in: presenter.
			near := presenter modelFiles files at: 5.
			self deny: (table container isRowIndexFullyVisible:
					 (self rowOf: near in: presenter)).
			presenter showFile: near.
			self waitUpTo: 300 until: [ false ].
			self assert: (table container isRowIndexFullyVisible:
					 (self rowOf: near in: presenter)).
			self assert: presenter currentFile equals: near.

			visibleFile := (table dataSource elementAt: table showIndex + 2)
				               data.
			visibleFile isFolder ifFalse: [
					| before |
					before := table showIndex.
					presenter showFile: visibleFile file.
					self waitUpTo: 300 until: [ false ].
					self assert: table showIndex equals: before.
					self assert: presenter currentFile equals: visibleFile file ] ]
]

{ #category : 'fixture' }
MMCCoveragePresenterFileTreeScrollTest >> waitUpTo: someMilliseconds until: aBlock [
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
MMCCoveragePresenterFileTreeScrollTest >> withWindowOf: aPresenter do: aBlock [
	"Skipped without World. Open aPresenter, let it settle, evaluate aBlock with the FastTable of the file tree. A watchdog process raises an error in the test process after 30 s (never blocked longer); the window is always closed."

	| window watchdog testProcess |
	World ifNil: [ self skip: 'no world' ].
	testProcess := Processor activeProcess.
	watchdog := [
		            (Delay forSeconds: 30) wait.
		            testProcess signalException:
			            (Error new messageText:
				             'test did not finish within 30 s (freeze)') ]
		            forkAt: Processor userInterruptPriority.
	[
		window := aPresenter open.
		self waitUpTo: 500 until: [ false ].
		aBlock value: (self tableOf: aPresenter) ] ensure: [
			watchdog terminate.
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ]
]
