filename = 'sernums.txt'

try:
    with open(filename, 'r') as file:
        sernums = file.read().splitlines() 
    concatenated_sernums = ','.join(sernums)
    print(concatenated_sernums)
except FileNotFoundError:
    print(f"File {filename} not found.")
