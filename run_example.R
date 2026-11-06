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

observations <- data.frame(GDD = data$GDD, CC = data$CC)
curves <- rbind(
  data.frame(GDD = grid$GDD, CC = grid$beta, Model = "Beta"),
  data.frame(GDD = grid$GDD, CC = grid$piecewise, Model = "Piecewise")
)
plot <- ggplot2::ggplot() +
  ggplot2::geom_point(
    data = observations,
    ggplot2::aes(x = GDD, y = CC),
    colour = "grey40"
  ) +
  ggplot2::geom_line(
    data = curves,
    ggplot2::aes(x = GDD, y = CC, colour = Model),
    linewidth = 1
  ) +
  ggplot2::scale_colour_manual(
    values = c(Beta = "steelblue", Piecewise = "firebrick")
  ) +
  ggplot2::labs(
    x = "Growing degree days (GDD)",
    y = "Canopy cover (fraction)",
    colour = "Model"
  ) +
  ggplot2::theme_minimal()
ggplot2::ggsave(
  file.path(output, "canopy_models.png"),
  plot = plot,
  width = 9,
  height = 6,
  dpi = 100
)
cat("\nWrote predictions.csv and canopy_models.png to", output, "\n")
