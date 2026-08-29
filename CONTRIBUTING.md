# Contributing to Libris

Thanks for taking the time to contribute to Libris.

Libris is a small, offline-first Flutter application. Contributions that improve reliability, usability, portability, accessibility, translations, documentation, or maintainability are welcome.

## Before You Start

- Check the existing issues before opening a new one.
- For larger changes, open or comment on an issue first so the direction can be discussed.
- Keep pull requests focused. Unrelated cleanup should usually be a separate change.
- Avoid introducing network or cloud dependencies unless the feature genuinely requires them; offline-first behavior is a core project goal.
- Keep database and business-logic changes separate from visual-only changes where practical.

## Development Setup

The current release line is tested with Flutter `3.41.9` and Dart `3.11.5`.

```bash
git clone https://github.com/m4v3r4/Libris.git
cd Libris
flutter pub get
```

Run the app on your target platform, for example:

```bash
flutter run -d windows
```

## Code Style

- Follow standard Dart and Flutter conventions.
- Run `dart format` on changed Dart files.
- Prefer small reusable widgets and services over duplicated screen-local logic.
- Do not hard-code user-facing text when an existing localization path can be used.
- Preserve light and dark theme support for UI changes.
- Avoid unnecessary dependencies, especially for functionality Flutter or Dart already provides.

## Checks

Before submitting a pull request, run the checks relevant to your change:

```bash
flutter analyze
flutter test
```

For documentation-only changes, a full Flutter test run is not required.

The GitHub Actions workflow also performs analyze/test checks and desktop smoke builds for Windows, Linux, and macOS.

## Pull Requests

A good pull request should:

- Explain the problem and the chosen solution.
- Link the related issue when one exists (`Closes #123`).
- Mention any behavior or database compatibility impact.
- Include screenshots for visible UI changes.
- Keep generated files, local databases, build artifacts, and editor-specific files out of the commit.
- Keep the commit history reasonably clean and focused.

## Reporting Bugs

Use the bug report issue form and include:

- operating system and version,
- Libris version,
- steps to reproduce,
- expected behavior,
- actual behavior,
- relevant logs or screenshots.

Do not include private library data, member information, credentials, or other sensitive information in public issues.

## Feature Requests

Feature requests are welcome, but Libris intentionally stays relatively small. A feature is a particularly good fit when it improves day-to-day local library workflows without making the application unnecessarily complex or dependent on online services.

## Security Issues

Do not report security vulnerabilities in a public issue. Follow the instructions in [`SECURITY.md`](SECURITY.md).

## Code of Conduct

By participating in this project, you agree to follow [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions will be distributed under the project's GNU General Public License v3.0.
