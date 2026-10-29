"
Tests of MMCFileMatcher and its subclasses MMCCanonicalPathMatcher and MMCSuffixPathMatcher.
"
Class {
	#name : 'MMCFileMatcherTest',
	#superclass : 'TestCase',
	#instVars : [
		'folder',
		'model'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCFileMatcherTest >> anchorOn: aFileName [
	"Answer an indexed anchor on aFileName (relative to the model rootFolder, or absolute), added to the model."
	| anchor |
	anchor := FamixJavaIndexedFileAnchor new.
	anchor fileName: aFileName.
	anchor startPos: 1.
	anchor endPos: 1.
	model add: anchor.
	^ anchor
]

{ #category : 'running' }
MMCFileMatcherTest >> setUp [
	super setUp.
	folder := FileLocator temp / ('mmc-v2-', UUID new asString).
	folder ensureCreateDirectory.
	model := FamixJavaModel new.
	model rootFolder: folder asFileReference
]

{ #category : 'running' }
MMCFileMatcherTest >> tearDown [
	folder ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MMCFileMatcherTest >> testAbstractMatcherMatchesAnchorIsSubclassResponsibility [

	| tmp1 |
	self writeFile: 'a.txt'.
	tmp1 := self anchorOn: 'a.txt'.
	self
		should: [ MMCFileMatcher new matchesAnchor: tmp1 ]
		raise: SubclassResponsibility
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherAcceptsTargetAsString [

	| tmp1 tmp2 |
	tmp2 := self writeFile: 'a.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: tmp2 pathString.
	self assert: (tmp1 matchesAnchor: (self anchorOn: 'a.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherDoesNotMatchBySubstring [

	| tmp1 |
	self
		writeFile: 'a.txt';
		writeFile: 'data.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: folder / 'a.txt'.
	self deny: (tmp1 matchesAnchor: (self anchorOn: 'data.txt')).
	tmp1 := MMCCanonicalPathMatcher forFile: folder / 'data.txt'.
	self deny: (tmp1 matchesAnchor: (self anchorOn: 'a.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherDoesNotMixSameBasenameInDifferentFolders [

	| tmp1 tmp2 tmp3 tmp4 |
	self
		writeFile: 'a/Foo.txt';
		writeFile: 'b/Foo.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: folder / 'a' / 'Foo.txt'.
	tmp2 := MMCCanonicalPathMatcher forFile: folder / 'b' / 'Foo.txt'.
	tmp3 := self anchorOn: 'a/Foo.txt'.
	tmp4 := self anchorOn: 'b/Foo.txt'.
	self
		assert: (tmp1 matchesAnchor: tmp3);
		deny: (tmp1 matchesAnchor: tmp4);
		assert: (tmp2 matchesAnchor: tmp4);
		deny: (tmp2 matchesAnchor: tmp3)
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherMatchesAnchorWithAbsoluteFileName [

	| tmp1 tmp2 |
	tmp2 := self writeFile: 'sub/a.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: tmp2.
	self assert: (tmp1 matchesAnchor: (self anchorOn: tmp2 pathString))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherMatchesAnchorWithRelativeFileName [

	| tmp1 |
	self writeFile: 'sub/a.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: folder / 'sub' / 'a.txt'.
	self assert: (tmp1 matchesAnchor: (self anchorOn: 'sub/a.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherNormalizesNonNormalizedAnchorPath [

	| tmp1 |
	self writeFile: 'sub/a.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: folder / 'sub' / 'a.txt'.
	self assert:
		(tmp1 matchesAnchor: (self anchorOn: './sub/../sub/a.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherNormalizesNonNormalizedTargetPath [

	| tmp1 |
	self writeFile: 'sub/a.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile:
		        folder pathString , '/./sub/../sub/a.txt'.
	self assert: (tmp1 matchesAnchor: (self anchorOn: 'sub/a.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherRelativeAndAbsoluteAnchorsMatchSameTarget [

	| tmp1 tmp2 |
	tmp2 := self writeFile: 'sub/a.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: tmp2.
	self
		assert: (tmp1 matchesAnchor: (self anchorOn: 'sub/a.txt'));
		assert: (tmp1 matchesAnchor: (self anchorOn: tmp2 pathString))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testCanonicalMatcherWithMissingTargetDoesNotRaise [

	| tmp1 |
	self writeFile: 'other.txt'.
	tmp1 := MMCCanonicalPathMatcher forFile: folder / 'missing.txt'.
	self
		deny: (tmp1 matchesAnchor: (self anchorOn: 'other.txt'));
		assert: (tmp1 matchesAnchor: (self anchorOn: 'missing.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherAcceptsBackslashSeparators [

	| tmp1 |
	self
		writeFile: 'x/a/Foo.txt';
		writeFile: 'x/b/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'a\Foo.txt'.
	self
		assert: (tmp1 matchesAnchor: (self anchorOn: 'x/a/Foo.txt'));
		deny: (tmp1 matchesAnchor: (self anchorOn: 'x/b/Foo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherAcceptsForwardSlashAndBackslashEquivalently [

	| tmp1 tmp2 tmp3 |
	self writeFile: 'x/a/Foo.txt'.
	tmp3 := self anchorOn: 'x/a/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'x/a/Foo.txt'.
	tmp2 := MMCSuffixPathMatcher forSuffix: 'x\a\Foo.txt'.
	self
		assert: (tmp1 matchesAnchor: tmp3);
		assert: (tmp2 matchesAnchor: tmp3)
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherDoesNotMatchPartialDirectorySegment [

	| tmp1 |
	self writeFile: 'x/aa/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'a/Foo.txt'.
	self deny: (tmp1 matchesAnchor: (self anchorOn: 'x/aa/Foo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherDoesNotMatchPartialFileNameSegment [

	| tmp1 |
	self writeFile: 'x/a/xFoo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'a/Foo.txt'.
	self deny: (tmp1 matchesAnchor: (self anchorOn: 'x/a/xFoo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherDoesNotMatchPartialSingleSegmentSuffix [

	| tmp1 |
	self writeFile: 'x/a/xFoo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'Foo.txt'.
	self deny: (tmp1 matchesAnchor: (self anchorOn: 'x/a/xFoo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherDoesNotMatchWhenSuffixIsLongerThanPath [

	| tmp1 |
	self writeFile: 'a/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'zzz/yyy/xxx/www/a/Foo.txt'.
	self deny: (tmp1 matchesAnchor: (self anchorOn: 'a/Foo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherMatchesNonNormalizedAnchorPath [

	| tmp1 |
	self writeFile: 'x/a/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'a/Foo.txt'.
	self assert:
		(tmp1 matchesAnchor: (self anchorOn: 'x/b/../a/Foo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherMatchesRelativeAndAbsoluteAnchorNames [

	| tmp1 tmp2 |
	tmp2 := self writeFile: 'x/a/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'a/Foo.txt'.
	self
		assert: (tmp1 matchesAnchor: (self anchorOn: 'x/a/Foo.txt'));
		assert: (tmp1 matchesAnchor: (self anchorOn: tmp2 pathString))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherMatchesSingleSegmentSuffix [

	| tmp1 |
	self writeFile: 'x/a/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'Foo.txt'.
	self assert: (tmp1 matchesAnchor: (self anchorOn: 'x/a/Foo.txt'))
]

{ #category : 'tests' }
MMCFileMatcherTest >> testSuffixMatcherMatchesWholeTrailingSegments [

	| tmp1 |
	self writeFile: 'x/a/Foo.txt'.
	tmp1 := MMCSuffixPathMatcher forSuffix: 'a/Foo.txt'.
	self assert: (tmp1 matchesAnchor: (self anchorOn: 'x/a/Foo.txt'))
]

{ #category : 'helpers' }
MMCFileMatcherTest >> writeFile: aRelativePath [
	"Create a small file under the fixture folder and answer its reference."
	| ref |
	ref := folder resolve: aRelativePath.
	ref parent ensureCreateDirectory.
	ref ensureCreateFile.
	ref writeStreamDo: [ :s | s nextPutAll: 'content' ].
	^ ref
]
