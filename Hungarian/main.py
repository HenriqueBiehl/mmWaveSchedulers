#!/usr/bin/python3

from scipy.optimize import linear_sum_assignment
import numpy as np
import argparse, time, os, sys

def hungarian_file(data_path, show_x):
    # Lê toda a entrada do arquivo ou stdin  
    with open(data_path, "r") as data_file:
        dados = data_file.read().split()
        dados = list(map(float, dados))  # converte tudo para float para facilitar

    idx = 0

    nu = int(dados[idx]); idx += 1          #Quantidade de usuários
    nts = int(dados[idx]); idx += 1         #Quantidade de timeslots por sessao

    fairness_division = np.empty(nu, dtype=int) 
    for i in range(0, nu):
        fairness_division[i] = int(dados[idx])
        idx += 1

    R = np.empty((nu, nts))
    for i in range(0, nu):
        for j in range(0, nts):
            R[i][j] = dados[idx] 
            idx += 1

    resultado = []

    # Cria as cópias dos dispositivos
    R_expanded = np.vstack([
        R[d, :]
        for d in range(len(fairness_division))
        for _ in range(fairness_division[d])
    ])

    # Maximização
    rows, cols = linear_sum_assignment(
        R_expanded,
        maximize=True
    )

    for row, slot in zip(rows, cols):
        # Recupera o dispositivo original
        device = next(
            d for d in range(len(fairness_division))
            if row < sum(fairness_division[:d + 1])
        )

        resultado.append(
            (slot + 1, device + 1, R[device, slot])
        )

    # Ordena pelo timeslot
    resultado.sort(key=lambda x: x[0])
    taxa_total = sum(taxa for _, _, taxa in resultado)

    if show_x:
        print("X = ", end="")
        for _, device, _ in resultado:
            print(f"{device-1} ", end="")
        print()
    print(f"Objective = {taxa_total}")

    return taxa_total

def hungarian_stdin(show_x):
    # Lê toda a entrada do arquivo ou stdin  
    dados = sys.stdin.read().split()
    dados = list(map(float, dados))  # converte tudo para float para facilitar

    idx = 0

    nu = int(dados[idx]); idx += 1          #Quantidade de usuários
    nts = int(dados[idx]); idx += 1         #Quantidade de timeslots por sessao

    fairness_division = np.empty(nu, dtype=int) 
    for i in range(0, nu):
        fairness_division[i] = int(dados[idx])
        idx += 1

    R = np.empty((nu, nts))
    for i in range(0, nu):
        for j in range(0, nts):
            R[i][j] = dados[idx] 
            idx += 1

    resultado = []

    # Cria as cópias dos dispositivos
    R_expanded = np.vstack([
        R[d, :]
        for d in range(len(fairness_division))
        for _ in range(fairness_division[d])
    ])

    # Maximização
    rows, cols = linear_sum_assignment(
        R_expanded,
        maximize=True
    )

    for row, slot in zip(rows, cols):
        # Recupera o dispositivo original
        device = next(
            d for d in range(len(fairness_division))
            if row < sum(fairness_division[:d + 1])
        )

        resultado.append(
            (slot + 1, device + 1, R[device, slot])
        )

    # Ordena pelo timeslot
    resultado.sort(key=lambda x: x[0])
    taxa_total = sum(taxa for _, _, taxa in resultado)

    if show_x:
        print("X = ", end="")
        for _, device, _ in resultado:
            print(f"{device-1} ", end="")
        print()
    print(f"Objective = {taxa_total}")

    return taxa_total

def main():
    # Parseia entrada do programa
    parser = argparse.ArgumentParser(description="Algoritmo Húngaro para Escalonamento em Redes mmWave")
    parser.add_argument('-d', '--dir', help='Executa todos os arquivos de um diretorio')
    parser.add_argument('-x', '--x_result', action="store_true", help='Mostra o escalonamento final')
    args = parser.parse_args()

    start = time.perf_counter()

    obj = 0
    if args.dir:
        folderPath = args.dir
        for root, _, files in os.walk(folderPath, topdown=True):
            files.sort(key=lambda x: int(os.path.splitext(x)[0]))
            for name in files:
                fileName = os.path.join(root, name)
                obj += hungarian_file(fileName, args.x_result)
    else:
        obj = hungarian_stdin(args.x_result)

    end = time.perf_counter() - start

    print(f"Total Objective = {obj} Gbps")
    print(f"Results found in {end:.4f} secs")

if __name__ == '__main__':
    main()