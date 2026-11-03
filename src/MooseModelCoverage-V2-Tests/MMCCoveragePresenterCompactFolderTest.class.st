"
Tests of the compact folders of the file tree of MMCCoveragePresenter (chains of folders with a single folder child merged, as in VSCode): tree built from fictive files with relative anchors written in a temporary folder.
"
Class {
	#name : 'MMCCoveragePresenterCompactFolderTest',
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
MMCCoveragePresenterCompactFolderTest >> addFile: aRelativeName [
	"Write a 20 characters file in the folder and add to the model a class anchored on its 10 first characters (relative file name)."

	| ref entity anchor |
	ref := folder resolve: aRelativeName.
	ref parent ensureCreateDirectory.
	ref ensureDelete.
	ref binaryWriteStreamDo: [ :s |
		s nextPutAll: (String new: 20 withAll: $x) utf8Encoded ].
	entity := FamixJavaClass new.
	entity name: 'C' , aRelativeName size printString
		, (aRelativeName copyReplaceAll: '/' with: '_').
	model add: entity.
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aRelativeName.
	anchor startPos: 1.
	anchor endPos: 10.
	model add: anchor.
	entity sourceAnchor: anchor
]

{ #category : 'helpers' }
MMCCoveragePresenterCompactFolderTest >> fileNamed: aBasename of: aPresenter [

	^ aPresenter modelFiles files detect: [ :each |
		  each basename = aBasename ]
]

{ #category : 'helpers' }
MMCCoveragePresenterCompactFolderTest >> outlineOf: aPresenter [
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
MMCCoveragePresenterCompactFolderTest >> presenterOn: aCollectionOfNames [
	"Not opened presenter on the files named by aCollectionOfNames (relative names), closed in tearDown."

	^ self presenterOn: aCollectionOfNames class: MMCCoveragePresenter
]

{ #category : 'helpers' }
MMCCoveragePresenterCompactFolderTest >> presenterOn: aCollectionOfNames class: aClass [

	| presenter |
	aCollectionOfNames do: [ :each | self addFile: each ].
	presenter := aClass forModel: model.
	presenters add: presenter.
	presenter fileListPresenter build.
	presenter expandFileTree.
	^ presenter
]

{ #category : 'helpers' }
MMCCoveragePresenterCompactFolderTest >> selectedNodeOf: aPresenter [

	^ aPresenter fileListPresenter selection selectedItem
]

{ #category : 'running' }
MMCCoveragePresenterCompactFolderTest >> setUp [
	"Temporary folder (right root folder of the model), empty model, no presenter."

	super setUp.
	folder := FileLocator temp / ('mmc-compact-' , UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference.
	presenters := OrderedCollection new
]

{ #category : 'running' }
MMCCoveragePresenterCompactFolderTest >> tearDown [
	"Close every window opened by a test, then delete the temporary folder."

	presenters do: [ :each |
			[ each window ifNotNil: [ :aWindow | aWindow close ] ]
				on: Error
				do: [ :e | e return ] ].
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testClickingACompactedFolderDoesNotChangeTheFileNorTheText [

	| presenter file text |
	presenter := self presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	file := presenter currentFile.
	text := presenter textPresenter text.
	presenter fileListPresenter selectPathByItems:
		{ presenter fileListPresenter roots first }.
	self assert: (self selectedNodeOf: presenter) name equals: 'a/b/c'.
	self assert: presenter currentFile equals: file.
	self assert: presenter textPresenter text equals: text.
	"A leaf of the compacted folder is still shown when clicked."
	presenter fileListPresenter selectPathByItems:
		(presenter fileNodeOf: (self fileNamed: 'G.java' of: presenter))
			pathFromRoot.
	self assert: presenter currentFile basename equals: 'G.java'
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testCompactFoldersIsTrueByDefault [

	self assert: (self presenterOn: #( 'a/F.java' )) compactFolders
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testComputeAllKeepsTheCompactedTreeAndTheSelection [

	| presenter |
	presenter := self presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	presenter computeAllFiles.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'a/b/c' '  F.java' '  G.java' ).
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile.
	presenter fileFilterPresenter text: 'G.j'.
	presenter computeAllFiles.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'a/b/c' '  G.java' )
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testCurrentFileLeafIsSelectedInACompactedTree [

	| presenter node |
	presenter := self presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	node := self selectedNodeOf: presenter.
	self assert: node notNil.
	self assert: node isFile.
	self assert: node file equals: presenter currentFile.
	self assert: node parent name equals: 'a/b/c'.
	self assert: node == (presenter fileNodeOf: presenter currentFile)
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testFilterRecompactsTheTree [
	"The filter keeps one file: its folders form a single chain, merged; clearing the filter restores the whole tree."

	| presenter |
	presenter := self presenterOn: #( 'src/a/F.java' 'src/b/G.java' ).
	presenter fileFilterPresenter text: 'a/F'.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src/a' '  F.java' ).
	presenter fileFilterPresenter text: 'G.java'.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src/b' '  G.java' ).
	presenter fileFilterPresenter text: ''.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  a' '    F.java' '  b' '    G.java' )
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testFilterWithoutMatchGivesAnEmptyTree [

	| presenter |
	presenter := self presenterOn: #( 'a/b/F.java' ).
	presenter fileFilterPresenter text: 'zzz'.
	self assert: (self outlineOf: presenter) isEmpty
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testFlagAtFalseGivesTheUncompactedTree [

	| presenter |
	presenter := self
		             presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' )
		             class: MMCUncompactedFoldersPresenter.
	self deny: presenter compactFolders.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'a' '  b' '    c' '      F.java' '      G.java' )
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testFolderWithTwoFolderChildrenIsNotMerged [

	| presenter |
	presenter := self presenterOn: #( 'src/a/F.java' 'src/b/G.java' ).
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  a' '    F.java' '  b' '    G.java' )
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testNextAndPreviousMoveTheSelectionInACompactedTree [

	| presenter |
	presenter := self presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	self assert: presenter currentFile basename equals: 'F.java'.
	presenter nextFile.
	self assert: presenter currentFile basename equals: 'G.java'.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile.
	self
		assert:
			((self selectedNodeOf: presenter) pathFromRoot collect: [ :each |
				 each name ])
		equals: #( 'a/b/c' 'G.java' ) asOrderedCollection asArray.
	presenter previousFile.
	self assert: presenter currentFile basename equals: 'F.java'.
	self
		assert: (self selectedNodeOf: presenter) file
		equals: presenter currentFile.
	self
		assert: (self outlineOf: presenter)
		equals: #( 'a/b/c' '  F.java' '  G.java' )
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testOnlyTheChainsAreMergedInAMixedTree [
	"src has a file and the chain x/y: src is kept, x/y is merged."

	| presenter |
	presenter := self presenterOn: #( 'src/x/y/F.java' 'src/H.java' ).
	self
		assert: (self outlineOf: presenter)
		equals: #( 'src' '  x/y' '    F.java' '  H.java' )
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testOpenOnTwoThousandFilesWithACompactedChainIsFast [
	"2000 files in 20 folders under top/mid: the chain top/mid is merged (1 + 20 + 2000 rows). Real window, watchdog of 30 s, opening below 3 s, closed in ensure:."

	| names presenter window watchdog testProcess milliseconds node |
	World ifNil: [ self skip: 'no world' ].
	names := (1 to: 2000) collect: [ :i |
		         'top/mid/d' , (i \\ 20) printString , '/f' , i printString
		         , '.txt' ].
	names do: [ :each | self addFile: each ].
	presenter := MMCCoveragePresenter forModel: model.
	presenters add: presenter.
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
			assert: presenter fileListPresenter roots first name
			equals: 'top/mid'.
		self
			assert:
			presenter fileListPresenter adapter widget dataSource numberOfRows
			equals: 2021.
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

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testRealWindowShowsTheCompactedTreeAndFolderClickKeepsTheFile [
	"Real window (closed in ensure:): three rows (a/b/c, F.java, G.java), the leaf of F.java selected; a click on the folder row does not change the file, a click on G.java shows it."

	| presenter window table file text |
	World ifNil: [ self skip: 'no world' ].
	presenter := self presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	file := presenter currentFile.
	text := presenter textPresenter text.
	[
		window := presenter open.
		table := presenter fileListPresenter adapter widget.
		self assert: table dataSource numberOfRows equals: 3.
		self assert: table selectedIndex equals: 2.
		table selectIndex: 1.
		self assert: (self selectedNodeOf: presenter) name equals: 'a/b/c'.
		self assert: presenter currentFile equals: file.
		self assert: presenter textPresenter text equals: text.
		table selectIndex: 3.
		self assert: presenter currentFile basename equals: 'G.java'.
		self
			assert: (self selectedNodeOf: presenter) file
			equals: presenter currentFile ] ensure: [
			window ifNotNil: [
					[ window close ]
						on: Error
						do: [ :e | e return ] ] ]
]

{ #category : 'tests' }
MMCCoveragePresenterCompactFolderTest >> testSingleChainOfFoldersIsOneRow [
	"a/b/c/F.java and a/b/c/G.java: the folder row is a/b/c."

	| presenter |
	presenter := self presenterOn: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	self
		assert: (self outlineOf: presenter)
		equals: #( 'a/b/c' '  F.java' '  G.java' ).
	self assert: presenter fileListPresenter roots size equals: 1
]
