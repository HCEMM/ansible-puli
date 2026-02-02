#!/bin/bash

# Set date range: from 30 days ago to today
END_DATE=$(date +%F)
START_DATE=$(date -d "-30 days" +%F)

echo "=== Cluster Usage Report ==="
echo "From: $START_DATE"
echo "To:   $END_DATE"
echo

# Get all jobs in the date range
echo "[1] Gathering job data from Slurm accounting..."

# Get raw job accounting data
JOBS=$(sacct -S "$START_DATE" -E "$END_DATE" --format=JobID,User,Elapsed,TotalCPU,State --parsable2 --noheader)

if [ -z "$JOBS" ]; then
  echo "No jobs found in this time range."
  exit 0
fi

# Extract data
# Count jobs
TOTAL_JOBS=$(echo "$JOBS" | cut -d'|' -f1 | grep -vE '\.batch|\.extern' | wc -l)

# Count unique users
UNIQUE_USERS=$(echo "$JOBS" | cut -d'|' -f2 | sort | uniq | wc -l)

# Sum CPU time (TotalCPU column)
TOTAL_CPU_SECONDS=$(echo "$JOBS" | cut -d'|' -f4 | grep -v '^$' | \
  awk -F: '
  function to_sec(h,m,s) { return h*3600 + m*60 + s }
  {
    split($1, a, "-")
    if (length(a) == 2) {
      split(a[2], t, ":")
      days = a[1]
    } else {
      split($1, t, ":")
      days = 0
    }
    total += days*86400 + to_sec(t[1], t[2], t[3])
  }
  END { print total }'
)

# Convert to CPU hours
TOTAL_CPU_HOURS=$(awk "BEGIN { printf \"%.2f\", $TOTAL_CPU_SECONDS/3600 }")

# Print report
echo "👥  Unique users:   $UNIQUE_USERS"
echo "📝  Total jobs:     $TOTAL_JOBS"
echo "🕒  CPU time used:  $TOTAL_CPU_HOURS hours"
