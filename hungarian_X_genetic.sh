#!/bin/bash

DIR_BILP_TESTS="./BILP/Tests/"
DIR_HUNGARIAN_TESTS="./Hungarian/Tests"
DIR_HUNGARIAN_RESULTS="./Hungarian/Results"
DIR_GENETIC_TESTS="./Genetic/Tests"
DIR_GENETIC_RESULTS="./Results"
DIR_GENETIC_RESULTS_DIV="./Results-DIV"

if [ ! -d "$DIR_GENETIC_TESTS" ]; then
    mkdir -p "$DIR_GENETIC_TESTS"
else 
    rm -rf "$DIR_GENETIC_TESTS"/*
fi

if [ ! -d "$DIR_HUNGARIAN_TESTS" ]; then
    mkdir -p "$DIR_HUNGARIAN_TESTS"
else 
    rm -rf "$DIR_HUNGARIAN_TESTS"/*
fi

rm -rf dados_execucao.txt
touch dados_execucao.txt

inicio_data=$(date '+%Y-%m-%d %H:%M:%S')
inicio_ts=$(date +%s)
echo "Início Execução: $inicio_data" >> dados_execucao.txt

#######################################################################

cd ./BILP/
./create_run_tests.sh
cd ..

#######################################################################

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
    /usr/bin/time -v python3 ./Hungarian/main.py -d "$dir" > $DIR_HUNGARIAN_RESULTS/${dir_name}.txt 2> ./Hungarian/time_output.txt
done

#######################################################################

for dir in "${DIR_BILP_TESTS}"/*/; do
    echo "Convertendo $dir para genético"
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

for file in ./Tests/*.txt; do
    echo "Executando $file - Genético"
    file_name=$(basename -s .txt $file)

    if [ ! -d "$DIR_GENETIC_RESULTS/$file_name" ]; then
        mkdir -p "$DIR_GENETIC_RESULTS/$file_name"
    fi

    /usr/bin/time -v python3 main.py -pop 10 -m 0.15 -gen 100000 < $file > $DIR_GENETIC_RESULTS/$file_name/Output.txt 2> time_output.txt
done


cd ..

echo "Hungarian"
cd ./Hungarian
for file in ./Results/*.txt; do
    file_name=$(basename -s .txt "$file")
    printf '\tResultado %s -> ' "$file_name"
    awk '/^Total Objective/ {total=$4} {last=$0} END {printf "%.2f Gbps | %s\n", total, last}' "$file"
    awk '/Maximum resident set size/ {printf "\tRAM máxima: %.2f MB\n", $6/1024}' time_output.txt
done
cd ..

echo "Genetic"
cd ./Genetic
for file in ./Results/*/*.txt; do
    folder_name=$(basename "$(dirname "$file")")
    printf '\tResultado %s -> ' "$folder_name"
    tail -n 1 "$file" | awk -F'= ' '{print $2}'
    awk '/Maximum resident set size/ {printf "\tRAM máxima: %.2f MB\n", $6/1024}' time_output.txt
done
cd ..

#######################################################################

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
