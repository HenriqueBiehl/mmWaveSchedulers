#!/bin/bash

DIR_BILP_TESTS="./BILP/Tests/"
DIR_HUNGARIAN_TESTS="./Hungarian/Tests"
DIR_HUNGARIAN_RESULTS="./Hungarian/Results"
DIR_GENETIC_TESTS="./Genetic/Tests"
DIR_GENETIC_RESULTS="./Results"
tls=1000000000000
notify=false

######################################################################

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t)
            tls="$2"
            shift 2
            ;;
        -n|--notify)
            notify=true
            shift
            ;;
        *)
            echo "Uso: $0 [-t valor] [-n | --notify]"
            exit 1
            ;;
    esac
done

######################################################################

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

######################################################################

rm -rf dados_execucao.txt
touch dados_execucao.txt

inicio_data=$(date '+%Y-%m-%d %H:%M:%S')
inicio_ts=$(date +%s)
echo "Início Execução: $inicio_data" >> dados_execucao.txt

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

######################################################################

cd ./BILP/
./create_run_tests.sh -nobilp
if [[ $? -ne 0 ]]; then
    echo "Erro na criação dos testes, encerrando."
    exit 1
fi
cd ..

#######################################################################

for dir in "${DIR_BILP_TESTS}"/*/; do
    echo "2-Convertendo $dir para húngaro"
    dir_name=$(basename "$dir")
    echo "$dir" | python3 BILPtoHungarian.py > /dev/null
    mv "convert_out/" $DIR_HUNGARIAN_TESTS/${dir_name}/
done

if [ ! -d "$DIR_HUNGARIAN_RESULTS" ]; then
    mkdir -p "$DIR_HUNGARIAN_RESULTS"
else 
    rm -rf "$DIR_HUNGARIAN_RESULTS"/*
fi

rm -rf ./Hungarian/time_output.txt

for dir in "${DIR_HUNGARIAN_TESTS}"/*/; do
    dir_name=$(basename "$dir")

    inicio=$(date +%s)
    descricao="3-Executando $dir - Húngaro"
    echo -n "$descricao "

    setsid  /usr/bin/time -v python3 ./Hungarian/main.py -d "$dir" > $DIR_HUNGARIAN_RESULTS/${dir_name}.txt 2>> ./Hungarian/time_output.txt &
    
    pid=$!
    relogio "$inicio" "$pid" "$descricao"
    wait "$pid"

    pid=""
    echo
done

#######################################################################

for dir in "${DIR_BILP_TESTS}"/*/; do
    echo "4-Convertendo $dir para genético"
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

rm -rf ./time_output.txt

for file in ./Tests/*.txt; do
    file_name=$(basename -s .txt $file)

    if [ ! -d "$DIR_GENETIC_RESULTS/$file_name" ]; then
        mkdir -p "$DIR_GENETIC_RESULTS/$file_name"
    fi

    inicio=$(date +%s)
    descricao="5-Executando $file - Genético"
    echo -n "$descricao "

    setsid /usr/bin/time -v python3 main_timebound.py -pop 10 -mut 0.15 -gen 100000 -tl $tls < $file > $DIR_GENETIC_RESULTS/$file_name/Output.txt 2>> time_output.txt &
    
    pid=$!
    relogio "$inicio" "$pid" "$descricao"
    wait "$pid"

    pid=""
    echo
done
cd ..

#######################################################################

echo "Hungarian"
cd ./Hungarian
index=0
for file in ./Results/*.txt; do
    file_name=$(basename -s .txt "$file")
    printf '\tResultado %s -> ' "$file_name"
    awk '/^Total Objective/ {total=$4} /Results found in/ {time=$4} END {printf "%.2f Gbps | %.2f secs | ", total, time}' "$file"
    index=$((index + 1))
    awk -v n="$index" '/^\tCommand being timed:/ {bloco++} bloco == n && /Maximum resident set size/ {printf "Max RAM: %.2f MB\n", $6/1024}' time_output.txt
done
cd ..

echo "Genetic"
cd ./Genetic
index=0
for file in ./Results/*/*.txt; do
    folder_name=$(basename "$(dirname "$file")")
    printf '\tResultado %s -> ' "$folder_name"
    awk '/Max fitness of generation/ {printf "%.2f Gbps | %s %s | ", $7, $10, $11}' "$file"
    index=$((index + 1))
    awk -v n="$index" '/^\tCommand being timed:/ {bloco++} bloco == n && /Maximum resident set size/ {printf "Max RAM: %.2f MB\n", $6/1024}' time_output.txt
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

if $notify; then
    powershell.exe -Command "Import-Module BurntToast; New-BurntToastNotification -Text 'Experimento terminado', 'O script Python terminou!'"
fi
