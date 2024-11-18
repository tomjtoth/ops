#!/bin/python
# uses about 4MB of RAM launched from the service vs 0,7MB of *.sh

import os
import time

path_to_bat = os.environ.get("PATH_TO_BAT")
crit_bat_level = int(os.environ.get("CRIT_BAT_LEVEL", 10))
crit_bat_command = os.environ.get("CRIT_BAT_COMMAND")

if not (path_to_bat and crit_bat_command and crit_bat_level):
    print(
        f"""example usage:
    PATH_TO_BAT=/sys/class/power_supply/BAT0 \\
    CRIT_BAT_LEVEL=10 \\
    CRIT_BAT_COMMAND=\"systemctl -i suspend\" \\
    python {os.path.basename(__file__)}
    """
    )
    exit(1)

status_file = f"{path_to_bat}/status"
capacity_file = f"{path_to_bat}/capacity"

while True:
    try:
        # Read status
        with open(status_file, "r") as fs:
            status = fs.read().strip()

        # Read capacity
        with open(capacity_file, "r") as fc:
            capacity = int(fc.read().strip())

        # Check critical battery condition
        if capacity <= crit_bat_level and status != "Charging":
            os.system(crit_bat_command)

    except FileNotFoundError as e:
        print(f"Error: {e}. Check your PATH_TO_BAT.")
        break
    except ValueError as e:
        print(f"Error: {e}. Ensure the files contain valid data.")
        break

    time.sleep(60)
