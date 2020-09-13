# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
 - Upcoming feature description.

## [Major.Minor.Revision-Pre.release+Build.metadata] - YYYY-MM-DD
### Added
 - Description.
### Changed
 - Description.
### Depreciated
 - Description.
### Removed
 - Description.
### Fixed
 - Description.
### Security
 - Description.

***

# Change Log Formatting
Github markdown guide can be found at https://guides.github.com/features/mastering-markdown/
## Change Log version 1.0.0
### Summary
- Change Log
    All notable changes to this project will be documented in this file.
    The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
    - [Unreleased]
        - Keep an Unreleased section at the top to track upcoming changes.
        - This serves two purposes:
            - People can see what changes they might expect in upcoming releases
            - At release time, you can move the Unreleased section changes into a new release version section.
    - [Major.Minor.Revision-Pre.release+Build.metadata] - YYYY-MM-DD
        - Added
            - New features.
        - Changed
            - Changes in existing functionality.
        - Depreciated
            - Soon-to-be removed features.
        - Removed
            - Now removed features.
        - Fixed
            - Any bug fixes.
        - Security
            - Changes dealing with vulnerabilities.
    - Guiding Principles
        - Changelogs are for humans, not machines.
        - There should be an entry for every single version.
        - The same types of changes should be grouped.
        - Versions and sections should be linkable.
        - The latest version comes first.
        - The release date of each version is displayed.
        - Mention whether you follow Semantic Versioning.

## Semantic Versioning 2.0.0
### Summary
- Given a version number MAJOR.MINOR.PATCH, increment the:
    - MAJOR version when you make incompatible API changes,
    - MINOR version when you add functionality in a backwards compatible manner, and
    - PATCH version when you make backwards compatible bug fixes.
    - Additional labels for pre-release and build metadata are available as extensions to the MAJOR.MINOR.PATCH format.
        - Pre-release data may be appended with hyphen and a series of dot separated an ASCII alphanumeric identifiers.
            - Pre-release data used in this repository:
                - "rc" or "rc.#" - Release Candidate.
                - "beta" or "beta.#" - Beta version.
                - "alpha" or "alpha.#" -Alpha version.
            - Examples:
                - 0.1.0-alpha.1  >  0.1.0-alpha
                - 0.1.1-beta.2  >  0.1.0-beta.1
                - 0.9.99-rc.3  >  0.9.98-rc.4
        - Build metadata may be appended with a plus and a series of dot separated ASCII alphanumeric identifiers.
            - Build meta data used in this repository:
                - "f0f0f0f" - Build number or git commit identifier.  Used if many builds or commits are used and knowing which one is the official version listed in the change log.
                - "yyyyMMdd" - Date in four-digit year, two-digit month, and two-digit day format.
                - "sha.f0f0f0" - SHA signature with "sha." followed by hexidecimal data.
            - Examples:
                - 0.1.0-alpha+340f5c2
                - 0.1.1-beta+20191121
                - 0.9.9-rc+sha.f0e1d0c
- RegEx: ```^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$```
