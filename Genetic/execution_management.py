import numpy as np 
import genetic_scheduling as gs


def calculate_maxfitness(generations_metadata, pop_division, last_metadata):

    max_fitness = 0.0
    for j in range(pop_division):
        max_fitness += generations_metadata[j][last_metadata]['max']

    return max_fitness


def read_execution_data(dados):
    idx = 0
    gene_size = int(dados[idx]); idx += 1   #Quantidade de scheduling sessions em um individuo
    nts = int(dados[idx]); idx += 1         #Quantidade de timeslots por sessao
    nu = int(dados[idx]); idx += 1          #Quantidade de usuários

    user_nts_constraint = np.empty(nu) 
    for i in range(0, nu):
        user_nts_constraint[i] = dados[idx] 
        idx += 1

    scheduling_sesssions_list = [] 
    for k in range(0, gene_size):
        predicted_rate = np.empty((nu, nts))
        for i in range(0, nu):
            for j in range(0, nts):
                predicted_rate[i][j] = dados[idx] 
                idx += 1

        scheduling_sesssions_list.append(predicted_rate)

    scheduling_sesssions = np.array(scheduling_sesssions_list)

    return gene_size, nts, nu, user_nts_constraint, scheduling_sesssions


def initialize_population(scheduling_sesssions, pop_division, user_nts_constraint, population_size, nts, nu, gene_size):
    base = gene_size // pop_division
    rest = gene_size % pop_division
    gene_pop = []
    for i in range(pop_division):
        if i < rest: gene_pop.append(base + 1)
        else: gene_pop.append(base)

    population = []
    population_copy = []
    start = 0

    for i in range(pop_division):
        end = start + gene_pop[i]

        p = gs.initial_population_replicated_gene(scheduling_sesssions.copy()[start:end], user_nts_constraint.copy(), gene_pop[i], population_size, nts, nu)
        population.append(p)
        population_copy.append(p.copy())

        start = end
    
    return population, gene_pop


def print_max_individuals(generations_metadata, gene_size, pop_division, last_gen):
    print("Maximal individuals:")
    full_individual = []

    for p_ind in range(pop_division):
        full_individual.extend(generations_metadata[p_ind][last_gen]['max_ind'])

    full_individual = np.array(full_individual)
    print("\t", end="")
    for j in range(gene_size):
        print(f"{full_individual[j][0]}", end="")
    print("")


def write_metadata_file(generations_metadata, gen, pop_division):

    with open("metadata.txt", "w") as metadataFile:
        for k in range(gen):
            low_f = 0.0
            avg_f = 0.0
            max_f = 0.0
            for j in range(pop_division):
                low_f += generations_metadata[j][k]['low']
                avg_f += generations_metadata[j][k]['avg']
                max_f += generations_metadata[j][k]['max']
            metadataFile.write(f"{low_f:.2f} - {avg_f:.2f} - {max_f:.2f}\n")

def print_execution_metadata(exec_seed, population_size, pop_division, num_generations, elitism_rate, mutation_rate):

    print("\n")
    print("---- Metadata and Parameters -----")
    print(f"    Seed: {exec_seed}")
    print(f"    Population size: {population_size}")
    print(f"    Num. of Populations: {pop_division}")
    print(f"    Generation Number: {num_generations}")
    print(f"    Elitism Rate: {elitism_rate:.2f}")
    print(f"    Mutation Rate: {mutation_rate:.2f}")


def validate_final_scheduling(pop_division, gene_pop, generations_metadata, last_gen, user_nts_constraint, nts, nu):

    for p_ind in range(pop_division):
        for i in range(gene_pop[p_ind]):
            scheduling = generations_metadata[p_ind][last_gen]['max_ind'][i][0]
            if(not gs.validate_scheduling(scheduling, user_nts_constraint,nts, nu)):
                print(f"Erro: scheduling {p_ind + i} é inválido: ")
                print(scheduling)
                exit(1)