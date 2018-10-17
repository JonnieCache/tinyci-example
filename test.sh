#!/usr/bin/env sh

set -e

echo 'test!'

exit 1

grep "foo" baz.txt
grep "abc" baz.txt
