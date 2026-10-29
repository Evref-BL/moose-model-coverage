# Moose Model Coverage

Petit outil pour visualiser la couverture de code d'un modèle Moose. Il repose sur les classes `CodeCoverageAnalyzer` et `CoverageUIBuilder`, ainsi que sur un presenter Spec.

## Prérequis

- Pharo 13
- Moose 13

## Installation

### 1. Image Pharo neuve (script Metacello)

```smalltalk
Metacello new
  baseline: 'MooseModelCoverage';
  repository: 'github://Evref-BL/moose-model-coverage:master/src';
  load.
```

La baseline charge Moose depuis `github://moosetechnology/Moose:development/src`. Le groupe `default` ne charge que le package `MooseModelCoverage` (pas les tests).

Ce script est donné pour une image Pharo neuve. Il n'a pas été testé de bout en bout.

### 2. Note importante : image où Moose 13 est déjà chargé

Dans une image où Moose 13 est **déjà** chargé, le script Metacello ci-dessus tente de recharger des dépendances de Moose, notamment Ghost, qui est incompatible avec Pharo 13 (warning « Package UNKNOWN depends on StRawInspection »). Le chargement se bloque alors. Dans ce cas, utiliser l'installation via Iceberg ci-dessous.

### 3. Installation via Iceberg dans une image Moose 13 existante

Cloner le dépôt `https://github.com/Evref-BL/moose-model-coverage.git` (branche `master`, dossier source `src`) avec l'outil Iceberg : « Add repository » puis « Clone from GitHub », avec owner `Evref-BL` et project `moose-model-coverage`.

Puis charger les packages :

```smalltalk
| repo |
repo := IceRepository registry detect: [ :x | x name = 'moose-model-coverage' ].
repo workingCopy loadPackageNamed: 'MooseModelCoverage'.
repo workingCopy loadPackageNamed: 'MooseModelCoverage-Tests'.
```

## Tests

Les tests se trouvent dans le package `MooseModelCoverage-Tests`. Il n'y a actuellement qu'un seul test, `CodeCoverageAnalyzerTest>>testCoveredLines`, qui est un placeholder : il échoue volontairement (`self assert: false`).

## Contenu du dépôt

Les sources sont au format Tonel dans `src/` :

- `src/BaselineOfMooseModelCoverage` : la baseline Metacello
- `src/MooseModelCoverage` : le code de l'outil
- `src/MooseModelCoverage-Tests` : les tests
