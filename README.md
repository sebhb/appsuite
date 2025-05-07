# appsuite
A simple command line tool for interaction with Open-Xchange's App Suite.

### Motivation

The main motivation for this tool is to be able to "fill" test accounts with demo data for demonstrational purposes in a very fast manner.

### Compatibility

This tool is compatible with any App Suite 7.10.6 or higher regardless of location. No matter whether this is an cloud installation maintained by Open Xchange or a small custom installation, behind a VPN or not. As long as it is reachable, it can be filled with data.

### Capabilities
- Importing data
  - Mails

    eml files from a source directory can be imported, either leaving them "as is" or by adjusting the recipient to the App Suite user and/or adjusting the date/time of the email to something in the most recent past. (Configurable)

  - Appointments

    A specific JSON format is used.

  - Files

    Files can only be uploaded to the root level of the user's Drive directory.

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

    The purpose of this funcitonality is two fold, a) deleting lots of appointments can be tedious, b) the way this deletion is implemented, no emails are sent to participants.

### Further help

Use `appsuite --help` for any subcommand. All custom JSON formates for data import and data generation are documented there.

### Why Swift

Swift is a modern and robust programming language. Apple's [Argument Parser](https://github.com/apple/swift-argument-parser) is a powerful package for the processing of command line arguments.
