#!/bin/bash
#
# Cluster Usage Report (Slurm)
# Clean & comprehensive summary of job/accounting statistics
#

# Default date range: last 30 days (override with arguments: ./report.sh START_DATE END_DATE)
END_DATE=${2:-$(date +%F)}
START_DATE=${1:-$(date -d "-30 days" +%F)}

echo "=== Cluster Usage Report ==="
echo "From: $START_DATE"
echo "To:   $END_DATE"
echo

echo "[1] Gathering job data from Slurm accounting..."
JOBS=$(sacct -S "$START_DATE" -E "$END_DATE" --format=JobID,User,Elapsed,TotalCPU,MaxRSS,State,Nodelist --parsable2 --noheader)

if [ -z "$JOBS" ]; then
  echo "No jobs found in this time range."
  exit 0
fi

########################################
# Global summary
########################################
TOTAL_JOBS=$(echo "$JOBS" | cut -d'|' -f1 | grep -vE '\.batch|\.extern' | wc -l)
UNIQUE_USERS=$(echo "$JOBS" | cut -d'|' -f2 | sort -u | wc -l)

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
  END { print total }')
TOTAL_CPU_HOURS=$(awk "BEGIN { printf \"%.2f\", $TOTAL_CPU_SECONDS/3600 }")

echo "👥  Unique users:   $UNIQUE_USERS"
echo "📝  Total jobs:     $TOTAL_JOBS"
echo "🕒  CPU time used:  $TOTAL_CPU_HOURS hours"
echo

########################################
# Per-user stats
########################################
echo "=== Per-user statistics ==="
echo

# Jobs per user
echo "🧾 Jobs per user:"
echo "--------------------------"
echo "$JOBS" | cut -d'|' -f2 | sort | uniq -c | sort -nr
echo

# CPU time per user
echo "🧠 CPU time per user (core-hours):"
echo "--------------------------"
echo "$JOBS" | awk -F'|' '
function to_sec(str) {
  split(str, a, "-")
  if (length(a) == 2) {
    split(a[2], t, ":"); days = a[1]
  } else { split(str, t, ":"); days = 0 }
  return days*86400 + t[1]*3600 + t[2]*60 + t[3]
}
$4 != "" {cpu[$2] += to_sec($4)}
END {for (u in cpu) printf "%-15s %.2f\n", u, cpu[u]/3600}' | sort -k2 -nr
echo

# Wall time per user
echo "⏱️  Wall time per user (hours):"
echo "--------------------------"
echo "$JOBS" | awk -F'|' '
function to_sec(str) {
  split(str, a, "-")
  if (length(a) == 2) {
    split(a[2], t, ":"); days = a[1]
  } else { split(str, t, ":"); days = 0 }
  return days*86400 + t[1]*3600 + t[2]*60 + t[3]
}
$3 != "" {wall[$2] += to_sec($3)}
END {for (u in wall) printf "%-15s %.2f\n", u, wall[u]/3600}' | sort -k2 -nr
echo

# Memory per user
echo "💾 Memory usage per user (sum of MaxRSS in GB):"
echo "--------------------------"
echo "$JOBS" | awk -F'|' '
{
  u=$2; m=$5
  if (m ~ /K$/) {val = m+0; mem[u] += val/1024/1024}
  else if (m ~ /M$/) {val = m+0; mem[u] += val/1024}
  else if (m ~ /G$/) {val = m+0; mem[u] += val}
}
END {for (u in mem) printf "%-15s %.2f GB\n", u, mem[u]}' | sort -k2 -nr
echo

# Job states per user
echo "📊 Job states per user:"
echo "--------------------------"
echo "$JOBS" | awk -F'|' '{print $2 "|" $6}' | sort | uniq -c | \
  awk '{split($2, parts, "|"); printf "%-15s %-12s %s\n", parts[1], parts[2], $1}' | sort
echo

# Node usage per user
echo "🖥️  Nodes used per user:"
echo "--------------------------"
echo "$JOBS" | awk -F'|' '{if($7!="") print $2 "|" $7}' | sort | uniq -c | \
  awk '{split($2, p, "|"); printf "%-15s %-20s %s\n", p[1], p[2], $1}' | sort -k3 -nr
echo

########################################
# Optional: SLURM sreport summary
########################################
echo "📈 SLURM 'Used' time (CPU hours) summary:"
echo "--------------------------"
sreport user TopUsage start=$START_DATE end=$END_DATE format=Login,Used -t Hours
echo
