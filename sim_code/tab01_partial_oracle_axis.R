# Benchmark partial oracle, axis-aligned projections
# Test H_0: log-concave versus H_1: not log-concave using universal LRT.
# Split data into D_0 and D_1. 
# Consider each component separately (d >= 2).
# Get Gaussian mixture EM estimate on D_1. Get log-concave MLE on D_0.
# Evaluate at all values in D_0.
# Reject if T_{n,k} >= d/alpha for at least one k \in {1, 2, ..., d}.

suppressMessages(library(logcondens))
suppressMessages(library(MASS))
suppressMessages(library(data.table))
suppressMessages(library(progress))
suppressMessages(library(tidyverse))
suppressMessages(library(mclust))

# Read in arguments for file with all parameters and 
# line number for parameters for current simulation.

parameter_file <- "sim_params/tab01_partial_oracle_axis_params.csv"
line_number <- 1

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  parameter_file <- args[1]
  line_number <- as.numeric(args[2])
}

parameter_df <- fread(parameter_file)

# Assign arguments based on input.
# Arguments are d (dimension), mu_norm, n_obs (number of obs),
# start_sim (index of starting sim), n_sim (number of sims), 
# B (number of subsamples),
# equal_space_mu (indicator for mu structure. 
#                 If 1, each component is ||mu||*d^(-1/2).
#                 If 0, mu = (||mu||, 0, ... 0).
parameters <- parameter_df %>% slice(line_number)
d <- parameters$d
mu_norm <- parameters$mu_norm
n_obs <- parameters$n_obs
start_sim <- parameters$start_sim
n_sim <- parameters$n_sim
B <- parameters$B
equal_space_mu <- parameters$equal_space_mu

# Create mu vector
if(equal_space_mu == 0) {
  mu <- rep(0, d)
  mu[1] <- mu_norm
} else if(equal_space_mu == 1) {
  mu <- rep(mu_norm * d^(-1/2), d)
}

# Proportions for the two Gaussian components
p <- 0.5

# Alpha level
alpha <- 0.1

# Create data frame to store results
results <- data.table(Method = "Partial oracle, axis-aligned projections",
                      n_obs = n_obs, d = d, mu_norm = mu_norm,
                      equal_space_mu = equal_space_mu, B = B,
                      sim = start_sim:(start_sim + n_sim - 1), alpha = alpha,
                      p_0 = p, time_sec = NA_real_)

# Run simulations to check whether to reject H_0
for(row in 1:nrow(results)) {
  
  # Generate sample from two-component normal location model
  true_sample <- matrix(NA, nrow = n_obs, ncol = d)
  
  for(i in 1:n_obs) {
    mixture_comp <- rbinom(n = 1, size = 1, prob = p)
    if(mixture_comp == 0) {
      true_sample[i, ] <- rnorm(n = d, mean = 0, sd = 1)
    } else if(mixture_comp == 1) {
      true_sample[i, ] <- mvrnorm(n = 1, mu = 0 - mu, Sigma = diag(d))
    }
  }
  
  # Get start time for simulation
  start_time <- proc.time()[3]
  
  # Matrix of subsampled test statistics
  ts_mat <- matrix(NA, nrow = B, ncol = d)
  
  # Consider each dimension separately
  for(d_val in 1:d) {
    
    # Repeatedly subsample to get subsampled test statistic on each dimension
    for(b in 1:B) {
      
      # Split Y into Y_0 and Y_1
      Y_0_indices <- sample(1:n_obs, size = n_obs/2)
      
      Y_1_indices <- setdiff(1:n_obs, Y_0_indices)
      
      Y_0 <- matrix(true_sample[Y_0_indices, ], ncol = d)
      
      Y_1 <- matrix(true_sample[Y_1_indices, ], ncol = d)
      
      # Remove previously fitted mclust_dens_D1 object
      if(exists("mclust_dens_D1")) { rm(mclust_dens_D1) }
      
      # Get two-component Gaussian mixture estimate for each dimension on D_1.
      # modelNames:
      #   - V: unequal variance
      #   - E: equal variance
      
      mclust_dens_D1 <- try(densityMclust(data = Y_1[, d_val], G = 2, 
                                          modelNames = "V",
                                          warn = FALSE, verbose = FALSE))
      if(is(mclust_dens_D1, "try-error") | is.null(mclust_dens_D1)) {
        mclust_dens_D1 <- try(densityMclust(data = Y_1[, d_val], G = 2, 
                                            modelNames = "E",
                                            warn = FALSE, verbose = FALSE))
      }
      
      # If mclust_dens_D1 is not an Mclust object, fit a single Normal density.
      # (This is very rare in simulations.)
      if(!("Mclust" %in% class(mclust_dens_D1))) {
        print("Fitting single Normal density")
        mclust_dens_D1 <- try(densityMclust(data = Y_1, G = 1, modelNames = "V",
                                            warn = FALSE, verbose = FALSE,
                                            plot = FALSE))
      }
      
      # Evaluate Gaussian mixture on D_0
      eval_gauss_mix_D0 <- predict.densityMclust(object = mclust_dens_D1, 
                                                 newdata = Y_0[, d_val], 
                                                 what = "dens")
      
      # Stop if max evaluated density is over 100 (probably convergence issue)
      # (Never occurs in simulations.)
      stopifnot(max(eval_gauss_mix_D0) < 100)
      
      # Get log-concave MLE on D_0
      log_concave_D0 <- logConDens(x = Y_0[, d_val])
      
      # Evaluate log-concave MLE on D_0
      eval_log_concave_D0 <- evaluateLogConDens(
        xs = Y_0[, d_val], res = log_concave_D0, which = 2)[, 3]
      
      # Store dimension d, subsample B test stat
      ts_mat[b, d_val] <- 
        exp(sum(log(eval_gauss_mix_D0)) - sum(log(eval_log_concave_D0)))
      
      # Break if you would reject based on current info
      if(sum(apply(ts_mat, MARGIN = 2, FUN = function(x) sum(x, na.rm = T)) >= 
             B * d /alpha) >= 1 & b < B) {
        ts_mat[(b+1):B, d_val] <- 0
        break
      }
      
    }
    
  }
  
  # Get end time for simulation
  end_time <- proc.time()[3]
  
  # Store run time for simulation
  results[row, time_sec := end_time - start_time]
  
}

# Save simulation results
fwrite(results, file = paste0("data/tab01_partial_oracle_axis_",
                              line_number, ".csv"))