import numpy as np
import genetic_scheduling as gs
import execution_management as exec
import createPlot as cPlot
import sys, argparse, time
import random  


population_size = 10
num_generations = 100000
elitism_rate = 0.2
tournament_size = 2
mutation_rate = 0.3


# Parseia entrada do programa
parser = argparse.ArgumentParser(description="Algoritmo Genético de Escalonamento em Redes mmWave")
parser.add_argument('-p', '--plot', action='store_true', help='Exibe o gráfico')
parser.add_argument('-fi', '--finalind', action='store_true', help='Exibe o(s) indivíduo(s) de fitness máximo ao final')
parser.add_argument('-meta ', '--metadata', action='store_true', help='Retorna, ao fim da execuçaõ, os metadados e parametors utilizados')
parser.add_argument('-s', '--seed', action='store_true', help='Adicionar seed manualmente')
parser.add_argument('-sv', '--seed_value', type=int, help='Valor da seed')
parser.add_argument('-div', '--divide', type=int, help='Divisão da população')
parser.add_argument('-m', '--mutation', type=float, help='Taxa de mutação')
parser.add_argument('-pop', '--population', type=int, help='Tamanho população')
parser.add_argument('-gen', '--max_gen', type=int, help='Quantidade de gerações')

#Adicionar opcao -m que printa os metadados utilizados (tamanho populacao, geracoes, eltitimos, seed utilizada no programa, etc)
#adiciona opcao -s que utiliza uma seed passada por argumento 
args = parser.parse_args()

# Checa se criterios de convergencia estão corretos
if args.seed:
    if args.seed is None:
            parser.error("Ao usar -s/--seed, você deve informar -sv e indicar o valor da seed")
    else:
        print(f'Used seed: {args.seed_value}')
        exec_seed = args.seed_value
else:
    exec_seed = random.randrange(sys.maxsize)

random.seed(exec_seed)

if args.mutation:
    mutation_rate = args.mutation 

if args.population: 
    population_size = args.population

if args.max_gen:
    num_generations = args.max_gen

# Lê toda a entrada do arquivo ou stdin  
dados = sys.stdin.read().split()
dados = list(map(float, dados))  # converte tudo para float para facilitar

gene_size, nts, nu, user_nts_constraint, scheduling_sesssions = exec.read_execution_data(dados)

print(f'Total timeslots:{nts}')
print(f'Total Users:{nu}')

print("User Timeslot usage:")
print(user_nts_constraint)
print("")

if args.divide:
    if (args.divide <= 1):
        print("ERROR: divide must be at least 2")
    elif (gene_size // args.divide) < 2:
        print("ERROR: gene_size // divide must be at least 2")
        exit(0)
    pop_division = args.divide
else:
    pop_division = 1

generations_metadata = []
for i in range(pop_division):
    generations_metadata.append([])

population, gene_pop = exec.initialize_population(scheduling_sesssions, pop_division, user_nts_constraint, population_size, nts, nu, gene_size)

print("Crossover using Roulette, Timeslot Mutation and One-Point Crossover")
print(f"    Total Generations   : {num_generations}")
print(f"    Num. of Populations : {pop_division}")
print(f"    Population Size     : {population_size}")
print(f"    Mutation rate       : {mutation_rate}")
last_convergence = 0
conv_count = 0
start_time = time.perf_counter()

if (args.plot):
    for i in range(pop_division):
        gs.collect_generation_metadata(generations_metadata[i], population[i], population_size)

new_population = []
for i in range(pop_division):
    new_population.append(population[i])

for gen in range(num_generations):
    for i in range(pop_division):
        new_population[i] = gs.crossover(population[i], elitism_rate, gene_pop[i], population_size)  

    start = 0
    for i in range(pop_division):
        end = start + gene_pop[i]
        new_population[i] = gs.timeslot_mutation(new_population[i], scheduling_sesssions[start:end], mutation_rate, gene_pop[i], population_size, nts)
        start = end

    if (args.plot) or (gen == num_generations-1): 
        for i in range(pop_division):
            gs.collect_generation_metadata(generations_metadata[i], new_population[i], population_size)

    for i in range(pop_division):
        population[i] = new_population[i].copy()

end_time = time.perf_counter() - start_time


if args.plot:
    exec.validate_final_scheduling(pop_division, gene_pop, generations_metadata, gen, user_nts_constraint, nts, nu)
else:
     exec.validate_final_scheduling(pop_division, gene_pop, generations_metadata, 0, user_nts_constraint, nts, nu)

print("Scheduling final válido!")

max_fitness = 0.0
if args.plot:
    max_fitness =  exec.calculate_maxfitness(generations_metadata, pop_division, gen)
else:
    max_fitness =  exec.calculate_maxfitness(generations_metadata, pop_division, 0)

print(f"Max fitness of generation {gen+1} = {max_fitness:.2f} found in {end_time:.2f} secs")


if args.plot:
     exec.write_metadata_file(generations_metadata, max_fitness)


if args.finalind:
    if args.plot:
         exec.print_max_individuals(generations_metadata, gene_size, pop_division, gen)   
    else:
         exec.print_max_individuals(generations_metadata, gene_size, pop_division, 0)

if args.plot:
    cPlot.plotFitness()

if args.metadata:
     exec.print_execution_metadata(exec_seed, population_size, pop_division, num_generations, elitism_rate, mutation_rate)
  