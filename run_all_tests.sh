#!/bin/bash

DIR_BILP_TESTS="./BILP/Tests/"
DIR_GENETIC_TESTS="./Genetic/Tests"
DIR_GENETIC_RESULTS="./Results"
DIR_GENETIC_RESULTS_DIV="./Results-DIV"

if [ ! -d "$DIR_GENETIC_TESTS" ]; then
    mkdir -p "$DIR_GENETIC_TESTS"
else 
    rm -rf "$DIR_GENETIC_TESTS"/*
fi

touch dados_execucao.txt

inicio_data=$(date '+%Y-%m-%d %H:%M:%S')
inicio_ts=$(date +%s)
echo "Início Execução: $inicio_data" >> dados_execucao.txt


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

if [ ! -d "$DIR_GENETIC_RESULTS" ]; then
    mkdir -p "$DIR_GENETIC_RESULTS"
else 
    rm -rf "$DIR_GENETIC_RESULTS"/*
fi

if [ ! -d "$DIR_GENETIC_RESULTS_DIV" ]; then
    mkdir -p "$DIR_GENETIC_RESULTS_DIV"
else 
    rm -rf "$DIR_GENETIC_RESULTS_DIV"/*
fi


for file in ./Tests/*.txt; do
    echo "Executando $file - Genético"
    file_name=$(basename -s .txt $file)

    if [ ! -d "$DIR_GENETIC_RESULTS/$file_name" ]; then
        mkdir -p "$DIR_GENETIC_RESULTS/$file_name"
    fi

    ./run_tests.sh "$file" > $DIR_GENETIC_RESULTS/$file_name/Output.txt
done

for file in ./Tests/*.txt; do
    echo "Executando $file - Genético com divisão"
    file_name=$(basename -s .txt $file)

    if [ ! -d "$DIR_GENETIC_RESULTS_DIV/$file_name" ]; then
        mkdir -p "$DIR_GENETIC_RESULTS_DIV/$file_name"
    fi

    ./run-multiple-test.sh "$file" > $DIR_GENETIC_RESULTS_DIV/$file_name/Output.txt
done

cd ..

fim_data=$(date '+%Y-%m-%d %H:%M:%S')
fim_ts=$(date +%s)


tempo_total=$((fim_ts - inicio_ts))

horas=$((tempo_total / 3600))
minutos=$(((tempo_total % 3600) / 60))
segundos=$((tempo_total % 60))


echo "Final Execução: $fim_data" >> dados_execucao.txt
printf "Tempo total: %02d:%02d:%02d\n" \
    "$horas" "$minutos" "$segundos" >> dados_execucao.txt
echo "----------------------------" >> dados_execucao.txt
