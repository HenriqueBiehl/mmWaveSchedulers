#!/bin/bash

SESSIONS=(1 1 1)
TIMESLOTS=(10000 10000 10000)
USERS=(10 25 50)

if [[ ${#SESSIONS[@]} -ne ${#TIMESLOTS[@]} ||
      ${#SESSIONS[@]} -ne ${#USERS[@]} ]]; then
    echo "Erro: SESSIONS, TIMESLOTS e USERS devem ter o mesmo tamanho."
    exit 1
fi

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
    users=${USERS[$i]}

    test_dir_result="${ts}TS-${sessions}S-${users}U"
    mkdir -p "${DIR_TESTS}/${test_dir_result}"
    echo "Criando teste SESSIONS=$sessions TIMESLOTS=$ts USERS=$users"

    for ((j=1; j<=sessions; j++)); do
        printf "%s\n%s\n" "$ts" "$users" | python3 randomBILPGenerator.py > /dev/null
        mv "BILP.dat" "${DIR_TESTS}/${test_dir_result}/BILP_${j}.dat"
    done
done

# for dir in "${DIR_TESTS}"/*/; do
#     echo "Executando $dir - BILP"
#     dir_name=$(basename "$dir")
#     python3 BILP.py -d "$dir" > $DIR_RESULTS/${dir_name}.txt
# done