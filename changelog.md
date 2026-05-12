# Ecosystem Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Anything documented with **RELEASED** is a downloadable version from [releases](https://github.com/Green-Screen/SecureClasses/releases)

### [The most recent Release](https://green-screen.github.io/Ecosystem/docs/Install)

--------------------------------------------------------------------------------------------------

## V: [2.1.3] - 05-08-2026
### **RELEASED**

### Changes:
-   Documentation updates to reflect new `__destroy` limitations and behaviours

--------------------------------------------------------------------------------------------------

## V: [2.1.0] - 05-08-2026

### Added:
-   NewIndex protections in Metadata table

### Changes:
-   `__destroy` function run order
-   Better memory linking and utilization

--------------------------------------------------------------------------------------------------

## V: [2.0.1] - 05-06-2026
### **RELEASED**

### Added:
-   Documentation through [Moonwave](https://github.com/evaera/moonwave)

--------------------------------------------------------------------------------------------------

## V: [2.0.0] - 05-05-2026

### Removed:
-   TransferMetatable Class
-   Userdata object support due to low use cases

### Added:
-   New Metamethod `__typeKey`
-   Runtime protections for `_Private`, `__metamethod`, `___Public`, and `Default` property classes


### Changed:
-   Module returns function instead of dictionary
-   Temporarily removed type function from type cast

--------------------------------------------------------------------------------------------------

## V: [1.0.0] - 04-12-2026
### **RELEASED**

- Initial release.