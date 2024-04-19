import sys
import asyncio
import asyncssh
import json
import re
import argparse
from tqdm.asyncio import tqdm
from backoff import on_exception, expo
import logging

# Configuração de log
logging.basicConfig(filename='error.log', level=logging.DEBUG, format='%(asctime)s %(message)s')

# Configuração dos argumentos do script
parser = argparse.ArgumentParser(description="Fetch management IPs based on serial numbers.")
parser.add_argument('username', help="Username for SSH")
parser.add_argument('password', help="Password for SSH")
parser.add_argument('hosts', help="Comma-separated list of hosts")
parser.add_argument('sernums', help="Comma-separated list of serial numbers")
args = parser.parse_args()

@on_exception(expo, (asyncssh.Error, asyncio.TimeoutError), max_time=120)
async def fetch_management_ip(sem, host, username, password, sernum):
    command = f"/ip dhcp-server lease print where agent-circuit-id={sernum}"
    async with sem:  
        try:
            async with asyncssh.connect(host, username=username, password=password, known_hosts=None, timeout=30) as conn:
                result = await conn.run(command, check=True)
                logging.debug(f"Command output for {sernum}@{host}: {result.stdout}")
                ip_match = re.search(r"\d+\sD\s(\d+\.\d+\.\d+\.\d+)", result.stdout)
                if ip_match:
                    return ip_match.group(1)
                else:
                    return None
        except Exception as e:  # Captura de exceções mais abrangente
            logging.error(f"Unexpected error on device {host}: {e}")
            return None

async def process_sernums(hosts, username, password, sernums):
    sem = asyncio.Semaphore(5)  # Redução do número de conexões simultâneas
    tasks = [fetch_management_ip(sem, host, username, password, sernum) for host in hosts for sernum in sernums]

    results = []
    for result in tqdm(asyncio.as_completed(tasks), total=len(tasks), desc="Fetching IPs"):
        results.append(await result)
    return results

if __name__ == "__main__":
    username = args.username
    password = args.password
    hosts = args.hosts.split(',')
    sernums = args.sernums.split(',')

    loop = asyncio.get_event_loop()
    results = loop.run_until_complete(process_sernums(hosts, username, password, sernums))
    
    output_results = [{"sernum": sernum, "ip": ip if ip else "IP not found or error in command execution"} for sernum, ip in zip(sernums, results)]
    
    output_filename = 'management_ips.json'
    with open(output_filename, 'w') as json_file:
        json.dump({"results": output_results}, json_file, indent=4)

    print(f"Results have been written to {output_filename}")
