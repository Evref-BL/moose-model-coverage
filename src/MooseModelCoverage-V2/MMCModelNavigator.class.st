"
Pure navigation model over a Moose model and an MMCFileCoverage: roots, children, parent, index paths and entity <-> region links, for a tree widget. The index is built lazily once per (filter, nameFilter). Filter #covered shows entities with a region plus their ancestors; #all shows every entity of the model. A name filter keeps matching entities plus their ancestors. Parent of an entity is the first of its containers, so each entity appears once. Ancestors outside the model are deliberately shown: the ancestors of an entity are always included, even when their container is not in the model (same in #covered and #all modes). Siblings and roots are sorted by first region position, then by label ignoring case, then by mooseName, then by exact label.
"
Class {
	#name : 'MMCModelNavigator',
	#superclass : 'Object',
	#instVars : [
		'model',
		'coverage',
		'filter',
		'nameFilter',
		'regionsByEntity',
		'visible',
		'parentByEntity',
		'childrenByParent',
		'rootEntities',
		'indexByEntity'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCModelNavigator class >> on: aMooseModelOrNil coverage: anMMCFileCoverage [

	^ self new
		  setModel: aMooseModelOrNil coverage: anMMCFileCoverage;
		  yourself
]

{ #category : 'navigation' }
MMCModelNavigator >> ancestorsOf: anEntity [
	"Answer the ancestors of anEntity from the root to its parent, without anEntity; empty for a root or a hidden entity."

	| result current steps |
	(self includes: anEntity) ifFalse: [ ^ #(  ) ].
	result := OrderedCollection new.
	current := parentByEntity at: anEntity ifAbsent: [ nil ].
	steps := 0.
	[ current notNil and: [ (steps := steps + 1) <= visible size ] ]
		whileTrue: [
				result addFirst: current.
				current := parentByEntity at: current ifAbsent: [ nil ] ].
	^ result asArray
]

{ #category : 'private' }
MMCModelNavigator >> buildIndex [
	"Build the whole index for the current filters. rootEntities is assigned last: an error leaves the index invalid."

	regionsByEntity := self groupRegions.
	parentByEntity := IdentityDictionary new.
	visible := IdentitySet new.
	self candidateEntities do: [ :each | self markVisible: each ].
	self buildTree
]

{ #category : 'private' }
MMCModelNavigator >> buildTree [
	"Group visible entities by parent, sort every sibling list and number the entities among their siblings."

	| keys children roots index |
	keys := IdentityDictionary new: visible size.
	visible do: [ :each |
			keys at: each put: {
					(self startKeyOf: each).
					(self labelOf: each) } ].
	children := IdentityDictionary new.
	roots := OrderedCollection new.
	visible do: [ :each |
			(parentByEntity at: each ifAbsent: [ nil ])
				ifNil: [ roots add: each ]
				ifNotNil: [ :parent |
					(children at: parent ifAbsentPut: [ OrderedCollection new ])
						add: each ] ].
	index := IdentityDictionary new: visible size.
	children keys do: [ :parent |
			children
				at: parent
				put: (self sorted: (children at: parent) keys: keys) ].
	roots := self sorted: roots keys: keys.
	children valuesDo: [ :list |
		list doWithIndex: [ :each :i | index at: each put: i ] ].
	roots doWithIndex: [ :each :i | index at: each put: i ].
	childrenByParent := children.
	indexByEntity := index.
	rootEntities := roots
]

{ #category : 'private' }
MMCModelNavigator >> candidateEntities [
	"Entities selected by the current filter and name filter, before adding their ancestors."

	| base |
	model ifNil: [ ^ #(  ) ].
	base := filter = #all
		        ifTrue: [ model allModelEntities ]
		        ifFalse: [ regionsByEntity keys ].
	nameFilter isEmpty ifTrue: [ ^ base ].
	^ base select: [ :each |
			  (self labelOf: each)
				  includesSubstring: nameFilter
				  caseSensitive: false ]
]

{ #category : 'navigation' }
MMCModelNavigator >> childrenOf: anEntity [

	self ensureIndex.
	^ (childrenByParent at: anEntity ifAbsent: [ #(  ) ]) copy
]

{ #category : 'private' }
MMCModelNavigator >> compare: a with: b keys: keys [
	"Answer -1, 0 or 1 comparing two entities by start position, label ignoring case, mooseName, then exact label."

	| ka kb result |
	ka := keys at: a.
	kb := keys at: b.
	ka first = kb first ifFalse: [
			^ ka first < kb first
				  ifTrue: [ -1 ]
				  ifFalse: [ 1 ] ].
	result := self
		          compareString: ka second asString asLowercase
		          with: kb second asString asLowercase.
	result = 0 ifFalse: [ ^ result ].
	result := self
		          compareString: (self mooseNameOf: a)
		          with: (self mooseNameOf: b).
	result = 0 ifFalse: [ ^ result ].
	^ self compareString: ka second asString with: kb second asString
]

{ #category : 'private' }
MMCModelNavigator >> compareString: x with: y [
	"Answer -1, 0 or 1 comparing two strings case-sensitively (total order)."

	x = y ifTrue: [ ^ 0 ].
	^ (x caseSensitiveLessOrEqual: y)
		  ifTrue: [ -1 ]
		  ifFalse: [ 1 ]
]

{ #category : 'accessing' }
MMCModelNavigator >> coverage [

	^ coverage
]

{ #category : 'regions' }
MMCModelNavigator >> deepestEntityAt: aPosition [
	"Answer the entity of the innermost region at aPosition, or nil."

	coverage ifNil: [ ^ nil ].
	^ (coverage deepestRegionAt: aPosition) ifNotNil: [ :region |
		  region entity ]
]

{ #category : 'private' }
MMCModelNavigator >> ensureIndex [

	rootEntities ifNil: [ self buildIndex ]
]

{ #category : 'regions' }
MMCModelNavigator >> entitiesAt: aPosition [
	"Answer the entities of the regions at aPosition, outermost first, without repetition."

	| result |
	coverage ifNil: [ ^ #(  ) ].
	result := OrderedCollection new.
	(coverage regionsAt: aPosition) do: [ :region |
			(result anySatisfy: [ :each | each == region entity ]) ifFalse: [
				result add: region entity ] ].
	^ result asArray
]

{ #category : 'navigation' }
MMCModelNavigator >> entityAtPath: aPath [
	"Answer the entity reached by following the 1-based indices of aPath from the roots, or nil when the path is empty or invalid (not a collection of positive integers)."

	| list entity |
	(aPath isCollection and: [
			 aPath isDictionary not and: [
				 aPath isSymbol not and: [ aPath isString not ] ] ]) ifFalse: [
		^ nil ].
	aPath isEmpty ifTrue: [ ^ nil ].
	self ensureIndex.
	list := rootEntities.
	aPath do: [ :i |
			(i isInteger and: [ i between: 1 and: list size ]) ifFalse: [
				^ nil ].
			entity := list at: i.
			list := childrenByParent at: entity ifAbsent: [ #(  ) ] ].
	^ entity
]

{ #category : 'filtering' }
MMCModelNavigator >> filter [

	^ filter
]

{ #category : 'filtering' }
MMCModelNavigator >> filter: aSymbol [
	"Set the visibility mode: #covered or #all."

	(#( #covered #all ) includes: aSymbol) ifFalse: [
			^ self error:
				  'Invalid filter (expected #covered or #all): '
				  , aSymbol printString ].
	filter := aSymbol.
	self invalidateIndex
]

{ #category : 'private' }
MMCModelNavigator >> firstContainerOf: anEntity [
	"Answer the first container of anEntity, or nil (containers allocates a fresh collection)."

	| containers |
	(anEntity respondsTo: #containers) ifFalse: [ ^ nil ].
	containers := anEntity containers.
	^ containers ifEmpty: [ nil ] ifNotEmpty: [ containers first ]
]

{ #category : 'private' }
MMCModelNavigator >> firstOf: aRegionCollection [
	"Answer the region with the smallest start, the largest one on a tie, or nil."

	| best |
	aRegionCollection do: [ :region |
			(best isNil or: [
					 region interval first < best interval first or: [
							 region interval first = best interval first and: [
								 region interval last > best interval last ] ] ]) ifTrue: [
				best := region ] ].
	^ best
]

{ #category : 'regions' }
MMCModelNavigator >> firstRegionOf: anEntity [

	^ self firstOf: (self regionsOf: anEntity)
]

{ #category : 'private' }
MMCModelNavigator >> groupRegions [
	"Answer an IdentityDictionary entity -> Array of its regions, in the order of the coverage."

	| dict |
	dict := IdentityDictionary new.
	coverage ifNil: [ ^ dict ].
	coverage regions do: [ :region |
			(dict at: region entity ifAbsentPut: [ OrderedCollection new ])
				add: region ].
	dict keys do: [ :key | dict at: key put: (dict at: key) asArray ].
	^ dict
]

{ #category : 'accessing' }
MMCModelNavigator >> includes: anEntity [

	self ensureIndex.
	^ visible includes: anEntity
]

{ #category : 'initialization' }
MMCModelNavigator >> initialize [

	super initialize.
	filter := #covered.
	nameFilter := ''
]

{ #category : 'private' }
MMCModelNavigator >> invalidateIndex [

	regionsByEntity := visible := parentByEntity := childrenByParent := rootEntities := indexByEntity := nil
]

{ #category : 'regions' }
MMCModelNavigator >> isCovered: anEntity [

	self ensureIndex.
	^ regionsByEntity includesKey: anEntity
]

{ #category : 'labels' }
MMCModelNavigator >> labelOf: anEntity [
	"Answer the name of anEntity, or '<unnamed>' when it has none."

	| name |
	(anEntity respondsTo: #name) ifFalse: [ ^ '<unnamed>' ].
	name := anEntity name.
	name isNil ifTrue: [ ^ '<unnamed>' ].
	name := name asString.
	^ name isEmpty
		  ifTrue: [ '<unnamed>' ]
		  ifFalse: [ name ]
]

{ #category : 'private' }
MMCModelNavigator >> markVisible: anEntity [
	"Mark anEntity and its ancestors as visible. Stops at an already visible entity, which also guards against container cycles."

	| current |
	current := anEntity.
	[ current notNil and: [ (visible includes: current) not ] ]
		whileTrue: [
				visible add: current.
				current := parentByEntity
					           at: current
					           ifAbsentPut: [ self firstContainerOf: current ] ]
]

{ #category : 'private' }
MMCModelNavigator >> metamodelPrefixOf: aClass [
	"Copy of MMCEntityRegion>>metamodelPrefixOf: (private there): the topmost Famix<Metamodel>Entity class of the superclass chain gives Famix<Metamodel>, else Famix."

	| rootEntity |
	rootEntity := aClass withAllSuperclasses reversed
		              detect: [ :each |
				              (each name beginsWith: 'Famix') and: [
					              (each name endsWith: 'Entity') and: [
						              each name size > 11 ] ] ]
		              ifNone: [ ^ 'Famix' ].
	^ rootEntity name allButLast: 6
]

{ #category : 'accessing' }
MMCModelNavigator >> model [

	^ model
]

{ #category : 'private' }
MMCModelNavigator >> mooseNameOf: anEntity [
	"Last tie-breaker of the sort; empty when the entity has no mooseName."

	^ (anEntity respondsTo: #mooseName)
		  ifTrue: [ anEntity mooseName asString ]
		  ifFalse: [ '' ]
]

{ #category : 'filtering' }
MMCModelNavigator >> nameFilter [

	^ nameFilter
]

{ #category : 'filtering' }
MMCModelNavigator >> nameFilter: aString [
	"Keep entities whose label contains aString (case insensitive); empty means no filter."

	nameFilter := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	self invalidateIndex
]

{ #category : 'navigation' }
MMCModelNavigator >> parentOf: anEntity [
	"Answer the first container of a visible entity, nil for a root or a hidden entity."

	self ensureIndex.
	^ parentByEntity at: anEntity ifAbsent: [ nil ]
]

{ #category : 'navigation' }
MMCModelNavigator >> pathTo: anEntity [
	"Answer the 1-based sibling indices from the roots down to anEntity, or nil when it is not visible. Cost is the depth of anEntity."

	| path current steps |
	(self includes: anEntity) ifFalse: [ ^ nil ].
	path := OrderedCollection new.
	current := anEntity.
	steps := 0.
	[ current notNil ] whileTrue: [
			(steps := steps + 1) > visible size ifTrue: [ ^ nil ].
			path addFirst: (indexByEntity at: current).
			current := parentByEntity at: current ifAbsent: [ nil ] ].
	^ path asArray
]

{ #category : 'regions' }
MMCModelNavigator >> regionsOf: anEntity [
	"Answer a copy of the coverage regions whose entity is anEntity, in coverage order."

	self ensureIndex.
	^ (regionsByEntity at: anEntity ifAbsent: [ #(  ) ]) copy
]

{ #category : 'navigation' }
MMCModelNavigator >> roots [

	self ensureIndex.
	^ rootEntities copy
]

{ #category : 'initialization' }
MMCModelNavigator >> setModel: aMooseModelOrNil coverage: anMMCFileCoverage [

	model := aMooseModelOrNil.
	coverage := anMMCFileCoverage
]

{ #category : 'accessing' }
MMCModelNavigator >> size [
	"Number of visible entities."

	self ensureIndex.
	^ visible size
]

{ #category : 'private' }
MMCModelNavigator >> sorted: aCollection keys: keys [
	"Answer an Array of aCollection sorted by start position (first region, infinity without region), then by label ignoring case, then by mooseName, then by exact label (case), so the order is deterministic."

	^ (aCollection asSortedCollection: [ :a :b |
		   (self compare: a with: b keys: keys) <= 0 ]) asArray
]

{ #category : 'private' }
MMCModelNavigator >> startKeyOf: anEntity [
	"Start of the first region of anEntity in the file, or infinity when it has none."

	^ (self firstOf: (regionsByEntity at: anEntity ifAbsent: [ #(  ) ]))
		  ifNil: [ Float infinity ]
		  ifNotNil: [ :region | region interval first ]
]

{ #category : 'labels' }
MMCModelNavigator >> typeNameOf: anEntity [
	"Same logic as MMCEntityRegion>>typeName (not reusable without a region): class name without the Famix and metamodel prefixes."

	| name prefix |
	name := anEntity class name.
	prefix := self metamodelPrefixOf: anEntity class.
	(name beginsWith: prefix) ifTrue: [ ^ name allButFirst: prefix size ].
	^ (name beginsWith: 'Famix')
		  ifTrue: [ name allButFirst: 5 ]
		  ifFalse: [ name ]
]

{ #category : 'accessing' }
MMCModelNavigator >> visibleEntities [
	"Answer a copy of the visible entities."

	self ensureIndex.
	^ visible asArray
]
