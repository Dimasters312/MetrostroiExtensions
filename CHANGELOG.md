## 0.9.0 (2025-02-03)

### Feat

- add new MEL_DEBUG_CONVAR convar

### Fix

- delete ci for now

## 0.8.7 (2025-02-01)

### Feat

- start adding new docs
- **generate_client_props**: add callback for labels

### Fix

- remove debug print
- add fix for old custom bogeys
- **asnp**: draw on every panel

### Refactor

- use vector_origin, angle_zero, color_white

## 0.8.6 (2024-11-02)

### Feat

- add model precaching api
- **MEL.UpdateModelCallback**: allow to pass string with model path for simple modelcallback
- add cookiecutter template for fast creation of scoped recipies
- add lamp base data
- enable debug by default for now
- improvments for non-debug logging and spawner working
- add ability to choose scope of recipe
- add dot5 as nw2 var for 717_lvz
- add 717lvz custom
- **717_lvz**: add kvr chooser
- **spawner**: add ability to pass function as callback for autorandom
- **helpers**: add helpers which help determine wagon type
- **MarkClientPropForReload**: add ability to pass multiple field names as table with strings

### Fix

- make injects work on spawned trains on first enter
- use right var name in MEL.NewClientProp
-  do not check for server recipies on client in SinglePlayer
- make opened seat cap at zeros by default
- clear decorator cache on reload
- actually send client recipe lol
- use right BaseRecipe for this scope
- typo in ModifyButtonMap and MoveButtonMapButton
- 717_lvz_kvr_chooser
- **714**: add lvz flag
- allow usage of salon_seats and salon_lamp_types on spb 717
- add states for otsekdoors into backports
- make rolling sounds on 717 louder

### Refactor

- make 717_customization recipies scoped
- salon seats
- **salon_lamp_types**: use common vector for default color

### Perf

- optimizations and bugfixes
- try to remove all client overrides on ext_reload
- make use of Metrostroi.SpawnedTrains

## 0.5.2 (2024-08-08)

### Fix

- **AddSpawnerField**: really fix it now

## 0.5.1 (2024-08-08)

### Fix

- **AddSpawnerField**: add check for nil pos

## 0.5.0 (2024-08-08)

### Feat

- call button_callback for buttons even without model

### Refactor

- AddSpawnerField new changes from f54e459

## 0.4.0 (2024-07-21)

### Feat

- add new spawner mapping helper functions.
- add fixes for 718 cab
- add more GetMappingValue error handling
- new number ranges for 717/714. close #24

### Fix

- add more error handling into AddSpawnerField and GetEntclass
- inject randomFieldHelper into interim too, check for CustomSetting on 717/714
- fix KDL light pollution, close #37
- add additional backports for 718/719

## 0.3.0 (2024-07-11)

### Feat

- 718/719 backports

## 0.2.2 (2024-07-10)

### Fix

- **platform_backport.lua**: fix errors when trying to load passengers

## 0.2.1 (2024-07-08)

### Refactor

- refactor weighted autorandom

## 0.2.0 (2024-07-08)

### Feat

- add weighted random

### Fix

- **sh_extensions_lib.lua**: return back system inject
- **sh_extensions_lib.lua**: fix injectAnimationReloadHelper

### Refactor

- **sh_extensions_lib.lua**: remove unused print in injectAnimationReloadHelper

## 0.1.1 (2024-07-06)

### Refactor

- use DefineRecipe as train type chooser
