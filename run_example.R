args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 2) stop("Usage: Rscript run_example.R [data.csv] [output-directory]")
input <- if (length(args) >= 1) args[1] else "data/example_canopy.csv"
output <- if (length(args) >= 2) args[2] else "output"
source("R/models.R")

data <- read.csv(input)
fits <- fit_models(data)
dir.create(output, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(output)) stop("Could not create output directory: ", output)

cat("\nBeta coefficients:\n")
print(coef(fits$beta))
cat("\nPiecewise coefficients:\n")
print(coef(fits$piecewise))
beta_params <- coef(fits$beta)
beta_peak_gdd <- unname(beta_params["t1"] + beta_params["alpha"] /
  (beta_params["alpha"] + beta_params["beta"]) *
  (beta_params["te"] - beta_params["t1"]))
cat("\nBeta peak GDD:", beta_peak_gdd, "\n")
cat("Beta peak canopy fraction:", predict(fits$beta, newdata = data.frame(GDD = beta_peak_gdd)), "\n")
cat("\nAIC (lower is better for these two fits to the same observations):\n")
print(AIC(fits$beta, fits$piecewise))

grid <- data.frame(GDD = seq(min(data$GDD), max(data$GDD), length.out = 501))
grid$beta <- predict(fits$beta, newdata = grid)
grid$piecewise <- predict(fits$piecewise, newdata = grid)
write.csv(grid, file.path(output, "predictions.csv"), row.names = FALSE)

png(file.path(output, "canopy_models.png"), width = 900, height = 600)
plot(data$GDD, data$CC, xlab = "Growing degree days (GDD)",
     ylab = "Canopy cover (fraction)", pch = 16, col = "grey40",
     ylim = range(c(0, 1, grid$beta, grid$piecewise)))
lines(grid$GDD, grid$beta, col = "steelblue", lwd = 2)
lines(grid$GDD, grid$piecewise, col = "firebrick", lwd = 2)
legend("topright", c("Observations", "Beta", "Piecewise"),
       col = c("grey40", "steelblue", "firebrick"), pch = c(16, NA, NA),
       lty = c(NA, 1, 1), lwd = 2, bty = "n")
dev.off()
cat("\nWrote predictions.csv and canopy_models.png to", output, "\n")
