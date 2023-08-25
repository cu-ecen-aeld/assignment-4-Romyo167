#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Wrong number of arguments";
    exit 1;
else 
    filesdir=$1
    searchstr=$2
    if [ -d $filesdir ]
    then
        X=$(ls  $filesdir | wc -l);
        Y=$(grep -rnw $filesdir -e $searchstr | wc -l)
        echo "The number of files are $X and the number of matching lines are $Y" 
    else
        echo "$filesdir not a directory";
        exit 1;
    fi
fi