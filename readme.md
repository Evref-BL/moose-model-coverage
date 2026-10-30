# Moose Model Coverage

Petit outil pour visualiser la couverture de code d'un modèle Moose. Il repose sur les classes `CodeCoverageAnalyzer` et `CoverageUIBuilder`, ainsi que sur un presenter Spec.

## Prérequis

- Pharo 13
- Moose 13 (déjà chargé dans l'image, ou chargé automatiquement par la baseline, voir ci-dessous)

## Installation

### 1. Script Metacello (installation principale)

Ce script est valable pour une image Moose 13 existante comme pour une image neuve :

```smalltalk
Metacello new
  baseline: 'MooseModelCoverage';
  repository: 'github://Evref-BL/moose-model-coverage:master/src';
  load.
```

La baseline détecte si Moose est déjà présent (méthode `isMooseLoaded`, qui teste l'existence de la classe `MooseModel`) :

- si Moose est **déjà chargé** dans l'image, la baseline utilise la version actuelle de Moose et ne recharge rien ;
- sinon, elle charge Moose depuis `github://moosetechnology/Moose:development/src` (Moose 13 en développement).

Cette détection évite que Metacello tente de recharger les dépendances de Moose dans une image qui l'a déjà (notamment Ghost, incompatible avec Pharo 13, qui bloquait le chargement avec le warning « Package UNKNOWN depends on StRawInspection »).

Le groupe `default` charge les packages `MooseModelCoverage` (V1, déprécié) et `MooseModelCoverage-V2` (pas les tests).

**État de la validation :**

- Le cas « Moose déjà chargé » a été validé dans une image Pharo 13 + Moose 13, en chargeant la baseline depuis le clone local (`tonel://`).
- Le cas « Moose absent » (image neuve, chargement de Moose development depuis GitHub) n'a **pas** été testé de bout en bout.
- La correction n'est effective via `github://` qu'une fois la baseline poussée sur `master`.

### 2. Installation via Iceberg (alternative, installation de développement)

Cloner le dépôt `https://github.com/Evref-BL/moose-model-coverage.git` (branche `master`, dossier source `src`) avec l'outil Iceberg : « Add repository » puis « Clone from GitHub », avec owner `Evref-BL` et project `moose-model-coverage`.

Puis charger le package :

```smalltalk
| repo |
repo := IceRepository registry detect: [ :x | x name = 'moose-model-coverage' ].
repo workingCopy loadPackageNamed: 'MooseModelCoverage'.
repo workingCopy loadPackageNamed: 'MooseModelCoverage-V2'.
```

Pour charger aussi les tests (absents du groupe `default` de la baseline) :

```smalltalk
repo workingCopy loadPackageNamed: 'MooseModelCoverage-Tests'.
repo workingCopy loadPackageNamed: 'MooseModelCoverage-V2-Tests'.
```

## Usage (V2)

L'implémentation actuelle se trouve dans le package `MooseModelCoverage-V2`. Son point d'entrée est `MMCCoveragePresenter` :

```smalltalk
"Ouvrir le presenter sur un modèle (un fichier peut ensuite être choisi dans l'interface)"
MMCCoveragePresenter openOn: aMooseModel.

"Ouvrir le presenter directement sur un fichier source du modèle"
MMCCoveragePresenter openOn: aMooseModel file: '/path/to/File.ts'.

"Ouvrir un presenter sur un modèle d'exemple fourni"
MMCCoveragePresenter example.
MMCCoveragePresenter newExample.
```

`forModel:` et `forModel:file:` construisent le presenter sans l'ouvrir, pour l'intégrer ailleurs ou pour les tests.

## Fonctionnalités

- La couverture est calculée par caractère, espaces exclus.
- Chaque caractère est coloré selon le type de l'entité qui le couvre, en tenant compte de l'imbrication (l'entité la plus interne l'emporte).
- Les zones non couvertes sont listées.
- L'arbre du modèle est synchronisé avec le texte source : sélectionner une entité met en évidence son code, et se déplacer dans le texte sélectionne l'entité.
- Un menu contextuel (clic droit) sur l'arbre propose Inspect.
- La navigation se fait fichier par fichier, et bascule automatiquement sur le fichier de l'entité sélectionnée.

## Limites connues

- Le thème est choisi à l'ouverture du presenter ; changer de thème ensuite ne met pas à jour une fenêtre déjà ouverte.
- L'ouverture est lente sur des fichiers de plusieurs centaines de milliers de caractères.

## Déprécié

Les classes V1 `CodeCoverageAnalyzer` et `CoverageUIBuilder` (package `MooseModelCoverage`) sont conservées mais dépréciées. Appeler `CodeCoverageAnalyzer class>>runCoverageForModel:file:` signale une `Deprecation`. Utiliser `MMCCoveragePresenter` (V2) à la place.

## Tests

Les tests se trouvent dans les packages `MooseModelCoverage-Tests` (V1) et `MooseModelCoverage-V2-Tests` (V2). Ils comptent plusieurs centaines de tests, tous verts.

La baseline définit un groupe `Tests` (les deux packages de tests) :

```smalltalk
Metacello new
  baseline: 'MooseModelCoverage';
  repository: 'github://Evref-BL/moose-model-coverage:master/src';
  load: 'Tests'.
```

Utiliser `load: 'all'` pour charger ensemble le code et les tests.

Pour les lancer, ouvrir le TestRunner de Pharo et sélectionner les packages `MooseModelCoverage-Tests` et `MooseModelCoverage-V2-Tests`.

## Contenu du dépôt

Les sources sont au format Tonel dans `src/` :

- `src/BaselineOfMooseModelCoverage` : la baseline Metacello
- `src/MooseModelCoverage` : le code de l'outil V1 (déprécié)
- `src/MooseModelCoverage-Tests` : les tests V1
- `src/MooseModelCoverage-V2` : le code V2 (implémentation actuelle)
- `src/MooseModelCoverage-V2-Tests` : les tests V2
