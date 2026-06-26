#!/bin/bash

runs=1
total_time=0
total_fitness=0
time_limits=(1 2 3 4 4.5 1000000000000)
population_sizes=(5 10 30 50 100)
generation_sizes=(30000 50000 100000)
mutation_types=(0.05 0.10 0.15 0.30)

if [ -z "$1" ]; then
    echo "Uso: $0 <arquivo_entrada>"
    exit 1
fi

input_file=$1

run_index=0

for pop in "${population_sizes[@]}"; do 

    for gen in "${generation_sizes[@]}"; do 

        for mut in "${mutation_types[@]}"; do 

            for tls in "${time_limits[@]}"; do 
                echo -e "\nExecution $run_index: ${pop} Population - ${gen} Generation - ${mut} Mutation - ${tls} second time limit"
                total_time=0
                total_fitness=0
                for i in $(seq 1 $runs); do
                    output=$(python3 main_timebound.py -tl $tls -pop $pop -mut $mut -gen $gen -meta < "$input_file")

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

echo "done"

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