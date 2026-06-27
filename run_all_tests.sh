#!/bin/bash

DIR_BILP_TESTS="./BILP/Tests/"
DIR_GENETIC_TESTS="./Genetic/Tests"

if [ ! -d "$DIR_GENETIC_TESTS" ]; then
    mkdir -p "$DIR_GENETIC_TESTS"
else 
    rm -rf "$DIR_GENETIC_TESTS"/*
fi

cd ./BILP/
./create_run_tests.sh
cd ..

for dir in "${DIR_BILP_TESTS}"/*/; do
    echo "Convertendo $dir"
    dir_name=$(basename "$dir")
    echo "$dir" | python3 BILPtoGenetic.py > /dev/null
    mv "convert_out.txt" $DIR_GENETIC_TESTS/${dir_name}.txt
done

cd ./Genetic
for file in ./Tests/*.txt; do
    echo "Executando $file - Genético"
    ./run_tests.sh "$file" > /dev/null
done