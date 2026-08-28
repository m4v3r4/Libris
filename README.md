# Libris

A simple, offline-first library management application built with Flutter and SQLite.

Libris is designed for small school, community, personal, or local libraries that need a straightforward way to manage books, members, physical copies, and loans without depending on a server or an internet connection.

> A small project with a surprisingly real origin.

## The Story

Libris started when I was in high school.

To pass my literature class, I was given a rather unusual task: build a program for the school library and help catalogue roughly **10,000 books**.

So I wrote the first version of Libris.

What began as a school requirement turned into a real piece of software used by the library. As far as I know, it may still be running there today.

Years later, I still return to the project from time to time. Libris is not intended to become a huge enterprise library platform. It is a hobby project that I enjoy maintaining, improving, breaking, fixing, and occasionally adding new ideas to.

The goal is simple: keep it useful, understandable, offline-friendly, and easy enough for almost anyone to run.

Libris is free software released under the **GNU General Public License v3.0**. Contributions, forks, experiments, fixes, and new ideas are welcome.

## Screenshots

Screenshots of the current interface will be added here.

## Features

### 📚 Book Management

- Add, edit, delete, and browse books
- View book details
- Organize books by category
- Store shelf/location information
- Track multiple physical copies of the same title
- Assign unique inventory/barcode identifiers to physical copies
- Track copy states: available, loaned, lost, and maintenance
- Track recently added and frequently borrowed books

### 👥 Member Management

- Add, update, delete, and browse members
- Search by name, phone number, or email address
- View recently added and active members

### 🔄 Loan Management

- Check a specific physical copy out to a member
- Process book returns
- Track active, returned, and overdue loans
- Search books and members while creating a loan
- Filter loans by date and status
- Allow multiple copies of the same title to be loaned at the same time
- Prevent the same physical copy from being loaned twice

### 📊 Dashboard

- Overview of the current library state
- Book, member, and loan statistics
- Quick-access actions

### 🗄️ Database Tools

- Inspect and edit the local SQLite database
- Import and export data using JSON, CSV, and Excel
- Manage book categories

## Why Offline-First?

Libris was originally built for a real school library, where the most important requirement was simple: **the application had to work on the computer in front of the librarian**.

There was no need for an account system, cloud subscription, remote API, or permanent internet connection.

That idea is still part of the project today. The library data belongs to the library and is stored locally in SQLite.

## Tech Stack

- **Language:** Dart
- **Framework:** Flutter
- **Database:** SQLite
- **State management:** Provider
- **Architecture:** Feature-based structure with shared database services

```text
lib/
├── common/
│   ├── database/
│   ├── models/
│   ├── providers/
│   ├── services/
│   ├── theme/
│   └── widgets/
├── features/
│   ├── books/
│   ├── members/
│   ├── loans/
│   ├── home/
│   ├── settings/
│   └── dbeditor/
└── main.dart
```

## Platform Support

Libris is primarily a desktop application.

| Platform | Status |
| --- | --- |
| Windows | ✅ Primary target |
| Linux | ✅ Supported |
| macOS | ✅ Supported |
| Android | 🧪 Experimental |
| iOS | 🧪 Experimental |
| Web | ❌ Not currently supported |

Desktop platforms use `sqflite_common_ffi`, while Android and iOS use the standard `sqflite` implementation.

## Getting Started

The current release line is tested with **Flutter 3.41.9 / Dart 3.11.5**.

Clone the repository:

```bash
git clone https://github.com/m4v3r4/Libris.git
cd Libris
```

Install dependencies:

```bash
flutter pub get
```

Run the checks:

```bash
flutter analyze
flutter test
```

Run the application:

```bash
flutter run
```

For Windows, for example:

```bash
flutter run -d windows
```

## Development

The project uses GitHub Actions to run the basic quality checks on pushes and pull requests:

```text
flutter pub get
flutter analyze
flutter test
```

Desktop pull requests are also smoke-built for Windows, Linux, and macOS.

The project deliberately stays relatively small and approachable. Changes that improve reliability, usability, portability, or maintainability are especially welcome.

## Contributing

Contributions are welcome.

If you would like to improve Libris, you can:

- Report a bug through GitHub Issues
- Suggest a feature
- Pick an existing issue and submit a pull request
- Improve documentation or translations
- Test the application on another platform
- Fork the project and take it in your own direction

For larger changes, opening an issue first is useful so the idea can be discussed before implementation.

## Roadmap

Development is intentionally informal. There are things that should be fixed, things that would be nice to have, and things that may happen simply because they sound fun.

The current roadmap lives in GitHub Issues:

**[Libris Roadmap — stabilize first, then have fun 😄](https://github.com/m4v3r4/Libris/issues/31)**

Current release line: **v1.2.0**

## License

Libris is licensed under the **GNU General Public License v3.0**.

You are free to use, study, modify, and redistribute the software under the terms of the GPL.

See [`LICENSE`](LICENSE) for the full license text.
