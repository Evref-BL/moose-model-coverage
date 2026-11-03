"
A node of the file tree of the coverage window: a folder (no file, children) or a file leaf (the FileReference of the inventory). Build the tree with MMCFileTreeNode class>>rootsOf:naming:.
"
Class {
	#name : 'MMCFileTreeNode',
	#superclass : 'Object',
	#instVars : [
		'name',
		'file',
		'children',
		'parent',
		'folders'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'instance creation' }
MMCFileTreeNode class >> compactedRoots: aCollectionOfRoots [
	"Answer the roots of aCollectionOfRoots (see #rootsOf:naming:) with their chains of single folders merged (see #compact), sorted on the merged names. The nodes are modified."

	aCollectionOfRoots do: [ :each |
		each isFolder ifTrue: [ each compact ] ].
	^ aCollectionOfRoots asArray sort: [ :a :b | a precedes: b ]
]

{ #category : 'instance creation' }
MMCFileTreeNode class >> rootsOf: aFileCollection naming: aBlock [
	"Answer the top level nodes of the tree of aFileCollection. aBlock gives the relative name of a file, with / separators; its empty segments are ignored."

	| top |
	top := self new.
	aFileCollection do: [ :each |
			| segments |
			segments := ((aBlock value: each) splitOn: '/') reject: [ :s |
				            s isEmpty ].
			segments isEmpty ifFalse: [ top addFile: each segments: segments ] ].
	top sortChildren.
	top children do: [ :each | each parent: nil ].
	^ top children asArray
]

{ #category : 'building' }
MMCFileTreeNode >> addFile: aFile segments: aCollection [
	"Add the leaf of aFile under the folders named by all the segments but the last one, which names the leaf. Answer the leaf."

	| folder leaf |
	folder := self.
	aCollection allButLast do: [ :each |
		folder := folder folderNamed: each ].
	leaf := self class new
		        name: aCollection last;
		        file: aFile;
		        parent: folder;
		        yourself.
	folder children add: leaf.
	^ leaf
]

{ #category : 'accessing' }
MMCFileTreeNode >> children [

	^ children ifNil: [ children := OrderedCollection new ]
]

{ #category : 'compacting' }
MMCFileTreeNode >> compact [
	"Merge, in the whole subtree, every folder whose only child is a folder with that child (names joined by /, like the compact folders of VSCode), then sort the children on the merged names. Answer the receiver."

	| only |
	children ifNil: [ ^ self ].
	children do: [ :each | each isFolder ifTrue: [ each compact ] ].
	(children size = 1 and: [
		 self isFolder and: [ children first isFolder ] ]) ifTrue: [
			only := children first.
			name := name , '/' , only name.
			children := only children.
			children do: [ :each | each parent: self ] ].
	children sort: [ :a :b | a precedes: b ]
]

{ #category : 'accessing' }
MMCFileTreeNode >> file [

	^ file
]

{ #category : 'accessing' }
MMCFileTreeNode >> file: aFile [

	file := aFile
]

{ #category : 'building' }
MMCFileTreeNode >> folderNamed: aString [
	"Answer the child folder named aString, created when absent."

	^ (folders ifNil: [ folders := Dictionary new ])
		  at: aString
		  ifAbsentPut: [
				  | folder |
				  folder := self class new
					            name: aString;
					            parent: self;
					            yourself.
				  self children add: folder.
				  folder ]
]

{ #category : 'accessing' }
MMCFileTreeNode >> isFile [

	^ file notNil
]

{ #category : 'accessing' }
MMCFileTreeNode >> isFolder [

	^ file isNil
]

{ #category : 'accessing' }
MMCFileTreeNode >> name [

	^ name
]

{ #category : 'accessing' }
MMCFileTreeNode >> name: aString [

	name := aString
]

{ #category : 'accessing' }
MMCFileTreeNode >> parent [

	^ parent
]

{ #category : 'accessing' }
MMCFileTreeNode >> parent: aNode [

	parent := aNode
]

{ #category : 'building' }
MMCFileTreeNode >> pathFromRoot [
	"Answer the nodes from the top level folder down to the receiver."

	| path node |
	path := OrderedCollection new.
	node := self.
	[ node notNil ] whileTrue: [
			path addFirst: node.
			node := node parent ].
	^ path asArray
]

{ #category : 'building' }
MMCFileTreeNode >> precedes: aNode [
	"Folders come before files, then the names in alphabetical order (ignoring case)."

	self isFolder = aNode isFolder ifFalse: [ ^ self isFolder ].
	^ name asLowercase <= aNode name asLowercase
]

{ #category : 'accessing' }
MMCFileTreeNode >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: name asString;
		nextPut: $)
]

{ #category : 'building' }
MMCFileTreeNode >> sortChildren [
	"Sort the whole subtree, see #precedes:."

	children ifNil: [ ^ self ].
	children sort: [ :a :b | a precedes: b ].
	children do: [ :each | each sortChildren ]
]
