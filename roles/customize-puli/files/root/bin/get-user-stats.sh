#!/bin/bash

# Default start date
START_DATE="${1:-2024-01-01}"

echo "📊 Cluster usage summary from $START_DATE"
echo -e "========================================\n"

# 1. Number of jobs per user
echo -e "🧾 Jobs per user:"
echo -e "----------------------------------------"
sacct -S "$START_DATE" --format=User,JobID --noheader | awk '{print $1}' | grep -vE '.*\.batch|.*\.interac|*.0' | sort | uniq -c | sort -nr
echo -e "----------------------------------------\n"

# 2. Total CPU time (in seconds) per user
echo -e "🧠 Total CPU time per user (in core-hours):"
echo -e "----------------------------------------"
sacct -S "$START_DATE" --format=User,TotalCPU --noheader | \
    grep -vE '^\s*$|\.batch|\.interacti\+?$' | \
    awk '{u=$1; t=$2} 
         match(t, /([0-9]+)-)?([0-9]+):([0-9]+):([0-9.]+)/, a) {
             days=(a[1] ? a[1] : 0)
             hours=a[2]; minutes=a[3]; seconds=a[4]
             total_sec = days*86400 + hours*3600 + minutes*60 + seconds
             cpu[u] += total_sec
         }
         END { for (u in cpu) printf "%-15s %.2f\n", u, cpu[u]/3600 }' | sort -k2 -nr
echo -e "----------------------------------------\n"

# 3. Wall time per user
echo -e "⏱️  Wall time per user (in hours):"
echo -e "----------------------------------------"
sacct -S "$START_DATE" --format=User,Elapsed --noheader | \
    grep -vE '^\s*$|\.batch|\.interacti\+?$' | \
    awk '{u=$1; t=$2} 
         match(t, /([0-9]+)-)?([0-9]+):([0-9]+):([0-9.]+)/, a) {
             days=(a[1] ? a[1] : 0)
             hours=a[2]; minutes=a[3]; seconds=a[4]
             total_sec = days*86400 + hours*3600 + minutes*60 + seconds
             wall[u] += total_sec
         }
         END { for (u in wall) printf "%-15s %.2f\n", u, wall[u]/3600 }' | sort -k2 -nr
echo -e "----------------------------------------\n"

# 4. Memory usage per user (GB, estimated from MaxRSS)
echo -e "💾 Memory usage per user (sum of MaxRSS in GB):"
echo -e "----------------------------------------"
sacct -S "$START_DATE" --format=User,MaxRSS --noheader | \
    grep -vE '^\s*$|\.batch|\.interacti\+?$' | \
    awk '{u=$1; m=$2}
         m ~ /K$/ {val = m + 0; mem[u] += val / 1024 / 1024}
         m ~ /M$/ {val = m + 0; mem[u] += val / 1024}
         m ~ /G$/ {val = m + 0; sub("G","",m); mem[u] += m}
         END { for (u in mem) printf "%-15s %.2f GB\n", u, mem[u] }' | sort -k2 -nr
echo -e "----------------------------------------\n"

# 5. Job state summary (user|state|count)
echo -e "📊 Job state per user:"
echo -e "----------------------------------------"
sacct -S "$START_DATE" --format=User,State --noheader | \
    grep -vE '^\s*$|\.batch|\.interacti\+?$' | \
    awk '{print $1 "|" $2}' | sort | uniq -c | \
    awk '{split($2, parts, "|"); printf "%-15s %-15s %s\n", parts[1], parts[2], $1}' | sort
echo -e "----------------------------------------\n"

# 6. Node usage per user
echo -e "🖥️  Nodes used per user:"
echo -e "----------------------------------------"
sacct -S "$START_DATE" --format=User,Nodelist --noheader | \
    grep -vE '^\s*$|\.batch|\.interacti\+?$' | \
    awk '{u=$1; n=$2} n != "" {print u "|" n}' | sort | uniq -c | \
    awk '{split($2, p, "|"); printf "%-15s %-20s %s\n", p[0], p[1], $1}' | sort -k3 -nr
echo -e "----------------------------------------\n"

# 7. Login session stats
echo -e "🔑 Login sessions per user:"
echo -e "----------------------------------------"
last -F | grep -v 'reboot' | grep -v 'wtmp' | awk '
/still logged in/ {next}
/ - / {
    user = $1
    match($0, / - ([A-Za-z]{3} [A-Za-z]{3} [ 0-9]+ [0-9:]{8})/, a)
    match($0, /([0-9]+)\+?([0-9]{2}):([0-9]{2})/, d)
    if (length(d) > 0) {
        days = d[1]; hours = d[2]; mins = d[3]
        dur = days * 24 * 60 + hours * 60 + mins
    } else {
        dur = 0
    }
    login_count[user]++
    total_time[user] += dur
}
END {
    for (u in login_count)
        printf "%-15s Sessions: %-5d  Total active time: %.2f hrs\n", u, login_count[u], total_time[u]/60
}'
echo -e "----------------------------------------\n"

# 8. Summary from sreport
echo -e "📈 SLURM 'Used' time (CPU minutes) from sreport:"
echo -e "----------------------------------------"
sreport user TopUsage start=$START_DATE end=now format=Login,Used
echo -e "----------------------------------------\n"
