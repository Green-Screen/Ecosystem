# Ecosystem Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Anything documented with **RELEASED** is a downloadable version from [releases](https://github.com/Green-Screen/Ecosystem/releases)

### [The most recent Release](./docs/Install)

--------------------------------------------------------------------------------------------------

## V: [2.4.1] - 05-14-2026
### **RELEASED**

### Added:
-   Documentation through [Moonwave](https://github.com/evaera/moonwave)

--------------------------------------------------------------------------------------------------

## V: [2.4.0] - 05-11-2026

### Added:
-   Embedded [SecureClasses](https://green-screen.github.io/SecureClasses) into the service
-   New API through `SecureClasses`: `Destroy`, `Opertable`
-   New global API: `GetEcosystemFromSpecie` & `GetSpeciesFromBindedInstance`
-   New Test script

### Changes:
-   `Ecosystem` & `Species` is now `SecuredMetatable` wrapped
-   All properties are properly protected through `SecureClasses`

--------------------------------------------------------------------------------------------------

## V: [2.1.0] - 04-08-2026
### **RELEASED**

### Added:
-   New complex types with the new type solver
-   New `Stop` reserved string to return to also stop

### Changed:
-   `Stop` function is new able to run inside of the system loop

### Fixed:
-   Events now broadcast their params in the right order.
-   Fixed `StateChanged` returning the same string twice

--------------------------------------------------------------------------------------------------

## V: [2.0.0] - 03-21-2026
### **RELEASED**

### Removed:
-   API: `AddStates`, `AddCustomProperties`

### Added:
-   New API: `ForceState`, `StateChanged`, `EnviormentUpdate`, `ForceAllStates`


### Changed:
-   Full class rewrite
-   Expanded ontop of the api.
-   Class name changes `Ecosystem`, `Species`

--------------------------------------------------------------------------------------------------

## V: [1.0.0] - 12-01-2025
### **RELEASED**

- Initial release.