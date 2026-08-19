#!/bin/bash
DIR_BILP_TESTS="./BILP/Tests/"
DIR_HUNGARIAN_TESTS="./Hungarian/Tests"
DIR_HUNGARIAN_RESULTS="./Hungarian/Results"

if [ ! -d "$DIR_HUNGARIAN_TESTS" ]; then
    mkdir -p "$DIR_HUNGARIAN_TESTS"
else 
    rm -rf "$DIR_HUNGARIAN_TESTS"/*
fi

for dir in "${DIR_BILP_TESTS}"/*/; do
    echo "Convertendo $dir para húngaro"
    dir_name=$(basename "$dir")
    echo "$dir" | python3 BILPtoHungarian.py > /dev/null
    mv "convert_out/" $DIR_HUNGARIAN_TESTS/${dir_name}/
done

if [ ! -d "$DIR_HUNGARIAN_RESULTS" ]; then
    mkdir -p "$DIR_HUNGARIAN_RESULTS"
else 
    rm -rf "$DIR_HUNGARIAN_RESULTS"/*
fi

for dir in "${DIR_HUNGARIAN_TESTS}"/*/; do
    echo "Executando $dir - Húngaro"
    dir_name=$(basename "$dir")
    python3 ./Hungarian/main.py -d "$dir" > $DIR_HUNGARIAN_RESULTS/${dir_name}.txt
done