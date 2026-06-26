#!/bin/bash

SESSIONS=(5 10 20)
TIMESLOTS=(4000 2000 1000)
USERS=10
DIR_TESTS="./Tests/"
DIR_RESULTS="./Results/"

if [ ! -d "$DIR_TESTS" ]; then
    mkdir -p "$DIR_TESTS"
else 
    rm -rf "$DIR_TESTS"/*
fi

if [ ! -d "$DIR_RESULTS" ]; then
    mkdir -p "$DIR_RESULTS"
else 
    rm -rf "$DIR_RESULTS"/*
fi

for i in "${!TIMESLOTS[@]}"; do
    ts=${TIMESLOTS[$i]}
    sessions=${SESSIONS[$i]}

    mkdir -p "${DIR_TESTS}/${ts}-TS"

    for ((j=1; j<=sessions; j++)); do
        # echo "\tCriando teste TIMESLOTS=$ts (sessão $j de $sessions)"
        printf "%s\n%s\n" "$ts" "$USERS" | python3 randomBILPGenerator.py > /dev/null
        mv "BILP.dat" "${DIR_TESTS}/${ts}-TS/BILP_${j}.dat"
    done
done

for dir in "${DIR_TESTS}"/*/; do
    echo "Executando $dir"
    dir_name=$(basename "$dir")
    python3 BILP.py -d "$dir" > $DIR_RESULTS/${dir_name}.txt
done