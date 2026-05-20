alias sq='squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --me'
alias sac='sacct --format=JobID,JobName%40,Partition,User,AllocCPUS,ReqMem,Start,End,TimeLimit,State,ExitCode'