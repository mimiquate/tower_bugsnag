# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.2] - 2025-11-07

### Fixed

- Don't crash when reporting a struct in `Tower.Event.metadata` (#74)

## [0.4.1] - 2025-10-28

### Fixed

- Reports for tower messages are missing metadata and user data when available (#73)
- Don't crash when reporting elixir terms in Tower.Event.metadata that don't have native JSON representation (#70)

## [0.4.0] - 2025-09-23

### Added

- Supports configuration option `release_stage`
- Igniter compatibility and `mix tower_bugsnag.install` task.

## [0.3.6] - 2025-05-03

### Dependencies

- Don't force dependency on `jason` package if Elixir's native `JSON` module is available

## [0.3.5] - 2025-02-21

### Added

- Allows reporting `app.version` by optionally setting `config :tower_bugsnag, app_version: ...` (#43)

## [0.3.4] - 2025-02-13

### Added

- Allow use with Tower 0.8.x

### Changed

- Updates `tower` dependency from `{:tower, "~> 0.7.1"}` to `{:tower, "~> 0.7.1 or ~> 0.8.0"}`.

## [0.3.3] - 2024-11-20

### Added

- Supports reporting any Tower messages. E.g. `Tower.report_message(:info, ...)` will be reported as BugSnag error of severity "info".
- Includes information about the Device in the error report. Will be shown in the Device tab in the BugSnag UI.

## [0.3.2] - 2024-11-19

### Added

- Include in report whether exception was handled or unhandled

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

[0.4.2]: https://github.com/mimiquate/tower_bugsnag/compare/v0.4.1...v0.4.2/
[0.4.1]: https://github.com/mimiquate/tower_bugsnag/compare/v0.4.0...v0.4.1/
[0.4.0]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.6...v0.4.0/
[0.3.6]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.5...v0.3.6/
[0.3.5]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.4...v0.3.5/
[0.3.4]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.3...v0.3.4/
[0.3.3]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.2...v0.3.3/
[0.3.2]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.1...v0.3.2/
[0.3.1]: https://github.com/mimiquate/tower_bugsnag/compare/v0.3.0...v0.3.1/
[0.3.0]: https://github.com/mimiquate/tower_bugsnag/compare/v0.2.0...v0.3.0/
[0.2.0]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.3...v0.2.0/
[0.1.3]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.2...v0.1.3/
[0.1.2]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.1...v0.1.2/
[0.1.1]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.0...v0.1.1/
