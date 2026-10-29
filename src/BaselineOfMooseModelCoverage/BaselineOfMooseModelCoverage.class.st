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

{ #category : 'baselines' }
BaselineOfMooseModelCoverage >> defineDependencies: spec [
	"donne les ref vers le projet qui se trouve sur un depot distance.
	Si Moose est deja charge dans l'image, on utilise la version actuelle et on ne declare pas la dependance : sinon Metacello tente de recharger Moose et ses dependances (ex. Ghost), incompatibles avec Pharo 13, et se bloque."

	self isMooseLoaded ifTrue: [ ^ self ].
	spec
		baseline: 'Moose'
		with: [
		spec repository: 'github://moosetechnology/Moose:development/src' ]
]

{ #category : 'groups' }
BaselineOfMooseModelCoverage >> defineGroups: spec [
	"optional if you want to create specifc configuration of your baseline"
	spec
		group: 'default' with: #('MooseModelCoverage')
]

{ #category : 'baselines' }
BaselineOfMooseModelCoverage >> definePackages: spec [
	"mentionne l'ensemble des packages requis (ici 1 package).
	MooseModelCoverage ne requiert 'Moose' que si Moose n'est pas deja charge (voir defineDependencies:)."

	self isMooseLoaded
		ifTrue: [ spec package: 'MooseModelCoverage' ]
		ifFalse: [
				spec
					package: 'MooseModelCoverage'
					with: [ spec requires: #( 'Moose' ) ] ]
]

{ #category : 'testing' }
BaselineOfMooseModelCoverage >> isMooseLoaded [
	"Indique si Moose est deja charge dans l'image.
	On teste la presence de la classe MooseModel (noyau de Moose) plutot qu'un package ou une baseline : c'est ce dont MooseModelCoverage a reellement besoin, et ca ne depend pas de la maniere dont Moose a ete charge.
	Cette methode est evaluee au chargement de la baseline (dans baseline:), donc l'etat de l'image est celui du moment du chargement."

	^ self class environment includesKey: #MooseModel
]
