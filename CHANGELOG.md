# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2024-11-19

### Fixed

- Properly format reported throw value

### Changed

- Updates `tower` dependency from `{:tower, "~> 0.6.0"}` to `{:tower, "~> 0.7.1"}`.

## [0.3.0] - 2024-10-24

### Changed

- Change config name from `:environment` to `:release_stage` (prefers use of BugSnag specific nomenclature)

### Fixed

- Properly report common `:gen_server` abnormal exits

## [0.2.0] - 2024-10-04

### Changed

- No longer necessary to call `Tower.attach()` in your application `start`. It is done
automatically.

- Updates `tower` dependency from `{:tower, "~> 0.5.0"}` to `{:tower, "~> 0.6.0"}`.

## [0.1.3] - 2024-10-03

### Fixed

- Corrects reported `tower_bugsnag` notifier version in payloads

## [0.1.2] - 2024-10-03

### Added

- Passes along `Tower.Event.metadata.user_id` to BugSnag report `user.id`.
- Passes along `Tower.Event.metadata` to BugSnag report `metaData`.
- Reports `user-agent` HTTP header if available.

## [0.1.1] - 2024-10-02

### Added

- Includes request data if available

### Fixed

- Don't crash on `Tower.handle_message` despite BugSnag not supporting messages.

## 0.1.0 - 2024-10-02

### Added

- Reports exceptions
- Reports throws
- Reports abnormal exits

[0.3.1]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.0...v0.3.1/
[0.3.0]: https://github.com/mimiquate/tower_bugsnag/compare/v0.2.0...v0.3.0/
[0.2.0]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.3...v0.2.0/
[0.1.3]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.2...v0.1.3/
[0.1.2]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.1...v0.1.2/
[0.1.1]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.0...v0.1.1/
