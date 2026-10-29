Class {
	#name : 'MMCUncoveredRegionTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'helpers' }
MMCUncoveredRegionTest >> crlfText [
	"a1 b2 CR3 LF4 c5 d6 CR7 LF8 e9 f10"

	^ 'ab' , String crlf , 'cd' , String crlf , 'ef'
]

{ #category : 'helpers' }
MMCUncoveredRegionTest >> lfText [
	"a1 b2 LF3 c4 d5 LF6 e7 f8"

	^ 'ab' , String lf , 'cd' , String lf , 'ef'
]

{ #category : 'helpers' }
MMCUncoveredRegionTest >> newCoverageFor: arg1 [

	^ MMCFileCoverage fromReadResult: (MMCAnchorReadResult
			   fileReference: 'a.txt' asFileReference
			   text: arg1
			   regions: #(  )
			   ignoredAnchors: #(  )
			   otherFileAnchorCount: 0)
]

{ #category : 'helpers' }
MMCUncoveredRegionTest >> newRegionFrom: arg1 to: arg2 in: arg3 [

	^ MMCUncoveredRegion interval: (arg1 to: arg2) in: arg3
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testIntervalIsTheOneGiven [

	self
		assert:
			(self newRegionFrom: 4 to: 5 in: (self newCoverageFor: self lfText))
				interval
		equals: (4 to: 5)
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testPrintOnShowsTheBounds [

	| string |
	string := (self
		           newRegionFrom: 14
		           to: 27
		           in: (self newCoverageFor: (String new: 30 withAll: $x)))
		          printString.
	self assert: (string includesSubstring: '14').
	self assert: (string includesSubstring: '27')
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testRegionIsNotEqualToAnotherKindOfObject [

	| region |
	region := self
		          newRegionFrom: 1
		          to: 2
		          in: (self newCoverageFor: 'abcd').
	self deny: region = (1 to: 2).
	self deny: region = 'ab'.
	self deny: region = nil
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testRegionsOnDifferentIntervalsAreNotEqual [

	| coverage |
	coverage := self newCoverageFor: self lfText.
	self deny: (self newRegionFrom: 4 to: 5 in: coverage)
		= (self newRegionFrom: 7 to: 8 in: coverage).
	self deny: (self newRegionFrom: 4 to: 5 in: coverage)
		= (self newRegionFrom: 4 to: 4 in: coverage)
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testRegionsOnSameIntervalAndTextAreEqual [
	"Two distinct coverages over equal texts."

	| one other |
	one := self
		       newRegionFrom: 4
		       to: 5
		       in: (self newCoverageFor: self lfText).
	other := self
		         newRegionFrom: 4
		         to: 5
		         in: (self newCoverageFor: self lfText).
	self assert: one equals: other.
	self assert: one hash equals: other hash
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testRegionsOnSameIntervalButDifferentTextAreNotEqual [

	| one other |
	one := self newRegionFrom: 1 to: 2 in: (self newCoverageFor: 'abcd').
	other := self
		         newRegionFrom: 1
		         to: 2
		         in: (self newCoverageFor: 'wxyz').
	self deny: one = other
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testSizeIsTheNumberOfCharacters [

	self
		assert:
			(self newRegionFrom: 4 to: 8 in: (self newCoverageFor: self lfText))
				size
		equals: 5.
	self
		assert:
			(self newRegionFrom: 7 to: 7 in: (self newCoverageFor: self lfText))
				size
		equals: 1
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testStartLineAndEndLineOfMultiLineRegion [
	"b2 LF3 c4 d5: from line 1 to line 2."

	| region |
	region := self
		          newRegionFrom: 2
		          to: 5
		          in: (self newCoverageFor: self lfText).
	self assert: region startLine equals: 1.
	self assert: region endLine equals: 2.
	self assert: region text equals: 'b' , String lf , 'cd'
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testStartLineAndEndLineOfSingleLineRegion [

	| region |
	region := self
		          newRegionFrom: 4
		          to: 5
		          in: (self newCoverageFor: self lfText).
	self assert: region startLine equals: 2.
	self assert: region endLine equals: 2
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testStartLineAndEndLineWithCrLf [
	"b2 CR3 LF4 c5 d6 CR7 LF8 e9: from line 1 to line 3."

	| region |
	region := self
		          newRegionFrom: 2
		          to: 9
		          in: (self newCoverageFor: self crlfText).
	self assert: region startLine equals: 1.
	self assert: region endLine equals: 3.
	self
		assert:
			(self
				 newRegionFrom: 5
				 to: 6
				 in: (self newCoverageFor: self crlfText)) startLine
		equals: 2
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testTextAndSizeCountCharactersNotBytes [
	"'a', e acute, euro, emoji, 'z': characters 2 to 4 are 3 characters."

	| text region |
	text := 'a' , (String
		         with: (Character value: 233)
		         with: (Character value: 8364)
		         with: (Character value: 128512)) , 'z'.
	region := self newRegionFrom: 2 to: 4 in: (self newCoverageFor: text).
	self assert: region size equals: 3.
	self assert: region text equals: (text copyFrom: 2 to: 4)
]

{ #category : 'tests' }
MMCUncoveredRegionTest >> testTextIsTheCoverageTextOverTheInterval [

	self
		assert:
			(self newRegionFrom: 4 to: 5 in: (self newCoverageFor: self lfText))
				text
		equals: 'cd'
]
