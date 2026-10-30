"
Tests of the pure construction (never executed) of the native command that reveals a file in the file manager, in MMCCoveragePresenter: shellQuoted: (POSIX single quotes), windowsQuoted:, nativeRevealCommandFor:platform: for #macOS, #windows and #other, with paths holding spaces, apostrophes, double quotes, dollar and parentheses, line breaks and non ASCII characters. The command is NEVER run.
"
Class {
	#name : 'MMCCoveragePresenterNativeCommandTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'MooseModelCoverage-V2-Tests',
	#package : 'MooseModelCoverage-V2-Tests'
}

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> accentedName [
	"A name with a line feed, e acute and the euro sign."

	^ String streamContents: [ :stream |
			  stream
				  nextPut: $a;
				  nextPut: Character lf;
				  nextPut: (Character value: 233);
				  nextPut: (Character value: 8364);
				  nextPutAll: '.txt' ]
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> fileNamed: aName [
	"A file reference of a memory file system (nothing on the disk)."

	^ FileSystem memory root / 'my dir' / aName
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> setUp [
	"A presenter on an empty model, only used for its pure command methods."

	super setUp.
	presenter := MMCCoveragePresenter forModel: FamixJavaModel new
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testMacOSCommandRevealsTheQuotedPath [

	self
		assert: (presenter
				 nativeRevealCommandFor: (self fileNamed: 'a b.txt')
				 platform: #macOS)
		equals: 'open -R ''/my dir/a b.txt'''
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testMacOSCommandWithApostropheDollarAndQuotes [

	| command |
	command := presenter
		           nativeRevealCommandFor:
		           (self fileNamed: 'it''s $(x) "q".txt')
		           platform: #macOS.
	self assert:
		(command beginsWith: 'open -R ''/my dir/it''\''''s $(x) "q".txt').
	self assert: command last equals: $'
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testMacOSCommandWithLineBreakAndNonAscii [

	| command |
	command := presenter
		           nativeRevealCommandFor:
		           (self fileNamed: self accentedName)
		           platform: #macOS.
	self assert: (command includes: (Character value: 8364)).
	self assert: (command includes: Character lf).
	self assert: (command beginsWith: 'open -R ''/my dir/a').
	self assert: command last equals: $'
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testNativePlatformNameIsOneOfThree [

	self assert:
		(#( #macOS #windows #other ) includes: presenter nativePlatformName)
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testOtherPlatformsHaveNoCommand [

	self
		assert: (presenter
				 nativeRevealCommandFor: (self fileNamed: 'a.txt')
				 platform: #other)
		equals: nil
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testShellQuotedEscapesApostrophes [

	self
		assert: (presenter shellQuoted: 'it''s')
		equals: '''it''\''''s'''
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testShellQuotedKeepsDangerousCharactersInert [

	| quoted |
	quoted := presenter shellQuoted: '$(rm -rf x)`id`"\;&|'.
	self assert: quoted equals: '''$(rm -rf x)`id`"\;&|'''
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testShellQuotedWrapsInSingleQuotes [

	self assert: (presenter shellQuoted: 'a b') equals: '''a b'''.
	self assert: (presenter shellQuoted: '') equals: ''''''
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testWindowsCommandSelectsTheQuotedPath [

	self
		assert: (presenter
				 nativeRevealCommandFor: (self fileNamed: 'a b.txt')
				 platform: #windows)
		equals: 'explorer /select,"/my dir/a b.txt"'
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testWindowsKeepsApostrophesAndNonAscii [

	self
		assert: (presenter windowsQuoted:
				 'it''s ' , (String with: (Character value: 233)))
		equals: '"it''s ' , (String with: (Character value: 233)) , '"'
]

{ #category : 'tests' }
MMCCoveragePresenterNativeCommandTest >> testWindowsRefusesUnsafeCharacters [

	{
		'a"b'.
		'%PATH%'.
		(String with: $a with: Character lf) } do: [ :each |
		self assert: (presenter windowsQuoted: each) isNil ].
	self
		assert: (presenter
				 nativeRevealCommandFor: (self fileNamed: '%PATH%.txt')
				 platform: #windows)
		equals: nil
]
