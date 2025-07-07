"
A CodeCoverageAnalyzerTest is a test class for testing the behavior of CodeCoverageAnalyzer
"
Class {
	#name : 'CodeCoverageAnalyzerTest',
	#superclass : 'TestCase',
	#category : 'MooseModelCoverage-Tests',
	#package : 'MooseModelCoverage-Tests'
}

{ #category : 'tests' }
CodeCoverageAnalyzerTest >> testCoveredLines [

	self flag: #toImplement.
	self assert: false
]
