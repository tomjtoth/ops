#!/bin/bash

# Get all commit timestamps for the current user
git log --author="${1:-Tamás Tóth}" --pretty=format:'%ad' --date=iso > commits.txt

# Process the commits
awk '
{
    # Extract the date (YYYY-MM-DD) and time (HH:MM:SS)
    date = substr($1, 1, 10);
    time = substr($2, 1, 8);

    # Convert the time to seconds since midnight
    split(time, arr, ":");
    seconds = arr[1] * 3600 + arr[2] * 60 + arr[3];

    # Store the timestamp for the current date
    timestamps[date][length(timestamps[date]) + 1] = seconds;
}
END {
    # Calculate the total minutes for each day
    for (date in timestamps) {
        total_minutes = 0;
        n = length(timestamps[date]);

        # Sort the timestamps for the day
        asort(timestamps[date]);

        # Calculate the differences between consecutive commits
        for (i = 2; i <= n; i++) {
            diff = timestamps[date][i] - timestamps[date][i - 1];
            total_minutes += diff / 60;
        }

        # Print the result for the day
        printf "Date: %s, Total Minutes Between Commits: %.2f\n", date, total_minutes;
    }
}
' commits.txt

# Clean up
rm commits.txt