import subprocess
import os

def run_command(command):
    result = subprocess.run(command, capture_output=True, text=True, shell=True)
    return result.stdout.strip()

# Script path
script_dir = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(script_dir, "wificreds.txt")

# Gets Wifi SSID
wifi_output = run_command('netsh wlan show interfaces')
wifi_name = ""

for line in wifi_output.split("\n"):
    if "SSID" in line and "BSSID" not in line:
        wifi_name = line.split(":")[-1].strip()
        break

if not wifi_name:
    print("No Wi-Fi connection found")
    exit()

# Checks if profile exists
profiles_output = run_command('netsh wlan show profiles')
if wifi_name not in profiles_output:
    print(f"Profile '{wifi_name}' not found.")
    exit()

# Extracts password
wifi_passwd_info = run_command(f'netsh wlan show profiles "{wifi_name}" key=clear')

# Saves to a file
with open(file_path, "w", encoding="utf-8") as file:
    file.write(wifi_passwd_info)

# Opens file
subprocess.run(f'notepad.exe "{file_path}"', shell=True)

print(f"Wi-Fi credentials saved to: {file_path}")