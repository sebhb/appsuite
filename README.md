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

### Why Swift

[Swift](https://www.swift.org) is a modern and robust programming language. Apple's [Argument Parser](https://github.com/apple/swift-argument-parser) is a powerful package for the processing of command line arguments. Swift uses [ARC](https://en.wikipedia.org/wiki/Automatic_Reference_Counting) and not Garbage Collection with all of its disadvantages.

### Demo

There is a small sample script in the "Demo" folder. It takes three parameters (host, username and password) and then fills the according account with test data. A little command line knowledge is required.
1. Copy the `appsuite` binary from the Binary folder to your `PATH`.
2. Alternatively, you can edit the `demo.sh` script and replace `appsuite` with the full path to the command
3. Execute the demo script: `demo.sh <host> <username> <password>`

### TODOs
- Tests
- Error Handling
- Path operations
  - Currently only tested on macOS, not on Windows
  - Currently relative paths are not supported (traversing hierarchy up using `..`)
- Importing VCF
- Importing ICS
- Optimizations
  - Use [Multiple](https://documentation.open-xchange.com/components/middleware/http/8/index.html#!Multiple) Calls to combine several smaller calls
- Uploading Files
  - Chunked upload for larger files
  - Upload hierarchies (not only to Drive root)
- Cross Platform workaround for ListFormatter on Linux currently only supports Locale en for lists
  
### Cross Compiling on a Mac for Linux
This statically compiles, including the swift runtime. The binary requires a Linux that supports glibc 2.38 like Ubuntu 23.10 or Fedora 38. Red Hat Linux (up to 9.x) does not support this.

`docker run --platform linux/amd64 --rm -v "$PWD":/src -w /src swift:6.0 /bin/bash -c "swift package clean && swift build -c release -Xswiftc -static-stdlib"`
