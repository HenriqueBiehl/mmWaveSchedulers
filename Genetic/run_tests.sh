#!/bin/bash

runs=2
total_time=0
total_fitness=0
# time_limits=(1 2 4 1000000000000)
# population_sizes=(5 10 30 50 100)
# generation_sizes=(30000 50000 100000)
# mutation_types=(0.15 0.30)

time_limits=(1 2 4 1000000000000)
population_sizes=(5)
generation_sizes=(100000)
mutation_types=(0.30)
DIR="./Results/"

if [ -z "$1" ]; then
    echo "Uso: $0 <arquivo_entrada>"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
fi

input_file=$1

run_index=0

file_name=$(basename -s .txt "$input_file")
# mkdir "${DIR}${file_name}"

for pop in "${population_sizes[@]}"; do 

    for gen in "${generation_sizes[@]}"; do 

        for mut in "${mutation_types[@]}"; do             
            for tls in "${time_limits[@]}"; do 
                echo -e "\nExecution $run_index: ${pop} Population - ${gen} Generation - ${mut} Mutation - ${tls} second time limit"
                total_time=0
                total_fitness=0

                time=$tls
                if [[ "$tls" == "1000000000000" || "$tls" == "1000000000000.0" ]]; then
                    time="no_limit"
                fi

                result_file="res-${pop}-${gen}-${mut}-${time}.txt"
                path="${DIR}${file_name}/${result_file}"


                for i in $(seq 1 $runs); do
                    output=$(python3 main_timebound.py -tl $tls -pop $pop -mut $mut -gen $gen -meta -fi < "$input_file")
                

                    echo "$output" >> $path

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

                ((run_index++))
            done 

        done

    done
done 

#!/bin/bash

# runs=30
# total_time=0
# total_fitness=0

# if [ -z "$1" ]; then
#     echo "Uso: $0 <arquivo_entrada>"
#     exit 1
# fi

# input_file=$1

# for i in $(seq 1 $runs); do
#     output=$(python3 main.py < "$input_file")

#     # Pega só a última linha relevante
#     line=$(echo "$output" | grep "Max fitness")

#     # Extrai fitness
#     fitness=$(echo "$line" | grep -oP '=\s*\K[0-9.]+')

#     # Extrai tempo
#     time=$(echo "$line" | grep -oP 'found in \K[0-9.]+')

#     total_time=$(echo "$total_time + $time" | bc)
#     total_fitness=$(echo "$total_fitness + $fitness" | bc)

#     printf "Run %02d -> fitness=%s | time=%s\n" "$i" "$fitness" "$time"
# done

# avg_time=$(echo "scale=4; $total_time / $runs" | bc)
# avg_fitness=$(echo "scale=4; $total_fitness / $runs" | bc)

# echo "----------------------"
# echo "Média do tempo: $avg_time secs"
# echo "Média do fitness: $avg_fitness Gbps"