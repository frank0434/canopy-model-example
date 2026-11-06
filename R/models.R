beta_model <- function(GDD, mu, alpha, beta, t1, te) {
  result <- rep(0, length(GDD))
  inside <- GDD > t1 & GDD < te
  result[inside] <- exp(mu) * (GDD[inside] - t1)^alpha *
    (te - GDD[inside])^beta
  result
}

piecewise_model <- function(GDD, tm1, t1, t2, te, vmax) {
  result <- rep(0, length(GDD))
  growth <- GDD >= 0 & GDD < t1
  plateau <- GDD >= t1 & GDD <= t2
  decline <- GDD > t2 & GDD < te
  result[growth] <- vmax * (1 + (t1 - GDD[growth]) / (t1 - tm1)) *
    (GDD[growth] / t1)^(t1 / (t1 - tm1))
  result[plateau] <- vmax
  result[decline] <- vmax * ((te - GDD[decline]) / (te - t2)) *
    ((GDD[decline] + t1 - t2) / t1)^(t1 / (te - t2))
  result
}

fit_models <- function(data) {
  if (!all(c("GDD", "CC") %in% names(data)) ||
      !is.numeric(data$GDD) || !is.numeric(data$CC) ||
      any(!is.finite(data$GDD)) || any(!is.finite(data$CC)) ||
      any(data$GDD < 0) || any(data$CC < 0 | data$CC > 1) ||
      nrow(data) < 6 || length(unique(data$GDD)) < 6) {
    stop("Data must contain at least six distinct nonnegative numeric GDD values and finite CC fractions in [0, 1].")
  }
  if (!requireNamespace("minpack.lm", quietly = TRUE)) {
    stop("Install the minpack.lm package: install.packages('minpack.lm')")
  }

  # Bounds and starts are tailored to the included synthetic data.
  beta_fit <- minpack.lm::nlsLM(
    CC ~ beta_model(GDD, mu, alpha, beta, t1, te), data = data,
    start = list(mu = -18, alpha = 0.8, beta = 2, t1 = 30, te = 1250),
    lower = c(mu = -40, alpha = 0.1, beta = 0.1, t1 = 0, te = 1000),
    upper = c(mu = 5, alpha = 5, beta = 5, t1 = 100, te = 2000),
    control = minpack.lm::nls.lm.control(maxiter = 1000)
  )
  piecewise_fit <- minpack.lm::nlsLM(
    CC ~ piecewise_model(GDD, tm1, t1, t2, te, vmax), data = data,
    start = list(tm1 = 150, t1 = 370, t2 = 650, te = 1250, vmax = 0.8),
    lower = c(tm1 = 1, t1 = 250, t2 = 500, te = 1000, vmax = 0),
    upper = c(tm1 = 249, t1 = 500, t2 = 800, te = 1500, vmax = 1),
    control = minpack.lm::nls.lm.control(maxiter = 1000)
  )
  if (!beta_fit$convInfo$isConv || !piecewise_fit$convInfo$isConv) {
    stop("A model did not converge; inspect the observations, starting values and bounds.")
  }
  list(beta = beta_fit, piecewise = piecewise_fit)
}
