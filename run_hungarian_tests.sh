#!/bin/bash
DIR_BILP_TESTS="./BILP/Tests/"
DIR_HUNGARIAN_TESTS="./Hungarian/Tests"
DIR_HUNGARIAN_RESULTS="./Hungarian/Results"

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

if [ ! -d "$DIR_HUNGARIAN_TESTS" ]; then
    mkdir -p "$DIR_HUNGARIAN_TESTS"
else 
    rm -rf "$DIR_HUNGARIAN_TESTS"/*
fi

for dir in "${DIR_BILP_TESTS}"/*/; do
    echo "1-Convertendo $dir para húngaro"
    dir_name=$(basename "$dir")
    echo "$dir" | python3 BILPtoHungarian.py > /dev/null
    mv "convert_out/" $DIR_HUNGARIAN_TESTS/${dir_name}/
done

######################################################################

if [ ! -d "$DIR_HUNGARIAN_RESULTS" ]; then
    mkdir -p "$DIR_HUNGARIAN_RESULTS"
else 
    rm -rf "$DIR_HUNGARIAN_RESULTS"/*
fi

rm -rf ./Hungarian/time_output.txt

for dir in "${DIR_HUNGARIAN_TESTS}"/*/; do
    dir_name=$(basename "$dir")
    
    inicio=$(date +%s)
    descricao="2-Executando $dir - Húngaro"
    echo -n "$descricao "

    /usr/bin/time -v python3 ./Hungarian/main.py -d "$dir" > $DIR_HUNGARIAN_RESULTS/${dir_name}.txt 2>> ./Hungarian/time_output.txt &
    
    pid=$!
    relogio "$inicio" "$pid" "$descricao"
    wait "$pid"

    pid=""
    echo
done

######################################################################

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