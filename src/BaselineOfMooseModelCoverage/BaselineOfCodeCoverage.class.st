Class {
	#name : 'BaselineOfCodeCoverage',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfMooseModelCoverage',
	#package : 'BaselineOfMooseModelCoverage'
}

{ #category : 'baselines' }
BaselineOfCodeCoverage >> baseline: spec [
	"donne l'ensemble des package requis pour la baseline (à inclure dans l'archive définis par Iceberg)"
	<baseline>
	spec for: #common do: [ 
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec ]
]

{ #category : 'dependencies' }
BaselineOfCodeCoverage >> defineDependencies: spec [
	"donne les ref vers le projet qui se trouve sur un depot distance"
	spec
		baseline: 'Moose'
		with: [ spec repository: 'github://moosetechnology/Moose:master/src' ]
]

{ #category : 'groups' }
BaselineOfCodeCoverage >> defineGroups: spec [
	"optional if you want to create specifc configuration of your baseline"
	spec
		group: 'default' with: #('CodeCoverage')
]

{ #category : 'packages' }
BaselineOfCodeCoverage >> definePackages: spec [
	"mentionne l'ensemble des packages requis (ici 1 package)"
	spec
		package: 'CodeCoverage' with: [ spec requires: #('Moose') ]
]
