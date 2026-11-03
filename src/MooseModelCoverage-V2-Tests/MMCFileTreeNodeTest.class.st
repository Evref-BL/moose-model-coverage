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
MMCFileTreeNodeTest >> compactedRootsOf: aCollection [
	"Compacted roots of the tree of aCollection of names (each name being its own file)."

	^ MMCFileTreeNode compactedRoots: (self rootsOf: aCollection)
]

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
MMCFileTreeNodeTest >> outlineOf: aCollectionOfNodes [
	"Names of the nodes, depth first, indented by two spaces per level."

	| lines walk |
	lines := OrderedCollection new.
	walk := nil.
	walk := [ :nodes :depth |
		        nodes do: [ :each |
				        lines add:
					        (String new: depth * 2 withAll: Character space)
					        , each name.
				        walk value: each children value: depth + 1 ] ].
	walk value: aCollectionOfNodes value: 0.
	^ lines asArray
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

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactAnswersTheReceiverAndLeavesALeafAlone [

	| roots leaf |
	roots := self rootsOf: #( 'a/b/F.java' ).
	self assert: roots first compact == roots first.
	self assert: roots first name equals: 'a/b'.
	leaf := roots first children first.
	self assert: leaf isFile.
	self assert: leaf compact == leaf.
	self assert: leaf name equals: 'F.java'.
	self assert: leaf children isEmpty
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactIsIdempotent [

	| roots once twice |
	roots := self compactedRootsOf:
		         #( 'src/m/n/F.java' 'src/p/q/r/G.java' 'x/y/H.java'
		            'a.txt' ).
	once := self outlineOf: roots.
	twice := self outlineOf: (MMCFileTreeNode compactedRoots: roots).
	self assert: twice equals: once.
	roots do: [ :each | each compact ].
	self assert: (self outlineOf: roots) equals: once
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactKeepsAFolderHoldingAFileAndAFolder [
	"src holds a file and a folder: the folder is not merged into src."

	| roots |
	roots := self compactedRootsOf: #( 'src/sub/B.java' 'src/A.java' ).
	self
		assert: (self outlineOf: roots)
		equals: #( 'src' '  sub' '    B.java' '  A.java' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactKeepsAFolderWithASingleFile [
	"A folder whose only child is a file keeps its name."

	| roots |
	roots := self compactedRootsOf: #( 'a/F.java' ).
	self assert: (self outlineOf: roots) equals: #( 'a' '  F.java' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactKeepsAFolderWithTwoChildren [
	"src has two folder children: it is not merged with them; each of them holds a file and keeps its name."

	| roots |
	roots := self compactedRootsOf: #( 'src/a/x.txt' 'src/b/y.txt' ).
	self
		assert: (self outlineOf: roots)
		equals: #( 'src' '  a' '    x.txt' '  b' '    y.txt' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactKeepsTheFilesOfTheLeaves [

	| roots |
	roots := self compactedRootsOf: #( 'a/b/F.java' 'a/b/G.java' ).
	self
		assert:
		(roots first children collect: [ :each | each file ]) asArray
		equals: #( 'a/b/F.java' 'a/b/G.java' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactMergesAChainOfSingleFolders [
	"a/b/c/F.java: the folders a, b, c form one folder named a/b/c holding the leaf."

	| roots |
	roots := self compactedRootsOf: #( 'a/b/c/F.java' ).
	self assert: (self outlineOf: roots) equals: #( 'a/b/c' '  F.java' ).
	self assert: roots first isFolder.
	self assert: roots first children first isFile
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactSortsTheChildrenOfAFolderOnTheDisplayedName [

	| roots |
	roots := self compactedRootsOf:
		         #( 'src/m/z/F.java' 'src/m-/G.java' 'src/H.java' ).
	self
		assert: (self namesOf: roots first children)
		equals: #( 'm-' 'm/z' 'H.java' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactSortsTheChildrenOnTheDisplayedName [
	"Before the merge m is before m-; after it m/z (/ is after -) is behind m-, a folder named m-."

	| roots |
	roots := self rootsOf: #( 'm/z/F.java' 'm-/G.java' ).
	self assert: (self namesOf: roots) equals: #( 'm' 'm-' ).
	roots := MMCFileTreeNode compactedRoots: roots.
	self assert: (self namesOf: roots) equals: #( 'm-' 'm/z' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactWorksDeepInTheTree [
	"src has two children so it stays; m/n and p/q/r are merged below it."

	| roots |
	roots := self compactedRootsOf:
		         #( 'src/m/n/F.java' 'src/p/q/r/G.java' ).
	self
		assert: (self outlineOf: roots)
		equals: #( 'src' '  m/n' '    F.java' '  p/q/r' '    G.java' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactedFolderWithTwoFilesKeepsTheMergedName [
	"The chain a/b ends on a folder with two files: a/b holds both."

	| roots |
	roots := self compactedRootsOf: #( 'a/b/F.java' 'a/b/G.java' ).
	self
		assert: (self outlineOf: roots)
		equals: #( 'a/b' '  F.java' '  G.java' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactedRootsAreSortedFoldersFirst [
	"Folders before files, then by displayed name."

	| roots |
	roots := self compactedRootsOf:
		         #( 'z.txt' 'b/c/F.java' 'a.txt' 'a/F.java' 'a-/G.java' ).
	self
		assert: (self namesOf: roots)
		equals: #( 'a' 'a-' 'b/c' 'a.txt' 'z.txt' )
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactedRootsOfAFileAtTheTopLevelIsTheLeaf [

	| roots |
	roots := self compactedRootsOf: #( 'only.txt' ).
	self assert: roots size equals: 1.
	self assert: roots first isFile.
	self assert: roots first name equals: 'only.txt'
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactedRootsReparentsTheMergedChildren [
	"After the merge the leaf points to the merged folder, which is a top level node without parent."

	| roots leaf |
	roots := self compactedRootsOf: #( 'a/b/c/F.java' 'a/b/c/G.java' ).
	self assert: roots first parent isNil.
	roots first children do: [ :each |
		self assert: each parent == roots first ].
	leaf := roots first children first.
	self assert: leaf name equals: 'F.java'
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testCompactedRootsWithoutFilesIsEmpty [

	self assert: (self compactedRootsOf: #(  )) isEmpty
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

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testPathFromRootOfALeafOfACompactedFolder [

	| roots leaf |
	roots := self compactedRootsOf: #( 'src/m/z/F.java' 'src/n/G.java' ).
	leaf := roots first children first children first.
	self assert: leaf name equals: 'F.java'.
	self
		assert: (self namesOf: leaf pathFromRoot)
		equals: #( 'src' 'm/z' 'F.java' ).
	self assert: leaf pathFromRoot first == roots first.
	self assert: leaf pathFromRoot last == leaf
]

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testPathFromRootOfALeafUnderACompactedRoot [

	| roots leaf |
	roots := self compactedRootsOf: #( 'a/b/c/F.java' ).
	leaf := roots first children first.
	self
		assert: (self namesOf: leaf pathFromRoot)
		equals: #( 'a/b/c' 'F.java' ).
	self assert: leaf pathFromRoot first == roots first
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

{ #category : 'tests - compact' }
MMCFileTreeNodeTest >> testRootsOfNamingDoesNotCompact [
	"The tree built by rootsOf:naming: keeps one folder per segment."

	self
		assert: (self outlineOf: (self rootsOf: #( 'a/b/c/F.java' )))
		equals: #( 'a' '  b' '    c' '      F.java' )
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
