Class {
	#name : 'BaselineOfMooseModelCoverage',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfMooseModelCoverage',
	#package : 'BaselineOfMooseModelCoverage'
}

{ #category : 'baselines' }
BaselineOfMooseModelCoverage >> baseline: spec [
	"donne l'ensemble des package requis pour la baseline (à inclure dans l'archive définis par Iceberg)"
	<baseline>
	spec for: #common do: [ 
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec ]
]

{ #category : 'dependencies' }
BaselineOfMooseModelCoverage >> defineDependencies: spec [
	"donne les ref vers le projet qui se trouve sur un depot distance"
	spec
		baseline: 'Moose'
		with: [ spec repository: 'github://moosetechnology/Moose:development/src' ]
]

{ #category : 'groups' }
BaselineOfMooseModelCoverage >> defineGroups: spec [
	"optional if you want to create specifc configuration of your baseline"
	spec
		group: 'default' with: #('MooseModelCoverage')
]

{ #category : 'packages' }
BaselineOfMooseModelCoverage >> definePackages: spec [
	"mentionne l'ensemble des packages requis (ici 1 package)"
	spec
		package: 'MooseModelCoverage' with: [ spec requires: #('Moose') ]
]
