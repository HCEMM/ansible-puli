#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
PINK='\033[1;31m'
RESET='\033[0m'

echo -e "                                                                                                            "
echo -e "                                                                                                            "
echo -e "               a@@@@@@@@@@                                                                                  "
echo -e "            d@@@|        @@@M                                                                               "
echo -e "          I@@c   \"@@@@@{   \"@@-                                                                           "
echo -e "         |@@   @@@a{ Id@@@|  M@J                                                                            "
echo -e "         @@  d@@         O@@  @@                                                                            "
echo -e "        j@{ c@M  @@@@@@@  -@O  @@       @@@@@@@@@@@@@M    @@          >@a     @@              M@            "
echo -e "        d@  @@  @@-    @@  @@  @@       @@          O@>   @@          >@a     @@              M@            "
echo -e "        d@  @@  @@  @j @@  @@  @@       @@          @@    @@          >@a     @@              @@            "
echo -e "        d@  @@  @@  -  @@  @@  @@       @@@@@@@@@@@@@     @@I         |@O     @@              M@            "
echo -e "        d@  @@  @@${PINK}IJJJI${RESET}@@  @@  @@       @@                 @@         @@      M@|             M@            "
echo -e "        d@  @@  @@ ${PINK}JJJ${RESET} @@  @@  @@       @@                  @@@>   -@@@        d@@j           @@            "
echo -e "         J  @@  @@     @@  @@  |{       @@                    J@@@@@|            I@@@@@@@@    d@            "
echo -e "            @@  @@     @@  @@                                                                               "
echo -e "                @@     @@                                                                                   "
echo -e "                O@     O@                                                                                   "
echo -e "                                                                                                            "
echo -e "                                                                                                            "
echo -e "    Welcome to the PULI Cluster!"
echo -e "    ------------------------------"
echo -e "    🖥️ System Info:"
echo -e ""

# Fetching system information
hostname=$(hostname)
uptime=$(uptime -p)
users_logged=$(who | awk '{print $1}' | sort | uniq | wc -l)
processes=$(ps ax | wc -l)
cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')    # CPU load is 100% minus idle time
mem_total=$(free -m | awk 'NR==2{printf "%.2f", $2/1024}')          # Total memory in GB
mem_used=$(free -m | awk 'NR==2{printf "%.2f", $3/1024}')           # Used memory in GB
mem_percentage=$(free | awk 'NR==2{printf "%.2f", $3/$2 * 100.0}')  # Percentage used
disk_used=$(df -h / | awk 'NR==2 {print $3}')                       # Disk space used
disk_total=$(df -h / | awk 'NR==2 {print $2}')                      # Total disk space
disk_percentage=$(df -h / | awk 'NR==2 {print $5}')                 # Disk space percentage used
home_used=$(df -h /home | awk 'NR==2 {print $3}')                   # Home directory space used
home_total=$(df -h /home | awk 'NR==2 {print $2}')                  # Total home directory space
home_percentage=$(df -h /home | awk 'NR==2 {print $5}')             # Home directory space percentage used

# Displaying system info
echo -e "    Hostname         : $hostname"
echo -e "    Uptime           : $uptime"
echo -e "    Users Logged In  : $users_logged"
echo -e "    Processes        : $processes"
echo -e "    CPU Load         : $cpu_load used"
echo -e "    Memory Usage     : $mem_used GB / $mem_total GB ($mem_percentage%)"
echo -e "    Disk Usage       : $disk_used / $disk_total ($disk_percentage used)"
echo -e "    Home Directory   : $home_used / $home_total ($home_percentage used)"
echo -e ""
echo -e "    --------------------------------"
echo -e "    Keep calm and compute on! 🦴"
echo -e ""
echo -e "    The PULI cluster has some built-in features that might be helpful for your work. Run \`puli-tools\` for details."
echo -e ""