# How to use this repository

This repository contains code to replicate the results of [Universal inference meets random projections: a scalable test for log-concavity](https://arxiv.org/abs/2111.09254) by [Robin Dunn](https://robinmdunn.github.io/), [Larry Wasserman](https://www.stat.cmu.edu/~larry/), and [Aaditya Ramdas](http://www.stat.cmu.edu/~aramdas/).

## Folder contents

- [batch_scripts](batch_scripts): Contains SLURM batch scripts to run the simulations. Scripts are labeled by the figure for which their simulations produce data. These scripts run the code in [sim_code](sim_code), using the parameters in [sim_params](sim_params). 
- [data](data): Output of simulations.
- [plot_code](plot_code): Reads simulation outputs from [data](data) and reproduces all figures in the paper. Plots are saved to [plots](plots) folder.
- [plots](plots): Contains all plots in paper.
- [sim_code](sim_code): R code to run simulations. Simulation output is saved to [data](data) folder.
- [sim_params](sim_params): Parameters for simulations. Each row contains a single choice of parameters. The scripts in [sim_code](sim_code) read in these files, and the scripts in [batch_scripts](batch_scripts) loop through all choices of parameters.

## How do I ...

### Produce the simulations for a given figure?

In the [batch_scripts](batch_scripts) folder, scripts are labeled by the figure for which they simulate data. Run all batch scripts corresponding to the figure of interest. The allocated run time is estimated from the choice of parameters for which the code has the longest run time. Many scripts will run faster than this time. The files in [sim_code](sim_code) each contain progress bars to estimate the remaining run time. You may wish to start running these files outside of a batch submission to understand the run time on your computing system. 

Alternatively, to run the code without using a job submission system, click on any .sh file. The Rscript lines can be run on a terminal, replacing $SLURM_ARRAY_TASK_ID with all of the indices in the batch array. 

The simulation output will be stored in the [data](data) folder, with one dataset per choice of parameters. To combine these datasets into a single dataset (as they currently appear in [data](data)), run the code in [sim_code/combine_datasets.R](sim_code/combine_datasets.R).

**Example**: [batch_scripts/fig01_fully_NP_randproj.sh](batch_scripts/fig01_fully_NP_randproj.sh)

This script reproduces the universal test simulations for Figure 1. To do this, it runs the R script at [sim_code/fig01_fully_NP_randproj.R](sim_code/fig01_fully_NP_randproj.R). It reads in the parameters from [sim_params/fig01_fully_NP_randproj_params.csv](sim_params/fig01_fully_NP_randproj_params.csv). There are 30 sets of parameters in total. The results will be stored in the [data](data) folder, with names such as fig01_fully_NP_randproj_1.csv, ..., fig01_fully_NP_randproj_30.csv. To combine these files into a single .csv file, run the code at [sim_code/combine_datasets.R](sim_code/combine_datasets.R).

### Examine the code for a given simulation?

The R code in [sim_code](sim_code) is labeled by the figures for which they simulate data. Click on all files corresponding to a given figure.

### Reproduce a figure without rerunning the simulations?

The R scripts in [plot_code](plot_code) are labeled by their corresponding plots. They read in the necessary simulated data from the [data](data) folder and output the figures to the [plots](plots) folder.
