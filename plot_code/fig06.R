# Create Figure 6 in appendix.
# Plot log-concave MLE densities for normal mixtures at n = 50 and d = 1.

suppressMessages(library(data.table))
suppressMessages(library(tidyverse))

# Create theme
paper_theme <- theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        plot.subtitle = element_text(hjust = 0.5, size = 14),
        legend.title = element_text(size = 14),
        axis.title = element_text(size = 14),
        legend.text = element_text(size = 12),
        axis.text = element_text(size = 12),
        strip.text = element_text(size = 12),
        panel.spacing = unit(1.2, "lines"))

# Read in data
density_points <- fread("data/fig06_points.csv")

density_values <- fread("data/fig06_densities.csv")

# Check parameters
stopifnot(unique(density_values$d) == 1,
          unique(density_values$n_obs) == 50)

# Extract (1/n)*loglik values
loglik_df <- density_values %>% 
  group_by(mu_norm) %>% 
  slice(1) %>% 
  pivot_longer(cols = c("mean_loglik_true_dens", "mean_loglik_LogConcDEAD",
                        "mean_loglik_logcondens")) %>% 
  mutate(name = factor(name, 
                       levels = c("mean_loglik_true_dens", 
                                  "mean_loglik_LogConcDEAD",
                                  "mean_loglik_logcondens"),
                       labels = c("True density", 
                                  "Log-concave MLE (LogConcDEAD)",
                                  "Log-concave MLE (logcondens)")),
         mu_norm = factor(mu_norm, levels = c(0, 2, 4),
                          labels = c("||u|| = 0", "||u|| = 2", "||u|| = 4")))

# Plot densities
logconc_densities_n50_d1 <- density_values %>% 
  pivot_longer(cols = c("true_density", "LogConcDEAD_density",
                        "logcondens_density")) %>% 
  mutate(name = factor(name, levels = c("true_density", "LogConcDEAD_density",
                                        "logcondens_density"),
                       labels = c("True density", 
                                  "Log-concave MLE (LogConcDEAD)",
                                  "Log-concave MLE (logcondens)")),
         mu_norm = factor(mu_norm, levels = c(0, 2, 4),
                          labels = c("||u|| = 0", "||u|| = 2", "||u|| = 4"))) %>% 
  ggplot(aes(x = x, y = value)) + 
  geom_line() +
  facet_grid(mu_norm ~ name, scales = "free") +
  geom_rug(aes(x = x), sides = "b", inherit.aes = F, 
           data = density_points) +
  geom_text(aes(x = -4.5, y = 0.35, 
                label = paste("\n", "(1/n)*loglik =", round(value, 2))), 
            data = loglik_df %>% filter(d == 1, n_obs == 50)) +
  paper_theme +
  labs(y = "Density",
       title = "True density and log-concave MLE estimates, n = 50, d = 1")

#####################
##### Save plot #####
#####################

ggsave(plot = logconc_densities_n50_d1,
       filename = "plots/figure_06.pdf",
       width = 9.7, height = 5)
