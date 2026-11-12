# appsuite
A simple command line tool for interaction with [Open-Xchange's App Suite](https://www.open-xchange.com/products/ox-app-suite).

### Motivation

The main motivation for this tool is to be able to "fill" test accounts with demo data for demonstrational purposes in a very fast manner.

### Compatibility

This tool is compatible with any App Suite 7.10.6 or higher regardless of location. No matter whether this is a cloud installation maintained by Open-Xchange or a small custom installation, behind a VPN or not. As long as it is reachable, it can be filled with data.

### Capabilities
- Importing data
  - Mails

    eml files from a source directory can be imported, either leaving them "as is" or by adjusting the recipient to the App Suite user and/or adjusting the date/time of the email to something in the most recent past. (Configurable)

  - Appointments

    A specific JSON format is used.

  - Files

    Files can be uploaded to the root level of the user's Drive directory.

  - Tasks

    A specifix JSON format is used.

  - Contacts

    A specific JSON format is used.

- Generating data
  - Appointments

    For demonstration purposes, appointments can be generated for a specifix time frame. A JSON file specifies templates that will be used to generate appointments.
    
  - Contacts

    Also for demonstration purposes, random contacts can be generated. First names, last names, avatar images and addresses can be randomized.
    
- Deleting data
  - Appointments

    The purpose of this functionality is two fold, a) deleting lots of appointments via the UI can be tedious, b) the way this deletion is implemented, no emails are sent to participants.

### Further help

Use `appsuite --help` for any subcommand. All custom JSON formates for data import and data generation are documented there.

### Web service

Alongside the CLI there is a small web service (in the `webservice/` directory) that offers
the same seeding through a browser UI: enter a server URL and credentials, tick which
categories to seed (mails, contacts, appointments, tasks, files), and watch live progress.
It reuses the same `AppsuiteCore` library the CLI is built on, and can be run locally or as
a container. See [`webservice/README.md`](webservice/README.md).

The CLI also gained a `check drive` subcommand that reports whether the Drive capability is
enabled for a user (the web service uses this to gate file uploads).

### Why Swift

[Swift](https://www.swift.org) is a modern and robust programming language. Apple's [Argument Parser](https://github.com/apple/swift-argument-parser) is a powerful package for the processing of command line arguments. Swift uses [ARC](https://en.wikipedia.org/wiki/Automatic_Reference_Counting) and not [Garbage Collection with all of its disadvantages](https://www.swift.org/blog/swift-at-apple-migrating-the-password-monitoring-service-from-java/).

### Demo

There is a small sample script in the "Demo" folder. It takes three parameters (host, username and password) and then fills the according account with test data. A little command line knowledge is required.
1. Copy the `appsuite` binary from the Binary folder to your `PATH`.
2. Alternatively, you can edit the `demo.sh` script and replace `appsuite` with the full path to the command
3. Execute the demo script: `demo.sh <host> <username> <password>`

### TODOs
- Tests beyond mail import (contacts, appointments, tasks, Drive)
- Error Handling
- Path operations
  - Currently only tested on macOS, not on Windows
  - Currently relative paths are not supported (traversing hierarchy up using `..`)
- Importing VCF
- Importing ICS
- Optimizations
  - Mail import already batches several mails per request (`--maxBatchSizeMB`, `--maxBatchCount`); other modules still send one request per item and could use [Multiple](https://documentation.open-xchange.com/components/middleware/http/8/index.html#!Multiple) Calls
  - Mail import loads a whole folder into memory; streaming (sizing batches from file sizes on disk) would bound memory for very large folders
- Uploading Files
  - Chunked upload for larger files
- Cross Platform workaround for ListFormatter on Linux currently only supports Locale en for lists
  
### Prebuilt binaries

The `Binaries` folder (stored with [Git LFS](https://git-lfs.com), run `git lfs pull` after cloning) contains ready-to-use builds:

| File | Platform |
|---|---|
| `Binaries/macOS/appsuite` | macOS 13 or later, Apple Silicon (arm64) |
| `Binaries/x86 Linux/appsuite` | any x86-64 Linux, fully statically linked (no glibc dependency) |
| `Binaries/Docker Images/appsuite-seeder.tar.gz` | web service image for `linux/amd64`, see [`webservice/DEPLOY.md`](webservice/DEPLOY.md) |

The sections below describe how to rebuild them.

### Toolchain

The package needs Swift 6.0 or later. On a Mac, use the toolchain that ships with Xcode.

> **Note:** If [swiftly](https://www.swift.org/install/macos/) is installed, a plain `swift` command may resolve to a swiftly toolchain instead of Xcode's (for example when a `.swift-version` file pins one). Swiftly toolchains older than your macOS SDK can fail with errors such as `unknown argument: '-target-arch-variant'` or a compiler crash. Call Xcode's toolchain explicitly with `xcrun swift …` (or `/usr/bin/swift …`) to avoid this.

### Building for macOS

```bash
cd appsuite
xcrun swift build -c release
cp .build/release/appsuite ../Binaries/macOS/appsuite
```

The binary is built for the architecture of the building Mac (arm64 on Apple Silicon).

### Building for Linux on Linux

Install Swift from [swift.org](https://www.swift.org/install/linux/), then:

```bash
cd appsuite
swift build -c release
```

This binary links against the system's glibc. For a binary that runs on any distribution, use the static build below.

### Building the static Linux binary on a Mac

This uses the [Static Linux SDK](https://www.swift.org/documentation/articles/static-linux-getting-started.html) to produce a fully statically linked x86-64 binary (musl instead of glibc) that runs on **any** x86-64 Linux distribution regardless of its glibc version. The build runs in the official Swift container, so it works independent of the Mac's own toolchain and SDK. Only [Docker](https://www.docker.com/products/docker-desktop/) is required.

From the repository root:

```bash
docker run --rm --platform linux/arm64 \
  -v "$PWD/appsuite":/src:ro -v "$PWD/Binaries/x86 Linux":/out \
  swift:6.2.3 bash -euc '
    swift sdk install https://download.swift.org/swift-6.2.3-release/static-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
      --checksum f30ec724d824ef43b5546e02ca06a8682dafab4b26a99fbb0e858c347e507a2c
    mkdir /work && tar -C /src --exclude=./.build --exclude=./.swiftpm -cf - . | tar -xf - -C /work
    cd /work && swift build -c release --swift-sdk x86_64-swift-linux-musl
    llvm-objcopy --strip-all .build/release/appsuite /out/appsuite'
```

- `--platform linux/arm64` runs the compiler natively on Apple Silicon; the Static Linux SDK cross-compiles to x86-64. On an Intel Mac use `linux/amd64`.
- The sources are copied into the container so the Mac's `.build` folder is left untouched.
- `llvm-objcopy --strip-all` removes debug symbols (the container's `strip` only handles arm64 binaries).
- The container image version and the SDK version must match. When updating, take both from [swift.org](https://www.swift.org/documentation/articles/static-linux-getting-started.html) together with the SDK checksum.

To check the result on a minimal distribution:

```bash
docker run --rm --platform linux/amd64 -v "$PWD/Binaries/x86 Linux":/b:ro alpine:3.20 /b/appsuite --help
```

<details>
<summary>Alternative: cross-compiling with swiftly instead of Docker</summary>

This only works if the swiftly toolchain supports the installed macOS SDK (see the note under [Toolchain](#toolchain)).

```bash
# one-time setup
curl -O https://download.swift.org/swiftly/darwin/swiftly.pkg && \
installer -pkg swiftly.pkg -target CurrentUserHomeDirectory && \
~/.swiftly/bin/swiftly init --quiet-shell-followup && \
. ~/.swiftly/env.sh
swift sdk install https://download.swift.org/swift-6.2.3-release/static-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
  --checksum f30ec724d824ef43b5546e02ca06a8682dafab4b26a99fbb0e858c347e507a2c

# build
. ~/.swiftly/env.sh
cd appsuite
swift build -c release --swift-sdk x86_64-swift-linux-musl
```

The binary will be at `.build/release/appsuite`.
</details>

### Building the web service image

```bash
cd webservice
./build-image.sh
```

This builds the `linux/amd64` image (using emulation on Apple Silicon) and writes it to `Binaries/Docker Images/appsuite-seeder.tar.gz`. The image bundles the `Demo` folder, so make sure it only contains what should ship. Deploying the tarball to a server is described in [`webservice/DEPLOY.md`](webservice/DEPLOY.md).

### Running the tests

The tests don't need an App Suite server: the mail import is tested end to end against an in-memory fake of the HTTP API.

```bash
cd appsuite
xcrun swift test
```

On Linux, or in the Swift container from the repository root:

```bash
docker run --rm -v "$PWD/appsuite":/src:ro swift:6.2.3 bash -euc \
  'mkdir /work && tar -C /src --exclude=./.build -cf - . | tar -xf - -C /work && cd /work && swift test'
```
