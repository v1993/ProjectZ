#!/usr/bin/env bash

status = 0

for f in $(find . -name '*.lua')
do
	if luac $f -o ./luac.out
	then
		rm ./luac.out
	else
		status = 1
	fi
done

exit $status
