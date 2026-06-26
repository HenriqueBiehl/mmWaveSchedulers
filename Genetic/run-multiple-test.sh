#!/bin/bash

runs=30
total_time=0
total_fitness=0
time_limits=(0.5 1.5 5 8 15)
population_sizes=(5 10 30 50 100)
generation_sizes=(30000 50000 100000)
DIR="/Results/"

if [ -z "$1" ]; then
    echo "Uso: $0 <arquivo_entrada>"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
fi


input_file=$1

for pop in "${populations_sizes[@]}"; do 
    for gen in "${generations_sizes[@]}"; do 
        for tls in "${time_limits[@]}"; do 
            echo -e "\nRun: 10 ${pop} - 100000 Generation - 0.30 mutation - ${tls} second time limit"
            total_time=0
            total_fitness=0
            for i in $(seq 1 $runs); do
                output=$(python3 main_timebound.py -tl $tls < "$input_file")

                result_file="res_${}"
                echo "$output" > res${}.txt

                # Pega só a última linha relevante
                line=$(echo "$output" | grep "Max fitness")

                # Extrai fitness
                fitness=$(echo "$line" | grep -oP '=\s*\K[0-9.]+')

                # Extrai tempo
                time=$(echo "$line" | grep -oP 'found in \K[0-9.]+')

                total_time=$(echo "$total_time + $time" | bc)
                total_fitness=$(echo "$total_fitness + $fitness" | bc)

                printf "Run %02d -> fitness=%s | time=%s\n" "$i" "$fitness" "$time"
            done

            avg_time=$(echo "scale=4; $total_time / $runs" | bc)
            avg_fitness=$(echo "scale=4; $total_fitness / $runs" | bc)

            echo "----------------------"
            echo "Média do tempo: $avg_time secs"
            echo "Média do fitness: $avg_fitness Gbps"
        done 
    done
done 

total_time=0
total_fitness=0
echo -e "\nRun: 10 Population - 100000 Generation - 0.30 mutation - no time limit"
for i in $(seq 1 $runs); do
    output=$(python3 main.py < "$input_file")

    # Pega só a última linha relevante
    line=$(echo "$output" | grep "Max fitness")

    # Extrai fitness
    fitness=$(echo "$line" | grep -oP '=\s*\K[0-9.]+')

    # Extrai tempo
    time=$(echo "$line" | grep -oP 'found in \K[0-9.]+')

    total_time=$(echo "$total_time + $time" | bc)
    total_fitness=$(echo "$total_fitness + $fitness" | bc)

    printf "Run %02d -> fitness=%s | time=%s\n" "$i" "$fitness" "$time"
done

avg_time=$(echo "scale=4; $total_time / $runs" | bc)
avg_fitness=$(echo "scale=4; $total_fitness / $runs" | bc)

echo "----------------------"
echo "Média do tempo: $avg_time secs"
echo "Média do fitness: $avg_fitness Gbps"


total_time=0
total_fitness=0
echo -e "\nRun: 10 Population - 100000 Generation - 0.15 mutation - no time limit"
for i in $(seq 1 $runs); do
    output=$(python3 main.py -m 0.15 < "$input_file")

    # Pega só a última linha relevante
    line=$(echo "$output" | grep "Max fitness")

    # Extrai fitness
    fitness=$(echo "$line" | grep -oP '=\s*\K[0-9.]+')

    # Extrai tempo
    time=$(echo "$line" | grep -oP 'found in \K[0-9.]+')

    total_time=$(echo "$total_time + $time" | bc)
    total_fitness=$(echo "$total_fitness + $fitness" | bc)

    printf "Run %02d -> fitness=%s | time=%s\n" "$i" "$fitness" "$time"
done

avg_time=$(echo "scale=4; $total_time / $runs" | bc)
avg_fitness=$(echo "scale=4; $total_fitness / $runs" | bc)

echo "----------------------"
echo "Média do tempo: $avg_time secs"
echo "Média do fitness: $avg_fitness Gbps"


total_time=0
total_fitness=0
echo -e "\nRun: 30 Population - 50000 Generation - 0.15 mutation - no time limit"
for i in $(seq 1 $runs); do
    output=$(python3 main.py -m 0.15 -pop 30 -gen 50000 < "$input_file")

    # Pega só a última linha relevante
    line=$(echo "$output" | grep "Max fitness")

    # Extrai fitness
    fitness=$(echo "$line" | grep -oP '=\s*\K[0-9.]+')

    # Extrai tempo
    time=$(echo "$line" | grep -oP 'found in \K[0-9.]+')

    total_time=$(echo "$total_time + $time" | bc)
    total_fitness=$(echo "$total_fitness + $fitness" | bc)

    printf "Run %02d -> fitness=%s | time=%s\n" "$i" "$fitness" "$time"
done

avg_time=$(echo "scale=4; $total_time / $runs" | bc)
avg_fitness=$(echo "scale=4; $total_fitness / $runs" | bc)

echo "----------------------"
echo "Média do tempo: $avg_time secs"
echo "Média do fitness: $avg_fitness Gbps"