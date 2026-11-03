"
Tests of MMCFileTreeNode, the node of the file tree of the coverage presenter: construction from relative names, sort (folders first, then alphabetical ignoring case), empty segments, folders versus files and path from the root. The files are plain strings here (the node does not look at them).
"
Class {
	#name : 'MMCFileTreeNodeTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCFileTreeNodeTest >> namesOf: aCollectionOfNodes [

	^ (aCollectionOfNodes collect: [ :each | each name ]) asArray
]

{ #category : 'helpers' }
MMCFileTreeNodeTest >> nodeAt: aPath in: roots [
	"The node reached from roots by the names of aPath."

	| nodes node |
	nodes := roots.
	aPath do: [ :each |
			node := nodes detect: [ :n | n name = each ].
			nodes := node children ].
	^ node
]

{ #category : 'helpers' }
MMCFileTreeNodeTest >> rootsOf: aCollection [
	"Roots of the tree of aCollection of names, each name being its own file."

	^ MMCFileTreeNode rootsOf: aCollection naming: [ :each | each ]
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testAbsolutePathKeepsEveryFolderOfThePath [

	| roots leaf |
	roots := self rootsOf: #( '/abs/dir/file.txt' ).
	self assert: (self namesOf: roots) equals: #( 'abs' ).
	leaf := self nodeAt: #( 'abs' 'dir' 'file.txt' ) in: roots.
	self assert: leaf isFile.
	self assert: leaf file equals: '/abs/dir/file.txt'
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testAddFileSegmentsAnswersTheLeaf [

	| top leaf |
	top := MMCFileTreeNode new.
	leaf := top addFile: #file segments: #( 'src' 'A.java' ).
	self assert: leaf isFile.
	self assert: leaf file equals: #file.
	self assert: leaf name equals: 'A.java'.
	self assert: leaf parent name equals: 'src'.
	self assert: (top folderNamed: 'src') children first == leaf
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testChildrenKnowTheirParent [

	| roots |
	roots := self rootsOf: #( 'a/x' 'a/y' ).
	roots first children do: [ :each |
		self assert: each parent == roots first ]
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testEmptySegmentsAreIgnored [

	| roots |
	roots := self rootsOf: #( 'a//b.txt' '/c.txt' 'd/' ).
	self assert: (self namesOf: roots) equals: #( 'a' 'c.txt' 'd' ).
	self
		assert: (self namesOf: (self nodeAt: #( 'a' ) in: roots) children)
		equals: #( 'b.txt' ).
	self assert: (self nodeAt: #( 'c.txt' ) in: roots) isFile.
	"'d/' has the only segment 'd': a leaf."
	self assert: (self nodeAt: #( 'd' ) in: roots) isFile
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testFileAtTheRootIsALeafAtTopLevel [

	| roots |
	roots := self rootsOf: #( 'only.txt' ).
	self assert: roots size equals: 1.
	self assert: roots first isFile.
	self assert: roots first parent isNil
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testFolderAndFileMayShareTheSameName [

	| roots |
	roots := self rootsOf: #( 'a/b.txt' 'a' ).
	self assert: roots size equals: 2.
	self assert: roots first isFolder.
	self assert: roots last isFile.
	self assert: roots first name equals: roots last name
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testFolderNamedAnswersTheSameFolderAndCreatesItOnce [

	| top folder |
	top := MMCFileTreeNode new.
	folder := top folderNamed: 'src'.
	self assert: (top folderNamed: 'src') == folder.
	self assert: top children size equals: 1.
	self assert: folder parent == top.
	self assert: folder isFolder
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testFoldersAreSortedIgnoringCaseToo [

	| roots |
	roots := self rootsOf: #( 'beta/x' 'Alpha/x' 'gamma/x' ).
	self
		assert: (self namesOf: roots)
		equals: #( 'Alpha' 'beta' 'gamma' )
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testFoldersComeBeforeFiles [

	| roots |
	roots := self rootsOf:
		         #( 'a.txt' 'z/inner.txt' 'b.txt' 'm/inner.txt' ).
	self
		assert: (self namesOf: roots)
		equals: #( 'm' 'z' 'a.txt' 'b.txt' ).
	self assert: roots first isFolder.
	self assert: roots last isFile
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testFoldersComeBeforeFilesInsideAFolderToo [

	| roots |
	roots := self rootsOf: #( 'src/A.java' 'src/sub/B.java' ).
	self
		assert: (self namesOf: roots first children)
		equals: #( 'sub' 'A.java' )
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testIsFileAndIsFolderAreExclusive [

	| roots folder file |
	roots := self rootsOf: #( 'd/f.txt' ).
	folder := roots first.
	file := folder children first.
	self assert: folder isFolder.
	self deny: folder isFile.
	self assert: file isFile.
	self deny: file isFolder
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testLeafKeepsItsFileAndIsNamedByTheLastSegment [

	| roots leaf |
	roots := self rootsOf: #( 'x/y/z.txt' ).
	leaf := self nodeAt: #( 'x' 'y' 'z.txt' ) in: roots.
	self assert: leaf name equals: 'z.txt'.
	self assert: leaf file equals: 'x/y/z.txt'.
	self assert: leaf children isEmpty
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testNamesMadeOfEmptySegmentsOnlyAreSkipped [

	self assert: (self rootsOf: #( '' '/' '///' )) isEmpty
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testNamingBlockGivesTheRelativeName [
	"The tree is built from the names given by the block, not from the files themselves."

	| roots |
	roots := MMCFileTreeNode
		         rootsOf: #( 1 2 )
		         naming: [ :each | 'dir/f' , each printString ].
	self assert: (self namesOf: roots) equals: #( 'dir' ).
	self
		assert:
		(roots first children collect: [ :each | each file ]) asArray
		equals: #( 1 2 )
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testNoFilesGiveNoRoots [

	self assert: (self rootsOf: #(  )) isEmpty
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testPathFromRootOfAFolder [

	| roots folder |
	roots := self rootsOf: #( 'src/a/Alpha.java' ).
	folder := self nodeAt: #( 'src' 'a' ) in: roots.
	self
		assert: (self namesOf: folder pathFromRoot)
		equals: #( 'src' 'a' )
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testPathFromRootOfALeaf [

	| roots leaf |
	roots := self rootsOf: #( 'src/a/Alpha.java' ).
	leaf := self nodeAt: #( 'src' 'a' 'Alpha.java' ) in: roots.
	self
		assert: (self namesOf: leaf pathFromRoot)
		equals: #( 'src' 'a' 'Alpha.java' ).
	self assert: leaf pathFromRoot first == roots first.
	self assert: leaf pathFromRoot last == leaf
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testPathFromRootOfARootIsItself [

	| roots |
	roots := self rootsOf: #( 'src/a.txt' ).
	self assert: roots first pathFromRoot equals: { roots first }
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testPrecedesComparesNamesIgnoringCase [

	| roots |
	roots := self rootsOf: #( 'a' 'B' ).
	self assert: (roots first precedes: roots last).
	self deny: (roots last precedes: roots first)
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testPrecedesPutsFoldersFirst [

	| roots folder file |
	roots := self rootsOf: #( 'z/x' 'a' ).
	folder := roots first.
	file := roots last.
	self assert: (folder precedes: file).
	self deny: (file precedes: folder)
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testPrintOnShowsTheName [

	| roots |
	roots := self rootsOf: #( 'a/b.txt' ).
	self assert: roots first printString equals: 'MMCFileTreeNode(a)'
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testRootsOfBuildsFoldersAndLeaves [

	| roots src a |
	roots := self rootsOf:
		         #( 'src/a/Alpha.java' 'src/a/Beta.java' 'src/b/Gamma.java' ).
	self assert: (self namesOf: roots) equals: #( 'src' ).
	src := roots first.
	self assert: (self namesOf: src children) equals: #( 'a' 'b' ).
	a := src children first.
	self
		assert: (self namesOf: a children)
		equals: #( 'Alpha.java' 'Beta.java' )
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testSameFolderIsSharedByItsFiles [

	| roots |
	roots := self rootsOf: #( 'src/a.txt' 'src/b.txt' ).
	self assert: roots size equals: 1.
	self assert: roots first children size equals: 2
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testSortDoesNotDependOnTheOrderOfTheInput [

	self
		assert: (self namesOf: (self rootsOf: #( 'c' 'a/x' 'b' 'a/w' )))
		equals: (self namesOf: (self rootsOf: #( 'a/w' 'b' 'a/x' 'c' )))
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testSortIsAlphabeticalIgnoringCase [

	| roots |
	roots := self rootsOf: #( 'b.txt' 'C.txt' 'a.txt' 'D.txt' ).
	self
		assert: (self namesOf: roots)
		equals: #( 'a.txt' 'b.txt' 'C.txt' 'D.txt' )
]

{ #category : 'tests' }
MMCFileTreeNodeTest >> testTopLevelNodesHaveNoParent [

	| roots |
	roots := self rootsOf: #( 'a/x' 'b/y' 'c' ).
	roots do: [ :each | self assert: each parent isNil ]
]
