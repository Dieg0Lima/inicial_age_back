import sys
import asyncio
import asyncssh
import json
import re
from tqdm.asyncio import tqdm

async def fetch_management_ip(sem, host, username, password, sernum):
    command = f"/ip dhcp-server lease print where agent-circuit-id={sernum}"
    async with sem:  
        try:
            async with asyncssh.connect(host, username=username, password=password, known_hosts=None) as conn:
                result = await conn.run(command, check=True)
                ip_match = re.search(r"\d+ D (\d+\.\d+\.\d+\.\d+)", result.stdout)
                if ip_match:
                    return ip_match.group(1)
                else:
                    return None
        except (asyncssh.Error, asyncio.TimeoutError) as e:
            print(f"Error connecting or executing command on device {host}: {e}", file=sys.stderr)
            return None

async def process_sernums(hosts, username, password, sernums):
    sem = asyncio.Semaphore(3) 
    tasks = []
    for host in hosts:
        for sernum in sernums:
            task = fetch_management_ip(sem, host, username, password, sernum)
            tasks.append(task)
    
    results = []
    for result in tqdm(asyncio.as_completed(tasks), total=len(tasks), desc="Fetching IPs"):
        results.append(await result)
    return results

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python script.py <username> <password> <host1,host2,...> '<sernum1,sernum2,...>'", file=sys.stderr)
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]
    hosts = sys.argv[3].split(',')
    sernums = sys.argv[4].split(',')

    loop = asyncio.get_event_loop()
    results = loop.run_until_complete(process_sernums(hosts, username, password, sernums))
    
    output_results = []
    for sernum, ip in zip(sernums, results):
        if ip:
            output_results.append({"sernum": sernum, "ip": ip})
        else:
            output_results.append({"sernum": sernum, "error": "IP not found or error in command execution"})

    output_filename = 'management_ips.json'
    with open(output_filename, 'w') as json_file:
        json.dump({"results": output_results}, json_file, indent=4)

    print(f"Results have been written to {output_filename}")
