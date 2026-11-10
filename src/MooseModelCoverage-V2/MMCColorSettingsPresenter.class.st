"
Non modal window that manages the color of each Famix type having source anchors. The base colors are stored in an MMCColorScheme (the one of the Moose model, kept in MMCColorSchemeRegistry): changing a color updates the scheme after a short debounce, which refreshes the coverage window through its subscription. A type is chosen in the table (sorted by decreasing number of entities, then by name), its effective color is edited by an hexadecimal field (#RRGGBB) and a graphical color picker. Reset type removes the override of the chosen type, Reset all removes all of them.
"
Class {
	#name : 'MMCColorSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'colorScheme',
		'counts',
		'defaultColorBlock',
		'modelName',
		'coveragePresenter',
		'subscription',
		'typeTable',
		'filterField',
		'previewPresenter',
		'hexField',
		'pickerPresenter',
		'pickButton',
		'resetTypeButton',
		'resetAllButton',
		'closeButton',
		'messageLabel',
		'selectedType',
		'pendingColor',
		'generation',
		'debounceMilliseconds',
		'isLoadingEditor',
		'colorChooser',
		'pendingProcess',
		'windowPresenter',
		'rows',
		'pendingType',
		'pendingVisibility',
		'showAllButton',
		'showNoneButton'
	],
	#category : 'MooseModelCoverage-V2',
	#package : 'MooseModelCoverage-V2'
}

{ #category : 'colors' }
MMCColorSettingsPresenter class >> colorFromHex: aString [
	"Answer the opaque color of '#RRGGBB' (the # is optional, any case, surrounding blanks ignored), nil when aString is not a color."

	| text |
	text := aString trim.
	(text beginsWith: '#') ifTrue: [ text := text allButFirst ].
	(text size = 6 and: [
		 text allSatisfy: [ :each | '0123456789abcdefABCDEF' includes: each ] ])
		ifFalse: [ ^ nil ].
	^ Color
		  r: (Integer readFrom: (text copyFrom: 1 to: 2) base: 16) / 255.0
		  g: (Integer readFrom: (text copyFrom: 3 to: 4) base: 16) / 255.0
		  b: (Integer readFrom: (text copyFrom: 5 to: 6) base: 16) / 255.0
]

{ #category : 'instance creation' }
MMCColorSettingsPresenter class >> forCoveragePresenter: aCoveragePresenter [
	"Answer a presenter editing the color scheme of aCoveragePresenter for the types of its inventory (none without inventory). The default colors are those of the palette of aCoveragePresenter, which follows its theme."

	| modelFiles |
	modelFiles := aCoveragePresenter modelFiles.
	^ self basicNew
		  configureScheme: aCoveragePresenter colorScheme
		  counts: (modelFiles
				   ifNil: [ Dictionary new ]
				   ifNotNil: [ :files | files typeCounts ])
		  defaultColors: [ :typeName |
			  aCoveragePresenter palette defaultColorForType: typeName depth: 0 ]
		  title: aCoveragePresenter modelName
		  coveragePresenter: aCoveragePresenter;
		  initialize;
		  yourself
]

{ #category : 'colors' }
MMCColorSettingsPresenter class >> hexOf: aColor [
	"Answer '#RRGGBB' (upper case) for aColor."

	^ '#' , aColor asHexString asUppercase
]

{ #category : 'instance creation' }
MMCColorSettingsPresenter class >> on: aColorScheme counts: aDictionary [
	"Answer a presenter editing aColorScheme for the types of aDictionary (typeName -> number of entities). The default colors are those of a fresh palette (dark theme)."

	^ self basicNew
		  configureScheme: aColorScheme
		  counts: aDictionary
		  defaultColors: nil
		  title: nil
		  coveragePresenter: nil;
		  initialize;
		  yourself
]

{ #category : 'instance creation' }
MMCColorSettingsPresenter class >> openOn: aCoveragePresenter [
	"Open, non modal, the color settings of aCoveragePresenter and answer the window (SpWindowPresenter)."

	^ (self forCoveragePresenter: aCoveragePresenter) open
]

{ #category : 'colors' }
MMCColorSettingsPresenter class >> swatchFormOf: aColor [
	"Answer a new plain 16x16 form of aColor."

	^ (Form extent: 16 @ 16 depth: 32)
		  fillColor: aColor;
		  yourself
]

{ #category : 'table' }
MMCColorSettingsPresenter >> applyFilter: aString [
	"Show only the types whose name contains aString (ignoring case); all of them when it is blank."

	self fillTable
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> cancelDebounce [
	"Cancel the wait of the debounce, if any: no process is left running and the deferred applications already queued become obsolete."

	generation := generation + 1.
	pendingProcess ifNotNil: [ :process |
			process == Processor activeProcess ifFalse: [ process terminate ].
			pendingProcess := nil ]
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> chooseColor: aColor [
	"Choose aColor (made opaque) as the base color of the selected type: the editor and the table show it at once, the color scheme (hence the coverage window) is updated after the debounce delay; the last color wins. Answer false, with a message, when no type is selected."

	selectedType ifNil: [
			self showMessage: 'Select a type first'.
			^ false ].
	pendingType := selectedType.
	pendingColor := Color
		                r: aColor red
		                g: aColor green
		                b: aColor blue
		                alpha: 1.
	self showMessage: ''.
	isLoadingEditor := true.
	[
		previewPresenter image: (self class swatchFormOf: pendingColor).
		(self class colorFromHex: hexField text) = pendingColor ifFalse: [
			hexField text: (self class hexOf: pendingColor) ] ] ensure: [
		isLoadingEditor := false ].
	self refreshTable.
	self scheduleApply.
	^ true
]

{ #category : 'actions' }
MMCColorSettingsPresenter >> close [
	"Close the window."

	windowPresenter ifNotNil: [ :window | window close ]
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> closeButton [

	^ closeButton
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> colorChooser [
	"Answer the block (current color -> Color, nil when cancelled) used by the Pick button. The default opens the modal ColorSelectorDialogWindow; tests replace it, they never open a graphical picker."

	^ colorChooser ifNil: [ colorChooser := self defaultColorChooser ]
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> colorChooser: aBlock [

	colorChooser := aBlock
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> colorScheme [

	^ colorScheme
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> colorSchemeChanged [
	"The scheme changed: show again the colors, and the effective color of the selected type unless a color is pending."

	self refreshTable.
	pendingColor ifNil: [ self loadEditor ]
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> configureScheme: aColorScheme counts: aDictionary defaultColors: aBlock title: aString coveragePresenter: aPresenter [
	"Set what the presenter edits; to be sent before initialize. aBlock answers the default color of a type name (nil: the colors of a fresh palette)."

	| palette |
	colorScheme := aColorScheme.
	counts := aDictionary.
	modelName := aString.
	coveragePresenter := aPresenter.
	aBlock
		ifNil: [
				palette := MMCColorPalette
					           forTypeNames: aDictionary keys
					           theme: #dark.
				defaultColorBlock := [ :typeName |
				                     palette
					                     defaultColorForType: typeName
					                     depth: 0 ] ]
		ifNotNil: [ defaultColorBlock := aBlock ]
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> coveragePresenter [
	"Answer the coverage presenter, nil without one or once the window is closed."

	^ coveragePresenter
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> debounceMilliseconds [

	^ debounceMilliseconds
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> debounceMilliseconds: anInteger [

	debounceMilliseconds := anInteger
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> defaultColorChooser [

	^ [ :aColor |
		  | dialog |
		  dialog := ColorSelectorDialogWindow new.
		  dialog selectedColor: aColor.
		  dialog openModal.
		  dialog cancelled
			  ifTrue: [ nil ]
			  ifFalse: [ dialog selectedColor ] ]
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 4;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 4;
				   add: filterField;
				   add: showAllButton width: 40;
				   add: showNoneButton width: 50;
				   yourself)
			  expand: false;
		  add: typeTable;
		  add: messageLabel expand: false;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 4;
				   add: previewPresenter width: 48;
				   add: hexField width: 100;
				   add: pickButton width: 70;
				   yourself)
		  height: 30;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 4;
				   add: resetTypeButton;
				   add: resetAllButton;
				   add: closeButton;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'table' }
MMCColorSettingsPresenter >> displayedTypeNames [
	"Answer the type names of the table, in order."

	^ rows asArray
]

{ #category : 'table' }
MMCColorSettingsPresenter >> effectiveColorOf: aTypeName [
	"Answer the color (level 0) shown for the type: the pending color, else the override, else the default color of the palette."

	(pendingColor notNil and: [ pendingType = aTypeName ]) ifTrue: [
		^ pendingColor ].
	^ (colorScheme overrideFor: aTypeName) ifNil: [
		  defaultColorBlock value: aTypeName ]
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> effectiveHiddenTypeNames [
	"Answer the set of the hidden type names, the pending choices applied."

	| hidden |
	hidden := colorScheme hiddenTypeNames.
	pendingVisibility keysAndValuesDo: [ :typeName :shown |
			shown
				ifTrue: [ hidden remove: typeName ifAbsent: [ ] ]
				ifFalse: [ hidden add: typeName ] ].
	^ hidden
]

{ #category : 'table' }
MMCColorSettingsPresenter >> fillTable [
	"Fill the table with the sorted types matching the filter, keep the selection when the type is still there, and show a message when there is no type."

	| filter previous |
	filter := filterField text trim.
	previous := selectedType.
	rows := self sortedTypeNames select: [ :typeName |
			        filter isEmpty or: [
				        typeName asString
					        includesSubstring: filter
					        caseSensitive: false ] ].
	typeTable items: rows.
	(previous notNil and: [ rows includes: previous ]) ifTrue: [
		typeTable selectItem: previous ].
	messageLabel label: (counts isEmpty
			 ifTrue: [ 'No Famix type with source anchors in this model.' ]
			 ifFalse: [
					 rows isEmpty
						 ifTrue: [ 'No type matches the filter.' ]
						 ifFalse: [ '' ] ])
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> filterField [

	^ filterField
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> flushPendingColor [
	"Apply at once the pending color and the pending visibility choices, if any, to the color scheme (which notifies the coverage window). Answer true when something was applied. Synchronous: used by the debounce, when the selection changes, and when the window closes."

	| typeName color applied |
	self cancelDebounce.
	applied := false.
	pendingColor ifNotNil: [
			typeName := pendingType.
			color := pendingColor.
			pendingType := nil.
			pendingColor := nil.
			colorScheme overrideAt: typeName put: color.
			applied := true ].
	self flushPendingVisibility ifTrue: [ applied := true ].
	applied ifTrue: [ self refreshTable ].
	^ applied
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> flushPendingVisibility [
	"Apply at once the pending visibility choices to the color scheme in one atomic step (one single notification, none when nothing changes). Answer true when something was pending."

	| hidden |
	pendingVisibility isEmpty ifTrue: [ ^ false ].
	hidden := self effectiveHiddenTypeNames.
	pendingVisibility := Dictionary new.
	colorScheme setHiddenTypeNames: hidden.
	self refreshTable.
	^ true
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> hasMessageToKeep [

	^ counts isEmpty or: [ rows isEmpty ]
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> hasPendingColor [

	^ pendingColor notNil
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> hasPendingVisibility [
	"True when a visibility choice waits for the debounce."

	^ pendingVisibility isNotEmpty
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> hexField [

	^ hexField
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> hexTextChanged: aString [
	"The hexadecimal field was edited: choose the color when it is valid, else signal it in the message (no exception)."

	| color |
	isLoadingEditor == true ifTrue: [ ^ self ].
	color := self class colorFromHex: aString.
	color ifNil: [
			self showMessage: 'Invalid color: expected #RRGGBB'.
			^ self ].
	self chooseColor: color
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> hideAllDisplayed [
	"The None button: hide the displayed types."

	self showDisplayedTypes: false
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> initialExtent [

	^ 560 @ 420
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> initialize [

	generation := 0.
	debounceMilliseconds := 250.
	isLoadingEditor := false.
	pendingVisibility := Dictionary new.
	super initialize
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> initializePresenters [
	"Build the table of the types, the editor and the buttons, and subscribe to the color scheme."

	rows := OrderedCollection new.
	filterField := self newTextInput.
	filterField
		placeholder: 'Filter types';
		whenTextChangedDo: [ :text | self applyFilter: text ].
	typeTable := self newTable.
	typeTable
		addColumn: (SpImageTableColumn new
				 title: 'Color';
				 evaluated: [ :typeName | self swatchFormFor: typeName ];
				 width: 40;
				 yourself);
		addColumn: (SpStringTableColumn new
				 title: 'Type';
				 evaluated: [ :typeName | typeName asString ];
				 yourself);
		addColumn: (SpStringTableColumn new
				 title: 'Entities';
				 evaluated: [ :typeName |
					 (counts at: typeName ifAbsent: [ 0 ]) asString ];
				 width: 80;
				 yourself);
		addColumn: (SpCheckBoxTableColumn new
				 title: 'Show';
				 evaluated: [ :typeName | self isTypeShown: typeName ];
				 onActivation: [ :typeName | self setType: typeName shown: true ];
				 onDeactivation: [ :typeName | self setType: typeName shown: false ];
				 beNotExpandable;
				 width: 50;
				 yourself);
		addColumn: (SpStringTableColumn new
				 title: 'Color source';
				 evaluated: [ :typeName |
						 (self isCustom: typeName)
							 ifTrue: [ 'custom' ]
							 ifFalse: [ 'auto' ] ];
				 width: 80;
				 yourself).
	typeTable whenSelectionChangedDo: [ :selection |
		self typeSelected: selection selectedItem ].
	messageLabel := self newLabel.
	previewPresenter := self newImage.
	hexField := self newTextInput.
	hexField
		placeholder: '#RRGGBB';
		whenTextChangedDo: [ :text | self hexTextChanged: text ].
	pickButton := self newButton.
	pickButton
		label: 'Pick' , (String with: (Character value: 16r2026));
		help: 'Choose the color with a graphical color selector';
		action: [ self pickColor ].
	showAllButton := self newButton.
	showAllButton
		label: 'All';
		help: 'Show all the listed types (those matching the filter)';
		action: [ self showAllDisplayed ].
	showNoneButton := self newButton.
	showNoneButton
		label: 'None';
		help: 'Hide all the listed types (those matching the filter)';
		action: [ self hideAllDisplayed ].
	resetTypeButton := self newButton.
	resetTypeButton
		label: 'Reset type';
		help: 'Go back to the automatic color of the selected type';
		action: [ self resetSelectedType ].
	resetAllButton := self newButton.
	resetAllButton
		label: 'Reset all';
		help: 'Go back to the automatic colors of all the types';
		action: [ self resetAll ].
	closeButton := self newButton.
	closeButton
		label: 'Close';
		action: [ self close ].
	self fillTable.
	self subscribeToColorScheme
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	windowPresenter := aWindowPresenter.
	aWindowPresenter
		title: self windowTitleText;
		initialExtent: self initialExtent;
		whenClosedDo: [ self windowClosed ]
]

{ #category : 'table' }
MMCColorSettingsPresenter >> isCustom: aTypeName [
	"True when the type has an override (a pending color counts)."

	^ (pendingColor notNil and: [ pendingType = aTypeName ]) or: [
		  (colorScheme overrideFor: aTypeName) notNil ]
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> isTypeShown: aTypeName [
	"Answer whether the type is shown in the coverage window: the pending choice when there is one, else the state of the color scheme."

	^ pendingVisibility
		  at: aTypeName
		  ifAbsent: [ colorScheme isTypeVisible: aTypeName ]
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> loadEditor [
	"Show the effective color of the selected type in the preview and in the hexadecimal field, without choosing it."

	isLoadingEditor := true.
	[
		selectedType
			ifNil: [
					previewPresenter image: nil.
					hexField text: '' ]
			ifNotNil: [ :typeName |
			self showColor: (self effectiveColorOf: typeName) ] ] ensure: [
		isLoadingEditor := false ].
	self hasMessageToKeep ifFalse: [ self showMessage: '' ]
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> messageLabel [

	^ messageLabel
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> pendingColor [
	"Answer the color waiting for the debounce, nil when none."

	^ pendingColor
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> pendingVisibility [
	"Answer a copy of the choices waiting for the debounce (type name -> Boolean)."

	^ pendingVisibility copy
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> pickButton [

	^ pickButton
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> pickColor [
	"Ask colorChooser for a color, starting from the effective color of the selected type, and choose it; nothing when cancelled or when no type is selected."

	selectedType ifNil: [
			self showMessage: 'Select a type first'.
			^ self ].
	(self colorChooser value: (self effectiveColorOf: selectedType))
		ifNotNil: [ :color | self chooseColor: color ]
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> previewPresenter [

	^ previewPresenter
]

{ #category : 'table' }
MMCColorSettingsPresenter >> refreshTable [
	"Show again the colors and the custom / auto column, keeping the selection."

	| keep |
	keep := selectedType.
	isLoadingEditor := true.
	[
		typeTable refresh.
		(keep notNil and: [ rows includes: keep ]) ifTrue: [
			typeTable selectItem: keep ] ] ensure: [ isLoadingEditor := false ]
]

{ #category : 'actions' }
MMCColorSettingsPresenter >> resetAll [
	"Go back to the automatic colors (colors only: the hidden types stay hidden), dropping a color still pending. A visibility choice still pending is applied first, not lost."

	self cancelDebounce.
	self flushPendingVisibility.
	pendingType := nil.
	pendingColor := nil.
	colorScheme reset.
	self refreshTable.
	self loadEditor
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> resetAllButton [

	^ resetAllButton
]

{ #category : 'actions' }
MMCColorSettingsPresenter >> resetSelectedType [
	"Remove the override of the selected type (automatic color again), dropping a color still pending."

	selectedType ifNil: [ ^ self ].
	self cancelDebounce.
	pendingType := nil.
	pendingColor := nil.
	colorScheme removeOverrideFor: selectedType.
	self refreshTable.
	self loadEditor
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> resetTypeButton [

	^ resetTypeButton
]

{ #category : 'debounce' }
MMCColorSettingsPresenter >> scheduleApply [
	"Apply the pending color after debounceMilliseconds without new choice: any previous wait is cancelled, so the last color wins. The wait is a background process; the application is deferred to the UI process and ignored when a newer choice (or a flush, or the closing) happened meanwhile."

	| myGeneration |
	self cancelDebounce.
	myGeneration := generation.
	pendingProcess := [
		                  (Delay forMilliseconds: debounceMilliseconds) wait.
		                  UIManager default defer: [
			                  myGeneration = generation ifTrue: [
				                  self flushPendingColor ] ] ]
		                  forkAt: Processor userBackgroundPriority
		                  named: 'MMCColorSettings debounce'
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> selectTypeNamed: aTypeName [
	"Select the type in the table (as a click on its row would do); do nothing for a type that is not displayed."

	(rows includes: aTypeName) ifTrue: [ typeTable selectItem: aTypeName ]
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> selectedType [
	"Answer the type selected in the table, nil when none."

	^ selectedType
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> setType: aTypeName shown: aBoolean [
	"The user ticked or unticked the type: keep the choice (the table shows it at once) and apply it to the color scheme after the debounce delay; several choices in a row make one single application."

	aBoolean = (colorScheme isTypeVisible: aTypeName)
		ifTrue: [ pendingVisibility removeKey: aTypeName ifAbsent: [ ] ]
		ifFalse: [ pendingVisibility at: aTypeName put: aBoolean ].
	self scheduleApply
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> showAllButton [

	^ showAllButton
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> showAllDisplayed [
	"The All button: show the displayed types."

	self showDisplayedTypes: true
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> showColor: aColor [

	previewPresenter image: (self class swatchFormOf: aColor).
	hexField text: (self class hexOf: aColor)
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> showDisplayedTypes: aBoolean [
	"Show (true) or hide (false) at once all the types of the table, that is those matching the filter (all of them without filter), in one atomic application. The other types keep their state, pending choices included; a pending color keeps waiting for its own debounce."

	| hidden |
	hidden := self effectiveHiddenTypeNames.
	aBoolean
		ifTrue: [
		rows do: [ :typeName | hidden remove: typeName ifAbsent: [ ] ] ]
		ifFalse: [ hidden addAll: rows ].
	self cancelDebounce.
	pendingVisibility := Dictionary new.
	colorScheme setHiddenTypeNames: hidden.
	self refreshTable.
	self hasPendingColor ifTrue: [ self scheduleApply ]
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> showMessage: aString [

	messageLabel label: aString
]

{ #category : 'visibility' }
MMCColorSettingsPresenter >> showNoneButton [

	^ showNoneButton
]

{ #category : 'table' }
MMCColorSettingsPresenter >> sortedTypeNames [
	"Answer the type names sorted by decreasing number of entities, then by name (the biggest types are the ones that matter on the screen)."

	^ counts keys asArray sorted: [ :a :b |
			  | countA countB |
			  countA := counts at: a.
			  countB := counts at: b.
			  countA = countB
				  ifTrue: [ a asString <= b asString ]
				  ifFalse: [ countA > countB ] ]
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> subscribeToColorScheme [
	"Show again the table when the scheme changes (reset, other window). The block holds the presenter weakly."

	| reference |
	self unsubscribeFromColorScheme.
	reference := WeakArray with: self.
	subscription := [
	                reference first ifNotNil: [ :presenter |
		                presenter colorSchemeChanged ] ].
	colorScheme whenChangedDo: subscription
]

{ #category : 'table' }
MMCColorSettingsPresenter >> swatchFormFor: aTypeName [
	"Answer a 16x16 form filled with the effective color of the type (level 0)."

	^ self class swatchFormOf: (self effectiveColorOf: aTypeName)
]

{ #category : 'editor' }
MMCColorSettingsPresenter >> typeSelected: aTypeName [
	"The selection of the table changed: apply the color still pending for the previous type, then show the effective color of the new one in the editor."

	isLoadingEditor == true ifTrue: [ ^ self ].
	self flushPendingColor.
	selectedType := aTypeName.
	self loadEditor
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> typeTable [

	^ typeTable
]

{ #category : 'scheme' }
MMCColorSettingsPresenter >> unsubscribeFromColorScheme [

	subscription ifNotNil: [ :block |
			colorScheme removeSubscriber: block.
			subscription := nil ]
]

{ #category : 'actions' }
MMCColorSettingsPresenter >> windowClosed [
	"The window was closed: apply the color still pending (the last choice is not lost), unsubscribe from the scheme, make sure no process is left and let the coverage presenter forget this window."

	self flushPendingColor.
	self cancelDebounce.
	self unsubscribeFromColorScheme.
	coveragePresenter ifNotNil: [ :presenter |
		presenter colorSettingsClosed: windowPresenter ].
	coveragePresenter := nil
]

{ #category : 'initialization' }
MMCColorSettingsPresenter >> windowTitleText [
	"Answer 'Settings - <model name>', or 'Settings' without model."

	^ modelName
		  ifNil: [ 'Settings' ]
		  ifNotNil: [ :name | 'Settings - ' , name ]
]
