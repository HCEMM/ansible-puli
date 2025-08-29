#!/bin/bash
#SBATCH --job-name=tumor-sim
#SBATCH --partition=cpu
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

cd $SLURM_SUBMIT_DIR
module load python

srun --multi-prog $SLURM_SUBMIT_DIR/multi.conf
