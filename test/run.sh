#!/usr/bin/env bash

set -e

ROOT="$( cd "$( dirname "$0" )/.." && pwd )"
cd "$ROOT"

# Clean previous builds, prepare the test environment and call build again with
# a test setup.
sed -i 's/.ifdef RUN_TESTS/RUN_TESTS = 1\n.ifdef RUN_TESTS/g' "$ROOT/test/suite.s"
DEBUG=1 make test/suite.nes

rm -f "$ROOT/tmp/test-results.txt"

# Github Actions do not allow GUI programs to be run. This means that the code
# below will always fail (fceux won't be able to run). There is a way to emulate
# an X server with tools like xvfb-run or xvncserver, but so far I've had no
# luck on this front.
if [ ! -z "${GITHUB_ACTION}" ]; then
    exit 0
fi

# Run all the tests that we have on Lua.
for file in test/*.lua; do
    if [ -n "$(echo $file | grep -v utils.lua)" ]; then
        echo $file
        fceux --loadlua $file "$ROOT/test/suite.nes"
    fi
done

#
# Show the results.

if [ ! -f "$ROOT/tmp/test-results.txt" ]; then
    echo "Something went wrong: test results were not printed out!"
    exit 1
fi

cat "$ROOT/tmp/test-results.txt"

n=$(cat "$ROOT/tmp/test-results.txt" | grep FAIL | wc -l)
echo ""
case $n in
    0)
        echo "All tests passed!"
        exit 0
        ;;
    1)
        echo "1 test failed!"
        exit 1
        ;;
    *)
        echo "$n tests failed!"
        exit 1
        ;;
esac
