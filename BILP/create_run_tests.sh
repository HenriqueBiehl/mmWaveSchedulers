#!/bin/bash

SESSIONS=(1 1 1)
TIMESLOTS=(10000 10000 10000)
USERS=(10 25 50)

########################################################################

if [[ ${#SESSIONS[@]} -ne ${#TIMESLOTS[@]} ||
      ${#SESSIONS[@]} -ne ${#USERS[@]} ]]; then
    echo "Erro: SESSIONS, TIMESLOTS e USERS devem ter o mesmo tamanho."
    exit 1
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

#######################################################################

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

bilp=true

for arg in "$@"; do
    if [ "$arg" = "-nobilp" ]; then
        bilp=false
        break
    fi
done

#######################################################################

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
    echo "1-Criando teste SESSIONS=$sessions TIMESLOTS=$ts USERS=$users"

    for ((j=1; j<=sessions; j++)); do
        printf "%s\n%s\n" "$ts" "$users" | python3 randomBILPGenerator.py > /dev/null
        mv "BILP.dat" "${DIR_TESTS}/${test_dir_result}/BILP_${j}.dat"
    done
done

if $bilp; then
    rm -rf time_output.txt

    for dir in "${DIR_TESTS}"/*/; do
        dir_name=$(basename "$dir")

        inicio=$(date +%s)
        descricao="2-Executando $dir - BILP"
        echo -n "$descricao "
        
        setsid /usr/bin/time -v python3 BILP.py -d "$dir" > $DIR_RESULTS/${dir_name}.txt 2>> time_output.txt &
        
        pid=$!
        relogio "$inicio" "$pid" "$descricao"
        wait "$pid"

        pid=""
        echo
    done
fi