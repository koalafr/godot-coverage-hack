# godot-coverage-hack

* [TL;DR](#tldr)
* [Description](#description)
* [Installation](#installation)
* [Options](#options)
* [Usage](#usage)
* [CI Usage](#ci-usage)
* [Contribute](#contribute)
* [Code of Conduct](#code-of-conduct)
* [License](#license)

## TLDR

- Get the tool in your project & use bash to set it as executable
- `chmod +x ./godot_coverage_hack.sh`
- Create some unit tests
- `mkdir -p test/unit && touch test/unit/test_Koala.gd`
- Create some features
- `touch Koala.gd`
- Optional: Implement Koala features and unit test
- Run `./godot_coverage_hack.sh`

## Description

```
Godot Coverage Hack, version 1.0.1-release
Usage: godot_coverage_hack.sh [option]
Options:
    --verbose
       print missing and matching tests to console
    --help
       print this notice then exit
Description:
    This tool creates pseudo-coverage reports for gdscript files and godot projects
    It finds ".gd" files and then looks for the corresponding unit test, ignores file content
    Call it from the project root to find missing tests files
    Integrate it into CI/CD for fancy coverage report badges
    One script - One test - One percentage.
Tests:
    A unit test must begin with "test_" followed by the name of the script it tests
    A unit test must be located in ./test/unit/ (configurable:UNIT_TEST_PATH)
    The tested scripts can be anywhere/subfolders but the test/ and addons/ folders are skipped
    For example: "res://player/Player.gd" will match "res://test/unit/test_Player.gd"
Coverage Report:
    Coverage Report is exported to ./test/reports (configurable:EXPORT_FOLDER)
    It's a fake-cobertura xml: "coverage_<timestamp>.xml" (configurable:EXPORT_FILE)
    It supports std out regexp parsing: '/Coverage:.*\s([.\d]+)%/' and is usable in CI/CD

Information:
    Tested with Gut <https://github.com/bitwes/Gut> but should work with any plugin
    More info and ci config yaml example @ <https://github.com/koalafr/godot-coverage-hack>
    Alex K, Koala Bear Studios 2022
```

## Installation

- Git pull `https://github.com/koalafr/godot-coverage-hack.git`

- Allow executing file: `chmod +x ./godot_coverage_hack.sh`

- Optional: Copy the tool to `<project_root>/tools/`


## Options

Godot Coverage Hack warns about tests with no matching scripts

- `--verbose` prints out all file names as it misses and matches

- `--help` prints out information then exits


## Usage

- Navigate to your godot project root directory

- Run the tool in bash: `./tools/godot_coverage_hack.sh`

- Example output:

```
$ ./tools/godot_coverage_hack.sh --verbose
Running Godot coverage hack by kbs...

Looking for gdscript files...
2 gdscript files found

[???] Done indexing scripts

Looking for unit test files...
2 unit test files found

[???] Done indexing tests

Running basic code (file) coverage...

[???] Found unit test for human.gd
[X] Missing test for koala.gd

[!] Warning: test without matching script: test_cat.gd

--- Coverage Report ---

- Scripts -
Tested:          1
Untested:        1
Total:           2

- Tests -
Valid:           1
Unused:          1
Total:           2

Coverage:        50%

[???] Coverage report finished
```

## CI Usage

- Add `test/reports/` to `.gitignore`

- Copy the tool to a convenient location: `<project_root>/tools/`

- Add a new coverage job in yaml config and run the tool

- Parse the stdout or the cobertura xml report file for coverage percentage

- Enjoy pseudo-coverage report badge, and increase it by adding unit tests

Example yaml for a coverage-report-job with valid parsing

Gitlab runner on ubuntu image:
```yaml
coverage-report-job:
  variables:
    TEST_OUTPUT_FOLDER: test/reports
  script:
    - mkdir -v -p $TEST_OUTPUT_FOLDER
    - chmod +x ./tools/godot_coverage_hack.sh
    - ./tools/godot_coverage_hack.sh --verbose
  coverage: '/Coverage:.*\s([.\d]+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: $TEST_OUTPUT_FOLDER/coverage_*.xml
```

## Contribute

[Contributing to Godot Coverage Hack](/docs/CONTRIBUTING.md)

## Code of Conduct

[Contributor Covenant](/docs/CODE_OF_CONDUCT.md)

## License

[MIT license](/LICENSE)
