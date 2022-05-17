#!/bin/bash

if [[ $1 == "--help" ]]
then
cat << ENDOFMESSAGE
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
ENDOFMESSAGE
    exit
fi

## bash colors

NO_COLOR='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

main () {
    TIMESTAMP=$(date +%s)
    # Human readable time: $(date +"%Y-%m-%dT%T.%3N%z")

    ## Config

    EXPORT_FOLDER="test/reports"
    EXPORT_FILE="coverage_$TIMESTAMP.xml"

    UNIT_TEST_PATH="./test/unit"
    EXCLUDE_PATH_TEST="./test"
    EXCLUDE_PATH_ADDONS="./addons"
    GD_FILES="*.gd"

    ## Variables

    NO_GD_FILES_TO_TEST=0
    GD_FILES_TO_TEST=()

    NO_GD_TESTING_FILES=0
    GD_TESTING_FILES=()

    ## Main

    echo -e "Running ${GREEN}Godot coverage hack${NO_COLOR} by kbs...\n"

    echo "Looking for gdscript files..."

    NO_GD_FILES_TO_TEST=$(find . -type d \( -path $EXCLUDE_PATH_TEST -o -path $EXCLUDE_PATH_ADDONS \) -prune -o -name $GD_FILES -print | wc -l)

    echo -e $NO_GD_FILES_TO_TEST "gdscript files found\n"

    if [ $NO_GD_FILES_TO_TEST != 0 ]
    then
        readarray -d '\n' GD_FILES_TO_TEST < <(find . -type d \( -path $EXCLUDE_PATH_TEST -o -path $EXCLUDE_PATH_ADDONS \) -prune -o -name $GD_FILES -print | grep -o '[^/]*$')

        echo -e "[${GREEN}✓${NO_COLOR}] Done indexing scripts\n"

        echo "Looking for unit test files..."

        if [[ ! -d $UNIT_TEST_PATH ]]
        then
            echo -e "[${RED}X${NO_COLOR}] Error: directory $UNIT_TEST_PATH not found."
            exit 1
        fi

        NO_GD_TESTING_FILES=$(find $UNIT_TEST_PATH -name $GD_FILES -print | wc -l)

        echo -e $NO_GD_TESTING_FILES "unit test files found\n"

        if [[ $NO_GD_TESTING_FILES == 0 ]]
        then
            echo -e "[${GREEN}✓${NO_COLOR}] Coverage report finished: no tests."
            exit
        fi

        readarray -d '\n' GD_TESTING_FILES < <(find $UNIT_TEST_PATH -name $GD_FILES -print | grep -o '[^/]*$' | cut -c 6-)

        echo -e "[${GREEN}✓${NO_COLOR}] Done indexing tests\n"

        echo -e "Running basic code (file) coverage..."

        MISSING_TESTS=()
        MATCHED_TESTS=()
        for script in $GD_FILES_TO_TEST
        do
            match=0
            for test in $GD_TESTING_FILES
            do
                if [[ $script == $test ]]
                then
                    MATCHED_TESTS+=("$test")
                    match=1
                fi
            done
            if [[ $match == 0 ]]
            then
                MISSING_TESTS+=("$script")
            fi
        done

        if [[ $1 == "--verbose" ]]
        then
            sorted=($(echo "${MATCHED_TESTS[@]}" | sed 's/ /\n/g' | sort))
            echo
            for name in ${sorted[@]}
            do
                echo -e "[${GREEN}✓${NO_COLOR}] Found unit test for" $name
            done
            sorted=($(echo "${MISSING_TESTS[@]}" | sed 's/ /\n/g' | sort))
            for name in ${sorted[@]}
            do
                echo -e "[${RED}X${NO_COLOR}] Missing test for" $name;
            done
        fi

        echo -e ${YELLOW}
        WARNING="[!] Warning: test without matching script: test_"
        echo -e ${GD_TESTING_FILES} ${MATCHED_TESTS[@]} | tr ' ' '\n' | sort | sed "s/^/${WARNING}/" | uniq -u
        echo -e ${NO_COLOR}

        echo_summary
        output_file
    else
        echo -e "[${GREEN}✓${NO_COLOR}] Done, no files to cover."
    fi
}

echo_summary() {
cat << ENDOFMESSAGE
--- Coverage Report ---

- Scripts -
Tested:          ${#MATCHED_TESTS[@]}
Untested:        ${#MISSING_TESTS[@]}
Total:           $NO_GD_FILES_TO_TEST

- Tests -
Valid:           ${#MATCHED_TESTS[@]}
Unused:          $(echo ${GD_TESTING_FILES} ${MATCHED_TESTS[@]} | tr ' ' '\n' | sort | uniq -u | wc -l)
Total:           $NO_GD_TESTING_FILES

Coverage:        $(awk "BEGIN{printf(${#MATCHED_TESTS[@]}/$NO_GD_FILES_TO_TEST*100)}")%

[✓] Coverage report finished
ENDOFMESSAGE
}

output_file() {
mkdir -p $EXPORT_FOLDER
cat >$EXPORT_FOLDER/$EXPORT_FILE << ENDOFMESSAGE
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">
<coverage line-rate="1" branch-rate="1" \
lines-covered="${#MATCHED_TESTS[@]}" \
lines-valid="$NO_GD_FILES_TO_TEST" \
branches-covered="0" \
branches-valid="0" \
complexity="0" \
version="0" \
timestamp="$TIMESTAMP">
</coverage>
ENDOFMESSAGE
}

main $1
