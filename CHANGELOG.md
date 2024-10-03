# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.2]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.1...v0.1.2/
[0.1.1]: https://github.com/mimiquate/tower_bugsnag/compare/v0.1.0...v0.1.1/
