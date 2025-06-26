#!/bin/sh

filesdir=$1
searchstr=$2

if [ $# -eq 2 ]
then
    echo "Parameters specified: directory: ${filesdir} and searchstring: ${searchstr}"
else
    echo "Parameters not specified!"
    exit 1
fi

if [ ! -d "${filesdir}" ]
then
    echo "${filesdir} is not a directory!"
    exit 1
fi

x=$(find "${filesdir}" -type f | wc -l)

y=$(find "${filesdir}" -type f -exec grep -l "${searchstr}" {} + | wc -l)

echo "The number of files are ${x} and the number of matching lines are ${y}"

exit 0