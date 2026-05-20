#!/bin/bash
#SBATCH --job-name=tumor-sim
#SBATCH --partition=cpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:30:00
#SBATCH --output=/home/jsequeira/logs/%x_%A_%a.out
#SBATCH --error=/home/jsequeira/logs/%x_%A_%a.err

cd /home/jsequeira/cancer_job

SUBMIT_DIR=$(pwd)

. .env/bin/activate

srun --multi-prog multi.conf
