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

Le groupe `default` ne charge que le package `MooseModelCoverage` (pas les tests).

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
```

Pour charger aussi les tests (absents du groupe `default` de la baseline) :

```smalltalk
repo workingCopy loadPackageNamed: 'MooseModelCoverage-Tests'.
```

## Tests

Les tests se trouvent dans le package `MooseModelCoverage-Tests`. Il n'y a actuellement qu'un seul test, `CodeCoverageAnalyzerTest>>testCoveredLines`, qui est un placeholder : il échoue volontairement (`self assert: false`).

## Contenu du dépôt

Les sources sont au format Tonel dans `src/` :

- `src/BaselineOfMooseModelCoverage` : la baseline Metacello
- `src/MooseModelCoverage` : le code de l'outil
- `src/MooseModelCoverage-Tests` : les tests
