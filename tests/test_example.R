source("R/models.R")
data <- read.csv("data/example_canopy.csv")
fits <- fit_models(data)
stopifnot(all(vapply(fits, function(fit) fit$convInfo$isConv, logical(1))))
for (fit in fits) {
  predictions <- predict(fit, newdata = data)
  stopifnot(all(is.finite(predictions)),
            sqrt(mean((data$CC - predictions)^2)) < 0.10)
}
p <- coef(fits$piecewise)
stopifnot(p["tm1"] < p["t1"], p["t1"] <= p["t2"], p["t2"] < p["te"])
stopifnot(identical(beta_model(c(-1, 0, 10, 11), -2, 1.1, 1.3, 0, 10),
                    c(0, 0, 0, 0)))
stopifnot(identical(piecewise_model(c(-1, 0, 10, 11), 1, 3, 5, 10, 0.8),
                    c(0, 0, 0, 0)))
stopifnot(isTRUE(all.equal(piecewise_model(c(3, 5), 1, 3, 5, 10, 0.8),
                           c(0.8, 0.8))))
bad <- data
bad$CC[1] <- 100
stopifnot(inherits(try(fit_models(bad), silent = TRUE), "try-error"))
cat("Model checks passed.\n")
