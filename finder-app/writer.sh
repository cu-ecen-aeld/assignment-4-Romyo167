#!/bin/sh


if [ $# -ne 2 ]
then
    echo "Wrong number of arguments";
    exit 1;
else 

    { echo $2 > $1 ;} || {
        echo "file could not be created";
        exit 1;
    } 
fi