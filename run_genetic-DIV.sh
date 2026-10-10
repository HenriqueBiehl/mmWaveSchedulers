#!/bin/bash
DIR_GENETIC_TESTS="./Genetic/Tests"
DIR_GENETIC_RESULTS="./Results-DIV"
tls=1000000000000
notify=false

######################################################################
if [[ ! -d "$DIR_GENETIC_TESTS" || -z "$(ls -A "$DIR_GENETIC_TESTS" 2>/dev/null)" ]]; then
    echo "ERROR!!!!!!! TESTS DIRECTORY EMPTY OR NOT FOUND!!!!"
    exit 0
fi

#######################################################################

relogio() {
    local inicio=$1
    local pid=$2
    local descricao=$3

    while kill -0 "$pid" 2>/dev/null; do
        local agora=$(date +%s)
        local tempo=$((agora - inicio))

        printf "\r%s [%02d:%02d:%02d]" \
            "$descricao" \
            $((tempo / 3600)) \
            $(((tempo % 3600) / 60)) \
            $((tempo % 60))

        sleep 1
    done
}

######################################################################

pid=""

trap '
    echo
    echo -n "Encerrando processos... "

    if [ -n "$pid" ]; then
        echo "Matando grupo de processos $pid..."
        kill -TERM -- "-$pid" 2>/dev/null
    fi

    exit 130
' INT TERM

#######################################################################
cd ./Genetic

if [ ! -d "$DIR_GENETIC_RESULTS" ]; then
    mkdir -p "$DIR_GENETIC_RESULTS"
else 
    rm -rf "$DIR_GENETIC_RESULTS"/*
fi

rm -rf ./time_output.txt

for file in ./Tests/*.txt; do
    file_name=$(basename -s .txt $file)

    if [ ! -d "$DIR_GENETIC_RESULTS/$file_name" ]; then
        mkdir -p "$DIR_GENETIC_RESULTS/$file_name"
    fi

    inicio=$(date +%s)
    descricao="1-Executando $file - Genético COM DIVISÃO"
    echo -n "$descricao "

    setsid /usr/bin/time -v python3 main_timebound.py -pop 10 -mut 0.15 -gen 100000 -tl $tls -div 2 < $file > $DIR_GENETIC_RESULTS/$file_name/Output.txt 2>> time_output.txt &
    
    pid=$!
    relogio "$inicio" "$pid" "$descricao"
    wait "$pid"

    pid=""
    echo
done
cd ..

#######################################################################
echo "Genetic-DIV"
cd ./Genetic
index=0
for file in ./Results-DIV/*/*.txt; do
    folder_name=$(basename "$(dirname "$file")")
    printf '\tResultado %s -> ' "$folder_name"
    awk '/Max fitness of generation/ {printf "%.2f Gbps | %s %s | ", $7, $10, $11}' "$file"
    index=$((index + 1))
    awk -v n="$index" '/^\tCommand being timed:/ {bloco++} bloco == n && /Maximum resident set size/ {printf "Max RAM: %.2f MB\n", $6/1024}' time_output.txt
done
cd ..

#######################################################################